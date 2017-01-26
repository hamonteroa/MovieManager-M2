//
//  MovieDetailViewController.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import Foundation
import UIKit

class MovieDetailViewController: UIViewController {
    
    var movie: TMDBMovie!
    var isFavorite = false
    var isWatchlist = false
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toogleWatchlistButton: UIBarButtonItem!
    @IBOutlet weak var toogleFavoriteButton: UIBarButtonItem!
    @IBOutlet weak var overviewLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.navigationBar.isTranslucent = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        activityIndicator.alpha = 1.0
        activityIndicator.startAnimating()
        
        if let movie = movie {
            if let releaseYear = movie.releaseYear {
                navigationItem.title = "\(movie.title) (\(releaseYear))"
            } else {
                navigationItem.title = "\(movie.title)"
            }
            
            if let overview = movie.overview {
                overviewLabel.text = overview
            } else {
                overviewLabel.text = "No overview"
            }
        
            posterImageView.image = UIImage(named: "MissingPoster")
            isFavorite = false
            isWatchlist = false
            
            if let posterPath = movie.posterPath {
                TMDBClient.sharedInstance().taskForGETImage(size: TMDBClient.PosterSizes.DetailPoster, filePath: posterPath) { (imageData, error) in
                    
                    if let image = UIImage(data: imageData as! Data) {
                        performUIUpdatesOnMain {
                            self.activityIndicator.alpha = 0.0
                            self.activityIndicator.stopAnimating()
                            self.posterImageView.image = image
                            
                        }
                    }
                }
            } else {
                self.activityIndicator.alpha = 0.0
                self.activityIndicator.stopAnimating()
            }
            
            TMDBClient.sharedInstance().getFavoritesMovies { (movies, error) in
                if let movies = movies {
                    for movie in movies {
                        if movie.id == self.movie.id {
                            self.isFavorite = true
                        }
                    }
                    
                    performUIUpdatesOnMain {
                        if self.isFavorite {
                            self.toogleFavoriteButton.tintColor = nil
                        } else {
                            self.toogleFavoriteButton.tintColor = UIColor.black
                        }
                    }
                } else {
                    print(error)
                }
            }
            
            TMDBClient.sharedInstance().getWatchlistMovies { (movies, error) in
                if let movies = movies {
                    for movie in movies {
                        if movie.id == self.movie.id {
                            self.isWatchlist = true
                        }
                    }
                    
                    performUIUpdatesOnMain {
                        if self.isWatchlist {
                            self.toogleWatchlistButton.tintColor = nil
                        } else {
                            self.toogleWatchlistButton.tintColor = UIColor.black
                        }
                    }
                } else {
                    print(error)
                }
            }
        }
        
    }
    
    
    @IBAction func onClickToogleFavoriteButton(_ sender: AnyObject) {
        let markAsFavorite = !self.isFavorite
        TMDBClient.sharedInstance().postToFavorite(movie: self.movie, markAsFavorite: markAsFavorite) { (statusCode, error) in
            if let error = error {
                print(error)
                
            } else {
                if statusCode == 1 || statusCode == 12 || statusCode == 13 {
                    self.isFavorite = markAsFavorite
                    performUIUpdatesOnMain {
                        self.toogleFavoriteButton.tintColor = markAsFavorite ? nil : UIColor.black
                    }
                }
            }
        }
    }
    
    @IBAction func onClickToogleWatchlistButton(_ sender: AnyObject) {
        let markAsWatchlist = !self.isWatchlist
        TMDBClient.sharedInstance().postToWatchlist(movie: movie, markToWatchlist: markAsWatchlist) { (statusCode, error) in
            if let error = error {
                print(error)
                
            } else {
                if statusCode == 1 || statusCode == 12 || statusCode == 13 {
                    self.isWatchlist = markAsWatchlist
                    performUIUpdatesOnMain {
                        self.toogleWatchlistButton.tintColor = markAsWatchlist ? nil : UIColor.black
                    }
                }
            }
        }
    }
    
}

