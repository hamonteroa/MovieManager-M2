//
//  TMDBMovie.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import Foundation

struct TMDBMovie {
    
    let title: String
    let id: Int
    let posterPath: String?
    let releaseYear: String?
    let overview: String?
    
    init(dictionary: [String: AnyObject]) {
        title = dictionary[TMDBClient.JSONResponseKeys.MovieTitle] as! String
        id = dictionary[TMDBClient.JSONResponseKeys.MovieID] as! Int
        posterPath = dictionary[TMDBClient.JSONResponseKeys.MoviePosterPath] as? String
        overview = dictionary[TMDBClient.JSONResponseKeys.MovieOverview] as? String
        
        if let releaseDateString = dictionary[TMDBClient.JSONResponseKeys.MovieReleaseDate] as? String, releaseDateString.isEmpty == false {
            releaseYear = releaseDateString.substring(to: releaseDateString.index(releaseDateString.startIndex, offsetBy: 4))
        } else {
            releaseYear = ""
        }
    }
    
    static func moviesFromResult(results: [[String: AnyObject]]) -> [TMDBMovie] {
        var movies = [TMDBMovie]()
        
        for result in results {
            movies.append(TMDBMovie(dictionary: result))
        }
        
        return movies
    }
}


//extension TMDBMovie: Equatable {}
extension TMDBMovie: Equatable {}

func ==(lhs: TMDBMovie, rhs: TMDBMovie) -> Bool {
    return lhs.id == rhs.id
}
