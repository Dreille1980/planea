//
//  PleneaWidget.swift
//  PleneaWidget
//
//  Created by Frederic Dreyer on 2025-11-06.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Entry
struct WeeklyPlanEntry: TimelineEntry {
    let date: Date
    let meals: [WidgetMealItem]
    let planName: String?
    let displayDay: String
    let isToday: Bool
}

// MARK: - Timeline Provider
struct WeeklyPlanProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyPlanEntry {
        WeeklyPlanEntry(
            date: Date(),
            meals: [],
            planName: "Plan de la semaine",
            displayDay: "Aujourd'hui",
            isToday: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WeeklyPlanEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyPlanEntry>) -> Void) {
        let entry = loadCurrentEntry()
        
        // Refresh widget at midnight and every 4 hours
        let currentDate = Date()
        let nextMidnight = Calendar.current.startOfDay(for: currentDate.addingTimeInterval(86400))
        let nextUpdate = min(
            nextMidnight,
            currentDate.addingTimeInterval(4 * 3600) // 4 hours
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCurrentEntry() -> WeeklyPlanEntry {
        print("Widget: Loading current entry...")
        
        // Try to load meals from Core Data
        if let result = loadMealsFromCoreData() {
            print("Widget: Found meals for \(result.displayDay)")
            return WeeklyPlanEntry(
                date: Date(),
                meals: result.meals,
                planName: result.planName,
                displayDay: result.displayDay,
                isToday: result.isToday
            )
        } else {
            print("Widget: No meals found")
            return WeeklyPlanEntry(
                date: Date(),
                meals: [],
                planName: nil,
                displayDay: "Aujourd'hui",
                isToday: true
            )
        }
    }
    
    private func loadMealsFromCoreData() -> (meals: [WidgetMealItem], planName: String?, displayDay: String, isToday: Bool)? {
        // Access shared Core Data store
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.dreille.planea"
        ) else {
            print("Widget: Failed to get App Group URL")
            return nil
        }
        
        let storeURL = appGroupURL.appendingPathComponent("Planea.sqlite")
        print("Widget: Store URL: \(storeURL.path)")
        
        // Check if file exists
        if !FileManager.default.fileExists(atPath: storeURL.path) {
            print("Widget: Store file does not exist at path")
            return nil
        }
        
        let container = NSPersistentContainer(name: "Planea")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSReadOnlyPersistentStoreOption)
        container.persistentStoreDescriptions = [description]
        
        var result: (meals: [WidgetMealItem], planName: String?, displayDay: String, isToday: Bool)?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        container.loadPersistentStores { _, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("Widget: Failed to load Core Data: \(error.localizedDescription)")
                return
            }
            
            print("Widget: Core Data loaded successfully")
            
            let context = container.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: "MealPlanEntity")
            request.predicate = NSPredicate(format: "status == %@", "active")
            request.fetchLimit = 1
            
            do {
                guard let planEntity = try context.fetch(request).first else {
                    print("Widget: No active plan found")
                    return
                }
                
                print("Widget: Active plan found")
                
                // Get plan name
                let planName = planEntity.value(forKey: "name") as? String
                
                // Decode items using Codable
                guard let itemsData = planEntity.value(forKey: "itemsData") as? Data else {
                    print("Widget: No items data")
                    return
                }
                
                // Define a temporary MealItem structure for decoding
                struct TempMealItem: Codable {
                    let id: UUID
                    let weekday: String
                    let mealType: String
                    let recipe: TempRecipe
                    
                    struct TempRecipe: Codable {
                        let title: String
                        let servings: Int
                        let totalMinutes: Int
                    }
                    
                    enum CodingKeys: String, CodingKey {
                        case id, weekday, recipe
                        case mealType = "meal_type"
                    }
                }
                
                guard let decodedItems = try? JSONDecoder().decode([TempMealItem].self, from: itemsData) else {
                    print("Widget: Failed to decode items")
                    return
                }
                
                print("Widget: Decoded \(decodedItems.count) items")
                
                // Convert to WidgetMealItem
                let allMeals = decodedItems.map { item in
                    WidgetMealItem(
                        id: item.id,
                        weekday: item.weekday,
                        mealType: item.mealType,
                        recipeTitle: item.recipe.title,
                        recipeServings: item.recipe.servings,
                        recipeTotalMinutes: item.recipe.totalMinutes
                    )
                }
                
                // Find meals for today or next available day
                let today = Date()
                let todayWeekdayString = today.weekdayString
                
                // Try today first
                let todayMeals = allMeals.filter { $0.weekday == todayWeekdayString }
                    .sorted { ($0.mealTypeEnum?.sortOrder ?? 0) < ($1.mealTypeEnum?.sortOrder ?? 0) }
                
                if !todayMeals.isEmpty {
                    print("Widget: Found \(todayMeals.count) meals for today")
                    result = (
                        meals: todayMeals,
                        planName: planName,
                        displayDay: "Aujourd'hui",
                        isToday: true
                    )
                    return
                }
                
                print("Widget: No meals for today, looking for next day with meals...")
                
                // Look for next day with meals (up to 7 days ahead)
                for dayOffset in 1...7 {
                    let futureDate = today.addingDays(dayOffset)
                    let futureWeekdayString = futureDate.weekdayString
                    
                    let futureMeals = allMeals.filter { $0.weekday == futureWeekdayString }
                        .sorted { ($0.mealTypeEnum?.sortOrder ?? 0) < ($1.mealTypeEnum?.sortOrder ?? 0) }
                    
                    if !futureMeals.isEmpty {
                        let displayDay = futureDate.dayName(relativeTo: today)
                        print("Widget: Found \(futureMeals.count) meals for \(displayDay)")
                        result = (
                            meals: futureMeals,
                            planName: planName,
                            displayDay: displayDay,
                            isToday: false
                        )
                        return
                    }
                }
                
                print("Widget: No meals found for next 7 days")
                
            } catch {
                print("Widget: Error fetching plan: \(error.localizedDescription)")
            }
        }
        
        // Wait for Core Data to finish (with timeout)
        _ = semaphore.wait(timeout: .now() + 2)
        
        return result
    }
}

// MARK: - Widget View
struct PlaneaWidgetEntryView: View {
    var entry: WeeklyPlanProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: WeeklyPlanEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(entry.displayDay)
                    .font(.caption)
                    .bold()
                Spacer()
            }
            .foregroundStyle(entry.isToday ? .blue : .orange)
            
            if entry.meals.isEmpty {
                Spacer()
                Text("Aucun repas planifié")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ForEach(entry.meals.prefix(2)) { meal in
                    MealRow(meal: meal, compact: true)
                }
                
                if entry.meals.count > 2 {
                    Text("+\(entry.meals.count - 2) autre(s)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: WeeklyPlanEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Icon and title
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title)
                    .foregroundStyle(entry.isToday ? .blue : .orange)
                
                if let planName = entry.planName {
                    Text(planName)
                        .font(.caption)
                        .bold()
                        .lineLimit(2)
                } else {
                    Text("Plan de la semaine")
                        .font(.caption)
                        .bold()
                }
                
                Text(entry.displayDay)
                    .font(.caption2)
                    .foregroundStyle(entry.isToday ? .blue : .orange)
                
                Spacer()
            }
            .frame(width: 80)
            
            Divider()
            
            // Right side - Meals
            VStack(alignment: .leading, spacing: 8) {
                if entry.meals.isEmpty {
                    Spacer()
                    Text("Aucun repas planifié")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ForEach(entry.meals) { meal in
                        MealRow(meal: meal, compact: false)
                    }
                    Spacer()
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: WeeklyPlanEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(entry.isToday ? .blue : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let planName = entry.planName {
                        Text(planName)
                            .font(.headline)
                    } else {
                        Text("Plan de la semaine")
                            .font(.headline)
                    }
                    
                    Text("\(entry.displayDay) - \(formattedDate)")
                        .font(.caption)
                        .foregroundStyle(entry.isToday ? .blue : .orange)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Meals list
            if entry.meals.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Aucun repas planifié")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(entry.meals) { meal in
                        MealRow(meal: meal, compact: false)
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "fr_CA")
        return formatter.string(from: entry.date)
    }
}

// MARK: - Meal Row Component
struct MealRow: View {
    let meal: WidgetMealItem
    let compact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(compact ? .caption : .body)
                .foregroundStyle(iconColor)
                .frame(width: compact ? 16 : 24)
            
            VStack(alignment: .leading, spacing: 2) {
                if !compact {
                    Text(meal.mealTypeEnum?.displayName ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(meal.recipeTitle)
                    .font(compact ? .caption : .caption)
                    .lineLimit(compact ? 1 : 2)
                    .bold()
            }
        }
    }
    
    private var iconName: String {
        switch meal.mealTypeEnum {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        case .none: return "fork.knife"
        }
    }
    
    private var iconColor: Color {
        switch meal.mealTypeEnum {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        case .none: return .gray
        }
    }
}

// MARK: - Widget Configuration
struct PlaneaWidget: Widget {
    let kind: String = "PlaneaWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyPlanProvider()) { entry in
            PlaneaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Plan de la semaine")
        .description("Affiche vos repas planifiés pour aujourd'hui ou les prochains à venir")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    PlaneaWidget()
} timeline: {
    WeeklyPlanEntry(
        date: .now,
        meals: [
            WidgetMealItem(
                id: UUID(),
                weekday: "Mon",
                mealType: "BREAKFAST",
                recipeTitle: "Omelette aux légumes",
                recipeServings: 2,
                recipeTotalMinutes: 15
            ),
            WidgetMealItem(
                id: UUID(),
                weekday: "Mon",
                mealType: "DINNER",
                recipeTitle: "Poulet rôti et légumes",
                recipeServings: 4,
                recipeTotalMinutes: 45
            )
        ],
        planName: "Semaine du 6 novembre",
        displayDay: "Aujourd'hui",
        isToday: true
    )
}

#Preview(as: .systemMedium) {
    PlaneaWidget()
} timeline: {
    WeeklyPlanEntry(
        date: .now,
        meals: [
            WidgetMealItem(
                id: UUID(),
                weekday: "Tue",
                mealType: "LUNCH",
                recipeTitle: "Salade César au poulet",
                recipeServings: 2,
                recipeTotalMinutes: 20
            ),
            WidgetMealItem(
                id: UUID(),
                weekday: "Tue",
                mealType: "DINNER",
                recipeTitle: "Spaghetti bolognaise",
                recipeServings: 4,
                recipeTotalMinutes: 30
            )
        ],
        planName: "Semaine du 6 novembre",
        displayDay: "Demain",
        isToday: false
    )
}
