import SwiftUI
import Combine
import UIKit

@MainActor
class BudgetViewModel: ObservableObject {
    
    @Published var expenses: [Expense] = []
    @Published var savedItems: [SavedItem] = []
    @Published var totalBudget: Double = 1650
    @Published var tripName: String = "Coachella Trip"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let apiService = APIService.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var remaining: Double {
        totalBudget - totalSpent
    }
    
    var percentageSpent: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalSpent / totalBudget) * 100
    }
    
    // Legacy support for views not yet migrated
    var budgetData: BudgetData {
        BudgetData(
            tripName: tripName,
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            expenses: expenses
        )
    }
    
    init() {
        fetchExpenses()
        fetchSavedItems()
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    if self?.errorMessage != nil || self?.expenses.isEmpty == true {
                        self?.fetchExpenses()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchExpenses() {
        // Allow attempt even if network monitor says disconnected
        if !networkMonitor.isConnected {
            print("NetworkMonitor says disconnected, but attempting fetch anyway...")
        }
        
        isLoading = true
        
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
                self?.expenses = expenses.sorted(by: { $0.date > $1.date })
            })
            .store(in: &cancellables)
    }
    
    func addExpense(title: String, amount: Double, category: ExpenseCategory, date: Date, splits: [Friend], items: [ExpenseItemCreate] = [], receiptImage: UIImage? = nil, recipientEmail: String? = nil, telegramChatId: String? = nil) {
        // Convert Friends to Splits
        let totalParticipants = splits.count + 1
        let splitAmount = amount / Double(totalParticipants)
        
        var splitCreates: [SplitCreate] = []
        
        // You
        splitCreates.append(SplitCreate(name: "You", initials: "YO", amount: splitAmount))
        
        // Friends
        for friend in splits {
            splitCreates.append(SplitCreate(name: friend.name, initials: friend.initials, amount: splitAmount))
        }
        
        let newExpense = ExpenseCreate(
            title: title,
            amount: amount,
            date: date,
            category: category,
            receiptData: receiptImage?.jpegData(compressionQuality: 0.8),
            recipientEmail: recipientEmail,
            telegramChatId: telegramChatId,
            splits: splitCreates,
            items: items
        )
        
        apiService.createExpense(expense: newExpense)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.fetchExpenses() // Refresh list
                case .failure(let error):
                    self?.errorMessage = "Failed to create: \(error.localizedDescription)"
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func updateExpense(id: UUID, title: String, amount: Double, category: ExpenseCategory, date: Date, splits: [Friend], items: [ExpenseItemCreate] = [], receiptImage: UIImage? = nil, recipientEmail: String? = nil, telegramChatId: String? = nil) {
        let totalParticipants = splits.count + 1
        let splitAmount = amount / Double(totalParticipants)
        
        var splitCreates: [SplitCreate] = []
        splitCreates.append(SplitCreate(name: "You", initials: "YO", amount: splitAmount))
        for friend in splits {
            splitCreates.append(SplitCreate(name: friend.name, initials: friend.initials, amount: splitAmount))
        }
        
        let updatedExpense = ExpenseCreate(
            title: title,
            amount: amount,
            date: date,
            category: category,
            receiptData: receiptImage?.jpegData(compressionQuality: 0.8),
            recipientEmail: recipientEmail,
            telegramChatId: telegramChatId,
            splits: splitCreates,
            items: items
        )
        
        apiService.updateExpense(id: id, expense: updatedExpense)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.fetchExpenses()
                case .failure(let error):
                    self?.errorMessage = "Failed to update: \(error.localizedDescription)"
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func deleteExpense(at offsets: IndexSet) {
        for index in offsets {
            let expense = expenses[index]
            deleteExpense(expense)
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        // Optimistic update
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
        }
        
        apiService.deleteExpense(id: expense.id)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    self?.fetchExpenses()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func updateBudget(newBudget: Double) {
        totalBudget = newBudget
        // In a real app, this should be persisted to API or UserDefaults
    }
    
    // MARK: - Saved Items Management
    
    func fetchSavedItems() {
        apiService.fetchSavedItems()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] items in
                self?.savedItems = items.sorted(by: { $0.name < $1.name })
            })
            .store(in: &cancellables)
    }
    
    func createSavedItem(name: String, defaultPrice: Double) {
        apiService.createSavedItem(name: name, defaultPrice: defaultPrice)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchSavedItems()
            })
            .store(in: &cancellables)
    }
    
    func deleteSavedItem(at offsets: IndexSet) {
        for index in offsets {
            let item = savedItems[index]
            deleteSavedItem(item)
        }
    }
    
    private func deleteSavedItem(_ item: SavedItem) {
        if let index = savedItems.firstIndex(where: { $0.id == item.id }) {
            savedItems.remove(at: index)
        }
        
        apiService.deleteSavedItem(id: item.id)
            .sink(receiveCompletion: { [weak self] _ in
                self?.fetchSavedItems()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
