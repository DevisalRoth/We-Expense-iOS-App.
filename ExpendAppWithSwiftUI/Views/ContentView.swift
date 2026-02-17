import SwiftUI

// MARK: - App Entry Point
@main
struct TripBudgetApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) var scenePhase
    @State private var isBlurring = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authViewModel.isAuthenticated {
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
                
                // Privacy Screen (Blur Effect) - Applies to ALL screens because it's in ZStack at Root
                if isBlurring {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            VStack(spacing: 20) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray)
                                Text("ExpendApp")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        )
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    withAnimation { isBlurring = false }
                case .inactive, .background:
                    withAnimation { isBlurring = true }
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Trip Budget
            NavigationView {
                TripBudgetScreen()
            }
            .tabItem {
                Image(systemName: "dollarsign.circle.fill")
                Text("Budget")
            }
            .tag(0)
            
            // Tab 2: Expenses (placeholder)
            NavigationView {
                ExpensesScreen()
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Expenses")
            }
            .tag(1)
            
            // Tab 3: Analytics (placeholder)
            NavigationView {
                AnalyticsScreen()
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Analytics")
            }
            .tag(2)
            
            // Tab 4: Settings (placeholder)
            NavigationView {
                SettingsScreen()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(3)
        }
        .accentColor(Color(red: 0.3, green: 0.9, blue: 0.5))
    }
}


#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

