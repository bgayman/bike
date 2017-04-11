//
//  ClientResponse.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation

enum ClientResponse<T>
{
    case error(errorMessage: String)
    case success(response: T)
}
