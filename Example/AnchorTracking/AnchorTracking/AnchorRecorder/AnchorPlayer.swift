import Foundation
import RealityKit
import Observation

@MainActor @Observable final class AnchorPlayer {
    private(set) var session: AnchorSession?
    var isPlaying: Bool { session != nil }
    var frame: Int?
    private(set) var frameRange: Range<Int>?
    private(set) var transforms: [AnchoringComponent.Target: Transform] = [:]
    
    func play(_ session: AnchorSession) {
        guard !session.frames.isEmpty else { return }
        self.session = session
        self.frame = 0
        self.frameRange = session.frames.indices
        Task {
            defer {
                self.session = nil
                self.frame = nil
                self.frameRange = nil
            }
            var frame = 0
            while true {
                transforms = .init(session.frames[frame].transforms)
                self.frame = frame
                
                let next = frame + 1
                guard next < session.frames.count else { break }
                let interval: TimeInterval = session.frames[next].time - session.frames[frame].time
                frame = next
                try await Task.sleep(nanoseconds: UInt64(interval * Double(NSEC_PER_SEC)))
            }
        }
    }
}
