import Foundation
import Combine

final class PlanViewModel: ObservableObject {
    @Published var slots: Set<SlotSelection> = []
    @Published var currentPlan: MealPlan?
    
    func select(_ slot: SlotSelection) {
        slots.insert(slot)
    }
    
    func deselect(_ slot: SlotSelection) {
        slots.remove(slot)
    }
}
