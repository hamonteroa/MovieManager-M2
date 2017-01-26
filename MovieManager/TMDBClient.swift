//
//  TMDBClient.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import Foundation

class TMDBClient: NSObject {
    
    var config = TMDBConfig()
    var session = URLSession.shared
    
    var requestToken: String? = nil
    var sessionID: String? = nil
    var userID: Int? = nil
    
    override init() {
        super.init()
    }
    
    func taskForGetMethod(method: String, parameters: [String: AnyObject],  completionHandlerForGet: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        // 1. Set the parameters
        var parametersWithApiKey = parameters
        parametersWithApiKey[ParameterKeys.ApiKey] = Constants.ApiKey as AnyObject?
        
        // 2/3. Build the URL, Configure the request
        let urlRequest = URLRequest(url: tmdbURLFromParameters(parameters: parametersWithApiKey, withPathExtension: method) as URL)
        
        print("taskForGetMethod url: \(urlRequest.url?.absoluteString)")
        
        // 4. Make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGet(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                sendError(error: "There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2xx!: \((response as? HTTPURLResponse)?.statusCode)")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                sendError(error: "No data was returned by the request!")
                return
            }
            
            // 5/6. Parse the data and use the data (happens in completion handler)
            self.convertDataWithCompletionHandler(data: data as NSData, completionHandlerForConvertData: completionHandlerForGet)
        })
        
        // 7. Start the request
        task.resume()
        
        return task
    }
    
    func taskForGETImage(size: String, filePath: String, completionHandlerForImage: @escaping (_ imageData: NSData?, _ error: NSError?) -> Void) -> URLSessionTask {
        
        // 1. Set the parameters
        // No parameters
        
        // 2/3. Build the URL, Configure the request
        let baseURL = URL(fileURLWithPath: config.baseImageURLString)
        let url = baseURL.appendingPathComponent(size).appendingPathComponent(filePath)
        let urlRequest = URLRequest(url: url)
        
        print("taskForGETImage url: \(urlRequest.url?.absoluteString)")
        
        // 4. Make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForImage(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                sendError(error: "There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2xx!")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                sendError(error: "No data was returned by the request!")
                return
            }
            
            // 5/6. Prase the data and use it (happens in completion handler)
            completionHandlerForImage(data as NSData?, nil)
        })
        
        // 7. Start the request
        task.resume()
        
        return task
    }
    
    func taskForPOSTMethod(method: String, parameters: [String:AnyObject], jsonBody: String, completionHandlerForPOST: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        // 1. Set the parameters
        var parametersWithApiKey = parameters
        parametersWithApiKey[ParameterKeys.ApiKey] = Constants.ApiKey as AnyObject?
        
        // 2/3. Build the URL, Configure the request
        var urlRequest = URLRequest(url: tmdbURLFromParameters(parameters: parametersWithApiKey, withPathExtension: method) as URL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonBody.data(using: String.Encoding.utf8)
        
        print("taskForPOSTMethod url: \(urlRequest.url?.absoluteString), jsonBody: \(jsonBody)")
        
        // 4. Make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForPOST(nil, NSError(domain: "taskForPostMethod", code: 1, userInfo: userInfo))
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                sendError(error: "There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2xx!")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                sendError(error: "No data was returned by the request!")
                return
            }
            
            // 5/6. Parse the data and use the data (happens in completion handler)
            self.convertDataWithCompletionHandler(data: data as NSData, completionHandlerForConvertData: completionHandlerForPOST)
        })
        
        // 7. Start the request
        task.resume()
        
        return task
    }
    
    // substitute the key for the value that is contained within the method name
    func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.range(of: "{\(key)}") != nil {
            return method.replacingOccurrences(of: "{\(key)}", with: value)
            
        } else {
            return nil
        }
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as AnyObject!
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }

    
    private func tmdbURLFromParameters(parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
        let components = NSURLComponents()
        components.scheme = TMDBClient.Constants.ApiScheme
        components.host = TMDBClient.Constants.ApiHost
        components.path = TMDBClient.Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
        
        for(key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem as URLQueryItem)
        }
        
        return components.url! as NSURL
    }
    
    class func sharedInstance() -> TMDBClient {
        struct Singleton {
            static var sharedInstance = TMDBClient()
        }
        return Singleton.sharedInstance
    }
}
