//
//  TMDBAuthViewController.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import UIKit

class TMDBAuthViewController: UIViewController {
    
    var urlRequest: URLRequest? = nil
    var requestToken: String? = nil
    var completionHandlerForView: ((_ success: Bool, _ errorString: String?) -> Void)? = nil
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        navigationItem.title = "TheMovieDB Auth"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAuth))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let urlRequest = urlRequest {
            webView.loadRequest(urlRequest)
        }
    }
    
    func cancelAuth() {
        dismiss(animated: false, completion: nil)
    }
    
}

extension TMDBAuthViewController: UIWebViewDelegate {

    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("webViewDidFinishLoad url: \(webView.request?.url!.absoluteString), expectedUrl: \(TMDBClient.Constants.AuthorizationURL)\(requestToken!)/allow")
        
        if webView.request?.url!.absoluteString == "\(TMDBClient.Constants.AuthorizationURL)\(requestToken!)/allow" {
            dismiss(animated: true) {
                self.completionHandlerForView!(true, nil)
            }
        }
    }
}
