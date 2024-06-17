//
//  OpalInteractor.swift
//  OpalTapes
//
//  Created by Ali Hammoud on 3/9/24.
//
// Request Logic of the player

import Foundation


class FetchTrack: NetworkRequest, ObservableObject {

    var urlResponse: URL?
    
    var data: Data?
    
    var networkFetchDone: (() -> Void)?
    
    var audioPlayer = AudioPlayer()
    
    let url = URL(string: "https://8ryrb4e4he.execute-api.us-east-1.amazonaws.com/***")!
    
    //#MARK: Network Request Method
    func performRequest() {
        
        var methodURL: URLRequest {
            var url = url.appending(path: DataManager.data.vinyl.vinylName)
            url.append(queryItems: [URLQueryItem(name: "song", value: DataManager.data.vinyl.song)])
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("***", forHTTPHeaderField: "x-api-key")
            
            return request
        }

        
        let task = URLSession.shared.dataTask(with: methodURL) { data, response, error in
            DispatchQueue.global().asyncAndWait {
                if let error = error {
                    assertionFailure("Error fetching URL: \(error)")
                }
                guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    assertionFailure("Response Failure: \(String(describing: response))")
                    return
                }
                
                if let data = data {
                    // String response of the temp-signed media file in s3 bucket (URL has percent format)
                    let stringData = String(data: data, encoding: .utf8)!.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    
                    self.urlResponse = URL(string: stringData)
                    self.networkFetchDone?()
                    DispatchQueue.global().sync {
                        self.setupAudioPlayer()
                    }
                    //audioPlayer.initalizePlayer(url: url!)
                }
            }
        }
        
        task.resume()

    }
    func setupAudioPlayer(){
        audioPlayer.initalizePlayer(url: self.urlResponse!)
    }
}

