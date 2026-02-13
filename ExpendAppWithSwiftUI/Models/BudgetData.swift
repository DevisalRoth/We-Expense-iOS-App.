import Foundation
import SwiftUI

struct BudgetData {
    static func sampleData() -> BudgetData {
        return BudgetData()
    }
    var id = UUID()
    var tripName: String = "Coachella Trip"
    var totalBudget: Double = 1650
    var totalSpent: Double = 1240
    
    var remaining: Double {
        totalBudget - totalSpent
    }
    
    var percentageSpent: Double {
        (totalSpent / totalBudget) * 100
    }
    
    // Helper to create date
    private static func date(from string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        // Set year to current year or fixed year to avoid issues
        formatter.defaultDate = Date()
        return formatter.date(from: string) ?? Date()
    }
    
    var expenses: [Expense] = [
        Expense(
            id: UUID(),
            title: "Hotel Check-in",
            amount: 250.00,
            date: BudgetData.date(from: "Oct 12"),
            category: .lodging,
            receiptData: nil,
            recipientEmail: nil,
            splits: [],
            items: []
        ),
        Expense(
            id: UUID(),
            title: "In-N-Out Burger",
            amount: 18.50,
            date: BudgetData.date(from: "Oct 12"),
            category: .food,
            receiptData: nil,
            recipientEmail: nil,
            splits: [],
            items: []
        ),
        Expense(
            id: UUID(),
            title: "Coachella Ticket",
            amount: 549.00,
            date: BudgetData.date(from: "Oct 11"),
            category: .activities,
            receiptData: nil,
            recipientEmail: nil,
            splits: [],
            items: []
        ),
        Expense(
            id: UUID(),
            title: "Uber to Venue",
            amount: 32.00,
            date: BudgetData.date(from: "Oct 11"),
            category: .transport,
            receiptData: nil,
            recipientEmail: nil,
            splits: [],
            items: []
        ),
        Expense(
            id: UUID(),
            title: "Morning Coffee",
            amount: 6.50,
            date: BudgetData.date(from: "Oct 11"),
            category: .food,
            receiptData: nil,
            recipientEmail: nil,
            splits: [],
            items: []
        )
    ]
}
