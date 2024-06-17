//
//  ContentView.swift
//  OpalTapes
//
//  Created by Ali Hammoud on 3/9/24.
//

import SwiftUI
import SwiftData
import AVKit

struct MainView: View {
    //private var viewData = OpalViewData.viewData
    @StateObject private var audioPlayerData = DataManager.data
    @State private var artist: String?
    @State private var playbackStatus: Bool = false
    @State private var showVinyls: Bool = false
    @State private var selectedVinyl: Bool = false
    @State private var firstLoaded: Bool = false
    @State private var firstLoadedVinyls: Bool = false
    @State private var vinyl: Vinyl? = nil
    @State private var vinylKey: String?

    
    var body: some View {
        GeometryReader { geo in
            let global = geo.frame(in: .global)
            ZStack {
                VStack(spacing: 40) {
                    // Player View
                    ViewSlices(geo: geo)
                    if firstLoadedVinyls {
                        Button {
                            self.showVinyls = true
                        } label: {
                            Image(systemName:  "record.circle.fill")
                                .scaleEffect(CGSize(width: 2, height: 2))
                                .foregroundStyle(.white)
                                .padding()
                                .opacity(self.firstLoaded ? 1 : 0)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 1).delay(1.5)) {
                                        self.firstLoaded = true
                                    }
                                }
                        }
                    }
                }
                .position(x: global.midX, y: global.midY*0.8)
                .onAppear {
                    audioPlayerData.playerReady = {
                        // Handle some local UI updates if the player is ready
                        withAnimation(.easeInOut(duration: 1).delay(0.8)) {
                            self.firstLoadedVinyls = true
                        }
                        print("Ready to play")

                    }
                    //let _ = viewData.chooseVinyl(geo: geo, mod: showVinylDetails)
                }
                // #MARK: Vinyls View / Info
                .sheet(isPresented: $showVinyls, onDismiss: { self.showVinyls = false }) {
                    if !selectedVinyl {
                        ViewSlices(geo: geo).chooseVinyl(geo: geo, mod: showVinylDetails)
                    } else {
                        ViewSlices(geo: geo).viewVinyl(dismiss: {
                            self.showVinyls = false ;
                            self.selectedVinyl = false
                        }, vinyl: self.vinyl, self.vinylKey)
                            .transition(.move(edge: .trailing))
                    }
                }
                
                
            } // ZStack Closure
        } // Geometry View Closure
        .background {
            // #MARK: Background Image
            Image(uiImage: audioPlayerData.vinyl.albumArt)
                .resizable()
                .blur(radius: 80)
                .ignoresSafeArea()
                .saturation(self.firstLoaded ? 0.6 : 0.2)
                .scaledToFill()
        }
    }
    
    func showVinylDetails(_ vinyl: String?) {
        if let vinyl = vinyl {
            print(vinyl)
            self.vinyl = self.audioPlayerData.setupVinyl(vinyl)
            self.vinylKey = vinyl
        }
        
        
        self.selectedVinyl = true
    }
    
    //@Environment(\.modelContext) private var modelContext
    //@Query private var items: [Item]
}

// #MARK: View Slices Struct

struct ViewSlices: View {
    
    var data = DataManager.data
    // temporary way to see vinyl information
    @State var vinylRecords = [
        "Vinyl-1" : "cover-1",
        "Vinyl-2" : "cover-2",
        "Vinyl-3" : "cover-3",
        "Vinyl-4" : "cover-4",
        "Vinyl-5" : "cover-5",
        "Vinyl-6" : "cover-6",
        "Vinyl-7" : "cover-7",
        "Vinyl-8" : "cover-8",
        "Vinyl-Relax-1" : "relax-cover-1",
        "Vinyl-Relax-2" : "relax-cover-2",
        "Vinyl-Relax-3" : "relax-cover-3"
    ]
    @State var geo: GeometryProxy
    @State var firstLoaded: Bool = false
    @State var didTap: Bool = false
    @State var songLoadState: Bool = false
    @State var viewAlbum: Bool = false
    @State var willRandomize: Bool = false
    
    init(geo: GeometryProxy) {
        self.geo = geo
    }
    
    var body: some View {
        //let height = geo.frame(in: .global).height
        let size = geo.size
        
        // #MARK: Track Info
        // this shows the album art as well as the title and artist
        trackInfo
            .scaleEffect(CGSize(width: 0.8, height: 0.8))
            .padding(EdgeInsets(top: CGFloat(60), leading: .zero, bottom: .zero, trailing: .zero))
            .frame(height: size.height/1.5)
            .sheet(isPresented: $viewAlbum, onDismiss: { self.viewAlbum = false }, content: {
                viewVinyl(dismiss: {}, vinyl: self.data.vinyl)
            })
        
        if firstLoaded {
            // #MARK: Bar / Controls
            songBar
                .padding()
            trackControls
                .scaleEffect(CGSize(width: 2, height: 2))
                .padding()
        }

    }
    
    
    // #MARK: Song Info View
    // ===================================================
    var trackInfo: some View {
        
        let geo = geo.size
        
        return VStack{
            ZStack {
                // Album Art View
                Image(uiImage: self.data.vinyl.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(data.songLoaded ? .offset(y: -20).animation(.easeInOut(duration: 2)) : .offset())
                    .saturation(self.songLoadState ? 1 : 0.2)
                    .scaleEffect(didTap ? 0.95 : 1, anchor: .center)
                    .onLongPressGesture(
                        minimumDuration: 0.8,
                        maximumDistance: 100,
                        perform: {
                            print("Show \(self.data.vinyl.vinylName)'s Info")
                            self.viewAlbum = true
                        },
                        onPressingChanged: { value in
                            withAnimation(.bouncy) {
                                self.didTap = value
                            }
                            return
                        }
                    )

                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .colorMultiply(.clear)
                            .onChange(of: data.songLoaded) {
                                if data.songLoaded && !firstLoaded {
                                    withAnimation {
                                        firstLoaded = true
                                    }
                                }
                                withAnimation(.easeInOut(duration: 1)) {
                                    self.songLoadState = data.songLoaded
                                }
                            }
                    }
                /*
                if data.songLoaded {
                    withAnimation(.easeInOut) {
                        Image(uiImage: self.data.vinyl.vinylCover)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity.combined(with: .scale))
                            .colorMultiply(Color(hue: 0.7, saturation: 0.3, brightness: 2, opacity: 100))
                            
                    }
                } */
            }
                //.padding(EdgeInsets(top: .zero, leading: .zero, bottom: 40, trailing: .zero))
            
            // Artist Name & Song Title
            if firstLoaded {
                Text(data.track.title ?? "")
                    .frame(minWidth: geo.width, alignment: .leading)
                    .foregroundStyle(.white)
                    .font(.largeTitle)
                    .offset(y: 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                Text(data.track.artist ?? "")
                    .foregroundStyle(.white)
                    .frame(minWidth: geo.width, alignment: .leading)
                    .font(.title2)
                    .offset(y: 60)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    // ===================================================
    
    // #MARK: Seek View
    // ===================================================
    var songBar: some View {
        return LazyVStack(alignment: .center, spacing: 10) {
            ProgressView(value: data.player?.currentTime().seconds.rounded(), total: data.track.duration?.rounded() ?? 0)
                .progressViewStyle(.linear)
                .gesture(DragGesture()
                    .onEnded { drag in
                        print(drag.startLocation.x)
                        print(drag.location.x)
                    }
                )
                .tint(.white)
                .scaleEffect(CGSize(width: 0.9, height: 2))
                
            LazyHStack(alignment: .center, spacing: geo.size.width.scaled(by: 0.7)) {
                var format : DateComponentsFormatter {
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.minute, .second]
                    formatter.unitsStyle = .positional
                    formatter.zeroFormattingBehavior = [.pad]
                    return formatter
                }
                if let currentTime = data.currentTime?.seconds {
                    Text(format.string(from: TimeInterval(currentTime)) ?? "0:00")
                        .tint(.white)
                        .font(Font.footnote)
                        
                }
                if !self.data.track.duration!.isNaN {
                    if let duration = data.track.duration {
                        Text(format.string(from: TimeInterval(duration))!)
                            .tint(.white)
                            .font(Font.footnote)
                    }
                } else {
                    Text(format.string(from: TimeInterval(Double.zero))!)
                        .tint(.white)
                        .font(Font.footnote)
                }
                
                
                    
            }
        }.transition(.opacity.animation(.easeInOut(duration: 1).delay(0.3)))
    }
    // ===================================================
    
    // #MARK: Controls View
    // ===================================================
    var trackControls: some View {
        let controls = ["play.fill", "pause.fill", "repeat", "repeat.1" , "infinity", "heart", "heart.fill"]
        return VStack(spacing: 20) {
                HStack(spacing: 100) {
                // play/pause
                Button {
                    self.data.setPlayback(())
                } label: {
                    Image(systemName: self.data.isPlaying ? controls[1] : controls[0])
                        .foregroundStyle(self.data.isPlaying ? .gray : .white)
                }
                // favorite
                Button {
                    self.favoriteSong()
                } label: {
                    ZStack {
                        if self.data.isFavorited {
                            Image(systemName: controls[5])
                                .shadow(radius: 2)
                                .transition(favAnimation())
                                .foregroundStyle(.pink)
                        }
                        Image(systemName: self.data.isFavorited ? controls[6] : controls[5])
                            .foregroundStyle(self.data.isFavorited ? .pink : .white)
                    }
                }
            }
            // repeat
            HStack(spacing: 60) {
                Button {
                    self.data.isRepeating.toggle()
                } label : {
                    ZStack {
                        Image(systemName: self.data.isRepeating ? controls[3] : controls[2])
                            .foregroundStyle(.white)
                            .shadow(color: self.data.isRepeating ? .white : .clear, radius: self.data.isRepeating ? 4 : 0)
                    }
                }
                // randomizer, picks song in the current album
                Button {
                    self.willRandomize.toggle()
                } label : {
                    Image(systemName: controls[4])
                        .foregroundStyle(.white)
                        .shadow(color: willRandomize ? .white : .clear, radius: willRandomize ? 4 : 0)
                }
            }
        }.transition(.opacity.animation(.easeInOut(duration: 1).delay(0.6)))
    }
    // ===================================================
    
    // #MARK: Vinyl Selection
    func chooseVinyl(geo: GeometryProxy, mod: (@escaping (String?) -> Void)) -> some View {
        return ZStack {
            // grid of all available albums (TBD)
            ScrollView() {
                LazyVGrid(columns: [GridItem(.fixed(geo.size.width/2)), GridItem(.fixed(geo.size.width/2))], content: {
                    ForEach(self.vinylRecords.keys.sorted(), id: \.self) { key in
                        if let image = UIImage(named: self.vinylRecords[key]!) {
                            Button {
                                print("Selected: \(key)")
                                mod(key)
                               
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(maxWidth: geo.size.width/2, maxHeight: geo.size.width/2)
                                   
                            }
                        }
                    }
                })
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.automatic)
        }
        .onAppear {
        }
    }
    
    // #MARK: View Album
    
    func viewVinyl(dismiss: (() -> Void)?, vinyl: Vinyl!, _ key: String? = nil) -> some View {
        return ZStack {
            VStack{
                withAnimation {
                    Image(uiImage: vinyl.vinylCover)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .transition(.opacity.combined(with: .scale))
                        .colorMultiply(Color(hue: 0.7, saturation: 0.3, brightness: 2, opacity: 100))
                        .scaleEffect(0.8, anchor: .center)
                }
                
                ForEach(vinyl.albumList, id: \.self) { song in
                    Button {
                        print(song)
                        if self.data.vinyl.song != song {
                            self.data.vinyl.song = song
                            if vinyl.vinylName != self.data.vinyl.vinylName {
                                if let key = key {
                                    self.data.selectedVinyl = self.data.VinylRecords[key]
                                    self.data.setupVinyl()
                                }
                            }
                            self.data.nextSong()
                        }
                        
                        if let dismiss = dismiss {
                            dismiss()
                        }
                        
                    } label: {
                        Text(song)
                            .foregroundStyle(.white)
                            .font(.title2)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // #MARK: Control Methods
    func favoriteSong() {
        self.data.isFavorited.toggle()
    }
    
    // #MARK: Animations
    func favAnimation() -> AnyTransition {
        .scale(scale: CGFloat(1.2)).combined(with: .offset(y: -10)).combined(with: .opacity)
    }
    
}

#Preview {
    MainView()
        //.modelContainer(for: Item.self, inMemory: true)
}
