//
//  Manager.swift
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

/// Used to represent whether a task was successful or encountered an error.
///
/// - success: The task and all operations were successful resulting of the provided associated value.
///
/// - failure: The task encountered an error resulting in a failure. The associated values are the original data
///            provided by the task as well as the error that caused the failure.
public enum Result<Value> {
    case success(Value)
    case failure(WLError)
}

/// `WLError` is the error type returned by WLM3U.
///
/// - parametersInvalid:     Returned when specified parameters are invalid.
/// - urlDuplicate:          Returned when attach a task that is already in progress.
/// - handleCacheFailed:     Returned when local cache has someting wrong.
/// - downloadFailed:        Returned when download requests encounter an error.
/// - logicError:            Returned when internal logic encounters an error.
/// - m3uFileContentInvalid: Returned when `m3u` file's content is invalid.
public enum WLError: Error {
    case parametersInvalid
    case urlDuplicate
    case handleCacheFailed(Error)
    case downloadFailed(Error?)
    case logicError
    case m3uFileContentInvalid
}

extension WLError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .parametersInvalid:
            return "参数错误，请检查传入的参数。"
        case .urlDuplicate:
            return "URL 已存在，当前正在处理中。"
        case .handleCacheFailed(_):
            return "操作缓存失败，请检查本地缓存是否正确。"
        case .logicError:
            return "逻辑错误"
        case .m3uFileContentInvalid:
            return "m3u 文件内容错误，请检查文件内容格式和数据是否正确。"
        default:
            return "未知错误"
        }
    }
}

/// A notification that will be sent when the progress of the task changes.
public let TaskProgressNotification: Notification.Name =
    Notification.Name(rawValue: "WLTaskProgressNotification")

/// A notification that will be sent when the progress of getting file size changes.
public let TaskGetFileSizeProgressNotification: Notification.Name =
    Notification.Name(rawValue: "WLTaskGetFileSizeProgressNotification")

/// A notification that will be sent when size of all files has got.
public let TaskGetFileSizeCompletionNotification: Notification.Name =
    Notification.Name(rawValue: "WLTaskGetFileSizeCompletionNotification")

/// A notification that will be sent when the task ends.
public let TaskCompletionNotification: Notification.Name =
    Notification.Name(rawValue: "WLTaskCompletionNotification")

/// A notification that will be sent when a task has an error.
public let TaskErrorNotification: Notification.Name =
    Notification.Name(rawValue: "WLTaskErrorNotification")

/// A closure that will be called when determine the URL of the slice file from a given String and URL.
/// This will be called multiple times.
/// String: A ts file path from the m3u file content.
/// URL: The relative URL.
/// URL?: URL of the slice file. Retuen `nil` if it is not a ts file.
public typealias TsURLHandler = (String, URL) -> URL?

/// A closure executed once a attach task has completed.
/// Result<Model>: A Result instance of the attach task. The `Model` value is an object parsed from m3u file.
public typealias AttachCompletion = (Result<Model>) -> ()

/// A closure executed when monitoring download progress of a request.
/// Progress: An object that represents the progress of the entire download task.
/// Int: The downloaded file size in this time.
public typealias DownloadProgress = (Progress, Int) -> ()

/// A closure executed once a download task has completed.
/// Result<URL>: A Result instance of the download task. The `URL` value is the path to the folder where all the
/// sliced ​​video files are located
public typealias DownloadCompletion = (Result<URL>) -> ()

/// A closure executed once a combine task has completed.
/// Result<URL>: A Result instance of the download task. The `URL` value is the path where the final video file is
/// located.
public typealias CombineCompletion = (Result<URL>) -> ()

/// Responsible for creating and managing `Workflow` objects.
open class Manager {
    
    /// A default instance of `Manager`, used by top-level `WLM3U` methods.
    public static let `default` = Manager()
    
    /// The directory where all task files are located. Any videos, caches and related files are stored here.
    /// Default is `../Documents/WLM3u/`
    var workSpace: URL = {
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let downloadDir = documentDir + "/WLM3U"
        return URL(fileURLWithPath: downloadDir)
    }()
    
    private var workflows = [Workflow]()
    
    /// Creates a `Workflow` to retrieve the contents of the specified `url`, `size`, `calculateSize` and `completion`.
    ///
    /// - Parameters:
    ///   - url:        A URL of m3u file.
    ///   - size:       The total size of the downloaded file, the default is `0`.
    ///   - tsURL:      A closure that will be called when determine the URL of the slice file from a given String and URL.
    ///   - completion: The attach task completion callback.
    /// - Returns: A `Workflow` instance.
    /// - Throws: A `WLError` instance.
    @discardableResult
    public func attach(url: URL,
                       size: Int = 0,
                       tsURL: TsURLHandler? = nil,
                       completion: AttachCompletion? = nil) throws -> Workflow {
            
            if url.isFileURL || !workSpace.isFileURL {
                NotificationCenter.default.post(name: TaskErrorNotification,
                                                object: nil,
                                                userInfo: ["error": WLError.parametersInvalid])
                throw WLError.parametersInvalid
            }
            
            if workflows.contains(where: { $0.url == url }) {
                NotificationCenter.default.post(name: TaskErrorNotification,
                                                object: nil,
                                                userInfo: ["url": url, "error": WLError.urlDuplicate])
                throw WLError.urlDuplicate
            }
            
            let workflow = Workflow(url: url, workSpace: workSpace, size: size)
            workflow.delegate = self
            workflows.append(workflow)
            workflow.attach(tsURL: tsURL, completion: completion)
            return workflow
    }
    
    /// Cancels the task which url is equal to the specified url.
    ///
    /// - Parameter url: The url of the task you want to cancel.
    public func cancel(url: URL) {
        if url.isFileURL { return }
        guard let index = workflows.firstIndex(where: { $0.url == url }) else { return }
        workflows[index].cancel()
        workflows.remove(at: index)
    }
    
    /// Get whether a task is in progress.
    ///
    /// - Parameter url: The url of the task.
    /// - Returns: Whether the task of the specified url is in progress.
    public func isRunning(for url: URL) -> Bool {
        if url.isFileURL { return false }
        return workflows.contains { $0.url == url }
    }
    
    /// A folder to hold all relevant data. You can remove all cache associated with this m3u by deleting this folder.
    ///
    /// - Parameter url: The raw URL of the m3u file.
    /// - Returns: Directory url of the folder.
    public func folder(for url: URL) -> URL? {
        if url.isFileURL { return nil }
        let name: String = url.deletingPathExtension().lastPathComponent
        let folder = workSpace.appendingPathComponent(name)
        return folder
    }
}

extension Manager: WorkflowDelegate {
    
    func workflow(didFinish workflow: Workflow) {
        workflows.removeAll { $0.url == workflow.url }
    }
}
