import Foundation

@MainActor
public protocol FloatingVideoControlling: AnyObject {
    var canFloatVideo: Bool { get }
    var isVideoFloating: Bool { get }
    var isVideoPlaying: Bool { get }
    var videoPlayback: FloatingVideoPlayback { get }
    @discardableResult func toggleFloatingVideo() async -> Bool
    func returnVideoToTab()
    func closeFloatingVideo()
    func toggleVideoPlayback() async
    func seekVideo(to seconds: Double) async
    func setVideoVolume(_ level: Double) async
    func toggleVideoMute() async
}

public extension FloatingVideoControlling {
    var canFloatVideo: Bool { false }
    var isVideoFloating: Bool { false }
    var isVideoPlaying: Bool { false }
    var videoPlayback: FloatingVideoPlayback { FloatingVideoPlayback() }
    func toggleFloatingVideo() async -> Bool { false }
    func returnVideoToTab() {}
    func closeFloatingVideo() {}
    func toggleVideoPlayback() async {}
    func seekVideo(to seconds: Double) async {}
    func setVideoVolume(_ level: Double) async {}
    func toggleVideoMute() async {}
}
