//
//  ViewController.swift
//  WLM3U
//
//  Created by Willie on 07/15/2019.
//  Copyright (c) 2019 Willie. All rights reserved.
//

import UIKit
import WLM3U

class ViewController: UIViewController {
    
    @IBOutlet weak var textView1: UITextView!
    @IBOutlet weak var progressView1: UIProgressView!
    @IBOutlet weak var speedLabel1: UILabel!
    @IBOutlet weak var progressLabel1: UILabel!
    
    @IBOutlet weak var textView2: UITextView!
    @IBOutlet weak var progressView2: UIProgressView!
    @IBOutlet weak var speedLabel2: UILabel!
    @IBOutlet weak var progressLabel2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url1 = "http://qf-oss.bofuns.com/mts_in/hls/01573a671542b017000c533e25f33abb/01573a671542b017000c533e25f33abb.m3u8"
        let url2 = "http://qf-oss.bofuns.com/mts_in/hls/9ba8c4ab624563ae418cb3f63c5dbfe1/9ba8c4ab624563ae418cb3f63c5dbfe1.m3u8"
        
        textView1.text = url1
        textView2.text = url2
    }
    
    @IBAction func onDownloadButton(_ sender: UIButton) {
        let url = URL(string: sender.tag == 0 ? textView1.text : textView2.text)!
        do {
            let workflow = try WLM3U.attach(url: url,
                                            completion: { (result) in
                                                switch result {
                                                case .success(let model):
                                                    print("attach success " + model.name!)
                                                case .failure(let error):
                                                    print("attach failure " + error.localizedDescription)
                                                }
            })
            
            run(workflow: workflow, index: sender.tag)
            
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func onPauseButton(_ sender: UIButton) {
        WLM3U.cancel(url: URL(string: sender.tag == 0 ? textView1.text : textView2.text)!)
    }
    
    @IBAction func onResumeButton(_ sender: UIButton) {
        let url = URL(string: sender.tag == 0 ? textView1.text : textView2.text)!
        do {
            let workflow = try WLM3U.attach(url: url,
                                            completion: { (result) in
                                                switch result {
                                                case .success(let model):
                                                    print("attach success " + model.name!)
                                                case .failure(let error):
                                                    print("attach failure " + error.localizedDescription)
                                                }
            })
            
            run(workflow: workflow, index: sender.tag)
            
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func run(workflow: Workflow, index: Int) {
        
        let progressView = (index == 0 ? progressView1 : progressView2)!
        let speedLabel = (index == 0 ? speedLabel1 : speedLabel2)!
        let progressLabel = (index == 0 ? progressLabel1 : progressLabel2)!
        
        workflow
            
            .download(progress: { (progress, completedCount) in
                progressView.progress = Float(progress.fractionCompleted)
                var text = ""
                let mb = Double(completedCount) / 1024 / 1024
                if mb >= 0.1 {
                    text = String(format: "%.1f", mb) + " M/s"
                } else {
                    text = String(completedCount / 1024) + " K/s"
                }
                speedLabel.text = text
                progressLabel.text = String(format: "%.2f", progress.fractionCompleted * 100) + " %"
            }, completion: { (result) in
                switch result {
                case .success(let url):
                    print("download success " + url.path)
                case .failure(let error):
                    print("download failure " + error.localizedDescription)
                }
            })
            
            .combine(completion: { (result) in
                switch result {
                case .success(let url):
                    print("combine success " + url.path)
                case .failure(let error):
                    print("combine failure " + error.localizedDescription)
                }
                
                speedLabel.text = "All finished"
                progressLabel.text = "All finished"
            })
    }
}

