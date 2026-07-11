import SwiftUI

struct PlantDiagnosisResultView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let taskID: UUID
    @Binding var path: [PlantScanRoute]
    @State private var showConfirmation = false

    private var task: PlantAnalysisTask? {
        analysisStore.task(withID: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RTDSpacing.xl) {
                ReportStepIndicator(activeStep: task?.status == .reported ? 4 : 3)

                if let task {
                    resultContent(task)
                } else {
                    missingResultState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, RTDSpacing.md)
            .padding(.bottom, RTDSpacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(RTDColor.background.ignoresSafeArea())
        .navigationTitle("Hasil Analisis")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let task, task.diagnosis != nil {
                actionArea(task: task)
            }
        }
        .sheet(isPresented: $showConfirmation) {
            if let task, let diagnosis = task.diagnosis {
                PlantReportConfirmationSheet(task: task, diagnosis: diagnosis) { _ in
                    path.append(.success(task.id))
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
            }
        }
    }

    @ViewBuilder
    private func resultContent(_ task: PlantAnalysisTask) -> some View {
        photoHero(task)

        if let diagnosis = task.diagnosis {
            diagnosisOverview(diagnosis)
            analysisDetailCard(
                title: "Gejala yang terbaca",
                text: diagnosis.symptoms,
                systemImage: "viewfinder.circle.fill",
                tint: RTDColor.warningOrange
            )
            analysisDetailCard(
                title: "Saran pemantauan awal",
                text: diagnosis.recommendation,
                systemImage: "checklist.checked",
                tint: RTDColor.safeGreen,
                highlighted: true
            )
            reportContext(task)
            DisclaimerCard()
        } else {
            processingState(task)
        }
    }

    private func photoHero(_ task: PlantAnalysisTask) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: task.image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 258)
                .clipped()

            LinearGradient(
                colors: [.clear, RTDColor.textPrimary.opacity(0.76)],
                startPoint: .center,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: RTDSpacing.md) {
                HStack(spacing: RTDSpacing.sm) {
                    heroBadge(
                        task.draft.category.rawValue,
                        systemImage: "leaf.fill",
                        color: RTDColor.warningOrange
                    )
                    heroBadge(
                        task.status.title,
                        systemImage: task.status.systemImage,
                        color: statusColor(task.status)
                    )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Foto berhasil dianalisis")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Label(task.farm.name, systemImage: "leaf.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.84))
                }
            }
            .padding(18)
        }
        .frame(height: 258)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Foto tanaman yang dianalisis dari \(task.farm.name), status \(task.status.title)")
    }

    private func diagnosisOverview(_ diagnosis: AIPlantDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: RTDSpacing.lg) {
            HStack(spacing: RTDSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RTDColor.deepGreen)
                    .accessibilityHidden(true)

                Text("PERKIRAAN AWAL AI")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(RTDColor.deepGreen)
            }

            HStack(alignment: .center, spacing: RTDSpacing.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(diagnosis.prediction)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundStyle(RTDColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Gunakan hasil ini sebagai petunjuk untuk pemantauan awal tanaman.")
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                confidenceRing(score: diagnosis.confidence)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RTDColor.softGreen, RTDColor.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(RTDColor.primaryGreen.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: RTDColor.deepGreen.opacity(0.08), radius: 18, x: 0, y: 9)
    }

    private func confidenceRing(score: Int) -> some View {
        ZStack {
            Circle()
                .stroke(RTDColor.borderSoft, lineWidth: 8)

            Circle()
                .trim(from: 0, to: min(max(Double(score) / 100, 0), 1))
                .stroke(
                    score >= 75 ? RTDColor.safeGreen : RTDColor.warningOrange,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(score)%")
                    .font(.headline.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                    .monospacedDigit()
                Text("yakin")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
            }
        }
        .frame(width: 84, height: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tingkat keyakinan AI \(score) persen")
    }

    private func analysisDetailCard(
        title: String,
        text: String,
        systemImage: String,
        tint: Color,
        highlighted: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: RTDSpacing.lg) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)

                Text(text)
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            highlighted ? RTDColor.softGreen.opacity(0.68) : RTDColor.cardBackground,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(highlighted ? RTDColor.leafGreen.opacity(0.3) : RTDColor.borderSoft, lineWidth: 1)
        }
    }

    private func reportContext(_ task: PlantAnalysisTask) -> some View {
        VStack(alignment: .leading, spacing: RTDSpacing.lg) {
            HStack(spacing: RTDSpacing.md) {
                Image(systemName: "doc.text.image.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTDColor.infoBlue)
                    .frame(width: 40, height: 40)
                    .background(
                        RTDColor.infoBlue.opacity(0.11),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Konteks laporan")
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    Text("Informasi yang akan diterima koperasi")
                        .font(.caption)
                        .foregroundStyle(RTDColor.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: RTDSpacing.sm) {
                Text(task.draft.title)
                    .font(.title3.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !task.draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(task.draft.description)
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .overlay(RTDColor.borderSoft)

            HStack(spacing: RTDSpacing.lg) {
                contextMetadata(task.farm.name, systemImage: "leaf.fill")
                contextMetadata(task.farm.location, systemImage: "mappin.and.ellipse")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }

    private func contextMetadata(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(RTDColor.textSecondary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func processingState(_ task: PlantAnalysisTask) -> some View {
        VStack(spacing: RTDSpacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        task.status == .failed
                            ? RTDColor.warningRed.opacity(0.1)
                            : RTDColor.softGreen
                    )

                if task.status == .failed {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(RTDColor.warningRed)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(RTDColor.deepGreen)
                }
            }
            .frame(width: 68, height: 68)

            VStack(spacing: RTDSpacing.sm) {
                Text(task.status == .failed ? "Analisis belum berhasil" : "Analisis sedang diproses")
                    .font(.title3.bold())
                    .foregroundStyle(RTDColor.textPrimary)

                Text(task.errorMessage ?? task.stageTitle)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }

    private var missingResultState: some View {
        ContentUnavailableView(
            "Hasil tidak ditemukan",
            systemImage: "exclamationmark.magnifyingglass",
            description: Text("Kembali ke Lapor dan mulai analisis baru.")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }

    @ViewBuilder
    private func actionArea(task: PlantAnalysisTask) -> some View {
        VStack(spacing: RTDSpacing.md) {
            if task.status == .reported {
                Label("Menunggu verifikasi koperasi", systemImage: "building.2.crop.circle.fill")
                    .font(.headline)
                    .foregroundStyle(RTDColor.infoBlue)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .padding(.horizontal, RTDSpacing.md)
                    .background(
                        RTDColor.infoBlue.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Button {
                    showConfirmation = true
                } label: {
                    Label("Laporkan ke Koperasi", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            Button {
                path.append(.chat(task.id))
            } label: {
                HStack(spacing: RTDSpacing.md) {
                    Image(systemName: "message.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .frame(width: 36, height: 36)
                        .background(
                            RTDColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tanya AI")
                            .font(.headline)
                            .foregroundStyle(RTDColor.deepGreen)

                        Text("Diskusikan hasil analisis tanaman")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: RTDSpacing.sm)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen.opacity(0.72))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 58)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(AskAIButtonStyle())
            .accessibilityHint("Membuka percakapan AI tentang hasil analisis")
        }
        .padding(.horizontal, 20)
        .padding(.top, RTDSpacing.md)
        .padding(.bottom, RTDSpacing.sm)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func heroBadge(_ title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.92), in: Capsule())
            .overlay {
                Capsule().stroke(.white.opacity(0.24), lineWidth: 1)
            }
    }

    private func statusColor(_ status: PlantAnalysisStatus) -> Color {
        switch status {
        case .queued, .uploading, .analyzing:
            RTDColor.warningOrange
        case .completed:
            RTDColor.safeGreen
        case .failed:
            RTDColor.warningRed
        case .reported:
            RTDColor.infoBlue
        }
    }
}

private struct AskAIButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RTDColor.softGreen,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(RTDColor.leafGreen.opacity(0.34), lineWidth: 1)
            }
            .shadow(
                color: RTDColor.deepGreen.opacity(configuration.isPressed ? 0.04 : 0.09),
                radius: configuration.isPressed ? 3 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}
