import Foundation

enum APIErrorCode {
    static let invalidCredentials = "INVALID_CREDENTIALS"
    static let emailAlreadyRegistered = "EMAIL_ALREADY_REGISTERED"
    static let invalidRefreshToken = "INVALID_REFRESH_TOKEN"
    static let forbidden = "FORBIDDEN"
    static let notFound = "NOT_FOUND"
    static let farmInUse = "FARM_IN_USE"
    static let reportAlreadyVerified = "REPORT_ALREADY_VERIFIED"
    static let reportAlreadyRejected = "REPORT_ALREADY_REJECTED"
    static let reportNotReady = "REPORT_NOT_READY"
    static let validationError = "VALIDATION_ERROR"
    static let farmRequired = "FARM_REQUIRED"
    static let locationRequired = "LOCATION_REQUIRED"
    static let payloadTooLarge = "PAYLOAD_TOO_LARGE"
    static let unsupportedMedia = "UNSUPPORTED_MEDIA_TYPE"
    static let aiTimeout = "AI_TIMEOUT"
    static let aiUnavailable = "AI_UNAVAILABLE"
}