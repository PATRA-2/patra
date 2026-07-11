import Foundation

protocol PlantAIChatService: Sendable {
    func reply(to message: String, diagnosis: AIPlantDiagnosis) async -> String
}

struct MockPlantAIChatService: PlantAIChatService {
    func reply(to message: String, diagnosis: AIPlantDiagnosis) async -> String {
        try? await Task.sleep(for: .milliseconds(650))

        let normalized = message.lowercased()
        let answer: String

        if normalized.contains("hari ini") || normalized.contains("sekarang") {
            answer = "Hari ini, tandai area terdampak, pisahkan daun yang paling rusak, dan foto ulang dari sudut yang sama untuk membandingkan perubahan besok."
        } else if normalized.contains("pisah") || normalized.contains("tanaman lain") {
            answer = "Pisahkan tanaman yang gejalanya paling jelas dan hindari memindahkan alat dari area terdampak ke tanaman sehat sebelum dibersihkan."
        } else if normalized.contains("penyuluh") || normalized.contains("koperasi") {
            answer = "Hubungi koperasi atau penyuluh jika bercak meluas cepat, lebih dari satu petak terdampak, atau tanaman mulai layu. Sertakan foto dan lokasi lahan saat melapor."
        } else {
            answer = "Berdasarkan perkiraan \(diagnosis.prediction.lowercased()), lanjutkan pemantauan harian dan catat perubahan gejala. Hindari menentukan pestisida hanya dari hasil AI."
        }

        return "\(answer) Jika kondisi memburuk, minta pemeriksaan langsung dari koperasi atau penyuluh."
    }
}
