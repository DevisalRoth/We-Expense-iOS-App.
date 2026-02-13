import Foundation
import SwiftUI
import UIKit

// MARK: - Auth Models
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

struct User: Codable {
    let id: String
    let email: String
    let isActive: Bool
    let username: String?
    let subtitle: String?
    let profileImageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case isActive = "is_active"
        case username, subtitle
        case profileImageData = "profile_image_data"
    }
}

// MARK: - API Models

enum ExpenseCategory: String, Codable, CaseIterable, Equatable {
    case lodging = "Lodging"
    case food = "Food"
    case activities = "Fun"
    case transport = "Transport"
    
    var icon: String {
        switch self {
        case .lodging: return "🏨"
        case .food: return "🍔"
        case .activities: return "🎪"
        case .transport: return "🚗"
        }
    }
    
    var color: Color {
        switch self {
        case .lodging:
            return Color(red: 0.2, green: 0.8, blue: 0.5)
        case .food:
            return Color(red: 0.3, green: 0.85, blue: 0.6)
        case .activities:
            return Color(red: 0.2, green: 0.6, blue: 0.5)
        case .transport:
            return Color(red: 0.15, green: 0.45, blue: 0.4)
        }
    }
}

struct ExpenseItem: Identifiable, Codable, Equatable {
    let id: UUID
    let expenseId: UUID
    let name: String
    let price: Double
    let quantity: Int
    let imageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case id
        case expenseId = "expense_id"
        case name
        case price
        case quantity
        case imageData = "image_data"
    }
}

struct Split: Identifiable, Codable, Equatable {
    let id: UUID
    let expenseId: UUID
    let name: String
    let initials: String
    let amount: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case expenseId = "expense_id"
        case name
        case initials
        case amount
    }
}

extension Split {
    var isPaid: Bool { false }
    var isCurrentUser: Bool { name == "You" }
}

struct SavedItem: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let defaultPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case defaultPrice = "default_price"
    }
}

struct Expense: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let amount: Double
    let date: Date
    let category: ExpenseCategory
    let receiptData: Data?
    let recipientEmail: String?
    let splits: [Split]
    let items: [ExpenseItem]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case date
        case category
        case receiptData = "receipt_data"
        case recipientEmail = "recipient_email"
        case splits
        case items
    }
    
    // Fallback for decoding older JSON without items
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Double.self, forKey: .amount)
        date = try container.decode(Date.self, forKey: .date)
        category = try container.decode(ExpenseCategory.self, forKey: .category)
        receiptData = try container.decodeIfPresent(Data.self, forKey: .receiptData)
        recipientEmail = try container.decodeIfPresent(String.self, forKey: .recipientEmail)
        splits = try container.decodeIfPresent([Split].self, forKey: .splits) ?? []
        items = try container.decodeIfPresent([ExpenseItem].self, forKey: .items) ?? []
    }
    
    // Memberwise init for previews
    init(id: UUID, title: String, amount: Double, date: Date, category: ExpenseCategory, receiptData: Data?, recipientEmail: String?, splits: [Split], items: [ExpenseItem] = []) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.receiptData = receiptData
        self.recipientEmail = recipientEmail
        self.splits = splits
        self.items = items
    }
}

extension Expense {
    var icon: String { category.icon }
    var wrappedTitle: String { title }
    var wrappedCategory: String { category.rawValue }
    var wrappedDate: Date { date }
    var splitArray: [Split] { splits }
    
    var receiptImage: UIImage? {
        if let data = receiptData {
            return UIImage(data: data)
        }
        return nil
    }
}
