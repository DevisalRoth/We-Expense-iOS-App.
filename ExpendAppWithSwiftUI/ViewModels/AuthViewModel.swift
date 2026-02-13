import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isAuthenticated = TokenManager.shared.getAccessToken() != nil
        
        NotificationCenter.default.publisher(for: .authSessionExpired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.logout()
            }
            .store(in: &cancellables)
    }
    
    func login() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.login(email: email, password: password)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [weak self] _ in
                self?.isAuthenticated = true
            }
            .store(in: &cancellables)
    }
    
    func register() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.register(email: email, password: password)
            .flatMap { _ in
                APIService.shared.login(email: self.email, password: self.password)
            }
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [weak self] _ in
                self?.isAuthenticated = true
            }
            .store(in: &cancellables)
    }
    
    func logout() {
        TokenManager.shared.clearTokens()
        isAuthenticated = false
        email = ""
        password = ""
    }
}
