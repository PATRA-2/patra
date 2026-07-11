import Foundation

enum MockUser {
    static let current = UserOut(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Petani RTD",
        email: "petani@radartani.id",
        cooperativeName: "Koperasi Desa Sukamaju")
}
