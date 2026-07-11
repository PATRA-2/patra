import SwiftUI

struct PlantAIChatView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let taskID: UUID
    @State private var viewModel = PlantAIChatViewModel()
    @FocusState private var isComposerFocused: Bool

    private var task: PlantAnalysisTask? {
        analysisStore.task(withID: taskID)
    }

    private var messages: [PlantChatMessage] {
        task?.chatMessages ?? []
    }

    private var isResponding: Bool {
        analysisStore.isResponding(in: taskID)
    }

    var body: some View {
        Group {
            if let task, let diagnosis = task.diagnosis {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            diagnosisContext(task: task, diagnosis: diagnosis)
                            suggestedPrompts

                            ForEach(messages) { message in
                                PlantChatBubble(message: message)
                                    .id(message.id)
                            }

                            if isResponding {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 76)
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToLatest(proxy)
                    }
                    .onChange(of: isResponding) { _, _ in
                        scrollToLatest(proxy)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Chat belum tersedia",
                    systemImage: "bubble.left.and.exclamationmark.bubble.right",
                    description: Text("Selesaikan analisis tanaman terlebih dahulu.")
                )
            }
        }
        .background(RTDColor.background)
        .navigationTitle("Tanya AI")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if task?.diagnosis != nil {
                composer
            }
        }
    }

    private func diagnosisContext(
        task: PlantAnalysisTask,
        diagnosis: AIPlantDiagnosis
    ) -> some View {
        HStack(spacing: 13) {
            Image(uiImage: task.image)
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Label("Konteks diagnosis", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.leafGreen)
                Text(diagnosis.prediction)
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                    .lineLimit(2)
                Text("Confidence \(diagnosis.confidence)% · \(task.farm.name)")
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)
            }

            Spacer(minLength: 4)
        }
        .padding(14)
        .rtdCard(radius: 18)
    }

    private var suggestedPrompts: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pertanyaan yang disarankan")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            send(suggestion)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(RTDColor.softGreen, in: Capsule())
                        .disabled(isResponding)
                    }
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Tanyakan langkah pemantauan...", text: $viewModel.draftMessage, axis: .vertical)
                .lineLimit(1 ... 4)
                .focused($isComposerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 20))
                .submitLabel(.send)
                .onSubmit(sendDraft)

            Button(action: sendDraft) {
                Image(systemName: "arrow.up")
                    .font(.headline.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(RTDColor.primaryGreen, in: Circle())
            }
            .disabled(
                viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || isResponding
            )
            .accessibilityLabel("Kirim pertanyaan")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func sendDraft() {
        send(viewModel.takeMessage())
    }

    private func send(_ message: String) {
        guard !message.isEmpty, !isResponding else { return }
        isComposerFocused = false
        Task {
            await analysisStore.sendChatMessage(message, taskID: taskID)
        }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        withAnimation(.smooth) {
            if isResponding {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

private struct PlantChatBubble: View {
    let message: PlantChatMessage

    private var isFarmer: Bool {
        message.role == .farmer
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFarmer {
                Spacer(minLength: 52)
            } else {
                Image(systemName: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(RTDColor.deepGreen)
                    .frame(width: 30, height: 30)
                    .background(RTDColor.primaryGreen, in: Circle())
                    .accessibilityHidden(true)
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(isFarmer ? Color.white : RTDColor.textPrimary)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    isFarmer ? RTDColor.deepGreen : RTDColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    if !isFarmer {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(RTDColor.borderSoft, lineWidth: 1)
                    }
                }
                .frame(maxWidth: 310, alignment: isFarmer ? .trailing : .leading)

            if !isFarmer {
                Spacer(minLength: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFarmer ? "Pesan Anda" : "Jawaban AI")
    }
}

private struct TypingIndicator: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(RTDColor.deepGreen)
            Text("AI sedang menyusun jawaban...")
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
            Spacer()
        }
        .padding(14)
        .rtdCard(radius: 18)
        .accessibilityLabel("AI sedang menyusun jawaban")
    }
}
