![](https://repository-images.githubusercontent.com/197013787/4935d600-ae5c-11e9-868c-e5f2338abd1a)

[![language](https://img.shields.io/badge/language-swift-orange.svg)](https://cocoapods.org/pods/WLM3U)
[![Platform](https://img.shields.io/cocoapods/p/WLM3U.svg?style=flat)](https://cocoapods.org/pods/WLM3U)
[![Version](https://img.shields.io/cocoapods/v/WLM3U.svg?style=flat)](https://cocoapods.org/pods/WLM3U)
[![License](https://img.shields.io/cocoapods/l/WLM3U.svg?style=flat)](https://cocoapods.org/pods/WLM3U)

WLM3U is a M3U tool written in Swift.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS   | Swift
----- | -----
10.0 + | 5.1 +

## Installation

### CocoaPods

```ruby
pod 'WLM3U'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/WillieWangWei/WLM3U.git", .upToNextMajor(from: "0.1.5"))
]
```

## Usage

### Parsing M3U files

```Swift
let url = URL(string:"http://xxx.com/yyy.m3u8")! // URL of the M3U file
let size: Int = <#fileSize#>                     // The total size of all ts files

WLM3U
    .attach(url: url,
            size: size, 
            tsURL: { (path, url) -> URL? in
                if path.hasSuffix(".ts") {
                    return url.appendingPathComponent(path)
                } else {
                    return nil
                }
    },
            completion: { (result) in
                switch result {
                case .success(let model):
                    print("[Attach Success] " + model.name!)
                case .failure(let error):
                    print("[Attach Failure] " + error.  localizedDescription)
                }
    })
```

### Download the ts file described by the M3U file

```Swift
let url = URL(string:"http://xxx.com/yyy.m3u8")! // URL of the M3U file
let size: Int = <#fileSize#>                     // The total size of all ts files

WLM3U
    .attach(url: url, size: size)
    .download(progress: { (progress, completedCount) in
        progress       // Current download progress
        completedCount // Download speed (B/S)
        
    }, completion: { (result) in
        switch result {
        case .success(let url):
            url // The directory where the ts file is located
        case .failure(let error):
            print("[Download Failure] " + error.localizedDescription)
        }
    })
```

### Combine downloaded ts files into one file

```Swift
let url = URL(string:"http://xxx.com/yyy.m3u8")! // URL of the M3U file
let size: Int = <#fileSize#>                     // The total size of all ts files

WLM3U
    .attach(url: url, size: size)
    .download()
    .combine(completion: { (result) in
        switch result {
        case .success(let url):
            url // The directory where the files are located after the combine is completed
        case .failure(let error):
            print("[Combine Failure] " + error.localizedDescription)
        }
    })
```

### Automatically get the total size of the ts file

WLM3U supports automatic acquisition of the total size of all files when calling the `WLM3U.attach()` function without passing the `size` parameter. The process of getting the size is asynchronous, you can get the size data by receiving `TaskGetFileSizeProgressNotification` and `TaskGetFileSizeCompletionNotification`.

### Pause and Resume tasks

To simplify the interface, WLM3U does not have the concepts of `pause` and `resume`. They are the same as `cancel` and `attach`, so:

When you need to pause a task, call `cancel(url: URL)` when you need to pause a task.

When you need to cancel a task, call `cancel(url: URL)` and get the task cache directory through `folder(for url: URL)` and delete it.

When you need to add a task, call `attach(url: URL)`.

When you need to resume a task, call `attach(url: URL)`, if the previous cache exists locally, it will automatically continue to download the remaining files.

### Listening status

The WLM3U has built-in notifications for several states that you can receive to process data:

```Swift
/// A notification that will be sent when the progress of the task changes.
public let TaskProgressNotification: Notification.Name

/// A notification that will be sent when the progress of getting file size changes.
public let TaskGetFileSizeProgressNotification: Notification.Name

/// A notification that will be sent when size of all files has got.
public let TaskGetFileSizeCompletionNotification: Notification.Name

/// A notification that will be sent when the task ends.
public let TaskCompletionNotification: Notification.Name

/// A notification that will be sent when a task has an error.
public let TaskErrorNotification: Notification.Name
```

## Playing downloaded files

AVPlayer and WLM3U do not support playing local ts files at this time. Here are two simple and feasible alternatives.

### Using GCDWebServer to build local services

**Note: Do not call the `WLM3U.combine()` function when playing in this way.**

Using the [GCDWebServer](https://github.com/swisspol/GCDWebServer) library:

```ruby
pod "GCDWebServer"
```

Create a local HTTP service to provide the downloaded ts file:

```Swift
let server = GCDWebServer()
let path = <#folderPath#> // The local directory where the ts file is located
server.addGETHandler(forBasePath: "/",
                     directoryPath: path,
                     indexFilename: "file.m3u8",
                     cacheAge: 3600,
                     allowRangeRequests: true)
server.start()
```

Then, use AVPlayer to play the ts file provided by the local service:

```Swift
let url = URL(string: "http://localhost:\(server.port)/file.m3u8")
let player = AVPlayer(url: url)
```

### Using FFmpeg to transcode ts files into mp4 files

Using the [mobile-ffmpeg-full](https://github.com/tanersener/mobile-ffmpeg) library：

```ruby
pod "mobile-ffmpeg-full"
```

Execute the transcoding command:

```Swift
let command = "-i 'The path where the ts file is located' 'The path to which the mp4 file is saved'"

let result = MobileFFmpeg.execute(command)

if result == RETURN_CODE_SUCCESS {
    // Transcode completion
}
```

## Author

> Willie, willie.wangwei@gmail.com

***

WLM3U 是一个用 Swift 实现的 M3U 工具。

## 示例

clone 这个仓库，接着执行 `pod install` 命令，然后运行示例项目。

## 要求


iOS   | Swift
----- | -----
9.0 + | 5.0 +

## 安装

WLM3U 可通过 [CocoaPods](https://cocoapods.org) 安装，只需将以下行添加到 Podfile 即可

```ruby
pod 'WLM3U'
```

## 使用

### 解析 M3U 文件

```Swift
let url = URL(string:"http://xxx.com/yyy.m3u8")! // M3U 文件的 URL
let size: Int = <#fileSize#>                     // 所有 ts 文件的总大小

WLM3U
    .attach(url: url,
            size: size, 
            tsURL: { (path, url) -> URL? in
                if path.hasSuffix(".ts") {
                    return url.appendingPathComponent(path)
                } else {
                    return nil
                }
    },
            completion: { (result) in
                switch result {
                case .success(let model):
                    print("[Attach Success] " + model.name!)
                case .failure(let error):
                    print("[Attach Failure] " + error.  localizedDescription)
                }
    })
```

### 下载 M3U 文件描述的 ts 文件

```Swift
let url = URL(string:"http://xxx.com/yyy.m3u8")! // M3U 文件的 URL
let size: Int = <#fileSize#>                     // 所有 ts 文件的总大小

WLM3U
    .attach(url: url, size: size)
    .download(progress: { (progress, completedCount) in
        progress       // 当前下载的进度
        completedCount // 下载速度（ B/S ）
        
    }, completion: { (result) in
        switch result {
        case .success(let url):
            url // ts 文件所在的目录
        case .failure(let error):
            print("[Download Failure] " + error.localizedDescription)
        }
    })
```

### 将下载的 ts 文件合并成一个文件

```Swift
let url = URL(string:"http://xxx.com/yyy.m3u8")! // M3U 文件的 URL
let size: Int = <#fileSize#>                     // 所有 ts 文件的总大小

WLM3U
    .attach(url: url, size: size)
    .download()
    .combine(completion: { (result) in
        switch result {
        case .success(let url):
            url // 合并完成后文件所在的目录
        case .failure(let error):
            print("[Combine Failure] " + error.localizedDescription)
        }
    })
```

### 自动获取 ts 文件总大小

当调用 `WLM3U.attach()` 函数未传递 `size` 参数时，WLM3U 会自动获取所有文件的总大小。这个过程是异步的，可以通过接收 `TaskGetFileSizeProgressNotification` 和 `TaskGetFileSizeCompletionNotification` 来获取大小数据。

### 暂停与恢复任务

为了简化接口，WLM3U 没有 `暂停` 与 `恢复` 的概念，它们和 `取消` 与 `添加` 是一样的，所以：

需要暂停一个任务时，调用 `cancel(url: URL)`。

需要取消一个任务时，调用 `cancel(url: URL)`，并通过 `folder(for url: URL)` 获取到此任务缓存目录，并删除它即可。

需要添加一个任务时，调用 `attach(url: URL)`。

需要恢复一个任务时，调用 `attach(url: URL)`，如果本地存在之前的缓存，会自动继续下载剩余的文件。

### 监听状态

WLM3U 内置了几个状态的通知，你可以接收这些通知来处理数据：

```Swift
/// 下载进度发生变化时会发出的通知。
public let TaskProgressNotification: Notification.Name

/// 获取文件总大小的进度发生变化时会发出的通知。
public let TaskGetFileSizeProgressNotification: Notification.Name

/// 获取文件总大小完成时会发出的通知。
public let TaskGetFileSizeCompletionNotification: Notification.Name

/// 任务完成时会发出的通知。
public let TaskCompletionNotification: Notification.Name

/// 任务发生错误时会发出的通知。
public let TaskErrorNotification: Notification.Name
```

## 播放下载的文件

AVPlayer 与 WLM3U 暂不支持播放本地 ts 文件，这里提供两个简单可行的替代方案。

### 使用 GCDWebServer 搭建本地服务

**注意：使用此方式播放时，不要调用 `WLM3U.combine()` 函数。**

引入 [GCDWebServer](https://github.com/swisspol/GCDWebServer) 库：

```ruby
pod "GCDWebServer"
```

创建本地 HTTP 服务来提供下载好的 ts 文件：

```Swift
let server = GCDWebServer()
let path = <#folderPath#> // ts 文件所在的本地目录
server.addGETHandler(forBasePath: "/",
                     directoryPath: path,
                     indexFilename: "file.m3u8",
                     cacheAge: 3600,
                     allowRangeRequests: true)
server.start()
```

使用 AVPlayer 来播放本地服务提供的 ts 文件：

```Swift
let url = URL(string: "http://localhost:\(server.port)/file.m3u8")
let player = AVPlayer(url: url)
```

### 使用 FFmpeg 将 ts 文件转码成 mp4 文件

引入 [mobile-ffmpeg-full](https://github.com/tanersener/mobile-ffmpeg) 库：

```ruby
pod "mobile-ffmpeg-full"
```

执行转码命令：

```Swift
let command = "-i 'ts文件所在的路径' 'mp4文件要保存到的路径'"

let result = MobileFFmpeg.execute(command)

if result == RETURN_CODE_SUCCESS {
    // 转码完成
}
```

接下来直接播放转码得到的 mp4 文件即可。

## 作者

> Willie, willie.wangwei@gmail.com

## License

WLM3U is available under the MIT license. See the LICENSE file for more info.
