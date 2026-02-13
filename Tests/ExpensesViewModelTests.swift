import XCTest
import Combine
@testable import ExpendAppWithSwiftUI

@MainActor
class ExpensesViewModelTests: XCTestCase {
    var viewModel: ExpensesViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = ExpensesViewModel()
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertTrue(viewModel.expenses.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFilterLogic() {
        // Setup dummy data
        let date = Date()
        let expense1 = Expense(id: UUID(), title: "Burger", amount: 10, date: date, category: .food, receiptData: nil, recipientEmail: nil, splits: [], items: [])
        let expense2 = Expense(id: UUID(), title: "Taxi", amount: 20, date: date, category: .transport, receiptData: nil, recipientEmail: nil, splits: [], items: [])
        
        viewModel.expenses = [expense1, expense2]
        
        // Test Category Filter
        viewModel.selectedCategory = .food
        
        // Wait for Combine pipeline to update filteredExpenses
        let expectation = self.expectation(description: "Filter updates")
        
        viewModel.$filteredExpenses
            .dropFirst() // Drop initial value
            .sink { filtered in
                if filtered.count == 1 && filtered.first?.category == .food {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(viewModel.filteredExpenses.count, 1)
        XCTAssertEqual(viewModel.filteredExpenses.first?.title, "Burger")
    }
    
    func testSearchLogic() {
        // Setup dummy data
        let date = Date()
        let expense1 = Expense(id: UUID(), title: "Burger", amount: 10, date: date, category: .food, receiptData: nil, recipientEmail: nil, splits: [], items: [])
        let expense2 = Expense(id: UUID(), title: "Taxi", amount: 20, date: date, category: .transport, receiptData: nil, recipientEmail: nil, splits: [], items: [])
        
        viewModel.expenses = [expense1, expense2]
        
        // Test Search Filter
        viewModel.searchText = "Tax"
        
        let expectation = self.expectation(description: "Search updates")
        
        viewModel.$filteredExpenses
            .dropFirst()
            .sink { filtered in
                if filtered.count == 1 && filtered.first?.title == "Taxi" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
            
        wait(for: [expectation], timeout: 2.0)
    }
}
