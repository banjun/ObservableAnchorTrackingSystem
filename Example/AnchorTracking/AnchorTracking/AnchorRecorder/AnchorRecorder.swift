import Foundation
import RealityKit
import Observation
import ObservableAnchorTrackingSystem

@MainActor @Observable final class AnchorRecorder {
    @ObservationIgnored private let observable: ObservableAnchorTrackingSystem.ObservableValue
    private var session: AnchorSession? {
        didSet { isRecording = session != nil }
    }
    private(set) var isRecording: Bool = false

    init(observable: ObservableAnchorTrackingSystem.ObservableValue) {
        self.observable = observable
    }

    func start() {
        session = .init(start: Date())
        startObserving()
    }

    private func startObserving() {
        guard session != nil else { return }
        withObservationTracking {
            append(transforms: observable.transforms)
        } onChange: {
            Task { @MainActor [weak self] in self?.startObserving() }
        }
    }

    func append(transforms: [AnchoringComponent.Target: Transform], date: Date = .init()) {
        guard let session else { return }
        self.session?.frames.append(.init(time: date.timeIntervalSince(session.start), transforms: .init(transforms)))
    }

    func stop() throws -> (Data, Date) {
        guard let session else { return (Data(), Date()) }
        defer { self.session = nil }
        return (try JSONEncoder().encode(session), session.start)
    }

    func stop(writingToFolder: URL, filename: (Date) -> String = {"AnchorTransforms-\({let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd'T'HHmmss"; return df}().string(from: $0)).json"}) throws {
        let (data, start) = try stop()
        let file = writingToFolder.appendingPathComponent(filename(start))
        try data.write(to: file)
    }
}
