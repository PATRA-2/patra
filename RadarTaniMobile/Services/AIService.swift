struct AIService: Sendable {
    func analyzePlant() async -> AIPlantDiagnosis {
        AIPlantDiagnosis(prediction: "Perkiraan awal gangguan hama", confidence: 82, symptoms: "Daun menguning", recommendation: "Periksa area terdampak")
    }
}
