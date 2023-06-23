// AudioRecorder.swift

import Foundation
import AVFoundation

class AudioRecorder: NSObject {
    // 用于录音的对象
    var audioRecorder: AVAudioRecorder!
    
    // 用于存储录音文件的URL
    var audioFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.wav")
    }
    
    // 用于判断是否正在录音的属性
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }
    
    // 用于获取录音时长的属性
    var recordingDuration: Double {
        audioRecorder?.currentTime ?? 0
    }
    
    override init() {
        super.init()
        
        // 设置录音的参数
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // 创建录音对象，并设置代理
        audioRecorder = try! AVAudioRecorder(url: audioFileURL, settings: settings)
        audioRecorder.delegate = self
        
        // 准备录音
        audioRecorder.prepareToRecord()
    }
    
    // 开始录音的函数
    func startRecording() {
        // 请求用户授权使用麦克风
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Permission granted")
                
                // 设置音频会话为录音模式，并激活会话
                try! AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
                try! AVAudioSession.sharedInstance().setActive(true)
                
                // 开始录音，并设置最大时长为15秒
                self.audioRecorder.record(forDuration: 15)
                
            } else {
                print("Permission denied")
            }
        }
    }
    
    // 停止录音的函数
    func stopRecording() {
        // 停止录音，并停用音频会话
        audioRecorder.stop()
        try! AVAudioSession.sharedInstance().setActive(false)
    }
}

// 实现录音对象的代理协议
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Finished recording")
        } else {
            print("Recording failed")
        }
    }
}
