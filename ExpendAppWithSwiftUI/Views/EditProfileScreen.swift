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
    private let backgroundColor = Color(red: 0.08, green: 0.15, blue: 0.15)
    private let rowBackgroundColor = Color(red: 0.12, green: 0.22, blue: 0.22)
    private let accentGreen = Color(red: 0.3, green: 0.9, blue: 0.5)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                    
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
                                        .fill(Color(red: 0.85, green: 0.75, blue: 0.65))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(30)
                                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                                        )
                                }
                                
                                // Camera Icon Overlay
                                Circle()
                                    .fill(accentGreen)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(backgroundColor)
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
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(accentGreen)
                    .frame(width: 24)
                
                TextField("", text: text)
                    .foregroundColor(.white)
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
