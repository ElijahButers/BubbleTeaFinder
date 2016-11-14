//
//  AppDelegate.swift
//  Bubble Tea Finder
//
//  Created by Pietro Rea on 8/24/14.
//  Copyright (c) 2014 Pietro Rea. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  lazy var  coreDataStack = CoreDataStack()
  
  
  func application(_ application: UIApplication,
    didFinishLaunchingWithOptions
    launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
      
      importJSONSeedDataIfNeeded()
      
      let navController = window!.rootViewController as! UINavigationController
      let viewController = navController.topViewController as! ViewController
      viewController.coreDataStack = coreDataStack
      
      return true
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    coreDataStack.saveContext()
  }
  
  func importJSONSeedDataIfNeeded() {
    
    let fetchRequest = NSFetchRequest(entityName: "Venue")
    var error: NSError? = nil
    
    let results =
    coreDataStack.context.count(for: fetchRequest,
      error: &error)
    
    if (results == 0) {
      
      do {
        let results =
        try coreDataStack.context.fetch(fetchRequest) as! [Venue]
        
        for object in results {
          let team = object as Venue
          coreDataStack.context.delete(team)
        }
        
        coreDataStack.saveContext()
        importJSONSeedData()
        
      } catch let error as NSError {
        print("Error fetching: \(error.localizedDescription)")
      }
    }
  }
  
  func importJSONSeedData() {
    let jsonURL = Bundle.main.url(forResource: "seed", withExtension: "json")
    let jsonData = try? Data(contentsOf: jsonURL!)

    let venueEntity = NSEntityDescription.entity(forEntityName: "Venue", in: coreDataStack.context)
    let locationEntity = NSEntityDescription.entity(forEntityName: "Location", in: coreDataStack.context)
    let categoryEntity = NSEntityDescription.entity(forEntityName: "Category", in: coreDataStack.context)
    let priceEntity = NSEntityDescription.entity(forEntityName: "PriceInfo", in: coreDataStack.context)
    let statsEntity = NSEntityDescription.entity(forEntityName: "Stats", in: coreDataStack.context)
    
    do {
      let jsonDict = try JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments) as! NSDictionary
      let jsonArray = jsonDict.value(forKeyPath: "response.venues") as! NSArray
      
      for jsonDictionary in jsonArray {
        
        let venueName = jsonDictionary["name"] as? String
        let venuePhone = (jsonDictionary as AnyObject).value(forKeyPath: "contact.phone") as? String
        let specialCount = (jsonDictionary as AnyObject).value(forKeyPath: "specials.count") as? NSNumber
        
        let locationDict = jsonDictionary["location"] as! NSDictionary
        let priceDict = jsonDictionary["price"] as! NSDictionary
        let statsDict = jsonDictionary["stats"] as! NSDictionary
        
        let location = Location(entity: locationEntity!, insertInto: coreDataStack.context)
        location.address = locationDict["address"] as? String
        location.city = locationDict["city"] as? String
        location.state = locationDict["state"] as? String
        location.zipcode = locationDict["postalCode"] as? String
        location.distance = locationDict["distance"] as? NSNumber
        
        let category = Category(entity: categoryEntity!, insertInto: coreDataStack.context)
        
        let priceInfo = PriceInfo(entity: priceEntity!, insertInto: coreDataStack.context)
        priceInfo.priceCategory = priceDict["currency"] as? String
        
        let stats = Stats(entity: statsEntity!, insertInto: coreDataStack.context)
        stats.checkinsCount = statsDict["checkinsCount"] as? NSNumber
        stats.usersCount = statsDict["userCount"] as? NSNumber
        stats.tipCount = statsDict["tipCount"] as? NSNumber
        
        let venue = Venue(entity: venueEntity!, insertInto: coreDataStack.context)
        venue.name = venueName
        venue.phone = venuePhone
        venue.specialCount = specialCount
        venue.location = location
        venue.category = category
        venue.priceInfo = priceInfo
        venue.stats = stats
      }
      
      coreDataStack.saveContext()
    } catch let error as NSError {
      print("Deserialization error: \(error.localizedDescription)")
    }
  }
  
}

