import SwiftUI
import Combine

struct ExpenseDetailScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingReceiptFullScreen = false
    @State private var fullExpense: Expense?
    let expense: Expense
    
    // Colors
    let accentGreen = Color(red: 0.3, green: 0.9, blue: 0.5)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    let cardBackground = Color(red: 0.1, green: 0.12, blue: 0.12)
    
    var body: some View {
        let displayExpense = fullExpense ?? expense
        
        ZStack {
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 1. Header Section
                        VStack(spacing: 12) {
                            // Icon with Glow
                            ZStack {
                                Circle()
                                    .fill(cardBackground)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: accentGreen.opacity(0.2), radius: 20, x: 0, y: 0)
                                    .overlay(
                                        Circle()
                                            .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Text(displayExpense.category.icon)
                                    .font(.system(size: 32))
                            }
                            .padding(.top, 20)
                            
                            VStack(spacing: 4) {
                                Text(displayExpense.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("San Francisco, CA") // Placeholder location
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.gray)
                            }
                            
                            Text(String(format: "$%.2f", displayExpense.amount))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(accentGreen)
                                .shadow(color: accentGreen.opacity(0.4), radius: 15, x: 0, y: 0)
                        }
                        
                        // 2. Info Card
                        HStack(spacing: 0) {
                            // Category
                            InfoColumn(title: "CATEGORY", value: displayExpense.category.rawValue)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .frame(height: 40)
                            
                            // Date
                            InfoColumn(title: "DATE", value: formatDate(displayExpense.date))
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .frame(height: 40)
                            
                            // Paid By
                            VStack(spacing: 6) {
                                Text("PAID BY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.gray)
                                    .tracking(0.5)
                                
                                HStack(spacing: 6) {
                                    // Small Avatar for "You"
                                    Circle()
                                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 20, height: 20)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    
                                    Text("You")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 20)
                        .background(cardBackground)
                        .cornerRadius(20)
                        .padding(.horizontal, 16)
                        
                        // 3. Line Items Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LINE ITEMS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.gray)
                                .tracking(1)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                if displayExpense.items.isEmpty {
                                    // Fallback if no items
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(displayExpense.title)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text("1x unit")
                                                .font(.system(size: 13))
                                                .foregroundColor(Color.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(String(format: "$%.2f", displayExpense.amount))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(20)
                                } else {
                                    ForEach(displayExpense.items) { item in
                                        HStack(alignment: .top) {
                                            // Item Image
                                            if let data = item.imageData, let uiImage = UIImage(data: data) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 40, height: 40)
                                                    .cornerRadius(8)
                                                    .clipped()
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                Text("\(item.quantity)x units at \(String(format: "$%.2f", item.price)) each")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Color.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(String(format: "$%.2f", item.price * Double(item.quantity)))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(20)
                                        
                                        if item.id != displayExpense.items.last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                
                                // Total Bill Row
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                HStack {
                                    Text("TOTAL BILL")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.gray)
                                        .tracking(1)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "$%.2f", displayExpense.amount))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(accentGreen)
                                }
                                .padding(20)
                                .background(Color.white.opacity(0.03))
                            }
                            .background(cardBackground)
                            .cornerRadius(20)
                            .padding(.horizontal, 16)
                        }
                        
                        // 4. Group Split Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("GROUP SPLIT")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.gray)
                                    .tracking(1)
                                
                                Spacer()
                                
                                Text("EQUALLY (\(displayExpense.splits.count + 1))") // +1 for You
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(accentGreen)
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                // You Row
                                SplitPersonRow(
                                    name: "You",
                                    initials: "YO",
                                    amount: String(format: "$%.2f", calculateSplitAmount(total: displayExpense.amount, count: displayExpense.splits.count + 1)),
                                    status: "Settled",
                                    statusColor: Color.gray,
                                    isYou: true
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                // Friends Rows
                                ForEach(displayExpense.splits) { split in
                                    SplitPersonRow(
                                        name: split.name,
                                        initials: split.initials,
                                        amount: String(format: "$%.2f", calculateSplitAmount(total: displayExpense.amount, count: displayExpense.splits.count + 1)),
                                        status: "OWES YOU",
                                        statusColor: accentGreen,
                                        isYou: false
                                    )
                                    
                                    if split.id != displayExpense.splits.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .background(cardBackground)
                            .cornerRadius(20)
                            .padding(.horizontal, 16)
                        }
                        
                        // 5. View Receipt Button
                        Button(action: {
                            showingReceiptFullScreen = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 18))
                                Text("View Receipt")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.gray)
                            }
                            .foregroundColor(.white)
                            .padding(20)
                            .background(cardBackground)
                            .cornerRadius(20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Expense Detail")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            // Delete action placeholder
                        }) {
                            Label("Delete Expense", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .task {
                loadFullExpense()
            }
            .sheet(isPresented: $showingReceiptFullScreen) {
                if let data = displayExpense.receiptData, let image = UIImage(data: data) {
                    ReceiptFullScreenView(receiptImage: image)
                } else {
                    ReceiptFullScreenView(receiptImage: UIImage(systemName: "doc.text")!)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func calculateSplitAmount(total: Double, count: Int) -> Double {
        guard count > 0 else { return 0 }
        return total / Double(count)
    }
    
    private func loadFullExpense() {
        APIService.shared.fetchExpense(id: expense.id)
            .sink(receiveCompletion: { _ in }, receiveValue: { fetchedExpense in
                self.fullExpense = fetchedExpense
            })
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Subviews

struct InfoColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.gray)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SplitPersonRow: View {
    let name: String
    let initials: String
    let amount: String
    let status: String
    let statusColor: Color
    let isYou: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(isYou ?
                          LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(red: 0.2, green: 0.25, blue: 0.3), Color(red: 0.15, green: 0.2, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 40, height: 40)
                
                if isYou {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.green)
                        .clipShape(Circle())
                        .offset(x: 14, y: 14)
                } else {
                    Text(initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if !isYou {
                    Text("OWES \(amount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.gray)
                } else {
                    Text("OWE \(amount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.5))
                }
            }
            
            Spacer()
            
            Text(status)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(statusColor)
        }
        .padding(16)
    }
}

// Receipt Full Screen View
struct ReceiptFullScreenView: View {
    @Environment(\.dismiss) var dismiss
    let receiptImage: UIImage
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: receiptImage)
                    .resizable()
                    .scaledToFit()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct ExpenseDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        let expense = Expense(
            id: UUID(),
            title: "Seafood & Cocktails",
            amount: 325.00,
            date: Date(),
            category: .food,
            receiptData: nil, recipientEmail: "",
            splits: [
                Split(id: UUID(), expenseId: UUID(), name: "John", initials: "JD", amount: 61.725),
                Split(id: UUID(), expenseId: UUID(), name: "Sarah", initials: "SM", amount: 61.725)
            ],
            items: [
                ExpenseItem(id: UUID(), expenseId: UUID(), name: "Seafood Dinner", price: 145.00, quantity: 1, imageData: nil),
                ExpenseItem(id: UUID(), expenseId: UUID(), name: "Cocktails", price: 60.00, quantity: 3, imageData: nil)
            ]
        )
        
        return ExpenseDetailScreen(expense: expense)
    }
}

