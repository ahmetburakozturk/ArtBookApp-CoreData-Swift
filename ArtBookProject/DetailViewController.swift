//
//  DetailsViewController.swift
//  ArtBookProject
//
//  Created by ahmetburakozturk on 12.04.2023.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var artistTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var savebutton: UIButton!
    
    var alert = UIAlertController()
    var alertTryAgainButton = UIAlertAction()
    var alertOkButton = UIAlertAction()
    
    var selectedArt = ""
    var selectedArtId : UUID?
    
    var appDelegate : AppDelegate?
    var context : NSManagedObjectContext?
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        
        artImageView.isUserInteractionEnabled = true
        let imagePickGesture = UITapGestureRecognizer(target: self, action: #selector(selectPhoto))
        artImageView.addGestureRecognizer(imagePickGesture)

        alert = UIAlertController(title: "Default", message: "Default", preferredStyle: UIAlertController.Style.alert)
        alertTryAgainButton = UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default)
        alertOkButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) {(UIAlertAction) in
            self.navigationController?.popViewController(animated: true)
        }
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        context = appDelegate!.persistentContainer.viewContext
        
        if selectedArt != "" {
            getChoosenArtFromCoreData()
            savebutton.isHidden = true
            savebutton.isEnabled = false
            nameTextField.isEnabled = false
            nameTextField.borderStyle = .none
            artistTextField.isEnabled = false
            artistTextField.borderStyle = .none
            yearTextField.isEnabled = false
            yearTextField.borderStyle = .none
            editButton.isHidden = false
        }
        else {
            savebutton.isEnabled = false
            editButton.isHidden = true
        }
    }
    

    func getChoosenArtFromCoreData (){
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Arts")
        let artId = selectedArtId?.uuidString
        fetchRequest.predicate = NSPredicate(format: "id = %@", artId!)
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context!.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject]{
                    if let name = result.value(forKey: "name") as? String{
                        nameTextField.text = name
                    }
                    if let artist = result.value(forKey: "artist") as? String{
                        artistTextField.text = artist
                    }
                    if let year = result.value(forKey: "year") as? Int{
                        yearTextField.text = String(year)
                    }
                    if let data = result.value(forKey: "image") as? Data{
                        let image = UIImage(data: data)
                        artImageView.image = image
                    }
                }
            }
        }
        catch{
            print("error")
        }
    }
    
    @objc func selectPhoto(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info :[UIImagePickerController.InfoKey : Any]){
        artImageView.image = info[.originalImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
        savebutton.isEnabled = true
    }
    

    @IBAction func onSaveButtonClicked(_ sender: Any) {
        
        if selectedArt != ""{
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Arts")
            let artId = selectedArtId?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", artId!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context!.fetch(fetchRequest)
                if results.count>0 {
                    for result in results as! [NSManagedObject]{
                        result.setValue(nameTextField.text, forKey: "name")
                        result.setValue(artistTextField.text, forKey: "artist")
                        if let year = Int(yearTextField.text!){
                            result.setValue(year, forKey: "year")
                        }
                        let imageData = artImageView.image?.jpegData(compressionQuality: 0.5)
                        result.setValue(imageData, forKey: "image")
                        result.setValue(UUID(), forKey: "id")
                            do{
                                try context?.save()
                            }catch{
                                print("error")
                            }
                            break
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name("newDataAdded"), object: nil)
                ShowAlertSuccess(message: "Updated Successfully")
            }
            catch{
                print("error")
            }
        }else{
            let artsTable = NSEntityDescription.insertNewObject(forEntityName: "Arts", into: context!)
            artsTable.setValue(nameTextField.text, forKey: "name")
            artsTable.setValue(artistTextField.text, forKey: "artist")
            if let year = Int(yearTextField.text!){
                artsTable.setValue(year, forKey: "year")
            }
            let imageData = artImageView.image?.jpegData(compressionQuality: 0.5)
            artsTable.setValue(imageData, forKey: "image")
            artsTable.setValue(UUID(), forKey: "id")
            
            do{
                try context!.save()
                NotificationCenter.default.post(name: NSNotification.Name("newDataAdded"), object: nil)
                self.navigationController?.popViewController(animated: true)
            }
                catch{
                    ShowAlertError(message: "Data Could Not Saved!")
            }
        }
        
    }
    
    @objc func HideKeyboard(){
        view.endEditing(true)
    }
    
    
    func ShowAlertError(message: String){
        alert.title = "Error"
        alert.message = message
        alert.addAction(alertTryAgainButton)
        self.present(alert, animated: true)
    }
    
    func ShowAlertSuccess(message: String){
        alert.title = "Success"
        alert.message = message
        alert.addAction(alertOkButton)
        self.present(alert, animated: true)
    }
    
    
    @IBAction func editButtonClicked(_ sender: Any) {
        savebutton.isHidden = false
        savebutton.isEnabled = true
        nameTextField.isEnabled = true
        nameTextField.borderStyle = .roundedRect
        artistTextField.isEnabled = true
        artistTextField.borderStyle = .roundedRect
        yearTextField.isEnabled = true
        yearTextField.borderStyle = .roundedRect
        editButton.isHidden = true
    }
}
