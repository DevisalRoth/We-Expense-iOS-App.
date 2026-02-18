import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var userSettings: UserSettings
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessAlert: Bool = false
    @Published var profileImage: UIImage? = nil
    
    private let userDefaults: UserDefaults
    private let profileImageFileName = "user_profile_image.jpg"
    private var cancellables = Set<AnyCancellable>()
    
    struct UserSettings: Codable {
        var currency: String
        var notificationsEnabled: Bool
        var darkModeEnabled: Bool
        var budgetAlertThreshold: Double
        var username: String
        var cardNumber: String
        var subtitle: String
        var telegramChatId: String?
        
        static let `default` = UserSettings(
            currency: "USD",
            notificationsEnabled: true,
            darkModeEnabled: true,
            budgetAlertThreshold: 80.0,
            username: "Visalroth",
            cardNumber: "VISA **** 1234",
            subtitle: "App Developer • Vzza Agent",
            telegramChatId: ""
        )
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.userSettings = Self.loadSettings(from: userDefaults)
        self.loadProfileImage()
        self.fetchUserProfile()
    }
    
    func fetchUserProfile() {
        APIService.shared.fetchCurrentUser()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Failed to fetch user profile: \(error)")
                case .finished:
                    break
                }
            } receiveValue: { [weak self] user in
                self?.userSettings.username = user.username ?? user.email.components(separatedBy: "@").first?.capitalized ?? "User"
                self?.userSettings.subtitle = user.subtitle ?? user.email
                if let imageData = user.profileImageData, let image = UIImage(data: imageData) {
                    self?.profileImage = image
                }
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    private static func loadSettings(from userDefaults: UserDefaults) -> UserSettings {
        guard let data = userDefaults.data(forKey: "userSettings") else {
            return UserSettings.default
        }
        
        do {
            return try JSONDecoder().decode(UserSettings.self, from: data)
        } catch {
            return UserSettings.default
        }
    }
    
    func saveSettings() {
        isLoading = true
        
        do {
            let data = try JSONEncoder().encode(userSettings)
            userDefaults.set(data, forKey: "userSettings")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoading = false
                self.showSuccessAlert = true
                
                // Auto-dismiss success alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showSuccessAlert = false
                }
            }
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func resetToDefaults() {
        userSettings = UserSettings.default
        saveSettings()
    }
    
    func saveProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        self.profileImage = image
        self.isLoading = true
        
        APIService.shared.updateUserProfile(username: nil, subtitle: nil, profileImage: data)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
                case .finished:
                    break
                }
            } receiveValue: { [weak self] user in
                self?.showSuccessAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.showSuccessAlert = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadProfileImage() {
        // No local load needed as we fetch from API
    }
    
    var availableCurrencies: [String] {
        ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
    }
}