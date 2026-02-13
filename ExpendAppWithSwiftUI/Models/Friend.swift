import SwiftUI

struct Friend: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let initials: String
    let gradientStart: Any
    let gradientEnd: Any
    
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        lhs.id == rhs.id
    }
}

let sampleFriends: [Friend] = [
    Friend(name: "John", initials: "JD", gradientStart: Color.blue, gradientEnd: Color.purple),
    Friend(name: "Sarah", initials: "SM", gradientStart: Color.orange, gradientEnd: Color.red),
    Friend(name: "Mike", initials: "MR", gradientStart: Color.green, gradientEnd: Color.teal)
]
