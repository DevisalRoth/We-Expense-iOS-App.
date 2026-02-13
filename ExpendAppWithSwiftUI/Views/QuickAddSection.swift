import SwiftUI

struct QuickAddSection: View {
    let savedItems: [SavedItem]
    let onAdd: (SavedItem) -> Void
    let onManage: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUICK ADD")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.gray)
                
                Spacer()
                
                Button(action: onManage) {
                    Text("Manage")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.5))
                }
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add New Button
                    Button(action: onManage) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.5))
                            
                            Text("New")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color(red: 0.1, green: 0.12, blue: 0.12))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    ForEach(savedItems) { item in
                        Button(action: { onAdd(item) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("$\(String(format: "%.2f", item.defaultPrice))")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.1, green: 0.12, blue: 0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 10)
    }
}
