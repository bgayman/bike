//
//  BikeStationDescriptionGenerator.swift
//  BikeShare
//
//  Created by B Gay on 9/12/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation
import GameplayKit


struct BikeStationDescriptionGenerator
{
    static let greenDescriptions = ["Get ready to break the sound-bear-ier!!",
                                    "Bear-y nice place to visit!",
                                    "Grab it with your bear hands and get going!",
                                    "Grrrrreat news!!!",
                                    "You have the right to bear bikes.",
                                    "Go bear-zerk 🐻!!",
                                    "This is paws-ibly the best station you'll see all day.",
                                    "This station: a Kodiak moment!!",
                                    "A real honey hole!! 🍯🐝",
                                    "I hope you're paws-itively ready, because this station is!",
                                    "This station has the bear necessities.",
                                    "Think you've seen the best station? Hold my bear.",
                                    "Bear-ed you go again!!",
                                    "Feel the bear-n!!",
                                    "No bear-iers that I can see!",
                                    "It's all grrrrrravy!",
                                    "Bear-y good news!!!",
                                    "🎶 Hey dirty...baby I got your honey 🍯 don't you worry, dirty. 🎶",
                                    "This station is right fur the job.",
                                    "I'm not just panda-ing to the audence; this is a great station.",
                                    "I'm koala-fied to say this station is great. 🐨",
                                    ]
    
    static let orangeDescriptions = ["Bear with me now, there might be what you need at this station.",
                                     "Bear-ly any left, but have at it.",
                                     "This might give you paws, but this station is just looking Ok.",
                                     "Just so you have your bear-ings, this station might not have what you need when you get there.",
                                     "Bear-leave strong enough, and this station might work for you.",
                                     "Paws before you go here.",
                                     "Things are about to get hairy.",
                                     "Feeling claws-trophobic about this station.",
                                     "You'll have to grin and bear it for this one.",
                                     "Bear down and get to this station quick.",
                                     "No time to take a paws!!",
                                     "Be pre-beared.",
                                     "This station is looking a little bear.",
                                     ]
    
    static let redDescriptions = ["This is Un-bear-able!!🐻!!!!",
                                  "Bad news bear!!🐻!!",
                                  "This station is polar-izing.",
                                  "Im-paws-ible!",
                                  "A-bear-antly this station is having a bad day!",
                                  "Well this looks grizzly for you",
                                  "Panda-monium!!🐼",
                                  "Hope you can claw your way out of this one!",
                                  "Bear-y bad news!!",
                                  "Want a hug?",
                                  "In-claws-ible!!",
                                  "Hope you were pre-bear-ed for this.",
                                  "I don't want to em-bear-ass you but this station might not be the one for you.",
                                  "This is scarier than the Bear Witch Project.",
                                  "I hope this isn't a panda-emic. 🐼",
                                  "This station is suffering from kodiak arrest.",
                                  "This can be bear-y teddie-ouses",
                                  ]
    
    static let redDistro = GKShuffledDistribution(lowestValue: 0, highestValue: BikeStationDescriptionGenerator.redDescriptions.count - 1)
    static let orangeDistro = GKShuffledDistribution(lowestValue: 0, highestValue: BikeStationDescriptionGenerator.orangeDescriptions.count - 1)
    static let greenDistro = GKShuffledDistribution(lowestValue: 0, highestValue: BikeStationDescriptionGenerator.greenDescriptions.count - 1)
    
    static func descriptionMessage(for bikeStation: BikeStation) -> String
    {
        let index: Int
        switch bikeStation.pinTintColor
        {
        case UIColor.app_red:
            index = redDistro.nextInt()
            return BikeStationDescriptionGenerator.redDescriptions[index]
        case UIColor.app_orange:
            index = orangeDistro.nextInt()
            return BikeStationDescriptionGenerator.orangeDescriptions[index]
        case UIColor.app_green:
            index = greenDistro.nextInt()
            return BikeStationDescriptionGenerator.greenDescriptions[index]
        default:
            return ""
        }
    }
}
