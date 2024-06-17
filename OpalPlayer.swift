//
//  OpalPlayer.swift
//  OpalTapes
//
//  Created by Ali Hammoud on 6/16/24.
//
// Player and Player Data

import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import SwiftUI


//#MARK: AudioPlayer Class
class AudioPlayer: ObservableObject, AudioPlayerSetup{
    
    var audioData = DataManager.data
    var songDidLoad = false
    
    
    //#MARK: Setup Audio Player With First Network Request
    func initalizePlayer(url: URL) {
        guard let _ = audioData.player else {
            
            Task {
                // Launch Audio Session On App Launch
                let session = AVAudioSession()
                guard let _ = try? session.setActive(true) else {
                    print("Error starting audio session")
                    return
                }
                let song = AVPlayerItem(url: url)
                await MainActor.run {
                    audioData.player = AVPlayer(playerItem: song)
                }
                
                ///Two Methods to setup the next song? *Look into AVQueuePlayer*
                
                //player.replaceCurrentItem(with: )
                //AVQueuePlayer(playerItem: )
                
                // setup audio session to play in the background
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    await UIApplication.shared.beginReceivingRemoteControlEvents()
                } catch {
                    print(error.localizedDescription)
                }
                
                
                // Observer to handle song interruptions
                NotificationCenter.default.addObserver(self,
                        selector: #selector(songInterrupted),
                        name: AVAudioSession.interruptionNotification,
                        object: AVAudioSession.sharedInstance())
                
                
                audioData.playerReady?()
                await audioData.loadSong()
                
                
                
                // If observer needs to be removed
                
                /*
                 if let timeObserver = timeObserver {
                 player?.removeTimeObserver(timeObserver)
                 self.timeObserver = nil
                 }
                 */
            }
            return
        }
        Task {
            let song = AVPlayerItem(url: url)
            audioData.player?.replaceCurrentItem(with: song)
            await audioData.loadSong()
        }
    }
    
    @objc func songInterrupted() {
        //#MARK: When the song has been interrupted by another source
        audioData.isPlaying = false
        audioData.player?.pause()
    }
}

class DataManager: ObservableObject, AudioData {
    
    static let data = DataManager()
    @Published public var track = Track()
    @Published public var vinyl = Vinyl(vinylName: "Cafe-de-Touhou-1", albumArt: UIImage(named: "cover-1")!, vinylCover: UIImage(named: "default-vinyl")!, song: "1-もし、空が晴れるなら.mp3", albumList: [""]) // first song of vinyl 1
    
    @Published var selectedVinyl: VinylDetails?
    @Published var player: AVPlayer?
    @Published var songLoaded: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isRepeating: Bool = false
    @Published var isFavorited: Bool = false
    @Published var currentTime: CMTime? = CMTime.zero
    
    
    var timeObserver: Any? = nil
    private let commandCenter = MPRemoteCommandCenter.shared()
    let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    var playerReady: (() -> Void)?
    
    public var VinylRecords: [String:VinylDetails] {
        var jsonData: [String:VinylDetails]?
        if let filePath = Bundle.main.path(forResource: "Vinyls", ofType: "json") {
            do {
                let url = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                jsonData = try decoder.decode([String: VinylDetails].self, from: data)
            } catch {
                print(error.localizedDescription)
            }
        }
        return jsonData!
    }
    
    func setupVinyl(_ vinyl: String? = nil) -> Vinyl? {
        if let name = vinyl {
            if let selection = self.VinylRecords[name] {
                
                return Vinyl(vinylName: selection.name,
                             albumArt: UIImage(named: selection.art)!,
                             vinylCover: UIImage(named: selection.vinyl_art)!,
                             song: selection.vinyl_song_list.first!,
                             albumList: selection.vinyl_song_list)
            }
        } else {
            if let name = selectedVinyl?.name,
               let art = UIImage(named: selectedVinyl!.art),
               let vinylCover = UIImage(named: selectedVinyl!.vinyl_art),
               let song = selectedVinyl?.vinyl_song_list.first,
               let songList = selectedVinyl?.vinyl_song_list
            {
                self.vinyl = Vinyl(vinylName: name, albumArt: art, vinylCover: vinylCover, song: song, albumList: songList)
            }
        }
        return nil
    }
    
    func loadSong() async {
        await MainActor.run {
            self.songLoaded = false
        }
        // Remove observer if there is one and setup a new one
        if let timeObserver = timeObserver {
            self.player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        await getMetadata(player: self.player)

    }
    
    func getMetadata(player: AVPlayer?) async {
        //#MARK: Fetch Metadata info from track
        var backgroundInfo = [String : Any]()
        
            do {
                
                if let playerItem = player?.currentItem {
                    /// .load() runs asynchronously, MainActor to apply UI updates on main thread
                    let metadata = try await playerItem.asset.load(.metadata)
                    for item in metadata {
                        switch item.commonKey {
                            // title
                        case .commonKeyTitle:
                            if let value = try await item.load(.stringValue) {
                                backgroundInfo[MPMediaItemPropertyTitle] = value
                                await MainActor.run {
                                    self.track.title = value
                                }
                            }
                            // artist
                        case .commonKeyArtist:
                            if let value = try await item.load(.stringValue) {
                                backgroundInfo[MPMediaItemPropertyArtist] = value
                                await MainActor.run {
                                    self.track.artist = value
                                }
                            }
                            // album name
                        case .commonKeyAlbumName:
                            if let value = try await item.load(.stringValue) {
                                backgroundInfo[MPMediaItemPropertyAlbumTitle] = value
                                await MainActor.run {
                                    self.track.album = value
                                }
                            }
                            
                           // album art
                        case .commonKeyArtwork:
                            if let value = try await item.load(.dataValue) {
                                let artwork = UIImage(data: value)
                                backgroundInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork!.size) { size in return artwork! }
                                await MainActor.run {
                                    self.track.art = artwork
                                }
                            }
                            
                        default:
                            continue
                        }
                    }
                }
            }
            catch {
                assertionFailure(error.localizedDescription)
            }
        
        // Configure Background Tasks, attatch metadata to NowPlaying class
        await setupBackgroundTasks(command: commandCenter.togglePlayPauseCommand)
        
        // vinyl album art setup for info center
        backgroundInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: self.vinyl.albumArt.size) { size in
            return self.vinyl.albumArt
        }
        
        backgroundInfo[MPMediaItemPropertyPlaybackDuration] = self.track.duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = backgroundInfo
        
        await MainActor.run {
            self.songLoaded = true
        }
    }
    
    // #MARK: Backgorund Tasks / Playback Methods
    
    func setupBackgroundTasks(command: MPRemoteCommand) async {
        
        timeObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time
            
        }
        
        //#MARK: Setup Observer For Player
        NotificationCenter.default.addObserver(self,
                selector: #selector(songDidComplete),
                name: AVPlayerItem.didPlayToEndTimeNotification,
                object: self.player?.currentItem)

        if let duration = self.player?.currentItem!.duration.seconds {
            await MainActor.run {
                self.track.duration = duration
            }
        }
        
        command.addTarget { [unowned self] _ in
            setPlayback(())
            return .success
        }
    }
    
    func vinylJSON() -> [String:VinylDetails]? {
        if let filePath = Bundle.main.path(forResource: "Vinyls", ofType: "json") {
            do {
                let url = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode([String: VinylDetails].self, from: data)
                return jsonData
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    
    // Observer Methods
    
    @objc func songDidComplete() {
        //#MARK: Logic Handled Here When Song Ends
        if self.isRepeating {
            self.repeatSong()
        } else {
            self.nextSong()
        }
        print("songCompleted")
    }
    
    
    func setPlayback(_: ()) {
        self.isPlaying ? self.player?.pause() : self.player?.play()
        self.isPlaying.toggle()
    }
    
    func favoriteSong() {
        //
    }
    
    func prevSong() {
        //
    }
    
    func nextSong() {
        //
        setPlayback(())
        let requestNext = FetchTrack()
        requestNext.performRequest()
    }
    
    func repeatSong() {
        setPlayback(())
        if let timeObserver = timeObserver {
            self.player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        self.player?.seek(to: CMTime.zero)
        timeObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let duration = self?.player?.currentItem!.duration, time <= duration else {
                self?.currentTime = CMTime.zero
                return
            }
            self?.currentTime = time
        }
        setPlayback(())
    }
    
}
