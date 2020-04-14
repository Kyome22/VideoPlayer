//
//  ViewController.swift
//  VideoPlayer
//
//  Created by Takuto Nakamura on 2020/04/14.
//  Copyright © 2020 Takuto Nakamura. All rights reserved.
//

import Cocoa
import AVKit

class ViewController: NSViewController {
    
    @IBOutlet weak var playerView: NSView!
    @IBOutlet weak var playStopButton: NSButton!
    @IBOutlet weak var beforeLabel: NSTextField!
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var afterLabel: NSTextField!
    @IBOutlet weak var loadButton: NSButton!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var seconds: Double = 0
    var timeObserver: Any?
    
    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.wantsLayer = true
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if timeObserver != nil {
            player?.removeTimeObserver(timeObserver!)
        }
    }
    
    @IBAction func playStop(_ sender: Any) {
        guard let player = player else { return }
        if isPlaying {
            playStopButton.image = NSImage(named: "play")
            player.pause()
        } else {
            playStopButton.image = NSImage(named: "stop")
            let current = player.currentItem!.currentTime().seconds
            if seconds <= current {
                player.seek(to: CMTime(seconds: 0.0, preferredTimescale: 1000))
            }
            player.play()
        }
    }
    
    @IBAction func changedTime(_ sender: NSSlider) {
        guard let player = player else { return }
        let destination = CMTime(seconds: sender.doubleValue, preferredTimescale: 1000)
        let diff: Double = floor(seconds) - floor(sender.doubleValue)
        let remainder = CMTime(seconds: diff, preferredTimescale: 1000)
        beforeLabel.stringValue = destination.positionalTime
        afterLabel.stringValue = remainder.positionalTime
        player.seek(to: destination, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @IBAction func openLoadSheet(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.message = "MOVまたはMP4ファイルを選択してください。"
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["mov", "mp4"]
        openPanel.beginSheetModal(for: self.view.window!) { [weak self] (response) in
            if response == NSApplication.ModalResponse.OK {
                guard let url = openPanel.url else { return }
                self?.loadButton.isEnabled = false
                self?.loadVideo(url)
            }
        }
    }
    
    func loadVideo(_ url: URL) {
        player = AVPlayer(url: url)
        guard let player = player else { return }
        if !player.currentItem!.asset.isPlayable { return }
        // player.isMuted = true
        let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: nil, using: { [weak self] time in
            self?.updateTimeSlider(time)
        })
        
        let start = player.currentItem!.currentTime()
        let duration = player.currentItem!.asset.duration
        seconds = duration.seconds
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = playerView.bounds
        playerView.layer?.addSublayer(playerLayer!)
        
        beforeLabel.stringValue = start.positionalTime
        afterLabel.stringValue = duration.positionalTime
        timeSlider.doubleValue = 0.0
        timeSlider.minValue = 0.0
        timeSlider.maxValue = Double(seconds)
        timeSlider.isContinuous = true
    }
    
    func updateTimeSlider(_ time: CMTime) {
        let diff: Double = floor(seconds) - floor(time.seconds)
        let remainder = CMTime(seconds: diff, preferredTimescale: 1000)
        timeSlider.doubleValue = time.seconds
        beforeLabel.stringValue = time.positionalTime
        afterLabel.stringValue = remainder.positionalTime
        if seconds <= time.seconds {
            playStopButton.image = NSImage(named: "play")
        }
    }
    
}

extension CMTime {
    var positionalTime: String {
        let floorSeconds: TimeInterval = floor(seconds)
        let hours = Int(floorSeconds / 3600)
        let minute = Int(floorSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let second = Int(floorSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minute, second)
        }
        return String(format: "%02d:%02d", minute, second)
    }
}
