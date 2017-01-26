//
//  TMDBConfig.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import Foundation

private let _documentsDirectoryURL: NSURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as NSURL!
private let _fileURL: NSURL = (_documentsDirectoryURL.appendingPathComponent("TheMoviewDB-Context") as NSURL?)!

class TMDBConfig: NSObject, NSCoding {
    
    // MARK: Properties
    
    // default values from 1/12/15
    var baseImageURLString = "http://image.tmdb.org/t/p/"
    var secureBaseImageURLString =  "https://image.tmdb.org/t/p/"
    var posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
    var profileSizes = ["w45", "w185", "h632", "original"]
    var dateUpdated: NSDate? = nil
    
    // returns the number days since the config was last updated
    var daysSinceLastUpdate: Int? {
        if let lastUpdate = dateUpdated {
            //return Int(NSDate().timeIntervalSinceDate(lastUpdate)) / 60*60*24
            return Int(NSDate().timeIntervalSince(lastUpdate as Date)) / 60*60*24
        } else {
            return nil
        }
    }
    
    override init() {}
    
    convenience init?(dictionary: [String:AnyObject]) {
        self.init()
        
        if let imageDictionary = dictionary[TMDBClient.JSONResponseKeys.ConfigImages] as? [String:AnyObject],
            let urlString = imageDictionary[TMDBClient.JSONResponseKeys.ConfigBaseImageURL] as? String,
            let secureURLString = imageDictionary[TMDBClient.JSONResponseKeys.ConfigSecureBaseImageURL] as? String,
            let posterSizesArray = imageDictionary[TMDBClient.JSONResponseKeys.ConfigPosterSizes] as? [String],
            let profileSizesArray = imageDictionary[TMDBClient.JSONResponseKeys.ConfigProfileSizes] as? [String] {
            baseImageURLString = urlString
            secureBaseImageURLString = secureURLString
            posterSizes = posterSizesArray
            profileSizes = profileSizesArray
            dateUpdated = NSDate()
        } else {
            return nil
        }
    }
    
    func updateIfDaysSinceUpdateExceeds(days: Int) {
        if let daysSinceLastUpdate = daysSinceLastUpdate, daysSinceLastUpdate <= days {
            return
        } else {
            updateConfiguration()
        }
    }
    
    private func updateConfiguration() {
        TMDBClient.sharedInstance().getConfig() { (didSucceed, error) in
            if let error = error {
                print("Error updating config: \(error.localizedDescription)")
            } else {
                print("Updated Config: \(didSucceed)")
                self.save()
            }
        }
    }
    
    // MARK: NSCoding
    
    let BaseImageURLStringKey = "config.base_image_url_string_key"
    let SecureBaseImageURLStringKey =  "config.secure_base_image_url_key"
    let PosterSizesKey = "config.poster_size_key"
    let ProfileSizesKey = "config.profile_size_key"
    let DateUpdatedKey = "config.date_update_key"
    
    //required init(coder aDecoder: NSCoder) {
    required init?(coder: NSCoder) {
        baseImageURLString = coder.decodeObject(forKey: BaseImageURLStringKey) as! String
        secureBaseImageURLString = coder.decodeObject(forKey: SecureBaseImageURLStringKey) as! String
        posterSizes = coder.decodeObject(forKey: PosterSizesKey) as! [String]
        profileSizes = coder.decodeObject(forKey:ProfileSizesKey) as! [String]
        dateUpdated = coder.decodeObject(forKey:DateUpdatedKey) as? NSDate
    }
    
    //func encodeWithCoder(aCoder: NSCoder) {
    func encode(with: NSCoder) {
        with.encode(baseImageURLString, forKey: BaseImageURLStringKey)
        with.encode(secureBaseImageURLString, forKey: SecureBaseImageURLStringKey)
        with.encode(posterSizes, forKey: PosterSizesKey)
        with.encode(profileSizes, forKey: ProfileSizesKey)
        with.encode(dateUpdated, forKey: DateUpdatedKey)
    }
    
    private func save() {
        NSKeyedArchiver.archiveRootObject(self, toFile: _fileURL.path!)
    }
    
    class func unarchivedInstance() -> TMDBConfig? {
        if FileManager.default.fileExists(atPath: _fileURL.path!) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: _fileURL.path!) as? TMDBConfig
        } else {
            return nil
        }
    }

}
