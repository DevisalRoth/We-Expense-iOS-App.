import SwiftUI
import Combine
import CoreData

@MainActor
final class AnalyticsViewModel: ObservableObject {
    // Replaced CoreData
    // private let context = PersistenceController.shared.container.viewContext
    
    @Published var categorySpending: [CategorySpending] = []
    @Published var monthlySpending: [MonthlySpending] = []
    @Published var isLoading: Bool = false
    @Published var selectedTimeRange: TimeRange = .month
    @Published var errorMessage: String? = nil
    
//    var totalSpent: Double {
//        categorySpending.reduce(0) { $0 + $1.amount }
//    }
    
    private let apiService = APIService.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    struct CategorySpending: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let amount: Double
        let percentage: Double
        let expenses: [Expense]
    }
    
    struct MonthlySpending: Identifiable {
        let id = UUID()
        let month: String
        let amount: Double
    }
    
    init() {
        loadAnalyticsData()
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    if self?.errorMessage != nil || self?.categorySpending.isEmpty == true {
                        self?.loadAnalyticsData()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func loadAnalyticsData() {
        if !networkMonitor.isConnected {
            print("NetworkMonitor says disconnected, but attempting fetch anyway...")
        }
        
        isLoading = true
        errorMessage = nil
        
        apiService.fetchExpenses()
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = "Failed: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] expenses in
                guard let self = self else { return }
                self.categorySpending = self.calculateCategorySpending(expenses: expenses)
                self.monthlySpending = self.calculateMonthlySpending(expenses: expenses)
            })
            .store(in: &cancellables)
    }
    
    private func calculateCategorySpending(expenses: [Expense]) -> [CategorySpending] {
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        
        return ExpenseCategory.allCases.map { category in
            let categoryExpenses = expenses.filter { $0.category == category }
            let categoryTotal = categoryExpenses.reduce(0) { $0 + $1.amount }
            let percentage = totalSpent > 0 ? (categoryTotal / totalSpent) * 100 : 0
            
            return CategorySpending(
                category: category,
                amount: categoryTotal,
                percentage: percentage,
                expenses: categoryExpenses.sorted { $0.date > $1.date }
            )
        }
        .filter { $0.amount > 0 }
        .sorted { $0.amount > $1.amount }
    }
    
    private func calculateMonthlySpending(expenses: [Expense]) -> [MonthlySpending] {
        // Simplified monthly calculation - in real app, you'd parse dates properly
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        let monthlyData = Dictionary(grouping: expenses) { expense in
            dateFormatter.string(from: expense.date)
        }
        
        return monthlyData.map { month, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            return MonthlySpending(month: month, amount: total)
        }
        .sorted { item1, item2 in
            // Sort by month order if possible, but for now simple string sort or amount?
            // Let's try to keep it simple. Ideally we need proper date sorting.
            // For this quick fix, we'll just sort by month name (which is imperfect) 
            // or maybe just keep it as is. 
            // Let's use a static calendar to get month index for sorting.
            let months = dateFormatter.shortMonthSymbols ?? []
            let index1 = months.firstIndex(of: item1.month) ?? 0
            let index2 = months.firstIndex(of: item2.month) ?? 0
            return index1 < index2
        }
    }
    
    var totalSpent: Double {
        categorySpending.reduce(0) { $0 + $1.amount }
    }
}
