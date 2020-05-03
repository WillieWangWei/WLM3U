//
//  WLM3U.swift
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

/// Get or set the work space.
public var workSpace: URL {
    get {
        return Manager.default.workSpace
    }
    set {
        Manager.default.workSpace = newValue
    }
}

/// Creates a `Workflow` using the default `Manager` to retrieve the contents of the specified `url` and `completion`.
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
        return try Manager.default.attach(url: url, size: size, tsURL: tsURL, completion: completion)
}

/// Cancels the task which url is equal to the specified url using the default `Manager`.
///
/// - Parameter url: The url of the task you want to cancel.
public func cancel(url: URL) {
    Manager.default.cancel(url: url)
}

/// Get whether a task is in progress using the default `Manager`.
///
/// - Parameter url: The url of the task.
/// - Returns: Whether the task of the specified url is in progress.
public func isRunning(for url: URL) -> Bool {
    return Manager.default.isRunning(for: url)
}

/// A folder to hold all relevant data using the default `Manager`. You can remove all cache associated with this m3u by
/// deleting this folder. Also, if the content is being downloaded, don't forget to cancel the download first.
///
/// - Parameter url: The raw URL of the m3u file.
/// - Returns: Directory url of the folder.
public func folder(for url: URL) -> URL? {
    return Manager.default.folder(for: url)
}
