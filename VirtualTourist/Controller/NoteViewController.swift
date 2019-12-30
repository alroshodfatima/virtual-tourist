//
//  NoteViewController.swift
//  VirtualTourist
//
//  Created by Fatimah on 02/05/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import UIKit
import CoreData

class NoteViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var noteTextField: UITextField!
    
    var context: NSManagedObjectContext {
        return DataController.shared.viewContext
    }
    var fetchedResultsController: NSFetchedResultsController<Note>?
    
    override func viewDidLoad() {
        loadData()
        configureTextField(noteTextField)
        let labelText = fetchedResultsController?.fetchedObjects?.first?.text
        if labelText != nil {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        
        imageView.image = UIImage(data: DataController.shared.photo!.image!)
        noteTextField.text = labelText ?? ""
    }
    
    func configureTextField(_ textField: UITextField) {
        textField.delegate = self
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        textField.defaultTextAttributes = [
            .foregroundColor: UIColor.brown,
            .backgroundColor: UIColor.clear,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    func loadData() {
        let fetchRequest:NSFetchRequest<Note> = Note.fetchRequest()
        let predicate = NSPredicate(format: "photo == %@", DataController.shared.photo!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "text", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    @IBAction func addNewNote(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "New", message: "Please enter your comment", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            guard let text = alertController.textFields?.first?.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            self.saveNote(with: text)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addTextField { (field) in
            field.textColor = .red
            field.textAlignment = .center
        }
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func saveNote(with title: String) {
        let note = Note(context: context)
        note.text = title
        note.photo = DataController.shared.photo
        try? context.save()
    }
}

extension NoteViewController:NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.viewDidLoad()
    }
    
}
