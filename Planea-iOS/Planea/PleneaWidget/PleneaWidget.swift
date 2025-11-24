//
//  PleneaWidget.swift
//  PleneaWidget
//
//  Created by Frederic Dreyer on 2025-11-06.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Models (Simplified versions for widget use only)
struct WidgetMealItem: Identifiable {
    let id: UUID
    let weekday: WidgetWeekday
    let mealType: WidgetMealType
    let recipeTitle: String
    let recipeServings: Int
    let recipeTotalMinutes: Int
}

enum WidgetWeekday: String {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    case sunday = "Sun"
}

enum WidgetMealType: String {
    case breakfast = "BREAKFAST"
    case lunch = "LUNCH"
    case dinner = "DINNER"
    case snack = "SNACK"
    
    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .snack: return 2
        case .dinner: return 3
        }
    }
}

// MARK: - Widget Entry
struct WeeklyPlanEntry: TimelineEntry {
    let date: Date
    let todayMeals: [WidgetMealItem]
    let planName: String?
}

// MARK: - Timeline Provider
struct WeeklyPlanProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyPlanEntry {
        WeeklyPlanEntry(
            date: Date(),
            todayMeals: [],
            planName: "Plan de la semaine"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WeeklyPlanEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyPlanEntry>) -> Void) {
        let entry = loadCurrentEntry()
        
        // Refresh widget at midnight and every 6 hours
        let currentDate = Date()
        let nextMidnight = Calendar.current.startOfDay(for: currentDate.addingTimeInterval(86400))
        let nextUpdate = min(
            nextMidnight,
            currentDate.addingTimeInterval(6 * 3600) // 6 hours
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCurrentEntry() -> WeeklyPlanEntry {
        // Get today's weekday
        let today = Calendar.current.component(.weekday, from: Date())
        let weekday = convertToWidgetWeekday(today)
        
        // Load active plan from Core Data
        guard let activePlan = loadActivePlan() else {
            return WeeklyPlanEntry(date: Date(), todayMeals: [], planName: nil)
        }
        
        // Filter meals for today
        let todayMeals = activePlan.meals.filter { $0.weekday == weekday }
            .sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
        
        return WeeklyPlanEntry(
            date: Date(),
            todayMeals: todayMeals,
            planName: activePlan.name
        )
    }
    
    private func convertToWidgetWeekday(_ calendarWeekday: Int) -> WidgetWeekday {
        // Calendar.component(.weekday) returns: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
    
    private func loadActivePlan() -> (meals: [WidgetMealItem], name: String?)? {
        // Access shared Core Data store
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.dreille.planea"
        ) else {
            return nil
        }
        
        let storeURL = appGroupURL.appendingPathComponent("Planea.sqlite")
        
        let container = NSPersistentContainer(name: "Planea")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions = [description]
        
        var result: (meals: [WidgetMealItem], name: String?)?
        
        let group = DispatchGroup()
        group.enter()
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Widget: Failed to load Core Data: \(error.localizedDescription)")
                group.leave()
                return
            }
            
            let context = container.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: "MealPlanEntity")
            request.predicate = NSPredicate(format: "status == %@", "active")
            request.fetchLimit = 1
            
            do {
                guard let planEntity = try context.fetch(request).first else {
                    group.leave()
                    return
                }
                
                // Get plan name
                let planName = planEntity.value(forKey: "name") as? String
                
                // Decode items
                guard let itemsData = planEntity.value(forKey: "itemsData") as? Data else {
                    group.leave()
                    return
                }
                
                // Manually decode the JSON
                if let jsonArray = try? JSONSerialization.jsonObject(with: itemsData) as? [[String: Any]] {
                    var meals: [WidgetMealItem] = []
                    
                    for item in jsonArray {
                        guard let idString = item["id"] as? String,
                              let id = UUID(uuidString: idString),
                              let weekdayRaw = item["weekday"] as? String,
                              let mealTypeRaw = item["mealType"] as? String,
                              let recipeDict = item["recipe"] as? [String: Any],
                              let recipeTitle = recipeDict["title"] as? String,
                              let servings = recipeDict["servings"] as? Int,
                              let totalMinutes = recipeDict["totalMinutes"] as? Int,
                              let weekday = WidgetWeekday(rawValue: weekdayRaw),
                              let mealType = WidgetMealType(rawValue: mealTypeRaw) else {
                            continue
                        }
                        
                        let meal = WidgetMealItem(
                            id: id,
                            weekday: weekday,
                            mealType: mealType,
                            recipeTitle: recipeTitle,
                            recipeServings: servings,
                            recipeTotalMinutes: totalMinutes
                        )
                        meals.append(meal)
                    }
                    
                    result = (meals: meals, name: planName)
                }
            } catch {
                print("Widget: Error fetching plan: \(error.localizedDescription)")
            }
            
            group.leave()
        }
        
        group.wait()
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
                Text("Aujourd'hui")
                    .font(.caption)
                    .bold()
                Spacer()
            }
            .foregroundStyle(.secondary)
            
            if entry.todayMeals.isEmpty {
                Spacer()
                Text("Aucun repas planifié")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ForEach(entry.todayMeals.prefix(2)) { meal in
                    MealRow(meal: meal, compact: true)
                }
                
                if entry.todayMeals.count > 2 {
                    Text("+\(entry.todayMeals.count - 2) autre(s)")
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
                    .foregroundStyle(.blue)
                
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
                
                Text("Aujourd'hui")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .frame(width: 80)
            
            Divider()
            
            // Right side - Meals
            VStack(alignment: .leading, spacing: 8) {
                if entry.todayMeals.isEmpty {
                    Spacer()
                    Text("Aucun repas planifié pour aujourd'hui")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ForEach(entry.todayMeals) { meal in
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
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let planName = entry.planName {
                        Text(planName)
                            .font(.headline)
                    } else {
                        Text("Plan de la semaine")
                            .font(.headline)
                    }
                    
                    Text("Aujourd'hui - \(formattedDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Meals list
            if entry.todayMeals.isEmpty {
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
                    ForEach(entry.todayMeals) { meal in
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
                    Text(mealTypeLabel)
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
        switch meal.mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    private var iconColor: Color {
        switch meal.mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        }
    }
    
    private var mealTypeLabel: String {
        switch meal.mealType {
        case .breakfast: return "Déjeuner"
        case .lunch: return "Dîner"
        case .dinner: return "Souper"
        case .snack: return "Collation"
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
        .description("Affiche vos repas planifiés pour aujourd'hui")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    PlaneaWidget()
} timeline: {
    WeeklyPlanEntry(
        date: .now,
        todayMeals: [
            WidgetMealItem(
                id: UUID(),
                weekday: .monday,
                mealType: .breakfast,
                recipeTitle: "Omelette aux légumes",
                recipeServings: 2,
                recipeTotalMinutes: 15
            ),
            WidgetMealItem(
                id: UUID(),
                weekday: .monday,
                mealType: .dinner,
                recipeTitle: "Poulet rôti et légumes",
                recipeServings: 4,
                recipeTotalMinutes: 45
            )
        ],
        planName: "Semaine du 6 novembre"
    )
}
