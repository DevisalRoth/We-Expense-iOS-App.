import SwiftUI

struct ItemsManagementScreen: View {
    @ObservedObject var viewModel: BudgetViewModel
    @State private var showingAddItem = false
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    
    var body: some View {
        List {
            ForEach(viewModel.savedItems) { item in
                HStack {
                    Text(item.name)
                        .font(.headline)
                    Spacer()
                    if item.defaultPrice > 0 {
                        Text(String(format: "$%.2f", item.defaultPrice))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: viewModel.deleteSavedItem)
        }
        .navigationTitle("Manage Items")
        .toolbar {
            Button(action: { showingAddItem = true }) {
                Image(systemName: "plus")
            }
        }
        .alert("Add New Item", isPresented: $showingAddItem) {
            TextField("Item Name", text: $newItemName)
            TextField("Default Price (Optional)", text: $newItemPrice)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {
                newItemName = ""
                newItemPrice = ""
            }
            Button("Add") {
                saveNewItem()
            }
        } message: {
            Text("Enter item details to save for future use.")
        }
    }
    
    private func saveNewItem() {
        guard !newItemName.isEmpty else { return }
        let price = Double(newItemPrice) ?? 0.0
        viewModel.createSavedItem(name: newItemName, defaultPrice: price)
        newItemName = ""
        newItemPrice = ""
    }
}
