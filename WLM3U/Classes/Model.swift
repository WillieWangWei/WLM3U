//
//  Model.swift
//  WLM3U
//
//  Created by Willie on 2019/7/7.
//  Copyright © 2019 Willie. All rights reserved.
//

import Foundation

/// A model class for saving data parsed from a m3u file.
open class Model: Codable {
    
    /// The m3u file's source URL.
    public var url: URL?
    /// Name of m3u file.
    public var name: String?
    /// An array of names of sliced ​​videos parsed from the contents of the file.
    public var tsArr: [String]?
    /// The total size of all sliced ​​videos.
    public var totalSize: Int?
    /// The m3u file's source path.
    public var uri: URL?
}
