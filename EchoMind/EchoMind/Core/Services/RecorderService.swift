//
//  RecorderService.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import AVFoundation
import Foundation
import SwiftUI

class RecorderService {
  private var outputContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation? = nil
  private let audioEngine: AVAudioEngine
  private let transcriber: SpokenWordTranscriber
  var playerNode: AVAudioPlayerNode?

  var meeting: Binding<Meeting>

  var file: AVAudioFile?
  private let url: URL

  init(transcriber: SpokenWordTranscriber, meeting: Binding<Meeting>) {
    audioEngine = AVAudioEngine()
    self.transcriber = transcriber
    self.meeting = meeting
    self.url = FileManager.default.temporaryDirectory
          .appending(component: UUID().uuidString)
          .appendingPathExtension(for: .wav)
  }

  func startRecording() async throws {
    self.meeting.url.wrappedValue = url

    guard await isAuthorized() else {
      print("Not Authorized")
      return
    }

    try setUpAudioSession()

    try await transcriber.setUpTranscriber()

    for await input in try await audioStream() {
        try await self.transcriber.streamAudioToTranscriber(input)
    }
  }

  func stopRecording() async throws{
    audioEngine.stop()
    meeting.isDone.wrappedValue = true

    try await transcriber.finishTranscribing()

    Task {
        self.meeting.title.wrappedValue = "Meeting \(meeting.timestamp.wrappedValue.formatted(date: .abbreviated, time: .omitted))"
    }
  }

  func pauseRecording() {
    audioEngine.pause()
  }

  func resumeRecording() throws{
    try audioEngine.start()
  }

  #if os(iOS)
    func setUpAudioSession() throws {
      let audioSession = AVAudioSession.sharedInstance()
      
      // Better category options for simulator compatibility
      if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
          // Simulator - use more permissive settings
          try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
      } else {
          // Real device - use optimized settings
          try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
      }
      
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
  #endif

  private func audioStream() async throws -> AsyncStream<AVAudioPCMBuffer> {
        try setupAudioEngine()
        audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 4096,
                                         format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            guard let self else { return }
            writeBufferToDisk(buffer: buffer)
            self.outputContinuation?.yield(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return AsyncStream(AVAudioPCMBuffer.self, bufferingPolicy: .unbounded) {
            continuation in
            outputContinuation = continuation
        }
    }
    
    private func setupAudioEngine() throws {
        // Remove any existing taps first
        audioEngine.inputNode.removeTap(onBus: 0)
        
        let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        
        // Validate input format
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            print("Warning: Invalid input format - sampleRate: \(inputFormat.sampleRate), channels: \(inputFormat.channelCount)")
            throw TranscriptionError.invalidAudioDataType
        }
        
        // Create file settings from input format
        var inputSettings = inputFormat.settings
        
        // Ensure we have valid settings for file writing
        if inputSettings.isEmpty {
            inputSettings = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: inputFormat.sampleRate,
                AVNumberOfChannelsKey: inputFormat.channelCount,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
        }
        
        do {
            self.file = try AVAudioFile(forWriting: url, settings: inputSettings)
            print("Audio file created successfully at: \(url)")
        } catch {
            print("Failed to create audio file: \(error)")
            throw TranscriptionError.audioFilePathNotFound
        }
    }
        
    func playRecording() {
        guard let file else {
            return
        }
        
        playerNode = AVAudioPlayerNode()
        guard let playerNode else {
            return
        }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode,
                            to: audioEngine.outputNode,
                            format: file.processingFormat)
        
        playerNode.scheduleFile(file,
                                at: nil,
                                completionCallbackType: .dataPlayedBack) { _ in
        }
        
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("error")
        }
    }
    
    func stopPlaying() {
        audioEngine.stop()
    }

}
