import AVFAudio
import EventKit
import Speech

enum PermissionBootstrap {
    static func requestPhaseOnePermissions() async {
        let store = EKEventStore()

        _ = try? await withCheckedThrowingContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        } as Bool

        _ = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        } as Bool

        _ = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        } as SFSpeechRecognizerAuthorizationStatus
    }
}
