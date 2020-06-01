//
//  Workflow.swift
//
//  Copyright (c) 2019 Willie <willie.wangwei@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import Alamofire

protocol WorkflowDelegate: AnyObject {
    func workflow(didFinish workflow: Workflow)
}

/// A class responsible for a single m3u task.
open class Workflow {
    
    /// Raw url.
    public let url: URL
    /// A model class for saving data parsed from a m3u file.
    public var model: Model = Model()
    /// An delegate that is usually the default `Manager`.
    weak var delegate: WorkflowDelegate?
    
    // Global
    
    private weak var fileManager = FileManager.default
    private var waitingFiles = [URL]()
    private let workSpace: URL
    private var workflowDir: URL?
    private var tsDir: URL?
    
    private let operationQueue: OperationQueue  = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .utility
        return operationQueue
    }()
    
    private let dispatchQueue = DispatchQueue(label: "com.willie.WLM3UManager")
    
    // Attach
    private var tsURLHandler: TsURLHandler?
    
    // Download
    
    private var downloadTimer: Timer?
    private var preCompletedCount: Int = 0
    private var currentRequest: DownloadRequest?
    private var progressDic = [URL: Progress]()
    private var downloadProgress: DownloadProgress?
    private var downloadCompletion: DownloadCompletion?
    
    // Combine
    
    private var combineCompletion: CombineCompletion?
    
    init(url: URL, workSpace: URL, size: Int = 0) {
        self.url = url
        self.workSpace = workSpace
        model.totalSize = size
    }
    
    /// Cancels all tasks holding by the `Workflow`.
    public func cancel() {
        destroyTimer()
        currentRequest?.cancel()
        progressDic.removeAll()
        waitingFiles.removeAll()
        tsURLHandler = nil
        currentRequest = nil
        downloadProgress = nil
        downloadCompletion = nil
        combineCompletion = nil
    }
}

// MARK: - Attach

extension Workflow {
    
    /// Creates a `Workflow` to retrieve the contents of the specified `url` and `completion`.
    ///
    /// - Parameters:
    ///   - url:        A URL of m3u file.
    ///   - tsURL:      A closure that will be called when determine the URL of the slice file from a given String and URL.
    ///   - completion: The attach task completion callback.
    /// - Returns: A `Workflow` instance.
    @discardableResult
    
    func attach(tsURL: TsURLHandler? = nil, completion: AttachCompletion?) -> Self {
        tsURLHandler = tsURL
        operationQueue.isSuspended = true
        
        // e.g. http://qq.com/123/hls/FromSoftware.m3u
        
        let m3uName: String = url.deletingPathExtension().lastPathComponent // FromSoftware
        workflowDir = workSpace.appendingPathComponent(m3uName) // ../workSpace/FromSoftware
        let cacheURL = workflowDir!.appendingPathComponent("m3uObj")
        
        if fileManager!.fileExists(atPath: cacheURL.path) {
            
            do {
                let data = try Data(contentsOf: cacheURL)
                model = try JSONDecoder().decode(Model.self, from: data)
            } catch {
                handleCompletion(of: "attach", completion: completion, result: .failure(.handleCacheFailed(error)))
                return self
            }
            
            tsDir = workflowDir!.appendingPathComponent("ts") // ../workSpace/FromSoftware/ts
            
            DispatchQueue.main.async {
                self.handleCompletion(of: "attach", completion: completion, result: .success(self.model))
            }
            
            return self
        }
        
        model.url = url
        
        let uri: URL = url.deletingLastPathComponent() // http://qq.com/123/hls/
        model.uri = uri
        model.name = m3uName
        
        var isDir: ObjCBool = false
        let exists: Bool = fileManager!.fileExists(atPath: workflowDir!.path, isDirectory: &isDir)
        if !isDir.boolValue || !exists {
            do {
                try fileManager!.createDirectory(at: workflowDir!,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
                try url.absoluteString.write(to: workflowDir!.appendingPathComponent("URL"),
                                             atomically: true,
                                             encoding: .utf8)
            } catch {
                operationQueue.cancelAllOperations()
                handleCompletion(of: "attach", completion: completion, result: .failure(.handleCacheFailed(error)))
                return self
            }
        }
        
        // Download m3u file ...
        let destinationURL = self.workflowDir!.appendingPathComponent("file.m3u8")
        Session.default.download(URLRequest(url: url)) { (_, _) -> (destinationURL: URL, options: DownloadRequest.Options) in
            return (destinationURL, [.removePreviousFile])
        }
        .responseData { (response) in
            if let error = response.error {
                self.handleCompletion(of: "attach",
                                      completion: completion,
                                      result: .failure(.downloadFailed(error)))
                return
            }
            
            self.m3uDownloadDidFinished(at: destinationURL, completion: completion)
        }
        
        return self
    }
    
    private func m3uDownloadDidFinished(at url: URL, completion: AttachCompletion?) {
        
        guard let workflowDir = workflowDir else {
            handleCompletion(of: "attach", completion: completion, result: .failure(.logicError))
            return
        }
        
        do {
            try parseM3u(file: url)
            let data = try JSONEncoder().encode(model)
            let cacheURL = workflowDir.appendingPathComponent("m3uObj") // ../workSpace/FromSoftware/m3uObj
            if fileManager!.fileExists(atPath: cacheURL.path) {
                try fileManager!.removeItem(at: cacheURL)
            }
            tsDir = workflowDir.appendingPathComponent("ts") // ../workSpace/FromSoftware/ts
            try data.write(to: cacheURL)
            try fileManager!.createDirectory(at: tsDir!,
                                             withIntermediateDirectories: true,
                                             attributes: nil)
            handleCompletion(of: "attach", completion: completion, result: .success(model))
        } catch {
            handleCompletion(of: "attach", completion: completion, result: .failure(error as! WLError))
            return
        }
    }
    
    private func parseM3u(file: URL) throws {
        guard let uri = model.uri else { throw WLError.m3uFileContentInvalid }
        let m3uStr = try String(contentsOf: file)
        let arr = m3uStr.components(separatedBy: "\n")
        if let handler = tsURLHandler {
            model.tsArr = arr.compactMap { handler($0, uri) }
        } else {
            model.tsArr = arr
                .filter { $0.hasSuffix(".ts") }
                .map { uri.appendingPathComponent($0) }
        }
        if model.tsArr?.isEmpty ?? true { throw WLError.m3uFileContentInvalid }
        if model.totalSize == 0 {
            calculateSize(with: model.tsArr!)
        }
    }
    
    private func calculateSize(with tsArr: [URL]) {
        var remain = tsArr.count
        var totalSize: Int = 0
        for url in tsArr {
            getFileSize(url: url) { (size, error) in
                remain -= 1
                let progress = Progress(totalUnitCount: Int64(tsArr.count))
                progress.completedUnitCount = Int64(tsArr.count - remain)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: TaskGetFileSizeProgressNotification,
                                                    object: self,
                                                    userInfo: ["task": "attach",
                                                               "url": self.url,
                                                               "value": progress])
                }
                totalSize += size
                if remain == 0 {
                    self.model.totalSize = totalSize
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: TaskGetFileSizeCompletionNotification,
                                                        object: self,
                                                        userInfo: ["task": "attach",
                                                                   "url": self.url,
                                                                   "value": totalSize])
                    }
                }
            }
        }
    }
    
    private func getFileSize(url: URL, completion: @escaping (Int, Error?) -> Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(0, error)
            } else {
                guard
                    let resp = response as? HTTPURLResponse,
                    let length = resp.allHeaderFields["Content-Length"] as? String,
                    let size = Int(length)
                    else {
                        completion(0, nil)
                        return
                }
                completion(size, nil)
            }
            }.resume()
    }
}

// MARK: - Download

extension Workflow {
    
    /// Begin a download task.
    ///
    /// - Parameters:
    ///   - progress:   Download progress callback, called once per second.
    ///   - completion: Download completion callback.
    /// - Returns: A reference to self.
    @discardableResult
    public func download(progress: DownloadProgress? = nil, completion: DownloadCompletion? = nil) -> Self {
        downloadProgress = progress
        downloadCompletion = completion
        operationQueue.addOperation {
            self.operationQueue.isSuspended = true
            guard let tsArr = self.model.tsArr else {
                self.handleCompletion(of: "download", completion: completion, result: .failure(.logicError))
                return
            }
            self.waitingFiles = tsArr
            self.downloadNextFile()
            self.createTimer()
        }
        return self
    }
    
    private func downloadNextFile() {
        
        let fullURL = waitingFiles.removeFirst() // http://qq.com/123/hls/ts/200.ts
        let fileName = fullURL.lastPathComponent // 200.ts
        let fileLocalURL = tsDir!.appendingPathComponent(fileName)
        
        // Check if file is exsist.
        
        if fileManager!.fileExists(atPath: fileLocalURL.path) {
            
            do {
                let size = try fileManager!.attributesOfItem(atPath: fileLocalURL.path)[FileAttributeKey.size] as! Int64
                let progress = Progress(totalUnitCount: size)
                progress.completedUnitCount = size
                preCompletedCount += Int(size)
                progressDic[fullURL] = progress
                
                if self.waitingFiles.count > 0 {
                    downloadNextFile()
                } else {
                    allDownloadsDidFinished()
                }
                
                return
                
            } catch {
                handleCompletion(of: "download",
                                 completion: downloadCompletion,
                                 result: .failure(.handleCacheFailed(error)))
                return
            }
        }
        
        let req = URLRequest(url: fullURL)
        let destination: DownloadRequest.Destination =
        {(_, _) -> (destinationURL: URL, options: DownloadRequest.Options) in
            return (fileLocalURL, [.removePreviousFile])
        }
        
        let request = Session
            .default
            .download(req, to: destination)
            .downloadProgress { (progress) in
                self.progressDic[fullURL] = progress
        }
        
        request.response(completionHandler: { (response) in
            
            if let error = response.error as NSError? {
                if error.code == -999 { return } // cancelled
                self.currentRequest = nil
                self.waitingFiles.insert(fullURL, at: 0)
                self.downloadNextFile()
                return
            }
            
            if self.waitingFiles.count > 0 {
                self.downloadNextFile()
            } else {
                self.allDownloadsDidFinished()
            }
        })
        
        currentRequest = request
    }
    
    private func createTimer() {
        DispatchQueue.main.async {
            self.downloadTimer = Timer.scheduledTimer(timeInterval: 1,
                                                      target: self,
                                                      selector: #selector(self.timerFire),
                                                      userInfo: nil,
                                                      repeats: true)
            RunLoop.current.add(self.downloadTimer!, forMode: RunLoop.Mode.common)
        }
    }
    
    private func destroyTimer() {
        downloadTimer?.invalidate()
        downloadTimer = nil
    }
    
    @objc private func timerFire() {
        
        guard let totalSize = model.totalSize, totalSize > 0 else { return }
        let progress = Progress(totalUnitCount: Int64(totalSize))
        for pro in progressDic.values {
            progress.completedUnitCount += pro.completedUnitCount
        }
        
        let completedCount = Int(progress.completedUnitCount) - preCompletedCount
        if completedCount < 0 { return }
        preCompletedCount = Int(progress.completedUnitCount)
        downloadProgress?(progress, completedCount)
        NotificationCenter.default.post(name: TaskProgressNotification,
                                        object: self,
                                        userInfo: ["url": url, "progress": progress, "completedCount": completedCount])
    }
    
    private func allDownloadsDidFinished() {
        timerFire()
        destroyTimer()
        
        let fileLocalUrl = workflowDir!.appendingPathComponent("file.m3u8")
        var m3uStr = try! String(contentsOf: fileLocalUrl)
        let arr = m3uStr.components(separatedBy: "\n")
        var lineArr = [String]()
        for str in arr {
            if str.hasSuffix(".ts"), let url = URL(string: str) {
                lineArr.append("ts/\(url.lastPathComponent)")
            } else {
                lineArr.append(str)
            }
        }
        m3uStr = lineArr.joined(separator: "\n")
        try! fileManager!.removeItem(at: fileLocalUrl)
        try! m3uStr.write(to: fileLocalUrl, atomically: true, encoding: .utf8)
        
        handleCompletion(of: "download", completion: downloadCompletion, result: .success(tsDir!))
    }
}

// MARK: - Combine

extension Workflow {
    
    /// Begin a combine task.
    ///
    /// - Parameters:
    ///   - completion: combine completion callback.
    /// - Returns: A reference to self.
    @discardableResult
    public func combine(completion: CombineCompletion? = nil) -> Self {
        combineCompletion = completion
        operationQueue.addOperation {
            self.doCombine()
        }
        return self
    }
    
    private func doCombine() {
        
        guard
            let name = model.name,
            let tsArr = model.tsArr,
            let tsDir = tsDir,
            let workflowDir = workflowDir else {
                handleCompletion(of: "combine", completion: combineCompletion, result: .failure(WLError.logicError))
                return
        }
        
        let combineFilePath = workflowDir.appendingPathComponent(name).appendingPathExtension("ts")
        fileManager!.createFile(atPath: combineFilePath.path, contents: nil, attributes: nil)
        let tsFilePaths = tsArr.map { tsDir.path + "/" + $0.lastPathComponent }
        
        dispatchQueue.async {
            
            let fileHandle = FileHandle(forUpdatingAtPath: combineFilePath.path)
            defer { fileHandle?.closeFile() }
            for tsFilePath in tsFilePaths {
                if self.fileManager?.fileExists(atPath: tsFilePath) ?? false {
                    let data = try! Data(contentsOf: URL(fileURLWithPath: tsFilePath))
                    fileHandle?.write(data)
                }
            }
            
            do {
                try self.fileManager!.removeItem(at: self.tsDir!)
                let cacheURL = self.workflowDir!.appendingPathComponent("m3uObj")
                try self.fileManager!.removeItem(at: cacheURL)
            } catch {
                DispatchQueue.main.async {
                    self.handleCompletion(of: "combine",
                                          completion: self.combineCompletion,
                                          result: .failure(.handleCacheFailed(error)))
                }
            }
            
            DispatchQueue.main.async {
                self.handleCompletion(of: "combine",
                                      completion: self.combineCompletion,
                                      result: .success(combineFilePath))
            }
        }
    }
}

// MARK: - Helper

private extension Workflow {
    
    func handleCompletion<T>(of task: String, completion: ((Result<T>) -> ())?, result: Result<T>) {
        
        completion?(result)
        
        switch result {
        case .failure(let error):
            operationQueue.cancelAllOperations()
            destroyTimer()
            NotificationCenter.default.post(name: TaskErrorNotification,
                                            object: nil,
                                            userInfo: ["task": task, "url": url, "error": error])
        case .success(let value):
            operationQueue.isSuspended = false
            NotificationCenter.default.post(name: TaskCompletionNotification,
                                            object: self,
                                            userInfo: ["task": task, "url": self.url, "value": value])
        }
        
        if operationQueue.operationCount == 0 {
            delegate?.workflow(didFinish: self)
        }
    }
}
