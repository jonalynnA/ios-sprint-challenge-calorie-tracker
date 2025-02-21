//
//  ChartTableViewController.swift
//  CalorieTracker
//
//  Created by Jonalynn Masters on 12/20/19.
//  Copyright © 2019 Jonalynn Masters. All rights reserved.
//

import UIKit
import SwiftChart
import CoreData

class ChartTableViewController: UITableViewController {

    // MARK: Outlets
    @IBOutlet var chartView: UIView!
    
    // MARK: Properties
    let calorieController = CalorieController()
    var chart: Chart?
   
    lazy var fetchedRC: NSFetchedResultsController<User> = {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let moodSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "dietLevel", ascending:  false)
        let dateSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "timestamp", ascending:  false)
        fetchRequest.sortDescriptors = [dateSortDescriptor,moodSortDescriptor]
        let moc = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "dietLevel", cacheName: nil)
        frc.delegate = self
        do {
            try frc.performFetch()
        } catch {
            fatalError()
        }
        return frc
    }()
    
    
    // MARK: ViewDidLoad
    override func viewDidLoad() {
        chartSetup()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshChart(notification:)), name: .calorieEntryCreated, object: nil)
    }
   
    // MARK: Action
    @IBAction func addCalorieIntakeTapped(_ sender: UIBarButtonItem) {
        alertViewSetup()
    }

    // MARK: TableViewSetup
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
         return fetchedRC.sections?[section].name.capitalized
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedRC.sections?.count ?? 0
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return fetchedRC.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CaloriesCell", for: indexPath) as? CaloriesTableViewCell else {return UITableViewCell()}
        let user = fetchedRC.object(at: indexPath)
        cell.user = user
        return cell
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let caloriesEntry = fetchedRC.object(at: indexPath)
            calorieController.deleteCalorieEntry(calorieEntry: caloriesEntry)
        }
    }
    
    // MARK: Methods
    private func caloriesEntryCreatedNotificationPost() {NotificationCenter.default.post(.init(name: .calorieEntryCreated))}
    private func alertViewSetup() {
    
    // MARK: UIAlert
        let alert = UIAlertController(title: "Add Calorie Intake", message: "Enter the amount of calories below", preferredStyle: .alert)
    // Textfield
        alert.addTextField { (textfield) in
            textfield.placeholder = "Calories"}
    // Add a submit action to the alert controller with a closure to do the following:
    // Add calories to the user in core data
    // Post a notification to the Notification Center, so an updated chart can be made
    // Reload the tableview
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (submitAction) in
            let textField = alert.textFields![0]
            guard  let caloriesString = textField.text, caloriesString != "",
                let calories = Double(caloriesString) else {return}
            let time = Date()
            self.calorieController.addCaloriesToUser(calories: calories, timeStamp: time)
            self.caloriesEntryCreatedNotificationPost()}
    
    // MARK: Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func refreshChart(notification: Notification) {
        chartSetup()
    }
    
     func chartSetup() {
        chart?.removeFromSuperview()
         chart = Chart(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
         guard let chart = chart else {return}
        guard let calorieEntries = fetchedRC.fetchedObjects else {return}
        var data: [Double] = []
        for calorieEntry in calorieEntries {
            let calories = calorieEntry.calories
            data.append(calories)
        }
        
        let series = ChartSeries(data)
        chart.add(series)
        chartView.addSubview(chart)
        chart.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = chart.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 5)
        let leadingConstraint = chart.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 5)
        let trailingConstraint = chart.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: 5)
        let bottomConstraint = chart.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 5)
        NSLayoutConstraint.activate([topConstraint, leadingConstraint, trailingConstraint, bottomConstraint])
    }
}

extension ChartTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRows(at: [newIndexPath], with: .fade)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.moveRow(at: indexPath, to: newIndexPath)
        case .update:
            guard let indexPath = indexPath else {return}
            tableView.reloadRows(at: [indexPath], with: .fade)
        @unknown default:
            fatalError()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionnIndexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(sectionnIndexSet, with: .fade)
        case .delete:
            tableView.deleteSections(sectionnIndexSet, with: .fade)
        default:
            break
        }
    }
}
