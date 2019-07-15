//
//  WLM3U.swift
//  WLM3U
//
//  Created by Willie on 2019/7/6.
//  Copyright © 2019 Willie. All rights reserved.
//

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
///   - completion: The attach task completion callback.
/// - Returns: A `Workflow` instance.
@discardableResult
public func attach(url: URL, completion: AttachCompletion? = nil) throws -> Workflow {
    return try Manager.default.attach(url: url, completion: completion)
}

/// Cancels the task which url is equal to the specified url using the default `Manager`.
///
/// - Parameter url: The url of the task you want to cancel.
public func cancel(url: URL) {
    Manager.default.cancel(url: url)
}

/// A folder to hold all relevant data using the default `Manager`. You can remove all cache associated with this m3u by
/// deleting this folder.
///
/// - Parameter url: The raw URL of the m3u file.
/// - Returns: Directory url of the folder.
public func folder(for url: URL) -> URL? {
    return Manager.default.folder(for: url)
}
