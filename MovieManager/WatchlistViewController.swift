//
//  WatchlistViewController.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import Foundation
import UIKit

class WatchlistViewController: UIViewController {
    
    var movies = [TMDBMovie]()
    
    @IBOutlet weak var watchlistTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        TMDBClient.sharedInstance().getWatchlistMovies { (movies, error) in
            if let movies = movies {
                self.movies = movies
                performUIUpdatesOnMain {
                    self.watchlistTableView.reloadData()
                }
            }
        }
    }
    
}

extension WatchlistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let movie = movies[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatchlistTableViewCell") as UITableViewCell!
        
        if let releaseYear = movie.releaseYear {
            cell?.textLabel?.text = "\(movie.title) (\(movie.releaseYear!))"
        } else {
            cell?.textLabel?.text = "\(movie.title)"
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tableView didSelectRowAt")
        let movie = movies[indexPath.row]
        let detailMovieVC = storyboard!.instantiateViewController(withIdentifier: "MovieDetailVC") as! MovieDetailViewController
        detailMovieVC.movie = movie
        navigationController!.pushViewController(detailMovieVC, animated: true)
    }
}

