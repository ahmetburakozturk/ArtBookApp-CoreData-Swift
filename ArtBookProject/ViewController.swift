//
//  ViewController.swift
//  ArtBookProject
//
//  Created by ahmetburakozturk on 12.04.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    @IBOutlet weak var mainTableView: UITableView!
    
    
    var nameArray = [String]()
    var idArray = [UUID]()
    
    var selectedArt = ""
    var selectedArtId : UUID?
    
    var appDelegate : AppDelegate?
    var context : NSManagedObjectContext?
    var fetchrequest : NSFetchRequest<NSFetchRequestResult>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(goDetailsVC))
        
        mainTableView.dataSource = self
        mainTableView.delegate = self
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        context = appDelegate!.persistentContainer.viewContext
        fetchrequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Arts");
        fetchrequest!.returnsObjectsAsFaults = false
        
        getValuesCoreData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getValuesCoreData), name: NSNotification.Name("newDataAdded"), object: nil)
    }
    
    @objc func getValuesCoreData(){
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        

        
        do{
            let results = try context!.fetch(fetchrequest!)
            
            for result in results as! [NSManagedObject]{
                if let name = result.value(forKey: "name") as? String{
                    nameArray.append(name)
                }
                if let id = result.value(forKey: "id") as? UUID{
                    idArray.append(id)
                }
            }
            self.mainTableView.reloadData()
            
        }
        catch{
            print("Values could not get from core data!")
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = nameArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    
    @objc func goDetailsVC(){
        selectedArt = ""
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailVC" {
            let destination = segue.destination as! DetailViewController
            destination.selectedArt = selectedArt
            destination.selectedArtId = selectedArtId
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedArt = nameArray[indexPath.row]
        selectedArtId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            
            let choosenId = idArray[indexPath.row].uuidString
            fetchrequest?.predicate = NSPredicate(format: "id = %@", choosenId)
            
            do{
                let results = try context!.fetch(fetchrequest!)
                if results.count>0 {
                    for result in results as! [NSManagedObject]{
                        if idArray[indexPath.row] == result.value(forKey: "id") as? UUID{
                            context?.delete(result)
                            idArray.remove(at: indexPath.row)
                            nameArray.remove(at: indexPath.row)
                            mainTableView.reloadData()
                            
                            do{
                                try context?.save()
                            }catch{
                                print("error")
                            }
                            break
                        }
                    }
                }
            }
            catch{
                print("error")
            }
            
        }
    }

}

