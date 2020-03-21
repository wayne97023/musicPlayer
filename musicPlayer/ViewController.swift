//
//  ViewController.swift
//  musicPlayer
//
//  Created by 林奇杰 on 2020/3/21.
//  Copyright © 2020 林奇杰. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {

   
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var albumImage: UIImageView!
    
    var songArray:[album]! = [album]()
    var playIndex = 0
    let player = AVQueuePlayer()
    var looper: AVPlayerLooper?
    
    var currentSongObj:album?
    
    @IBOutlet weak var controlButton: UIButton!
    
    let playIcon = UIImage(systemName: "play.fill")
    let pauseIcon = UIImage(systemName: "pause.fill")
    
    //  表單載入
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 定義音量UI
        let volumeView = MPVolumeView(frame: CGRect(x: 90, y: 543, width: 230, height: 40))
        volumeView.tintColor = UIColor(red:255 ,green:255 , blue:255 , alpha:1.0)
        volumeView.showsRouteButton = false
        view.addSubview(volumeView)
        
        //  音樂資料庫
        songArray.append(album(albumName:"終於了解自由",albumImage:"周興哲-怎麼了-ICON",songName:"周興哲-怎麼了"))
        songArray.append(album(albumName:"終於了解自由",albumImage:"周興哲-怎麼了-ICON",songName:"周興哲-終於了解自由"))
        songArray.append(album(albumName:"終於了解自由",albumImage:"周興哲-怎麼了-ICON",songName:"周興哲-Nobody But Me"))
        songArray.append(album(albumName:"終於了解自由",albumImage:"周興哲-怎麼了-ICON",songName:"周興哲-Old Days"))
        songArray.append(album(albumName:"終於了解自由",albumImage:"周興哲-怎麼了-ICON",songName:"周興哲-至少我還記得"))
        songArray.append(album(albumName:"小時候的我們",albumImage:"周興哲-小時候的我們-ICON",songName:"周興哲-小時候的我們"))
        songArray.append(album(albumName:"以後別做朋友",albumImage:"周興哲-以後別做朋友-ICON",songName:"周興哲-以後別做朋友"))
        songArray.append(album(albumName:"你好不好?",albumImage:"周興哲-你好不好-ICON",songName:"周興哲-你好不好"))
        songArray.append(album(albumName:"你好不好?",albumImage:"周興哲-你好不好-ICON",songName:"周興哲-This is love"))
        songArray.append(album(albumName:"如果雨之後",albumImage:"周興哲-如果雨之後-ICON",songName:"周興哲-如果雨之後"))
        songArray.shuffle()
        
        //  設定背景&鎖定播放
        setupRemoteTransportControls()
        
        //  播放音樂
        playSong()
        
        //  播完後，繼續播下一首
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { (_) in
            self.playIndex = self.playIndex + 1
            self.playSong()
            //  移除監聽
            self.player.removeTimeObserver(self.timeObserver)

        }
    }
    
    /*
     將 AVAudioSession 設為 playback
     為了讓 App 能在背景繼續播放，在螢幕鎖定 & silent mode 都能繼續播放音樂陪著我們，我們必須修改 AppDelegate 的 function application(_:didFinishLaunchingWithOptions:)，在 App 一啟動時將 AVAudioSession 設為 playback 的類別。
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       try? AVAudioSession.sharedInstance().setCategory(.playback)
       return true
    }
    */
    
    //  播放音樂
    func playSong(){
        if playIndex < songArray.count{
            if playIndex < 0{
                playIndex = songArray.count - 1
            }
            let albumObj = songArray[playIndex]
            currentSongObj = albumObj
            if albumObj != nil {
                let albumName:String = albumObj.albumName
                let songName:String = albumObj.songName
                let imageName:String = albumObj.albumImage
                
                //  設定Label顯示
                self.songName.text = songName
                self.albumName.text = albumName
                
                //  設定Image圖片顯示
                albumImage.image = UIImage(named: imageName)
                
                //  載入歌曲檔案，取得在手機APP中實際位置
                let fileUrl = Bundle.main.url(forResource: songName, withExtension: "mp4")!
                let playerItem = AVPlayerItem(url: fileUrl)
                player.replaceCurrentItem(with: playerItem)
                player.volume = 0.5
                looper = AVPlayerLooper(player: player, templateItem: playerItem)
                
                //  重置slider和播放軌道
                playbackSlider.setValue(Float(0), animated: true)
                let targetTime:CMTime = CMTimeMake(value: Int64(0), timescale: 1)
                player.seek(to: targetTime)
                
                //  播放
                player.play()
                
                //  更新slider時間value
                let duration : CMTime = playerItem.asset.duration
                let seconds : Float64 = CMTimeGetSeconds(duration)
                playbackSlider.minimumValue = 0
                playbackSlider.maximumValue = Float(seconds)

                //  事件監聽：進度條
                addProgressObserver(playerItem:playerItem)
                
                //  設定播放按鈕圖案
                controlButton.setImage(pauseIcon, for: UIControl.State.normal)
                
                // 設定背景當前播放資訊
                setupNowPlaying()
            }
        }else{
            playIndex = 0
        }
    }
    
    //  播放/暫停
    @IBAction func playButton(_ sender: UIButton) {
        let imageName = controlButton.imageView?.image
        if imageName == playIcon{
            if player.rate == 0{
                player.play()
                controlButton.setImage(pauseIcon, for: UIControl.State.normal)
            }
        }else if imageName == pauseIcon{
            if player.rate == 1{
                player.pause()
                controlButton.setImage(playIcon, for: UIControl.State.normal)
            }
        }
    }
    
    //  事件監聽：進度條
    var timeObserver: Any!
    func addProgressObserver(playerItem:AVPlayerItem){
        //  每秒執行一次
        timeObserver =  player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: Int64(1.0), timescale: Int32(1.0)), queue: DispatchQueue.main) { [weak self](time: CMTime) in
            //  已跑秒數
            let currentTime = CMTimeGetSeconds(time)
            //  歌曲秒數
            let totalTime = CMTimeGetSeconds(playerItem.duration)
            //  更新進度條
            print("正在播放",currentTime , "/" , "全部時間" , totalTime)
            self?.playbackSlider.setValue(Float(currentTime), animated: true)
        }
    }
    
    //  播放下一首
    @IBAction func nextButton(_ sender: UIButton) {
        playIndex = playIndex + 1
        playSong()
    }
    
    //  播放上一首
    @IBAction func backButton(_ sender: UIButton) {
        playIndex = playIndex - 1
        playSong()
    }
    
    //  設定背景&鎖定播放
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0.0 {
                self.player.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    //  設定背景播放的歌曲資訊
    func setupNowPlaying() {
        // Define Now Playing Info
        let songName:String = (self.currentSongObj?.songName)!
        let albumName:String = (self.currentSongObj?.albumName)!
        let albumImage:String = (self.currentSongObj?.albumImage)!
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = songName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName

        if let image = UIImage(named: albumImage) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.asset.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    //  拖曳slider進度，要設定player播放軌道
    @IBAction func playbackChangSlider(_ sender: UISlider) {
        //  slider移動的位置
        let seconds : Int64 = Int64(playbackSlider.value)
        //  計算秒數
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        //  設定player播放進度
        player.seek(to: targetTime)
        
        //  如果player暫停，則繼續播放
        if player.rate == 0{
            player.play()
            controlButton.setImage(pauseIcon, for: UIControl.State.normal)
        }
    }
}

