import AVFAudio
import Speech

final class VoiceInputManager {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private(set) var latestTranscript = ""
    private(set) var isRecording = false

    func bestAvailableLocaleIdentifier(preferred localeIdentifier: String) -> String {
        let supported = SFSpeechRecognizer.supportedLocales().map(\.identifier)
        let candidates = [
            localeIdentifier,
            localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            localeIdentifier.replacingOccurrences(of: "-", with: "_"),
            "zh_CN",
            "zh-CN",
            "zh_Hans_CN",
            "en_US",
            "en-US"
        ]

        return candidates.first(where: { supported.contains($0) }) ?? localeIdentifier
    }

    func microphonePermission() -> AVAudioApplication.recordPermission {
        AVAudioApplication.shared.recordPermission
    }

    func speechAuthorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func startRecording(localeIdentifier: String, language: AppLanguage, onUpdate: @escaping (String) -> Void) throws {
        guard !isRecording else { throw CalendarIntentError.recordingAlreadyInProgress }
        guard microphonePermission() == .granted else { throw CalendarIntentError.microphonePermissionDenied }
        guard speechAuthorizationStatus() == .authorized else { throw CalendarIntentError.speechAuthorizationDenied }

        let resolvedIdentifier = bestAvailableLocaleIdentifier(preferred: localeIdentifier)
        let locale = Locale(identifier: resolvedIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer() else {
            throw CalendarIntentError.speechRecognizerUnavailable
        }
        guard recognizer.isAvailable else {
            #if targetEnvironment(simulator)
            throw CalendarIntentError.speechRecognizerTemporarilyUnavailable(language.ui("当前运行在模拟器中，语音识别服务常会不可用。建议优先在真机上测试语音输入。", "Speech recognition is often unavailable in the simulator. Please test voice input on a real device when possible."))
            #else
            throw CalendarIntentError.speechRecognizerTemporarilyUnavailable(language.ui("语音识别服务当前不可用。请检查网络、系统语言包，或稍后再试。", "Speech recognition is currently unavailable. Please check network access, language packs, or try again later."))
            #endif
        }

        self.recognizer = recognizer
        latestTranscript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        recognitionRequest = request

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                self?.latestTranscript = text
                onUpdate(text)
            }

            if error != nil || result?.isFinal == true {
                self?.finishAudioSession()
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() async throws -> String {
        guard isRecording else {
            throw CalendarIntentError.noTranscription
        }

        recognitionRequest?.endAudio()
        finishAudioSession()
        try? await Task.sleep(for: .milliseconds(350))

        let transcript = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            throw CalendarIntentError.noTranscription
        }
        return transcript
    }

    func cancelRecording() {
        latestTranscript = ""
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        finishAudioSession()
    }

    private func finishAudioSession() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore teardown errors so the UI can recover on the next attempt.
        }
    }
}
