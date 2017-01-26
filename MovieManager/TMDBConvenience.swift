//
//  TMDBConvenience.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import UIKit
import Foundation

extension TMDBClient {

    /*
     Steps for Authentication...
     https://www.themoviedb.org/documentation/api/sessions
     
     Step 1: Create a new request token
     Step 2a: Ask the user for permission via the website
     Step 3: Create a session ID
     Bonus Step: Go ahead and get the user id 😄!
     */
    
    func authenticateWithViewController(hostViewController: UIViewController, completionHandlerForAuth: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        getRequestToken { (success, requestToken, errorString) in
            if success {
                self.requestToken = requestToken
                
                self.loginWithToken(requestToken: self.requestToken, hostViewController: hostViewController, completionHandlerForLogin: { (success, errorString) in
                    if success {
                        self.getSessionID(requestToken: self.requestToken, completionHandlerForSession: { (success, sessionID, errorString) in
                            if success {
                                self.sessionID = sessionID
                                
                                self.getUserID(completionHandlerForUserID: { (success, userID, errorString) in
                                    if success {
                                        if let userID = userID { self.userID = userID }
                                    }
                                    completionHandlerForAuth(success, errorString)
                                    
                                })
                            } else {
                                completionHandlerForAuth(success, errorString)
                            }
                        })
                    } else {
                        completionHandlerForAuth(success, errorString)
                    }
                })
            } else {
                completionHandlerForAuth(success, errorString)
            }
        }
    }
    
    private func getRequestToken(completionHandlerForToken: @escaping (_ success: Bool, _ requestToken: String?, _ errorString: String?) -> Void) {
    
        // 1. Specify parameters, method (if has {key}), and HTTP body (if post)
        let parameters = [String: AnyObject]()
        
        // 2. Make the request
        taskForGetMethod(method: Methods.AuthenticationTokenNew, parameters: parameters) { (results, error) in
            
            // 3. Send the desired value(s) to completion handler
            if let error = error {
                print(error)
                completionHandlerForToken(false, nil, "Login Failed (Request Token): \(error)")
            } else {
                if let requestToken = results?[TMDBClient.JSONResponseKeys.RequestToken] as? String {
                    completionHandlerForToken(true, requestToken, nil)
                } else {
                    print("Could not find \(TMDBClient.JSONResponseKeys.RequestToken) in \(results)")
                    completionHandlerForToken(false, nil, "Login Failed (Request Token). Could not find \(TMDBClient.JSONResponseKeys.RequestToken) in \(results)")
                }
            }
        }
    }
    
    private func loginWithToken(requestToken: String?, hostViewController: UIViewController , completionHandlerForLogin: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
    
        let authorizationURL = URL(string: "\(TMDBClient.Constants.AuthorizationURL)\(requestToken!)")
        let urlRequest = URLRequest(url: authorizationURL!)
        
        let webAuthViewController = hostViewController.storyboard!.instantiateViewController(withIdentifier: "TMDBAuthVC") as! TMDBAuthViewController
        
        webAuthViewController.urlRequest = urlRequest
        webAuthViewController.requestToken = requestToken
        webAuthViewController.completionHandlerForView = completionHandlerForLogin
        
        let webAuthNavigationController = UINavigationController()
        webAuthNavigationController.pushViewController(webAuthViewController, animated: false)

        performUIUpdatesOnMain {
            hostViewController.present(webAuthNavigationController, animated: true, completion: nil)
        }
    }
    
    private func getSessionID(requestToken: String?, completionHandlerForSession: @escaping (_ success: Bool, _ sessionID: String?, _ errorString: String?) -> Void) {
        
        // 1. Specify parameters, method (if has {key}), and HTTP body (if POST)
        let parameters = [TMDBClient.ParameterKeys.RequestToken: requestToken!]
        
        // 2. Make the request
        taskForGetMethod(method: Methods.AuthenticationSessionNew, parameters: parameters as [String: AnyObject]) { (results, error) in
            // 3. Send the desired value(s) to completion handler
            if let error = error {
                print(error)
                completionHandlerForSession(false, nil, "Login Failed (Session ID).")
            } else {
                if let sessionID = results?[TMDBClient.JSONResponseKeys.SessionID] as? String {
                    completionHandlerForSession(true, sessionID, nil)
                } else {
                    print("Could not find \(TMDBClient.JSONResponseKeys.SessionID) in \(results)")
                    completionHandlerForSession(false, nil, "Login Failed (Session ID). \(TMDBClient.JSONResponseKeys.SessionID) in \(results)")
                }
            }
        }
    }
    
    private func getUserID(completionHandlerForUserID: @escaping (_ success: Bool, _ userID: Int?, _ errorString: String?) -> Void) {
        let parameters = [TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID]
        
        taskForGetMethod(method: TMDBClient.Methods.Account, parameters: parameters as [String: AnyObject]) { (results, error) in
            if let error = error {
                print(error)
                completionHandlerForUserID(false, nil, "Login Failed (User ID): \(error)")
            } else {
                if let userID = results![TMDBClient.JSONResponseKeys.UserID] as? Int {
                    completionHandlerForUserID(true, userID, nil)
                } else {
                    print("Could not find \(TMDBClient.JSONResponseKeys.RequestToken) in \(results!)")
                    completionHandlerForUserID(false, nil, "Login Failed (User ID). Could not find \(TMDBClient.JSONResponseKeys.UserID) in \(results!)")
                }
            }
        }
    }
    
    func getMoviesForSearchString(searchString: String, completionHandlerForSearchMovie: @escaping (_ results: [TMDBMovie]?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        var searchStringQuery: String
        if searchString.isEmpty {
            searchStringQuery = " "
        } else {
            searchStringQuery = searchString
        }
        
        let parameters = [TMDBClient.ParameterKeys.Query: searchStringQuery]
        
        let task = taskForGetMethod(method: Methods.SearchMovie, parameters: parameters as [String : AnyObject]) { (results, error) in
            if let error = error {
                print(error)
                completionHandlerForSearchMovie(nil, error)
            } else {
                if let results = results?[TMDBClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]] {
                    let movies = TMDBMovie.moviesFromResult(results: results)
                    completionHandlerForSearchMovie(movies, nil)
                } else {
                    completionHandlerForSearchMovie(nil, NSError(domain: "getMoviesForSearchString parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getMoviesForSearchString"] ))
                }
            }
        }
        
        return task
    }
    
    func getWatchlistMovies(completionHandlerForWatchlistMovies: @escaping (_ results: [TMDBMovie]?, _ error: NSError?) -> Void) -> URLSessionTask {
        
        let parameters = [TMDBClient.ParameterKeys.ApiKey: TMDBClient.Constants.ApiKey,
                          TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID]
        
        var mutableMethod: String = TMDBClient.Methods.AccountIDWatchlistMovies
        mutableMethod = subtituteKeyInMethod(method: mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(describing: TMDBClient.sharedInstance().userID!))!
        
        let task = taskForGetMethod(method: mutableMethod, parameters: parameters as [String: AnyObject]) { (results, error) in
            if let error = error {
                print(error)
                completionHandlerForWatchlistMovies(nil, error)
            } else {
                if let results = results?[TMDBClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]] {
                    let movies = TMDBMovie.moviesFromResult(results: results)
                    completionHandlerForWatchlistMovies(movies, nil)
                } else {
                    completionHandlerForWatchlistMovies(nil, NSError(domain: "getWatchlistMovies parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getWatchlistMovies"]))
                }
            }
        }
        
        return task
    }
    
    func getFavoritesMovies(completionHandlerForFavoritesMovies: @escaping (_ results: [TMDBMovie]?, _ error: NSError?) -> Void) -> URLSessionTask {
        let parameters = [TMDBClient.ParameterKeys.ApiKey: TMDBClient.Constants.ApiKey,
                          TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID]
        
        var mutableMethod: String = TMDBClient.Methods.AccountIDFavoriteMovies
        mutableMethod = subtituteKeyInMethod(method: mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(describing: TMDBClient.sharedInstance().userID!))!
        
        let task = taskForGetMethod(method: mutableMethod, parameters: parameters as [String: AnyObject]) { (results, error) in
            if let error = error {
                print(error)
                completionHandlerForFavoritesMovies(nil, error)
            } else {
                if let results = results?[TMDBClient.JSONResponseKeys.MovieResults] as? [[String: AnyObject]] {
                    let movies = TMDBMovie.moviesFromResult(results: results)
                    completionHandlerForFavoritesMovies(movies, nil)
                } else {
                    completionHandlerForFavoritesMovies(nil, NSError(domain: "getFavoritesMovies parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getFavoritesMovies"]))
                }
            }
        }
        
        return task
    }
    
    func postToWatchlist(movie: TMDBMovie, markToWatchlist: Bool, completionHandlerForWatchlist: @escaping (_ result: Int?, _ error: NSError?) -> Void) {
        let parameters = [TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID]
        
        var mutableMethod: String = TMDBClient.Methods.AccountIDWatchlist
        mutableMethod = subtituteKeyInMethod(method: mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(describing: TMDBClient.sharedInstance().userID!))!

        let jsonBody = "{\"\(TMDBClient.JSONBodyKeys.MediaType)\": \"movie\", \"\(TMDBClient.JSONBodyKeys.MediaID)\": \(movie.id), \"\(TMDBClient.JSONBodyKeys.Watchlist)\": \(markToWatchlist)}"
        
        taskForPOSTMethod(method: mutableMethod, parameters: parameters as [String : AnyObject], jsonBody: jsonBody) { (results, error) in
            if let error = error {
                completionHandlerForWatchlist(nil, error)
            } else {
                if let results = results?[TMDBClient.JSONResponseKeys.StatusCode] as? Int {
                    completionHandlerForWatchlist(results, nil)
                } else {
                    completionHandlerForWatchlist(nil, NSError(domain: "addToWatchlist parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse addToWatchlist"]))
                }
            }
        }
    }
    
    func postToFavorite(movie: TMDBMovie, markAsFavorite: Bool, completionHandlerForFavorite: @escaping (_ result: Int?, _ error: NSError?) -> Void) {
        let parameters = [TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID]
        
        var mutableMethod: String = TMDBClient.Methods.AccountIDFavorite
        mutableMethod = subtituteKeyInMethod(method: mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(describing: TMDBClient.sharedInstance().userID!))!
        
        let jsonBody = "{\"\(TMDBClient.JSONBodyKeys.MediaType)\": \"movie\", \"\(TMDBClient.JSONBodyKeys.MediaID)\": \(movie.id), \"\(TMDBClient.JSONBodyKeys.Favorite)\": \(markAsFavorite)}"
        
        taskForPOSTMethod(method: mutableMethod, parameters: parameters as [String: AnyObject], jsonBody: jsonBody) { (results, error) in
            if let error = error {
                completionHandlerForFavorite(nil, error)
            } else {
                if let results = results?[TMDBClient.JSONResponseKeys.StatusCode] as? Int {
                    completionHandlerForFavorite(results, nil)
                } else {
                    completionHandlerForFavorite(nil, NSError(domain: "addToFavorite parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse addToFavorite"]))
                }
            }
        }
    }
    
    func getConfig(completionHandlerForConfig: @escaping (_ didSucceed: Bool, _ error: NSError?) -> Void) {
        let parameters = [String:AnyObject]()
        
        taskForGetMethod(method: Methods.Config, parameters: parameters as [String: AnyObject]) { (results, error) in
            
            if let error = error {
                completionHandlerForConfig(false, error)
            } else if let newConfig = TMDBConfig(dictionary: results as! [String:AnyObject]) {
                self.config = newConfig
                completionHandlerForConfig(true, nil)
            } else {
                completionHandlerForConfig(false, NSError(domain: "getConfig parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getConfig"]))
            }
        }
    }
    
}
