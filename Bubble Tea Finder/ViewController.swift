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
    var fetchRequest: NSFetchRequest<Venue>!
    var venues: [Venue]! = []
    var asyncFetchRequest: NSAsynchronousFetchRequest<Venue>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let batchUpdate = NSBatchUpdateRequest(entityName: "Venue")
    
    batchUpdate.propertiesToUpdate = ["favorite" : NSNumber(value: true as Bool)]
    batchUpdate.affectedStores = coreDataStack.context.persistentStoreCoordinator!.persistentStores
    batchUpdate.resultType = .updatedObjectsCountResultType
    
    do {
        let batchResult = try coreDataStack.context.execute(batchUpdate) as! NSBatchUpdateResult
        print("Records updated \(batchResult.result!)")
    } catch let error as NSError {
        print("Could not update \(error), \(error.userInfo)")
    }
    
    fetchRequest = NSFetchRequest(entityName: "Venue")
    
    asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { [unowned self] (result: NSAsynchronousFetchResult) in
        
        guard let venues = result.finalResult else {
            return
        }
        self.venues = venues
        self.tableView.reloadData()
    }
    
    do {
        try coreDataStack.context.execute(asyncFetchRequest)
    } catch let error as NSError {
        print("Could not fetch \(error), \(error.userInfo)")
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == filterViewControllerSegueIdentifier {
        
        let navController = segue.destination as! UINavigationController
        let filterVC = navController.topViewController as! FilterViewController
        filterVC.coreDataStack = coreDataStack
        filterVC.delegate = self
    }
  }
    
    func fetchAndReload() {
        
        do {
            venues = try coreDataStack.context.fetch(fetchRequest)
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
  
  @IBAction func unwindToVenuListViewController(_ segue: UIStoryboardSegue) {
    
  }
}

extension ViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView,
    numberOfRowsInSection section: Int) -> Int {
    return venues.count
  }

  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: venueCellIdentifier)!
    let venue = venues[(indexPath as NSIndexPath).row]
    cell.textLabel!.text = venue.name
    cell.detailTextLabel!.text = venue.priceInfo?.priceCategory
    
    return cell
  }
}

extension ViewController: FilterViewControllerDelegate {
    
    func filterViewController(_ filter: FilterViewController, didSelectPredicate predicate: NSPredicate?, sortDescriptor: NSSortDescriptor?) {
        
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
