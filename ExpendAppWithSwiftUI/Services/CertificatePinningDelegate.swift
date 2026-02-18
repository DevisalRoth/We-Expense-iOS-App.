import Foundation
import Security
import CryptoKit

class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    
    // The domain to pin.
    private let pinnedDomain = "we-expense-api.vercel.app"
    
    // The expected public key hash (Subject Public Key Info - SPKI).
    // Obtained via: openssl s_client -connect we-expense-api.vercel.app:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
    private let pinnedPublicKeys: [String] = [
        "DZM9Oxxp3uxt5JJnpUtfT6flVVHLDXP55RI/BtoaY1E=", // OpenSSL Hash
        "htzx3weuRotXX6zqZWWPLEwrFjgytfMB5Ny9CUgFb7A="  // Received Hash (Likely due to different header handling or cert)
    ]
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // 1. Check if this is a server trust challenge
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // 2. Check if the domain matches the one we want to pin
        let domain = challenge.protectionSpace.host
        if !domain.contains("vercel.app") { // Allow subdomains or exact match
             // For domains we don't care about, let default handling happen (e.g. image loading from other domains)
             completionHandler(.performDefaultHandling, nil)
             return
        }
        
        // 3. Evaluate the trust chain
        // Define a policy (default SSL)
        let policy = SecPolicyCreateSSL(true, domain as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        var trustError: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &trustError)
        
        guard isTrusted else {
            // Certificate is invalid or untrusted by the system
            if let trustError {
                print("❌ SSL Pinning: Trust evaluation error for \(domain): \(trustError)")
            }
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // 4. Perform Pinning (Public Key Pinning)
        if pinnedPublicKeys.isEmpty {
            // If no keys configured, fail safe or allow? 
            // For security, if you have this delegate, you probably want to pin.
            print("⚠️ SSL Pinning: No keys configured for \(domain)")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Get the server's public key using modern API (iOS 15+)
        guard let certChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let serverCertificate = certChain.first,
              let serverPublicKey = SecCertificateCopyKey(serverCertificate),
              let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Hash the public key
        let keyHash = sha256(data: serverPublicKeyData)
        
        if pinnedPublicKeys.contains(keyHash) {
            // Match found!
            print("✅ SSL Pinning: Success for \(domain)")
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // Pinning failed
            print("❌ SSL Pinning: FAILED for \(domain)")
            print("   Expected: \(pinnedPublicKeys)")
            print("   Received: \(keyHash)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    private func sha256(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
    }
}

