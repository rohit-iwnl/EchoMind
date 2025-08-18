import Foundation
import Speech
import SwiftUI

@Observable
final class SpokenWordTranscriber: Sendable {
    private var inputSequence: AsyncStream<AnalyzerInput>?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recognizerTask: Task<(), Error>?
    
    static let magenta = Color(red: 0.54, green: 0.02, blue: 0.6).opacity(0.8) // #e81cff
    
    // The format of the audio.
    var analyzerFormat: AVAudioFormat?
    
    var converter = BufferConverter()
    var downloadProgress: Progress?
    
    var meeting: Binding<Meeting>
    
    var volatileTranscript: AttributedString = ""
    var finalizedTranscript: AttributedString = ""
    
    static let locale = Locale(components: .init(languageCode: .english, script: nil, languageRegion: .unitedStates))
    
    init(meeting: Binding<Meeting>) {
        self.meeting = meeting
    }
    
    func setUpTranscriber() async throws {
        // Check for available locale
        guard let supportedLocale = await getSupportedLocale() else {
            print("No speech recognition locales are available")
            throw TranscriptionError.localeNotSupported
        }
        
        print("Using locale for speech recognition: \(supportedLocale.identifier(.bcp47))")
        
        transcriber = SpeechTranscriber(locale: supportedLocale,
                                        transcriptionOptions: [],
                                        reportingOptions: [.volatileResults],
                                        attributeOptions: [.audioTimeRange])

        guard let transcriber else {
            throw TranscriptionError.failedToSetupRecognitionStream
        }

        analyzer = SpeechAnalyzer(modules: [transcriber])
        
        do {
            try await ensureModel(transcriber: transcriber, locale: supportedLocale)
        } catch let error as TranscriptionError {
            print("Transcription setup error: \(error.descriptionString)")
            throw error // Re-throw to allow UI to handle
        }
        
        // Get compatible audio format
        self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        
        // Verify we have a valid format, create fallback if needed
        if analyzerFormat == nil {
            print("Warning: No compatible audio format found, using fallback")
            self.analyzerFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)
        }
        
        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        
        guard let inputSequence else { return }
        
        recognizerTask = Task {
            do {
                for try await case let result in transcriber.results {
                    let text = result.text
                    if result.isFinal {
                        finalizedTranscript += text
                        volatileTranscript = ""
                        updateMeetingWithText(withFinal: text)
                    } else {
                        volatileTranscript = text
                        volatileTranscript.foregroundColor = .purple.opacity(0.75)
                    }
                }
            } catch {
                print("Speech recognition failed: \(error)")
            }
        }
        
        try await analyzer?.start(inputSequence: inputSequence)
    }
    
    // Get a supported and allocated locale for speech recognition
    private func getSupportedLocale() async -> Locale? {
        do {
            let supportedLocales = await SpeechTranscriber.supportedLocales
            let installedLocales = await SpeechTranscriber.installedLocales
            let allocatedLocales = await AssetInventory.allocatedLocales
            
            print("=== Speech Recognition Locale Debug ===")
            print("Supported locales: \(supportedLocales.map { $0.identifier(.bcp47) })")
            print("Installed locales: \(installedLocales.map { $0.identifier(.bcp47) })")
            print("Allocated locales: \(allocatedLocales.map { $0.identifier(.bcp47) })")
            print("Current device locale: \(Locale.current.identifier(.bcp47))")
            
            // If no supported locales at all, this might be a simulator/permission issue
            if supportedLocales.isEmpty {
                print("⚠️ No supported locales found - this might be a simulator issue")
                print("Attempting to use fallback approach...")
                
                // Try to create a basic English locale and see if it works
                let fallbackLocale = Locale(identifier: "en_US")
                print("Trying fallback locale: \(fallbackLocale.identifier(.bcp47))")
                return fallbackLocale
            }
            
            // Find locales that are supported, installed, AND allocated
            let availableLocales = supportedLocales.filter { locale in
                let localeId = locale.identifier(.bcp47)
                let isInstalled = installedLocales.contains { $0.identifier(.bcp47) == localeId }
                let isAllocated = allocatedLocales.contains { $0.identifier(.bcp47) == localeId }
                return isInstalled && isAllocated
            }
            
            print("Available (installed + allocated) locales: \(availableLocales.map { $0.identifier(.bcp47) })")
            
            // If no locales are installed/allocated, try just supported ones
            if availableLocales.isEmpty {
                print("⚠️ No installed+allocated locales, checking just supported ones...")
                
                // Try current locale if supported
                if let currentMatch = supportedLocales.first(where: { $0.identifier(.bcp47) == Locale.current.identifier(.bcp47) }) {
                    print("Using current locale (supported but not allocated): \(currentMatch.identifier(.bcp47))")
                    return currentMatch
                }
                
                // Try English variants
                let englishLocales = supportedLocales.filter { locale in
                    locale.language.languageCode?.identifier == "en"
                }
                
                if let englishLocale = englishLocales.first {
                    print("Using English locale (supported but not allocated): \(englishLocale.identifier(.bcp47))")
                    return englishLocale
                }
                
                // Use first supported locale
                if let firstSupported = supportedLocales.first {
                    print("Using first supported locale: \(firstSupported.identifier(.bcp47))")
                    return firstSupported
                }
            } else {
                // Try current locale first from available
                if let currentMatch = availableLocales.first(where: { $0.identifier(.bcp47) == Locale.current.identifier(.bcp47) }) {
                    return currentMatch
                }
                
                // Try English variants from available
                let englishLocales = availableLocales.filter { locale in
                    locale.language.languageCode?.identifier == "en"
                }
                
                if let englishLocale = englishLocales.first {
                    return englishLocale
                }
                
                // Return first available locale
                return availableLocales.first
            }
            
            print("❌ No usable locales found")
            return nil
        } catch {
            print("❌ Error checking speech locales: \(error)")
            return nil
        }
    }
    
    func updateMeetingWithText(withFinal str: AttributedString) {
        if meeting.rawTranscript.wrappedValue != nil {
            meeting.rawTranscript.wrappedValue!.append(str)
        } else {
            meeting.rawTranscript.wrappedValue = str
        }
    }
    
    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let inputBuilder, let analyzerFormat else {
            print("Warning: Missing inputBuilder or analyzerFormat")
            return // Don't throw, just skip this buffer
        }
        
        // Verify buffer compatibility
        guard buffer.format.sampleRate > 0 && buffer.frameLength > 0 else {
            print("Warning: Invalid audio buffer - sampleRate: \(buffer.format.sampleRate), frameLength: \(buffer.frameLength)")
            return
        }
        
        do {
            let converted = try self.converter.convertBuffer(buffer, to: analyzerFormat)
            let input = AnalyzerInput(buffer: converted)
            inputBuilder.yield(input)
        } catch {
            print("Audio conversion error: \(error)")
            // Don't throw, continue with next buffer
        }
    }
    
    public func finishTranscribing() async throws {
        inputBuilder?.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        recognizerTask?.cancel()
        recognizerTask = nil
    }
}

extension SpokenWordTranscriber {
    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }
        
        // Check if already installed and allocated
        let isInstalled = await installed(locale: locale)
        let isAllocated = await allocated(locale: locale)
        
        if isInstalled && isAllocated {
            print("Speech model for \(locale.identifier(.bcp47)) is ready")
            return
        }
        
        print("Speech model for \(locale.identifier(.bcp47)) needs installation/allocation")
        try await downloadIfNeeded(for: transcriber)
    }
    
    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }
    
    func allocated(locale: Locale) async -> Bool {
        let allocated = await AssetInventory.allocatedLocales
        return allocated.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            print("Starting speech model download...")
            self.downloadProgress = downloader.progress
            try await downloader.downloadAndInstall()
            print("Speech model download completed")
        } else {
            print("No download needed for speech model")
        }
    }
    
    /// Get locales that can be downloaded
    func getAvailableLocalesForDownload() async -> [Locale] {
        let supported = await SpeechTranscriber.supportedLocales
        let installed = await Set(SpeechTranscriber.installedLocales)
        
        return supported.filter { locale in
            !installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
        }
    }
    
    /// Manually download a specific locale
    func downloadLocale(_ locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }
        
        let tempTranscriber = SpeechTranscriber(locale: locale,
                                               transcriptionOptions: [],
                                               reportingOptions: [],
                                               attributeOptions: [])
        
        try await downloadIfNeeded(for: tempTranscriber)
    }
    
    func deallocate() async {
        let allocated = await AssetInventory.allocatedLocales
        for locale in allocated {
            await AssetInventory.deallocate(locale: locale)
        }
    }
}
