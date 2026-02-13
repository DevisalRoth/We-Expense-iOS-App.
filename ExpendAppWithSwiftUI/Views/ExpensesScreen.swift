import SwiftUI

struct ExpensesScreen: View {
    @StateObject private var viewModel = ExpensesViewModel()
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.expenses.isEmpty {
                    ProgressView("Loading expenses...")
                        .scaleEffect(1.5)
                } else if viewModel.filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "list.bullet",
                        description: Text(viewModel.searchText.isEmpty ? "Add your first expense to get started" : "No expenses found for your search")
                    )
                } else {
                    List {
                        // Summary Section
                        summarySection
                        
                        // Expenses List
                        ForEach(viewModel.filteredExpenses) { expense in
                            NavigationLink(destination: ExpenseDetailScreen(expense: expense)) {
                                ExpenseRow(expense: expense)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                viewModel.deleteExpense(at: IndexSet(integer: viewModel.filteredExpenses.firstIndex(where: { $0.id == expense.id }) ?? 0))
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        viewModel.loadExpenses()
                    }
                }
            }
            .navigationTitle("Expenses")
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Category", selection: $viewModel.selectedCategory) {
                            Text("All Categories").tag(nil as ExpenseCategory?)
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category as ExpenseCategory?)
                            }
                        }
                        
                        Button(action: { viewModel.selectedCategory = nil }) {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolVariant(viewModel.selectedCategory != nil ? .fill : .none)
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), presenting: viewModel.errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error)
            }
        }
    }
    
    private var summarySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.totalSpent().formatted(.currency(code: "USD")))
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let category = viewModel.selectedCategory {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Filtered: \(category.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.totalSpent(for: category).formatted(.currency(code: "USD")))
                            .font(.body.bold())
                            .foregroundColor(category.color)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

fileprivate struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(expense.category.color.gradient)
                    .frame(width: 44, height: 44)
                
                Text(expense.icon)
                    .font(.system(size: 20))
            }
            
            // Title & Date
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(formatDate(expense.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text(expense.amount.formatted(.currency(code: "USD")))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(expense.category.color)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

//#Preview {
//    ExpensesScreen()
//}
