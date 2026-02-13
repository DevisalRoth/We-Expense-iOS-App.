# ExpendAppWithSwiftUI (Trip Budget)

A SwiftUI app that helps track a trip budget, visualize spending, and quickly add expenses. The app showcases modern SwiftUI techniques including custom charts, sheets, context menus, haptics, and UIKit integration for camera access.

## Overview

- Main screen displays a donut chart of total spent vs budget, category legend, budget stats, and a recent expenses list.
- Edit budget with a sheet, and add new expenses with a floating action button.
- A dedicated “Create Expense” screen includes amount entry, title, category selection, optional friend-splitting, and receipt capture via camera.

## Screens

- Trip Budget: [ContentView.swift](file:///Users/visalroth/Documents/Developer/SwiftUI/ExpendAppWithSwiftUI/ExpendAppWithSwiftUI/ContentView.swift#L15-L19) drives [TripBudgetScreen](file:///Users/visalroth/Documents/Developer/SwiftUI/ExpendAppWithSwiftUI/ExpendAppWithSwiftUI/ContentView.swift#L144-L301) with a donut chart, stats, and recent expenses.
- Create Expense: [CreateExpenseScreen](file:///Users/visalroth/Documents/Developer/SwiftUI/ExpendAppWithSwiftUI/ExpendAppWithSwiftUI/Views/CreateExpenseScreen.swift) provides the enhanced expense creation flow with category buttons, friend split, and camera.

## Architecture

- Entry point: `@main` [TripBudgetApp](file:///Users/visalroth/Documents/Developer/SwiftUI/ExpendAppWithSwiftUI/ExpendAppWithSwiftUI/ContentView.swift#L5-L12).
- State: `BudgetViewModel` ([ContentView.swift](file:///Users/visalroth/Documents/Developer/SwiftUI/ExpendAppWithSwiftUI/ExpendAppWithSwiftUI/ContentView.swift#L119-L141)) manages expense data via `APIService`.
- Networking: `APIService` handles all backend communication (FastAPI) using `Combine`.
- Authentication: `AuthViewModel` manages login/registration state, backed by `TokenManager` (Keychain).
- UI: Pure SwiftUI views with small helper types (e.g., `ExpenseRowView`, `DonutChartView`, `EditBudgetSheet`).
- UIKit bridge: `ImagePicker` ([Createexpensescreenenhanced.swift](file:///Users/visalroth/Documents/Developer/SwiftUI/ExpendAppWithSwiftUI/ExpendAppWithSwiftUI/Createexpensescreenenhanced.swift#L585-L621)) wraps `UIImagePickerController` for receipt capture.
- Haptics: `HapticManager` ([Createexpensescreenenhanced.swift](file:///Users/visalroth/Documents/Developer/SwiftUI/ExpendAppWithSwiftUI/ExpendAppWithSwiftUI/Createexpensescreenenhanced.swift#L624-L634)) provides light/success feedback.

## Project Structure

```
ExpendAppWithSwiftUI/
├── Views/
│   ├── ContentView.swift (App entry + main view)
│   ├── TripBudgetScreen.swift (Main budget screen with subviews)
│   ├── Createexpensescreenenhanced.swift (Expense creation)
│   ├── ExpenseDetailScreen.swift (Expense details)
│   ├── LoginView.swift (Authentication)
│   ├── SettingsScreen.swift (User profile & settings)
│   └── EditProfileScreen.swift (Profile editing)
├── ViewModels/
│   ├── BudgetViewModel.swift (Expense management)
│   ├── AuthViewModel.swift (Login/Register logic)
│   └── SettingsViewModel.swift (Profile & preferences)
├── Services/
│   └── APIService.swift (Networking layer)
├── Models/
│   ├── APIModels.swift (JSON codable structs)
│   ├── Expense.swift (Expense data model)
│   ├── ExpenseCategory.swift (Category enum with colors)
│   └── BudgetData.swift (Budget data structure)
└── Utilities/
    ├── TokenManager.swift (Keychain token storage)
    ├── HapticManager.swift (Haptic feedback)
    └── ImagePicker.swift (Camera/image picker)
```

## Features

- **Authentication**: Secure Login & Registration with JWT (Access + Refresh Tokens).
- **Backend Integration**: Real-time data sync with FastAPI backend.
- **Token Management**: Automatic token refresh and secure Keychain storage.
- **Profile**: Update username, subtitle, and profile picture.
- **Expenses**: Create, read, update, and delete expenses.
- **Saved Items**: Manage frequently used expense items.

## Requirements

- Xcode 15 or newer
- iOS 16 or newer (recommended due to `#Preview` usage)
- Swift 5.9+ (Xcode 15 toolchain)

## Getting Started

1. Open `ExpendAppWithSwiftUI.xcodeproj` in Xcode.
2. Select a simulator or device.
3. Run the app (⌘R).

Notes:
- The main entry point is `TripBudgetApp`. For the standalone Create Expense demo, `CreateExpenseApp` is compiled only under `#if DEBUG` and can be set as the run target if desired.
- Camera features require a real device; the iOS Simulator does not provide a camera.

## Usage

- On the Trip Budget screen:
  - Review donut chart for spending progress.
  - Use “Edit” to update budget and trip name.
  - Long-press an expense row to delete via context menu.
  - Tap the floating “+” to open the Create Expense screen.
- On Create Expense:
  - Enter amount and title, pick a category.
  - Optionally enable “Split with Friends” and select friends.
  - Tap “Scan Receipt” to capture an image via camera.

## Data and Persistence

- `BudgetData` is in-memory sample data; expenses and stats reset on app restart.
- `BudgetViewModel` applies simple mutations: add/delete expenses and update budget.

## Permissions

- Camera access is used for receipt capture. Ensure `NSCameraUsageDescription` is set in your app’s Info.plist when shipping; Xcode templates often prompt for this automatically when compiling for device.

## Extending the App

- Add persistence (e.g., Core Data or SwiftData) to store expenses and budgets.
- Integrate real friend models and contacts.
- Add charts per category and trend lines.
- Implement filtering and “View All” navigation.

## License

No explicit license is included in this repository.
