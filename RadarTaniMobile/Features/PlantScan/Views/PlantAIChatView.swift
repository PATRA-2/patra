import SwiftUI

struct PlantAIChatView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let taskID: UUID
    @State private var draftMessage = ""
    @FocusState private var isComposerFocused: Bool

    private var task: PlantAnalysisTask? {
        analysisStore.task(withID: taskID)
    }

    private var isResponding: Bool {
        analysisStore.isResponding(in: taskID)
    }

    var body: some View {
        Group {
            if let task, let diagnosis = task.diagnosis {
                chatContent(task: task, diagnosis: diagnosis)
            } else {
                ContentUnavailableView(
                    "Chat belum tersedia",
                    systemImage: "message.badge",
                    description: Text("Chat AI tersedia setelah analisis selesai.")
                )
                .background(RTDColor.background)
            }
        }
        .navigationTitle("Chat AI")
        .navigationBarTitleDisplayMode(.inline)
        .background(RTDColor.background)
    }

    private func chatContent(task: PlantAnalysisTask, diagnosis: AIPlantDiagnosis) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    diagnosisSummary(task: task, diagnosis: diagnosis)

                    ForEach(task.chatMessages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if isResponding {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.85)
                            Text("AI menyiapkan jawaban...")
                                .font(.caption)
                                .foregroundStyle(RTDColor.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RTDColor.mutedBackground, in: Capsule())
                    }
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                composer
                    .background(.regularMaterial)
            }
            .onChange(of: task.chatMessages.count) { _, _ in
                guard let lastID = analysisStore.task(withID: taskID)?.chatMessages.last?.id else { return }
                withAnimation(.snappy) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    private func diagnosisSummary(task: PlantAnalysisTask, diagnosis: AIPlantDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(uiImage: task.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Foto tanaman")

                VStack(alignment: .leading, spacing: 5) {
                    Text(diagnosis.prediction)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(task.farm.name, systemImage: "leaf.fill")
                        .font(.caption)
                        .foregroundStyle(RTDColor.textSecondary)
                }

                Spacer(minLength: 8)
                ConfidenceBadge(score: diagnosis.confidence)
            }

            Text("Tanyakan langkah pemantauan yang aman sebelum laporan dikirim ke koperasi.")
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .rtdCard(radius: 20)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Tanya langkah pemantauan...", text: $draftMessage, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .focused($isComposerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(RTDColor.borderSoft, lineWidth: 1)
                }

            Button {
                send()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(canSend ? RTDColor.primaryGreen : RTDColor.borderSoft, in: Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel("Kirim pesan")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var canSend: Bool {
        !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isResponding
    }

    private func send() {
        let message = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        draftMessage = ""
        Task {
            await analysisStore.sendChatMessage(message, taskID: taskID)
        }
    }
}

private struct ChatBubble: View {
    let message: PlantChatMessage

    private var isFarmer: Bool {
        message.role == .farmer
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFarmer { Spacer(minLength: 42) }

            VStack(alignment: isFarmer ? .trailing : .leading, spacing: 5) {
                Text(isFarmer ? "Petani" : "AI RadarTani")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(message.text)
                    .font(.callout)
                    .foregroundStyle(isFarmer ? RTDColor.textPrimary : RTDColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                isFarmer ? RTDColor.primaryGreen.opacity(0.9) : RTDColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                if !isFarmer {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(RTDColor.borderSoft, lineWidth: 1)
                }
            }
            .frame(maxWidth: 300, alignment: isFarmer ? .trailing : .leading)

            if !isFarmer { Spacer(minLength: 42) }
        }
        .frame(maxWidth: .infinity, alignment: isFarmer ? .trailing : .leading)
    }
}
