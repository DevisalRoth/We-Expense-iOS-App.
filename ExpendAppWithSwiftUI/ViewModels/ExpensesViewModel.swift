import SwiftUI
import Combine
import CoreData

@MainActor
final class ExpensesViewModel: ObservableObject {
    // Replaced CoreData with API
    // private let context = PersistenceController.shared.container.viewContext
    
    @Published var expenses: [Expense] = []
    @Published var filteredExpenses: [Expense] = []
    @Published var selectedCategory: ExpenseCategory? = nil
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let networkMonitor = NetworkMonitor.shared
    
    init() {
        setupBindings()
        loadExpenses()
        setupNetworkMonitoring()
    }
    
    private func setupBindings() {
        $expenses
            .combineLatest($selectedCategory, $searchText)
            .map { expenses, category, searchText in
                var filtered = expenses
                
                if let category = category {
                    filtered = filtered.filter { $0.category == category }
                }
                
                if !searchText.isEmpty {
                    filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                }
                
                return filtered
            }
            .assign(to: \.filteredExpenses, on: self)
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    print("Network connected. Retrying/Refreshing...")
                    // If we had an error or empty state, reload
                    if self?.errorMessage != nil || self?.expenses.isEmpty == true {
                        self?.loadExpenses()
                    }
                } else {
                    print("Network disconnected.")
                }
            }
            .store(in: &cancellables)
    }
    
    func loadExpenses() {
        // Allow attempt even if network monitor says disconnected, as localhost might work
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
                    self?.errorMessage = "Failed to fetch expenses: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] expenses in
                self?.expenses = expenses.sorted(by: { $0.date > $1.date })
            })
            .store(in: &cancellables)
    }
    
    func deleteExpense(at offsets: IndexSet) {
        offsets.forEach { index in
            let expense = filteredExpenses[index]
            deleteExpense(expense)
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        // Optimistic update: Remove immediately from UI
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
        }
        
        apiService.deleteExpense(id: expense.id)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    // Rollback if needed or show error
                    self?.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    self?.loadExpenses() // Reload to restore state
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func totalSpent(for category: ExpenseCategory? = nil) -> Double {
        let expensesToCalculate = category != nil ? expenses.filter { $0.category == category } : expenses
        return expensesToCalculate.reduce(0) { $0 + $1.amount }
    }
}

