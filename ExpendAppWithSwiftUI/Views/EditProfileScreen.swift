import SwiftUI

struct EditProfileScreen: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var username: String = ""
    @State private var subtitle: String = ""
    @State private var cardNumber: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    
    // Colors (matching app theme)
    private let backgroundColor = Color(.systemGroupedBackground)
    private let rowBackgroundColor = Color(.secondarySystemGroupedBackground)
    private let accentGreen = Color.green
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: saveProfile) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(accentGreen)
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Image
                        Button(action: { showImagePicker = true }) {
                            ZStack {
                                if let image = selectedImage ?? viewModel.profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(.systemGray4))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(30)
                                                .foregroundColor(Color(.systemGray))
                                        )
                                }
                                
                                // Camera Icon Overlay
                                Circle()
                                    .fill(accentGreen)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 40, y: 40)
                            }
                        }
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            inputField(title: "Username", text: $username, icon: "person")
                            inputField(title: "Subtitle / Role", text: $subtitle, icon: "text.quote")
                            inputField(title: "Visa Card Number", text: $cardNumber, icon: "creditcard")
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            // Load current values
            username = viewModel.userSettings.username
            subtitle = viewModel.userSettings.subtitle
            cardNumber = viewModel.userSettings.cardNumber
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private func inputField(title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(accentGreen)
                    .frame(width: 24)
                
                TextField("", text: text)
                    .foregroundColor(.primary)
                    .font(.body)
            }
            .padding()
            .background(rowBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    private func saveProfile() {
        // Update ViewModel
        viewModel.userSettings.username = username
        viewModel.userSettings.subtitle = subtitle
        viewModel.userSettings.cardNumber = cardNumber
        
        // Save Settings
        viewModel.saveSettings()
        
        // Save Image if changed
        if let newImage = selectedImage {
            viewModel.saveProfileImage(newImage)
        }
        
        dismiss()
    }
}
