//
//  MovieViewController.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import Foundation
import UIKit

protocol MoviePickerViewControllerDelegate {
    func moviePicker(moviePicker: MoviePickerViewController, didPickMovie movie: TMDBMovie?)
}

class MoviePickerViewController: UIViewController {
    
    var movies = [TMDBMovie]()
    
    // the most recent data download task. We keep a reference to it so that it can be canceled every time the search text changes
    var searchTask: URLSessionDataTask?
    
    // the delegate will typically be a view controller, waiting for the Movie Picker to return an movie
    var delegate: MoviePickerViewControllerDelegate?
    
    @IBOutlet weak var movieSearchBar: UISearchBar!
    @IBOutlet weak var movieTableView: UITableView!
    
    override func viewDidLoad() {
        parent!.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(logout))
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(recognizer:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        
        self.movieSearchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        searchTask = TMDBClient.sharedInstance().getMoviesForSearchString(searchString: "") { (movies, error) in
            self.searchTask = nil
            if let movies = movies {
                self.movies = movies
                performUIUpdatesOnMain {
                    self.movieTableView.reloadData()
                }
            }
        }
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    private func cancel() {
        delegate?.moviePicker(moviePicker: self, didPickMovie: nil)
        logout()
    }
    
    func logout() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension MoviePickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return movieSearchBar.isFirstResponder
    }
}

extension MoviePickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("searchBar textDidChange")
        if let task = searchTask {
            task.cancel()
        }
        
        if searchText == "" {
            movies = [TMDBMovie]()
            movieTableView?.reloadData()
            return
        }
        
        searchTask = TMDBClient.sharedInstance().getMoviesForSearchString(searchString: searchText) { (movies, error) in
            self.searchTask = nil
            if let movies = movies {
                self.movies = movies
                performUIUpdatesOnMain {
                    self.movieTableView.reloadData()
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarSearchButtonClicked")
        searchBar.resignFirstResponder()
    }
}

extension MoviePickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let movie = movies[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieTableViewCell") as UITableViewCell!
        
        if let releaseYear = movie.releaseYear {
            cell?.textLabel?.text = "\(movie.title) (\(movie.releaseYear!))"
        } else {
            cell?.textLabel?.text = "\(movie.title)"
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tableView didSelectRowAt")
        let movie = movies[indexPath.row]
        let detailMovieVC = storyboard!.instantiateViewController(withIdentifier: "MovieDetailVC") as! MovieDetailViewController
        detailMovieVC.movie = movie
        navigationController!.pushViewController(detailMovieVC, animated: true)
    }
}

