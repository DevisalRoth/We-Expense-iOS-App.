import Foundation
import Combine

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(Int, String) // Code, Message
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
}

class APIService {
    static let shared = APIService()
    
    private var isRefreshing = false
    private var refreshPublisher: AnyPublisher<Bool, APIError>?
    private let refreshLock = NSLock()
    
    private var baseURL: String {
        // Production URL (Vercel)
        return "https://we-expense-api.vercel.app"
        
        // Local Development URLs (Uncomment to use)
        /*
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8002"
        #else
        return "http://192.168.89.75:8002" // Replace with your machine's local IP
        #endif
        */
    }
    
    private init() {}
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try standard ISO8601 with fractional seconds (Python default)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 without fractional seconds
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to ISO8601DateFormatter for other variants
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }
    
    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    // MARK: - Logger Helper
    private func logRequest(request: URLRequest) {
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "GET"
        let headers = request.allHTTPHeaderFields ?? [:]
        
        print("\n🔵 ------------------ REQUEST ------------------")
        print("📍 URL: \(url)")
        print("📝 Method: \(method)")
        
        // Pretty print headers
        print("🔑 Headers:")
        for (key, value) in headers {
            if key == "Authorization" {
                print("   \(key): \(value.prefix(20))...")
            } else {
                print("   \(key): \(value)")
            }
        }
        
        if let body = request.httpBody {
            if let json = try? JSONSerialization.jsonObject(with: body, options: .mutableContainers),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📦 Body (Pretty JSON):\n\(jsonString)")
            } else if let bodyString = String(data: body, encoding: .utf8) {
                print("📦 Body (Raw): \(bodyString)")
            }
        }
        print("------------------------------------------------\n")
    }

    private func logResponse(data: Data, response: URLResponse?) {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("\n🔴 ------------------ RESPONSE ERROR ------------------")
            print("❌ Invalid Response Object")
            print("------------------------------------------------------\n")
            return
        }
        
        let statusCode = httpResponse.statusCode
        let url = httpResponse.url?.absoluteString ?? "Unknown URL"
        let icon = (200...299).contains(statusCode) ? "🟢" : "🔴"
        
        print("\n\(icon) ------------------ RESPONSE ------------------")
        print("📍 URL: \(url)")
        print("🔢 Status: \(statusCode)")
        
        if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📦 Body (Pretty JSON):\n\(jsonString)")
        } else if let bodyString = String(data: data, encoding: .utf8) {
             print("📦 Body (Raw): \(bodyString)")
        }
        print("--------------------------------------------------\n")
    }

    private func createAuthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    // MARK: - Helpers
    
    private struct ErrorResponse: Codable {
        let detail: String
    }
    
    private func parseError(data: Data, statusCode: Int) -> APIError {
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return .serverError(statusCode, errorResponse.detail)
        }
        
        // Handle validation errors which might be an array or different format
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = json["detail"] as? [[String: Any]],
           let firstError = detail.first,
           let msg = firstError["msg"] as? String {
            return .serverError(statusCode, msg)
        }
        
        return .serverError(statusCode, "Server returned error code: \(statusCode)")
    }

    // MARK: - Generic Request Handler
    
    private func performRequest<T: Decodable>(endpoint: String, method: String = "GET", body: Encodable? = nil, retryCount: Int = 0) -> AnyPublisher<T, APIError> {
        let urlString = "\(baseURL)\(endpoint)"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = createAuthenticatedRequest(url: url, method: method)
        
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
            }
        }
        
        // Log Request
        logRequest(request: request)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .flatMap { [weak self] data, response -> AnyPublisher<T, APIError> in
                guard let self = self else { return Fail(error: APIError.unknown).eraseToAnyPublisher() }
                
                // Log Response
                self.logResponse(data: data, response: response)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                // Handle 401 Unauthorized - Attempt Refresh Token
                if httpResponse.statusCode == 401 && retryCount == 0 {
                    return self.refreshToken()
                        .flatMap { success -> AnyPublisher<T, APIError> in
                            if success {
                                // Retry the original request with new token
                                return self.performRequest(endpoint: endpoint, method: method, body: body, retryCount: retryCount + 1)
                            } else {
                                // Refresh failed, trigger logout
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .authSessionExpired, object: nil)
                                }
                                return Fail(error: APIError.serverError(401, "Session expired")).eraseToAnyPublisher()
                            }
                        }
                        .eraseToAnyPublisher()
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: self.parseError(data: data, statusCode: httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: T.self, decoder: self.decoder)
                    .mapError { APIError.decodingFailed($0) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func refreshToken() -> AnyPublisher<Bool, APIError> {
        refreshLock.lock()
        defer { refreshLock.unlock() }
        
        if let publisher = refreshPublisher {
            return publisher
        }
        
        guard let refreshToken = TokenManager.shared.getRefreshToken() else {
            return Just(false).setFailureType(to: APIError.self).eraseToAnyPublisher()
        }
        
        let urlString = "\(baseURL)/refresh?token=\(refreshToken)"
        guard let url = URL(string: urlString) else {
            return Just(false).setFailureType(to: APIError.self).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let publisher = URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .flatMap { [weak self] data, response -> AnyPublisher<Bool, APIError> in
                guard let self = self else { return Just(false).setFailureType(to: APIError.self).eraseToAnyPublisher() }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    return Just(false).setFailureType(to: APIError.self).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: AuthResponse.self, decoder: self.decoder)
                    .map { authResponse in
                        TokenManager.shared.saveAccessToken(authResponse.accessToken)
                        // If backend returns a new refresh token, save it too
                        TokenManager.shared.saveRefreshToken(authResponse.refreshToken)
                        return true
                    }
                    .mapError { APIError.decodingFailed($0) }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.refreshLock.lock()
                self?.refreshPublisher = nil
                self?.refreshLock.unlock()
            })
            .share()
            .eraseToAnyPublisher()
            
        self.refreshPublisher = publisher
        return publisher
    }

    // MARK: - Auth
    
    func register(email: String, password: String) -> AnyPublisher<User, APIError> {
        let body: [String: String] = ["email": email, "password": password]
        // Note: register endpoint doesn't use the generic performRequest perfectly because
        // it manually sets content-type to json (generic does too via createAuthenticatedRequest)
        // but it doesn't need auth token. createAuthenticatedRequest handles adding token if present.
        // For register/login, we might want to ensure no token is sent, or it doesn't matter.
        // Let's use the manual implementation for auth to be safe and explicit, 
        // or refactor performRequest to allow unauthenticated.
        // For now, let's keep register/login manual as they are special (no auth required).
        
        let urlString = "\(baseURL)/register"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .flatMap { [weak self] data, response -> AnyPublisher<User, APIError> in
                guard let self = self else { return Fail(error: APIError.unknown).eraseToAnyPublisher() }
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: self.parseError(data: data, statusCode: httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: User.self, decoder: self.decoder)
                    .mapError { APIError.decodingFailed($0) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        // Login uses x-www-form-urlencoded, so it's different from standard JSON generic request
        let urlString = "\(baseURL)/token"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "username=\(email)&password=\(password)"
        request.httpBody = bodyString.data(using: .utf8)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .flatMap { [weak self] data, response -> AnyPublisher<AuthResponse, APIError> in
                guard let self = self else { return Fail(error: APIError.unknown).eraseToAnyPublisher() }
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: self.parseError(data: data, statusCode: httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: AuthResponse.self, decoder: self.decoder)
                    .mapError { APIError.decodingFailed($0) }
                    .handleEvents(receiveOutput: { authResponse in
                        TokenManager.shared.saveAccessToken(authResponse.accessToken)
                        TokenManager.shared.saveRefreshToken(authResponse.refreshToken)
                    })
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchCurrentUser() -> AnyPublisher<User, APIError> {
        return performRequest(endpoint: "/users/me")
    }
    
    func updateUserProfile(username: String?, subtitle: String?, profileImage: Data?) -> AnyPublisher<User, APIError> {
        // Create a custom struct for this specific update since it's dynamic
        var body: [String: String] = [:]
        if let username = username { body["username"] = username }
        if let subtitle = subtitle { body["subtitle"] = subtitle }
        if let profileImage = profileImage { body["profile_image_data"] = profileImage.base64EncodedString() }
        
        // Use a slight variation of performRequest logic since body is [String: String] not Encodable struct directly (though Dictionary is Encodable)
        return performRequest(endpoint: "/users/me", method: "PUT", body: body)
    }
    
    // MARK: - Expenses
    
    func fetchExpenses() -> AnyPublisher<[Expense], APIError> {
        return performRequest(endpoint: "/expenses/")
    }
    
    func createExpense(expense: ExpenseCreate) -> AnyPublisher<Expense, APIError> {
        return performRequest(endpoint: "/expenses/", method: "POST", body: expense)
    }
    
    func updateExpense(id: UUID, expense: ExpenseCreate) -> AnyPublisher<Expense, APIError> {
        return performRequest(endpoint: "/expenses/\(id.uuidString.lowercased())", method: "PUT", body: expense)
    }
    
    func deleteExpense(id: UUID) -> AnyPublisher<Expense, APIError> {
        return performRequest(endpoint: "/expenses/\(id.uuidString.lowercased())", method: "DELETE")
    }
    
    func fetchExpense(id: UUID) -> AnyPublisher<Expense, APIError> {
        return performRequest(endpoint: "/expenses/\(id.uuidString.lowercased())")
    }
    
    // MARK: - Saved Items
    
    func fetchSavedItems() -> AnyPublisher<[SavedItem], APIError> {
        return performRequest(endpoint: "/saved-items/")
    }
    
    func createSavedItem(name: String, defaultPrice: Double) -> AnyPublisher<SavedItem, APIError> {
        let itemCreate = SavedItemCreate(name: name, defaultPrice: defaultPrice)
        return performRequest(endpoint: "/saved-items/", method: "POST", body: itemCreate)
    }
    
    func deleteSavedItem(id: UUID) -> AnyPublisher<SavedItem, APIError> {
        return performRequest(endpoint: "/saved-items/\(id.uuidString.lowercased())", method: "DELETE")
    }
}

// DTO for Creating Expense
struct ExpenseCreate: Codable {
    let title: String
    let amount: Double
    let date: Date
    let category: ExpenseCategory
    let receiptData: Data?
    let recipientEmail: String?
    let telegramChatId: String?
    let splits: [SplitCreate]
    let items: [ExpenseItemCreate]
    
    enum CodingKeys: String, CodingKey {
        case title, amount, date, category, splits, items
        case receiptData = "receipt_data"
        case recipientEmail = "recipient_email"
        case telegramChatId = "telegram_chat_id"
    }
}

struct ExpenseItemCreate: Codable {
    let name: String
    let price: Double
    let quantity: Int
    let imageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case name, price, quantity
        case imageData = "image_data"
    }
}

struct SplitCreate: Codable {
    let name: String
    let initials: String
    let amount: Double?
}

struct SavedItemCreate: Codable {
    let name: String
    let defaultPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case name
        case defaultPrice = "default_price"
    }
}
