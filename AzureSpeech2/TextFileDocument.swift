// TextFileDocument.swift
import MicrosoftCognitiveServicesSpeech
import Foundation
import UniformTypeIdentifiers

// 定义一个文本文件的类，用于保存转化结果
struct TextFileDocument: FileDocument {
    // 定义文本文件的内容类型
    static var readableContentTypes: [UTType] { [.plainText] }
    
    // 定义文本文件的内容属性
    var text: String
    
    // 初始化文本文件的函数
    init(text: String) {
        self.text = text
    }
    
    // 从文件中读取文本的函数
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    // 将文本写入文件的函数
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
