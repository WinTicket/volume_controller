import AVFoundation
import MediaPlayer
import UIKit

public class VolumeController {
  private let audioSession: AVAudioSession
  private let volumeView: MPVolumeView = MPVolumeView()
  private var tempMuteVolume: Float?
  private let audioSessionQueue = DispatchQueue(
    label: "com.kurenai7968.volume_controller.audioSession", qos: .userInitiated)

  init(audioSession: AVAudioSession) {
    self.audioSession = audioSession
  }

  public func getVolume() -> Float {
    return audioSession.outputVolume
  }

  public func setVolume(volume: Float, showSystemUI: Bool) {
    let clampedVolume = volume.clamp(to: 0.0...1.0)
    if clampedVolume != 0.0 {
      tempMuteVolume = nil
    }

    if showSystemUI {
      volumeView.frame = CGRect()
      volumeView.showsRouteButton = true
      volumeView.removeFromSuperview()
    } else {
      volumeView.frame = CGRect(x: -1000, y: -1000, width: 1, height: 1)
      volumeView.showsRouteButton = false
      UIApplication.shared.keyWindow?.insertSubview(volumeView, at: 0)
    }

    guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else {
      return
    }

    slider.value = clampedVolume
  }

  public func isMuted() -> Bool {
    return getVolume() == 0
  }

  public func setMute(isMute: Bool, showSystemUI: Bool) {
    if isMute {
      tempMuteVolume = getVolume()
      setVolume(volume: 0, showSystemUI: showSystemUI)
    } else {
      guard let previousVolume = tempMuteVolume else { return }
      setVolume(volume: previousVolume, showSystemUI: showSystemUI)
      tempMuteVolume = nil
    }
  }

  public func activateAudioSession() {
    activateAudioSession { _ in }
  }

  public func activateAudioSession(completion: @escaping (Result<Void, Error>) -> Void) {
    setAudioSessionActive(true, completion: completion)
  }

  public func deactivateAudioSession() {
    deactivateAudioSession { _ in }
  }

  public func deactivateAudioSession(completion: @escaping (Result<Void, Error>) -> Void) {
    setAudioSessionActive(
      false,
      options: .notifyOthersOnDeactivation,
      completion: completion)
  }

  private func setAudioSessionActive(
    _ active: Bool,
    options: AVAudioSession.SetActiveOptions = [],
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    audioSessionQueue.async {
      do {
        try self.audioSession.setActive(active, options: options)
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
  }
}
