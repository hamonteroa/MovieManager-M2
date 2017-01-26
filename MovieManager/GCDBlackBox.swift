//
//  GCDBlackBox.swift
//  MovieManager
//
//  Created by Hector Montero on 1/11/17.
//  Copyright © 2017 Hector Montero. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
