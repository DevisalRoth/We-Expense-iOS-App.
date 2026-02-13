import SwiftUI
import Combine

struct SettingsScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditProfile = false
    @State private var showItemsManagement = false
    
    // Custom Colors
    private let backgroundColor = Color(red: 0.05, green: 0.1, blue: 0.08) // Dark green/black
    private let rowBackgroundColor = Color(red: 0.08, green: 0.15, blue: 0.12) // Slightly lighter
    private let accentGreen = Color(red: 0.0, green: 0.85, blue: 0.4) // Bright green
    private let textGray = Color(red: 0.6, green: 0.7, blue: 0.65)
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileSection
                    
                    // Account & Security
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("ACCOUNT & SECURITY")
                        
                        VStack(spacing: 1) {
                            SettingsNavigationRow(
                                icon: "person.fill",
                                title: "Profile Settings",
                                color: accentGreen,
                                action: { showEditProfile = true }
                            )
                            
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                isOn: $viewModel.userSettings.notificationsEnabled,
                                color: accentGreen
                            )
                        }
                        .background(rowBackgroundColor)
                        .cornerRadius(12)
                    }
                    
                    // California Vibes
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("CALIFORNIA VIBES")
                        
                        VStack(spacing: 1) {
                            SettingsNavigationRow(
                                icon: "map.fill",
                                title: "Trip Preferences",
                                color: accentGreen
                            )
                            
                            SettingsNavigationRow(
                                icon: "music.note",
                                title: "Music Events",
                                color: accentGreen
                            )
                        }
                        .background(rowBackgroundColor)
                        .cornerRadius(12)
                    }
                    
                    // Regional
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("REGIONAL")
                        
                        VStack(spacing: 1) {
                            SettingsNavigationRow(
                                icon: "banknote.fill",
                                title: "Currency & Units",
                                detail: "USD, Miles",
                                color: accentGreen
                            )
                        }
                        .background(rowBackgroundColor)
                        .cornerRadius(12)
                    }
                    
                    // App Settings
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("APP SETTINGS")
                        
                        VStack(spacing: 1) {
                            SettingsNavigationRow(
                                icon: "list.bullet.rectangle.portrait.fill",
                                title: "Manage Quick Add Items",
                                color: accentGreen,
                                action: { showItemsManagement = true }
                            )
                            
                            SettingsToggleRow(
                                icon: "moon.fill",
                                title: "Dark Mode",
                                isOn: $viewModel.userSettings.darkModeEnabled,
                                color: accentGreen
                            )
                        }
                        .background(rowBackgroundColor)
                        .cornerRadius(12)
                    }
                    
                    // Logout
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Color.red.opacity(0.2)
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(8)
                                
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                            
                            Text("Log Out")
                                .font(.body)
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding()
                        .background(rowBackgroundColor)
                        .cornerRadius(12)
                    }
                    
                    // Bottom Padding
                    Spacer().frame(height: 40)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) {
            EditProfileScreen(viewModel: viewModel)
        }
        .sheet(isPresented: $showItemsManagement) {
            NavigationView {
                ItemsManagementScreen(viewModel: budgetViewModel)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        // Force dark mode for this screen as per design
        .preferredColorScheme(.dark)
    }
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                // Profile Image Placeholder
                if let image = viewModel.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(red: 0.85, green: 0.75, blue: 0.65))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(20)
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                        )
                }
                
                // Edit Badge
                Button(action: { showEditProfile = true }) {
                    Circle()
                        .fill(accentGreen)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(backgroundColor)
                        )
                }
                .offset(x: 0, y: 0)
            }
            
            VStack(spacing: 4) {
                Text(viewModel.userSettings.username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(viewModel.userSettings.subtitle)
                    .font(.subheadline)
                    .foregroundColor(accentGreen)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(textGray)
            .tracking(1) // Letter spacing
            .padding(.leading, 8)
            .padding(.bottom, 4)
    }
}

// MARK: - Helper Components

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    var detail: String? = nil
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16))
                }
                
                Text(title)
                    .foregroundColor(.white)
                    .font(.body)
                
                Spacer()
                
                if let detail = detail {
                    Text(detail)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color(red: 0.08, green: 0.15, blue: 0.12))
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
            }
            
            Text(title)
                .foregroundColor(.white)
                .font(.body)
            
            Spacer()
            
            if isOn {
                Text("On")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.trailing, 4)
            }
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding()
        .background(Color(red: 0.08, green: 0.15, blue: 0.12))
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsScreen()
        }
    }
}
