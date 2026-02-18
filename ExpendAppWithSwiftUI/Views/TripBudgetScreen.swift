import SwiftUI

struct TripBudgetScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showEditSheet = false
    @State private var showCreateExpenseSheet = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    var filteredExpenses: [Expense] {
        var expenses = viewModel.expenses
        
        // Apply Search
        if !searchText.isEmpty {
            expenses = expenses.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply Filter (Mock implementation for now since we don't have paid status in model yet)
        if selectedFilter == "Unpaid" {
            // expenses = expenses.filter { !$0.isPaid }
        } else if selectedFilter == "Settled" {
            // expenses = expenses.filter { $0.isPaid }
        }
        
        return expenses
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground) // Adaptive system background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    
                    Spacer()
                    
                    Text("Trip Expenses")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary) // Adaptive text color
                    
                    Spacer()
                    
                  
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Total Spend Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOTAL SPEND")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(alignment: .center, spacing: 12) {
                                Text("$\(viewModel.budgetData.totalSpent, specifier: "%.2f")")
                                    .font(.system(size: 40, weight: .heavy))
                                    .foregroundColor(.green) // Adaptive green
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search California trip expenses...", text: $searchText)
                                .foregroundColor(.primary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground)) // Adaptive background
                        .cornerRadius(12)
                        
                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(title: "All", isSelected: selectedFilter == "All") {
                                    selectedFilter = "All"
                                }
                                FilterChip(title: "Unpaid", isSelected: selectedFilter == "Unpaid") {
                                    selectedFilter = "Unpaid"
                                }
                                FilterChip(title: "Settled", isSelected: selectedFilter == "Settled") {
                                    selectedFilter = "Settled"
                                }
                                FilterChip(title: "Export", isSelected: selectedFilter == "Export") {
                                    // Export action
                                }
                            }
                        }
                        
                        // Expenses List
                        VStack(alignment: .leading, spacing: 20) {
                            // Section Header
                            Text("TODAY")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            if filteredExpenses.isEmpty {
                                Text(searchText.isEmpty ? "No expenses yet" : "No results found")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(filteredExpenses) { expense in
                                    NavigationLink(destination: ExpenseDetailScreen(expense: expense)) {
                                        ModernExpenseRow(expense: expense)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for FAB
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showCreateExpenseSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditBudgetSheet(viewModel: viewModel, isPresented: $showEditSheet)
        }
        .sheet(isPresented: $showCreateExpenseSheet) {
            CreateExpenseScreen(viewModel: viewModel)
        }
    }
}

// MARK: - New Components

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isSelected ? Color.green : Color(.secondarySystemBackground))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.primary.opacity(0.1), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

struct ModernExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Text(expense.icon)
                    .font(.system(size: 24))
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(expense.category.rawValue) • \(formatDate(expense.date))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount & Status
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(expense.amount, specifier: "%.2f")")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    
                
                Text("SETTLED") // Static for now, can be dynamic
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Subviews

struct DonutChartView: View {
    let budgetData: BudgetData
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: CGFloat(budgetData.percentageSpent / 100))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                Text("\(Int(budgetData.percentageSpent))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("spent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BudgetSummaryView: View {
    let budgetData: BudgetData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(budgetData.tripName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("$\(budgetData.totalBudget, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Spent")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(budgetData.totalSpent, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Remaining")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(budgetData.remaining, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            
            ProgressView(value: budgetData.percentageSpent / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .background(Color(.systemGray5))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct RecentExpensesView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Binding var showCreateExpenseSheet: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Expenses")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showCreateExpenseSheet = true }) {
                    Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
                }
            }
            
            if viewModel.expenses.isEmpty {
                Text("No expenses yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.expenses) { expense in
                        NavigationLink(destination: ExpenseDetailScreen(expense: expense)) {
                            ExpenseRow(expense: expense)
                        }
                    }
                }
            }
        }
    }
}

fileprivate struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            Text(expense.icon)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(expense.category.color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(formatDate(expense.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(expense.amount, specifier: "%.2f")")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct EditBudgetSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Binding var isPresented: Bool
    @State private var newBudget: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter new budget", text: $newBudget)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Button("Update Budget") {
                    if let budget = Double(newBudget) {
                        viewModel.updateBudget(newBudget: budget)
                        isPresented = false
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Edit Budget")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}
