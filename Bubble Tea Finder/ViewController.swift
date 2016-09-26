//
//  ViewController.swift
//  Bubble Tea Finder
//
//  Created by Pietro Rea on 8/24/14.
//  Copyright (c) 2014 Pietro Rea. All rights reserved.
//

import UIKit
import CoreData

let filterViewControllerSegueIdentifier = "toFilterViewController"
let venueCellIdentifier = "VenueCell"

class ViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  var coreDataStack: CoreDataStack!
    var fetchRequest: NSFetchRequest!
    var venues: [Venue]! = []
    var asyncFetchRequest: NSAsynchronousFetchRequest!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let batchUpdate = NSBatchUpdateRequest(entityName: "Venue")
    
    batchUpdate.propertiesToUpdate = ["favorite" : NSNumber(bool: true)]
    batchUpdate.affectedStores = coreDataStack.context.persistentStoreCoordinator!.persistentStores
    batchUpdate.resultType = .UpdatedObjectsCountResultType
    
    do {
        let batchResult = try coreDataStack.context.executeRequest(batchUpdate) as! NSBatchUpdateResult
        print("Records updated \(batchResult.result!)")
    } catch let error as NSError {
        print("Could not update \(error), \(error.userInfo)")
    }
    
    fetchRequest = NSFetchRequest(entityName: "Venue")
    
    asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { [unowned self] (result: NSAsynchronousFetchResult) -> Void in
        self.venues = result.finalResult as! [Venue]
        self.tableView.reloadData()
    }
    
    do {
        try coreDataStack.context.executeRequest(asyncFetchRequest)
    } catch let error as NSError {
        print("Could not fetch \(error), \(error.userInfo)")
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if segue.identifier == filterViewControllerSegueIdentifier {
        
        let navController = segue.destinationViewController as! UINavigationController
        let filterVC = navController.topViewController as! FilterViewController
        filterVC.coreDataStack = coreDataStack
        filterVC.delegate = self
    }
  }
    
    func fetchAndReload() {
        
        do {
            venues = try coreDataStack.context.executeFetchRequest(fetchRequest) as! [Venue]
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
  
  @IBAction func unwindToVenuListViewController(segue: UIStoryboardSegue) {
    
  }
}

extension ViewController: UITableViewDataSource {
  
  func tableView(tableView: UITableView,
    numberOfRowsInSection section: Int) -> Int {
    return venues.count
  }

  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(venueCellIdentifier)!
    let venue = venues[indexPath.row]
    cell.textLabel!.text = venue.name
    cell.detailTextLabel!.text = venue.priceInfo?.priceCategory
    
    return cell
  }
}

extension ViewController: FilterViewControllerDelegate {
    
    func filterViewController(filter: FilterViewController, didSelectPredicate predicate: NSPredicate?, sortDescriptor: NSSortDescriptor?) {
        
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = nil
        
        if let fetchPredicate = predicate {
            fetchRequest.predicate = fetchPredicate
        }
        
        if let sr = sortDescriptor {
            fetchRequest.sortDescriptors = [sr]
        }
        
        fetchAndReload()
    }
}
