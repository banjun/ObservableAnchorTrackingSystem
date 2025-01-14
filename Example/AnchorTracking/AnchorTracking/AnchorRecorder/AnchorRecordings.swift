import Foundation
import Observation

@MainActor @Observable final class AnchorRecordings {
    private let folder: URL
    private(set) var list: [AnchorSession] = []
    
    init(folder: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!) {
        self.folder = folder
        reload()
    }
    
    func reload() {
        list = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).compactMap { url in
            guard url.lastPathComponent.hasSuffix(".json") == true else { return nil }
            return try? JSONDecoder().decode(AnchorSession.self, from: Data(contentsOf: url))
        })?.sorted {$0.start > $1.start} ?? []
    }
}
