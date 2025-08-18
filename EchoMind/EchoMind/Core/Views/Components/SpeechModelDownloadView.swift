//
//  SpeechModelDownloadView.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import SwiftUI
import Speech

struct SpeechModelDownloadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var availableLocales: [Locale] = []
    @State private var isLoading = false
    @State private var downloadProgress: Progress?
    @State private var selectedLocale: Locale?
    @State private var isDownloading = false
    @State private var errorMessage: String?
    
    let onCompletion: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                if isLoading {
                    ProgressView("Checking available speech models...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if availableLocales.isEmpty {
                    // No models available
                    emptyStateView
                } else {
                    // Available models list
                    availableModelsSection
                }
                
                Spacer()
                
                // Download button
                if !isLoading && !availableLocales.isEmpty {
                    downloadButton
                }
            }
            .padding()
            .navigationTitle("Speech Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Download Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await loadAvailableLocales()
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.badge.chevron.backward")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            
            VStack(spacing: 6) {
                Text("Download Speech Model")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Speech recognition requires a language model to be downloaded. Choose your preferred language to enable live transcription.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // Check if this is a "no speech support" vs "all downloaded" scenario
            if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
                // Simulator-specific message
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                
                Text("Simulator Limitation")
                    .font(.headline)
                    .fontWeight(.medium)
                
                VStack(spacing: 12) {
                    Text("Speech recognition may have limited functionality in the iOS Simulator.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("For full speech recognition features, please test on a physical device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Continue Without Speech Recognition") {
                    onCompletion()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Dismiss") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            } else {
                // Device - all models downloaded
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                
                Text("All Available Models Downloaded")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("All supported speech recognition models are already installed on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Continue") {
                    onCompletion()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Available Models Section
    @ViewBuilder
    private var availableModelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Languages")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(availableLocales, id: \.identifier) { locale in
                        localeRow(locale)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func localeRow(_ locale: Locale) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier(.bcp47))
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(locale.identifier(.bcp47))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if selectedLocale?.identifier(.bcp47) == locale.identifier(.bcp47) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            } else {
                Circle()
                    .stroke(.secondary, lineWidth: 1)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selectedLocale?.identifier(.bcp47) == locale.identifier(.bcp47) ? .blue.opacity(0.1) : .red.opacity(0.1))
        }
        .onTapGesture {
            selectedLocale = locale
        }
    }
    
    // MARK: - Download Button
    @ViewBuilder
    private var downloadButton: some View {
        VStack(spacing: 12) {
            if let progress = downloadProgress, isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: progress.fractionCompleted)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Downloading... \(Int(progress.fractionCompleted * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            
            Button(action: downloadSelectedModel) {
                HStack {
                    if isDownloading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    
                    Text(isDownloading ? "Downloading..." : "Download Selected Model")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedLocale != nil && !isDownloading ? .blue : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(selectedLocale == nil || isDownloading)
        }
    }
    
    // MARK: - Methods
    
    private func loadAvailableLocales() async {
        isLoading = true
        
        do {
            // First check if Speech Recognition is available at all
            let supportedLocales = await SpeechTranscriber.supportedLocales
            let installedLocales = await SpeechTranscriber.installedLocales
            
            print("=== Speech Model Download Debug ===")
            print("Supported locales: \(supportedLocales.map { $0.identifier(.bcp47) })")
            print("Installed locales: \(installedLocales.map { $0.identifier(.bcp47) })")
            
            await MainActor.run {
                if supportedLocales.isEmpty {
                    print("⚠️ No supported locales - speech recognition not available")
                    // Show empty state but with different message
                    self.availableLocales = []
                } else {
                    // Create a temporary transcriber to check available locales
                    let tempTranscriber = SpokenWordTranscriber(meeting: .constant(Meeting(id: UUID(), title: "", timestamp: Date())))
                    
                    Task {
                        let available = await tempTranscriber.getAvailableLocalesForDownload()
                        
                        await MainActor.run {
                            self.availableLocales = available.sorted { locale1, locale2 in
                                let name1 = locale1.localizedString(forIdentifier: locale1.identifier) ?? locale1.identifier(.bcp47)
                                let name2 = locale2.localizedString(forIdentifier: locale2.identifier) ?? locale2.identifier(.bcp47)
                                return name1 < name2
                            }
                            
                            // Auto-select user's current locale if available
                            if let currentMatch = availableLocales.first(where: { $0.identifier(.bcp47) == Locale.current.identifier(.bcp47) }) {
                                selectedLocale = currentMatch
                            } else if let englishLocale = availableLocales.first(where: { $0.language.languageCode?.identifier == "en" }) {
                                selectedLocale = englishLocale
                            } else {
                                selectedLocale = availableLocales.first
                            }
                        }
                    }
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                print("❌ Error loading speech locales: \(error)")
                self.availableLocales = []
                isLoading = false
            }
        }
    }
    
    private func downloadSelectedModel() {
        guard let locale = selectedLocale else { return }
        
        isDownloading = true
        errorMessage = nil
        
        Task {
            do {
                let tempTranscriber = SpokenWordTranscriber(meeting: .constant(Meeting(id: UUID(), title: "", timestamp: Date())))
                
                // Monitor download progress
                tempTranscriber.downloadProgress = Progress()
                await MainActor.run {
                    downloadProgress = tempTranscriber.downloadProgress
                }
                
                try await tempTranscriber.downloadLocale(locale)
                
                await MainActor.run {
                    isDownloading = false
                    onCompletion()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = "Failed to download speech model: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    SpeechModelDownloadView {
        print("Download completed")
    }
}
