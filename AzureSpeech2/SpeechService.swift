// SpeechService.swift

import Foundation
import SwiftUI
import AVFoundation
import Speech
import MicrosoftCognitiveServicesSpeech // 导入Azure语音服务的框架

class SpeechService: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    // 用于存储和更新视图的属性
    @Published var languages = [Language]()
    @Published var audioFileURL: URL?
    @Published var transcribedText = ""
    
    // 用于调用Azure语音服务的属性
    let speechConfig: SPXSpeechConfiguration
    let audioConfig: SPXAudioConfiguration
    let speechRecognizer: SPXSpeechRecognizer
    
    // 用于选择和播放语音文件的属性
    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
    let audioEngine = AVAudioEngine()
    
    override init() {
        // 初始化Azure语音服务的配置
        speechConfig = try! SPXSpeechConfiguration(subscription: "YourSubscriptionKey", region: "YourRegion")
        audioConfig = SPXAudioConfiguration()
        speechRecognizer = try! SPXSpeechRecognizer(speechConfiguration: speechConfig, audioConfiguration: audioConfig)
        
        super.init()
        
        // 设置语音服务的回调函数
        speechRecognizer.addRecognizingEventHandler { recognizer, event in
            print("Recognizing: \(event.result.text ?? "")")
            self.transcribedText = event.result.text ?? ""
        }
        
        speechRecognizer.addRecognizedEventHandler { recognizer, event in
            print("Recognized: \(event.result.text ?? "")")
            self.transcribedText = event.result.text ?? ""
        }
        
        speechRecognizer.addCanceledEventHandler { recognizer, event in
            print("Canceled: \(event.errorDetails ?? "")")
        }
        
        // 获取支持的语言列表
        getSupportedLanguages()
        
        // 设置文档选择器的代理
        documentPicker.delegate = self
        
    }
    
    // 获取支持的语言列表的函数
    func getSupportedLanguages() {
        let endpoint = "https://\(speechConfig.region).api.cognitive.microsoft.com/sts/v1.0/issuetoken"
        let headers = ["Ocp-Apim-Subscription-Key": speechConfig.subscriptionKey!] // 强制解包订阅密钥
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let token = String(data: data, encoding: .utf8)!
                print("Token: \(token)")
                
                let endpoint = "https://\(self.speechConfig.region).tts.speech.microsoft.com/cognitiveservices/voices/list"
                let headers = ["Authorization": "Bearer \(token)"]
                
                var request = URLRequest(url: URL(string: endpoint)!)
                request.httpMethod = "GET"
                request.allHTTPHeaderFields = headers
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data {
                        let languagesData = try! JSONDecoder().decode([Language].self, from: data)
                        print("Languages: \(languagesData)")
                        DispatchQueue.main.async {
                            self.languages = languagesData
                        }
                    }
                }.resume()
            }
        }.resume()
    }
    
    // 识别语音文件的函数
    func recognizeSpeech(from url: URL, languageCode: String) { // 修改参数名为languageCode，以避免与Language类型混淆
        do {
            // 设置语音服务的语言参数
            speechConfig.speechRecognitionLanguage = languageCode

            // 创建一个新的语音识别器对象，使用语音文件作为输入源
            let audioInput = try SPXAudioInputStream.init(url: url) // 使用SPXAudioInputStream而不是SPXAudioStreamInput
            let audioConfig = SPXAudioConfiguration(streamInput: audioInput)
            let speechRecognizer = try SPXSpeechRecognizer(speechConfiguration: speechConfig, audioConfiguration: audioConfig)
            
            // 开始识别语音文件，并等待结果返回
            speechRecognizer.recognizeOnce { result, error in
                guard error == nil else {
                    print("Error recognizing speech: \(error!.localizedDescription)")
                    return
                }
                
                guard result != nil else {
                    print("No result from speech recognition")
                    return
                }
                
                print("Recognition result: \(result!.text ?? "")")
                DispatchQueue.main.async {
                    self.transcribedText = result!.text ?? ""
                }
            }
            
        } catch {
            print("Error creating speech recognizer: \(error.localizedDescription)")
        }
    }
    
    // 选择语音文件的函数
    func selectAudioFile() {
        // 弹出文档选择器，让用户选择一个语音文件
        if let window = UIApplication.shared.windows.first {
            window.rootViewController?.present(documentPicker, animated: true, completion: nil)
        }
    }
}

// 实现文档选择器的代理协议
extension SpeechService: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // 获取用户选择的语音文件的URL，并保存到属性中
        guard let url = urls.first else { return }
        print("Selected file: \(url)")
        self.audioFileURL = url
        
        // 调用语音服务识别语音文件
        recognizeSpeech(from: url, languageCode: language.code) // 使用languageCode参数而不是language属性
    }
}
