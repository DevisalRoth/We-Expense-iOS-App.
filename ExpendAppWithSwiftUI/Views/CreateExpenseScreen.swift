import SwiftUI
import UIKit
// Refactored to break up large body for SwiftUI type-checker performance

// MARK: - Models
// Friend model is now in Models/Friend.swift

struct ExpenseItemInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var price: String = ""
    var quantity: Int = 1
    var image: UIImage? = nil
}

struct ExpenseInput {
    var amount: String = "0.00"
    var title: String = ""
    var selectedCategory: ExpenseCategory = .activities
    var selectedFriends: [Friend] = []
    var splitWithFriends: Bool = false
    var receiptImage: UIImage? = nil
    var recipientEmail: String = ""
    var telegramChatId: String = ""
    var items: [ExpenseItemInput] = []
}

// MARK: - Create Expense Screen

struct CreateExpenseScreen: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BudgetViewModel
    @State private var expenseInput = ExpenseInput()
    @State private var showImagePicker = false
    @State private var selectedFriendsForSplit = [Friend]()
    @State private var showAddFriendAlert = false
    @State private var newFriendName = ""
    @State private var showItemsManagement = false
    @State private var selectedItemForImage: UUID?
    @FocusState private var amountFieldFocused: Bool
    
    var formattedAmount: String {
        let amount = Double(expenseInput.amount) ?? 0
        return String(format: "$%.2f", amount)
    }
    
    var isFormValid: Bool {
        !(expenseInput.title.isEmpty || expenseInput.amount.isEmpty || Double(expenseInput.amount) == 0)
    }
    
    // Custom Colors
    let accentGreen = Color(red: 0.3, green: 0.9, blue: 0.5)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    let cardBackground = Color(red: 0.1, green: 0.12, blue: 0.12)
    
    // Break up large body into smaller views to help the type-checker
    @ViewBuilder
    private var backgroundView: some View {
        darkBackground
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var runningTotalSection: some View {
        VStack(spacing: 8) {
            Text("Running Total")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.gray)

            Text(formattedAmount)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(accentGreen)
                .shadow(color: accentGreen.opacity(0.3), radius: 10, x: 0, y: 0)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var categorySelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                ForEach([ExpenseCategory.lodging, .food, .activities, .transport], id: \.self) { category in
                    CategoryButtonView(
                        category: category,
                        isSelected: expenseInput.selectedCategory == category,
                        action: { expenseInput.selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            runningTotalSection
                            categorySelection
                            
                            QuickAddSection(savedItems: viewModel.savedItems, onAdd: { savedItem in
                                withAnimation {
                                    // If the last item is empty, replace it, otherwise add new
                                    if let last = expenseInput.items.last, last.name.isEmpty && last.price.isEmpty {
                                        expenseInput.items[expenseInput.items.count - 1].name = savedItem.name
                                        expenseInput.items[expenseInput.items.count - 1].price = String(format: "%.2f", savedItem.defaultPrice)
                                    } else {
                                        expenseInput.items.append(ExpenseItemInput(name: savedItem.name, price: String(format: "%.2f", savedItem.defaultPrice), quantity: 1))
                                    }
                                    calculateTotal()
                                }
                            }, onManage: {
                                showItemsManagement = true
                            })
                            
                            LineItemsHeaderView(accentGreen: accentGreen, splitWithFriends: $expenseInput.splitWithFriends)
                            LineItemsListView(
                                cardBackground: cardBackground, 
                                accentGreen: accentGreen, 
                                items: $expenseInput.items, 
                                onChange: calculateTotal,
                                showImagePicker: $showImagePicker,
                                selectedItemForImage: $selectedItemForImage
                            )

                            if expenseInput.splitWithFriends {
                                SplitWithFriendsSection(
                                    selectedFriendsForSplit: $selectedFriendsForSplit,
                                    selectedFriends: $expenseInput.selectedFriends,
                                    accentGreen: accentGreen,
                                    showAddFriendAlert: $showAddFriendAlert
                                )
                            }

                            VStack(alignment: .leading) {
                                Text("DESCRIPTION")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.gray)
                                    .padding(.horizontal, 24)

                                TextField("What is this for?", text: $expenseInput.title)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(cardBackground)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                            }

                            Color.clear.frame(height: 100)
                        }
                    }
                }

                BottomButtons(accentGreen: accentGreen, darkBackground: darkBackground, isFormValid: isFormValid, saveAction: {
                    saveExpense()
                    HapticManager.success()
                    dismiss()
                }, showImagePicker: $showImagePicker)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: Binding(
                    get: {
                        if let id = selectedItemForImage, let index = expenseInput.items.firstIndex(where: { $0.id == id }) {
                            return expenseInput.items[index].image
                        }
                        return expenseInput.receiptImage
                    },
                    set: { newImage in
                        if let id = selectedItemForImage, let index = expenseInput.items.firstIndex(where: { $0.id == id }) {
                            expenseInput.items[index].image = newImage
                        } else {
                            expenseInput.receiptImage = newImage
                        }
                        selectedItemForImage = nil // Reset after setting
                    }
                ))
            }
            .sheet(isPresented: $showItemsManagement) {
                NavigationView {
                    ItemsManagementScreen(viewModel: viewModel)
                }
            }
            .alert("Add New Friend", isPresented: $showAddFriendAlert) {
                TextField("Friend's Name", text: $newFriendName)
                Button("Cancel", role: .cancel) {
                    newFriendName = ""
                }
                Button("Add") {
                    addNewFriend()
                }
            } message: {
                Text("Enter the name of the friend you want to split expenses with.")
            }
        }
        .onAppear {
            selectedFriendsForSplit = sampleFriends
            if expenseInput.items.isEmpty {
                expenseInput.items.append(ExpenseItemInput())
            }
        } 
    }
    
    private func calculateTotal() {
        guard !expenseInput.items.isEmpty else { return }
        let total = expenseInput.items.reduce(0.0) { result, item in
            let price = Double(item.price) ?? 0.0
            return result + (price * Double(item.quantity))
        }
        expenseInput.amount = String(format: "%.2f", total)
    }
    
    private func saveExpense() {
        let amount = Double(expenseInput.amount) ?? 0
        // Use expenseInput.selectedFriends directly as they contain the user-selected friends.
        // Also ensure splitWithFriends is true.
        let selectedFriends = expenseInput.splitWithFriends ? expenseInput.selectedFriends : []
        
        let items = expenseInput.items.compactMap { item -> ExpenseItemCreate? in
            guard !item.name.isEmpty, let price = Double(item.price) else { return nil }
            return ExpenseItemCreate(name: item.name, price: price, quantity: item.quantity, imageData: item.image?.jpegData(compressionQuality: 0.8))
        }
        
        viewModel.addExpense(
            title: expenseInput.title,
            amount: amount,
            category: expenseInput.selectedCategory,
            date: Date(),
            splits: selectedFriends,
            items: items,
            receiptImage: expenseInput.receiptImage,
            recipientEmail: expenseInput.recipientEmail.isEmpty ? nil : expenseInput.recipientEmail,
            telegramChatId: expenseInput.telegramChatId.isEmpty ? nil : expenseInput.telegramChatId
        )
    }
    
    private func addNewFriend() {
        guard !newFriendName.isEmpty else { return }
        
        let initials = String(newFriendName.prefix(2)).uppercased()
        let newFriend = Friend(
            name: newFriendName,
            initials: initials,
            gradientStart: Color(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1)),
            gradientEnd: Color(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
        )
        
        withAnimation {
            selectedFriendsForSplit.append(newFriend)
            expenseInput.selectedFriends.append(newFriend)
        }
        newFriendName = ""
    }
}

// MARK: - Extracted Sections to aid type-checker

private struct LineItemsHeaderView: View {
    let accentGreen: Color
    @Binding var splitWithFriends: Bool

    var body: some View {
        HStack {
            Text("LINE ITEMS")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.gray)
                .tracking(1)

            Spacer()

            Button(action: {
                withAnimation {
                    splitWithFriends.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 12))
                    Text("Split Bill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(splitWithFriends ? accentGreen : .gray)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
}

private struct LineItemsListView: View {
    let cardBackground: Color
    let accentGreen: Color
    @Binding var items: [ExpenseItemInput]
    var onChange: () -> Void
    @Binding var showImagePicker: Bool
    @Binding var selectedItemForImage: UUID?

    var body: some View {
        VStack(spacing: 16) {
            ForEach($items) { $item in
                let itemID = $item.wrappedValue.id

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ITEM NAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentGreen)
                            .tracking(0.5)

                        Spacer()

                        Button(action: {
                            withAnimation {
                                if let index = items.firstIndex(where: { $0.id == itemID }) {
                                    items.remove(at: index)
                                    onChange()
                                }
                            }
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.gray)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        // Item Image Button
                        Button(action: {
                            selectedItemForImage = itemID
                            showImagePicker = true
                        }) {
                            ZStack {
                                if let image = $item.wrappedValue.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)
                                        .clipped()
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color.gray)
                                        )
                                }
                            }
                        }
                        
                        TextField("e.g. Seafood Dinner", text: $item.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    HStack(alignment: .bottom) {
                        HStack(spacing: 0) {
                            Text("QTY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.gray)
                                .padding(.trailing, 8)

                            HStack(spacing: 0) {
                                Button(action: {
                                    if $item.wrappedValue.quantity > 1 {
                                        $item.wrappedValue.quantity -= 1
                                        onChange()
                                    }
                                }) {
                                    Text("—")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color.gray)
                                        .frame(width: 32, height: 32)
                                }

                                TextField("1", value: $item.quantity, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(accentGreen)
                                    .frame(width: 30)
                                    .onChange(of: $item.wrappedValue.quantity) { _, _ in onChange() }

                                Button(action: {
                                    $item.wrappedValue.quantity += 1
                                    onChange()
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(accentGreen)
                                        .frame(width: 32, height: 32)
                                }
                            }
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("UNIT PRICE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.gray)

                            HStack(spacing: 2) {
                                Text("$")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                TextField("0.00", text: $item.price)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .onChange(of: $item.wrappedValue.price) { _, _ in onChange() }
                            }
                        }
                    }
                }
                .padding(20)
                .background(cardBackground)
                .cornerRadius(20)
                .padding(.horizontal, 16)
            }

            Button(action: {
                withAnimation {
                    items.append(ExpenseItemInput())
                }
            }) {
                HStack {
                    Text("Add another item...")
                        .font(.system(size: 16, weight: .medium))
                        .italic()
                        .foregroundColor(Color.gray)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color(white: 0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(accentGreen)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }
}

private struct SplitWithFriendsSection: View {
    @Binding var selectedFriendsForSplit: [Friend]
    @Binding var selectedFriends: [Friend]
    let accentGreen: Color
    @Binding var showAddFriendAlert: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPLIT WITH")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.gray)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedFriendsForSplit, id: \.id) { friend in
                        FriendAvatarButton(
                            friend: friend,
                            isSelected: selectedFriends.contains { $0.id == friend.id },
                            action: {
                                if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
                                    selectedFriends.remove(at: index)
                                } else {
                                    selectedFriends.append(friend)
                                }
                            }
                        )
                    }

                    Button(action: {
                        showAddFriendAlert = true
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color.gray)
                            }

                            Text("Add")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.gray)
                        }
                        .frame(width: 70)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 10)
    }
}

private struct BottomButtons: View {
    let accentGreen: Color
    let darkBackground: Color
    let isFormValid: Bool
    let saveAction: () -> Void
    @Binding var showImagePicker: Bool

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    saveAction()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Add to Trip")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentGreen)
                    .cornerRadius(28)
                    .shadow(color: accentGreen.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1 : 0.6)

                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Scan Receipt")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .background(
                LinearGradient(colors: [darkBackground.opacity(0), darkBackground], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
                    .offset(y: 20)
            )
        }
    }
}

// MARK: - Category Button View

struct CategoryButtonView: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(red: 0.3, green: 0.9, blue: 0.5).opacity(0.1) : Color(white: 0.1))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color(red: 0.3, green: 0.9, blue: 0.5) : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? Color(red: 0.3, green: 0.9, blue: 0.5).opacity(0.3) : .clear, radius: 10)

                    Text(category.icon)
                        .font(.system(size: 28))
                        .grayscale(isSelected ? 0 : 1)
                }

                Text(category.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 0.3, green: 0.9, blue: 0.5) : Color.gray)
            }
        }
    }
}

// MARK: - Friend Avatar Button

struct FriendAvatarButton: View {
    let friend: Friend
    let isSelected: Bool
    let action: () -> Void
    
    private var startColor: Color {
        color(from: friend.gradientStart) ?? Color(red: 0.2, green: 0.6, blue: 0.8)
    }
    
    private var endColor: Color {
        color(from: friend.gradientEnd) ?? Color(red: 0.8, green: 0.4, blue: 0.6)
    }
    
    private func color(from value: Any?) -> Color? {
        // Accept Color directly
        if let c = value as? Color { return c }
        // Accept UIColor
        if let ui = value as? UIColor { return Color(ui) }
        // Accept SwiftUI Color name as String or hex string
        guard let s = value as? String else { return nil }
        let lower = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Named color shortcuts
        switch lower {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "black": return .black
        case "white": return .white
        case "gray", "grey": return .gray
        default: break
        }
        // Hex parsing: #RRGGBB or RRGGBB, with optional alpha #RRGGBBAA
        var hex = lower
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6 || hex.count == 8, let intVal = UInt64(hex, radix: 16) else { return nil }
        let r, g, b, a: Double
        if hex.count == 8 {
            r = Double((intVal & 0xFF000000) >> 24) / 255.0
            g = Double((intVal & 0x00FF0000) >> 16) / 255.0
            b = Double((intVal & 0x0000FF00) >> 8) / 255.0
            a = Double(intVal & 0x000000FF) / 255.0
        } else {
            r = Double((intVal & 0xFF0000) >> 16) / 255.0
            g = Double((intVal & 0x00FF00) >> 8) / 255.0
            b = Double(intVal & 0x0000FF) / 255.0
            a = 1.0
        }
        return Color(red: r, green: g, blue: b, opacity: a)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    startColor,
                                    endColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Text(friend.initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color(red: 0.3, green: 0.9, blue: 0.5) : Color.clear, lineWidth: 2)
                )
                
                Text(friend.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? Color(red: 0.3, green: 0.9, blue: 0.5) : Color(white: 0.5))
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
    }
}

struct CreateExpenseScreen_Previews: PreviewProvider {
    static var previews: some View {
        CreateExpenseScreen(viewModel: BudgetViewModel())
    }
}

