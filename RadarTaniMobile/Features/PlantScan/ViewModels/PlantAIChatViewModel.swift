import Foundation
import Observation

@MainActor
@Observable
final class PlantAIChatViewModel {
    var draftMessage = ""

    let suggestions = [
        "Apa yang harus saya lakukan hari ini?",
        "Perlukah tanaman lain dipisahkan?",
        "Kapan saya harus menghubungi penyuluh?"
    ]

    func takeMessage() -> String {
        let message = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        draftMessage = ""
        return message
    }
}
