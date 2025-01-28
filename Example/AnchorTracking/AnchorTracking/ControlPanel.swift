import SwiftUI
import ObservableAnchorTrackingSystem

struct ControlPanel: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    private static let recordingFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    @State private var recorder: AnchorRecorder = .init(observable: ObservableAnchorTrackingSystem.observable)
    @State private var recordings: AnchorRecordings = .init(folder: recordingFolder)
    @Environment(AnchorPlayer.self) private var player
    @Environment(App.Model.self) private var appModel

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Upper Limb", isOn: .init(get: {appModel.upperLimbVisibility == .visible}, set: {appModel.upperLimbVisibility = $0 ? .visible : .hidden})).toggleStyle(.button)
            Text("\(recordings.list.count) recordings")
            List {
                ForEach(recordings.list, id: \.start) { session in
                    Button { player.play(session) } label: {
                        Text("\(session.start, format: Date.FormatStyle.init(date: .numeric, time: .shortened)), \(session.frames.count) frames in \(session.duration, format: .number.precision(.fractionLength(2)))s")
                    }
                }
            }
            if let frame = player.frame, let frameRange = player.frameRange {
                FrameGauge(frame: frame, frameRange: frameRange)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                    .padding()
            }
        }
        .animation(.spring, value: player.frameRange)
        .padding(40)
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                if !recorder.isRecording {
                    circleButton(systemName: "record.circle") { recorder.start() }.foregroundStyle(.red)
                } else {
                    circleButton(systemName: "stop.circle") {
                        do {
                            try recorder.stop(writingToFolder: Self.recordingFolder)
                        } catch {
                            NSLog("%@", "\(#function) error near recorder.stop(). error = \(String(describing: error))")
                        }
                    }
                    .foregroundStyle(.black)
                }
            }
        }
        .onChange(of: recorder.isRecording) { _, _ in recordings.reload() }
        .task {
            await openImmersiveSpace(id: "i")
        }
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: systemName) .resizable() }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
    }

    struct FrameGauge: View {
        var frame: Int
        var frameRange: Range<Int>
        var body: some View {
            Gauge(value: Float(frame), in: ClosedRange<Float>(uncheckedBounds: (Float(frameRange.lowerBound), Float(frameRange.upperBound))), label: {EmptyView()}, currentValueLabel: {Text("\(frame)")}, minimumValueLabel: { Text("\(frameRange.lowerBound)") }, maximumValueLabel: { Text("\(frameRange.upperBound)") })
                .gaugeStyle(FrameGaugeStyle())
        }
    }

    struct FrameGaugeStyle: GaugeStyle {
        func makeBody(configuration: Configuration) -> some View {
            GeometryReader { g in
                VStack {
                    HStack(alignment: .firstTextBaseline) {
                        configuration.minimumValueLabel
                        Spacer()
                        configuration.currentValueLabel
                        Spacer()
                        configuration.maximumValueLabel
                    }
                    .monospacedDigit()
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous).fill(.background).frame(width: g.size.width, height: 20)
                        Capsule(style: .continuous).fill(.foreground).frame(width: configuration.value * g.size.width, height: 20)
                    }
                }
            }
        }
    }
}
