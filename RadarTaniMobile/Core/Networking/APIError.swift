import Foundation

enum APIError: Error, Sendable {
    case unauthenticated
    case server(ServerError)
    case network(URLError)
    case decoding(Error)
    case invalidURL
    case unknown

    var isAIError: Bool {
        if case .server(let s) = self {
            return s.code == APIErrorCode.aiTimeout || s.code == APIErrorCode.aiUnavailable
        }
        return false
    }

    var userMessage: String {
        switch self {
        case .unauthenticated: return "Sesi habis, silakan masuk kembali."
        case .server(let s):
            switch s.code {
            case APIErrorCode.invalidCredentials: return "Email atau password salah."
            case APIErrorCode.emailAlreadyRegistered: return "Email sudah terdaftar."
            case APIErrorCode.farmInUse: return "Lahan masih digunakan laporan, tidak bisa dihapus."
            case APIErrorCode.reportAlreadyVerified: return "Laporan sudah diverifikasi, tidak bisa diubah."
            case APIErrorCode.reportAlreadyRejected: return "Laporan sudah ditolak."
            case APIErrorCode.validationError:
                return s.details?.compactMap { "\($0.field ?? "") \($0.message ?? "")" }
                    .joined(separator: "\n") ?? "Data tidak valid."
            case APIErrorCode.farmRequired: return "Pilih lahan aktif dulu."
            case APIErrorCode.locationRequired: return "Aktifkan lokasi atau pilih lahan aktif."
            case APIErrorCode.aiTimeout: return "Analisis AI melebihi batas waktu, coba lagi."
            case APIErrorCode.aiUnavailable: return "Layanan AI sedang tidak tersedia."
            case APIErrorCode.invalidRefreshToken: return "Sesi habis, silakan masuk kembali."
            default: return s.message
            }
        case .network: return "Tidak ada koneksi internet."
        case .decoding: return "Data response tidak terbaca."
        case .invalidURL: return "URL tidak valid."
        case .unknown: return "Terjadi kesalahan."
        }
    }
}