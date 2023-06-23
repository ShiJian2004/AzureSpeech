// ContentView.swift
import MicrosoftCognitiveServicesSpeech
import SwiftUI
import AVFoundation

struct ContentView: View {
    // 用于存储和更新视图的状态
    @StateObject var speechService = SpeechService()
    @State var selectedLanguage = Language(name: "English", code: "en-US")
    @State var selectedSource = "Microphone"
    @State var showSaveDialog = false
    
    // 用于控制录音和播放的对象
    let audioRecorder = AudioRecorder()
    let audioPlayer = AVPlayer()
    
    var body: some View {
        VStack {
            // 选择语言的下拉菜单
            Menu {
                ForEach(speechService.languages, id: \.self) { language in
                    Button(language.name) {
                        selectedLanguage = language
                    }
                }
            } label: {
                Text("Language: \(selectedLanguage.name)")
                    .font(.title)
                    .padding()
            }
            
            // 选择语音来源的分段控件
            Picker("Source", selection: $selectedSource) {
                Text("Microphone").tag("Microphone")
                Text("File").tag("File")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // 根据不同的语音来源显示不同的控件
            if selectedSource == "Microphone" {
                // 显示录音按钮和进度条
                Button {
                    if audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                        speechService.recognizeSpeech(from: audioRecorder.audioFileURL, language: selectedLanguage.code)
                    } else {
                        audioRecorder.startRecording()
                    }
                } label: {
                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: audioRecorder.recordingDuration, total: 15)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            } else {
                // 显示选择文件按钮和播放按钮
                Button {
                    speechService.selectAudioFile()
                } label: {
                    Image(systemName: "folder")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                }
                
                if let audioFileURL = speechService.audioFileURL {
                    Button {
                        let playerItem = AVPlayerItem(url: audioFileURL)
                        audioPlayer.replaceCurrentItem(with: playerItem)
                        audioPlayer.play()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 显示转化结果的文本编辑器
            TextEditor(text: $speechService.transcribedText)
                .font(.body)
                .padding()
            
            // 显示保存结果的按钮
            Button {
                showSaveDialog = true
            } label: {
                Text("Save")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        // 显示保存结果的对话框
        .fileExporter(isPresented: $showSaveDialog, document: TextFileDocument(text: speechService.transcribedText), contentType: .plainText) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
