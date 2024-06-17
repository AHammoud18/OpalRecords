//
//  OpalEntity.swift
//  OpalTapes
//
//  Created by Ali Hammoud on 3/9/24.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

// Create skeleton of data setup for app (classes, structs, etc.)


protocol NetworkRequest {
    func performRequest()
}

protocol AudioPlayerSetup {
    func initalizePlayer(url: URL)
}

protocol AudioData {
    func getMetadata(player: AVPlayer?) async
    func setPlayback(_: ())
    func favoriteSong()
    func loadSong() async
    func nextSong()
    func prevSong()
    func repeatSong()
}

struct Track {
    var artist: String?
    var album: String?
    var title: String?
    var art: UIImage?
    var duration: Double?
    
    init(artist: String = "", album: String = "", title: String = "", art: UIImage? = nil, duration: Double? = Double.zero) {
        self.artist = artist
        self.album = album
        self.title = title
        self.art = art
        self.duration = duration
    }
}


struct Vinyl {
    var vinylName: String
    var albumArt: UIImage
    var vinylCover: UIImage
    var song: String
    var albumList: [String]
    
    init(vinylName: String, albumArt: UIImage, vinylCover: UIImage, song: String, albumList: [String]) {
        self.vinylName = vinylName
        self.albumArt = albumArt
        self.vinylCover = vinylCover
        self.song = song
        self.albumList = albumList
    }
    
}

struct VinylDetails: Decodable {
    var name: String
    var art: String
    var vinyl_art: String
    var vinyl_song_list: [String]
}
