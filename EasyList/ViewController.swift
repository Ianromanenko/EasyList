//
// MAPD 714 - Mid Term Exam
//
// App name: Easy List
// Version: 0.04 - Tidy up comments
// Description: Shopping list application
// Date: Dec 6 2017
// Collaborators: 300964200 - Viktor Bilyk
//                300965775 - Timofei Sopin
//                300965052 - Yan Romanenko

import UIKit

class ViewController: UIViewController {
    
    //OUTLETS
    @IBOutlet weak var shoppingListName: UITextField!
    @IBOutlet weak var shoppingListItem1: UITextField!
    @IBOutlet weak var shoppingListItem2: UITextField!
    @IBOutlet weak var shoppingListItem3: UITextField!
    @IBOutlet weak var shoppingListItem4: UITextField!
    @IBOutlet weak var shoppingListItem5: UITextField!
    
    @IBOutlet weak var shoppingListItem1CountLabel: UILabel!
    @IBOutlet weak var shoppingListItem2CountLabel: UILabel!
    @IBOutlet weak var shoppingListItem3CountLabel: UILabel!
    @IBOutlet weak var shoppingListItem4CountLabel: UILabel!
    @IBOutlet weak var shoppingListItem5CountLabel: UILabel!
    
    //Variables to store information
    var shoppingListItem1Value: Int = 0
    var shoppingListItem2Value: Int = 0
    var shoppingListItem3Value: Int = 0
    var shoppingListItem4Value: Int = 0
    var shoppingListItem5Value: Int = 0


    
    //ACTION METHODS
    
    func shoppingItemCountChange (itemNumber: Int, operation: Bool) {
        // changing quantity of shopping item
        
        switch itemNumber {
        case 1: //item 1
            if operation {
                //PLUS SELECTED
                shoppingListItem1Value = shoppingListItem1Value + 1
            }
            else {
                //MINUS SELECTED
                if (shoppingListItem1Value - 1) >= 0 {
                    shoppingListItem1Value = shoppingListItem1Value - 1
                }
                
            }
            shoppingListItem1CountLabel.text = ": " + String(shoppingListItem1Value) //display changed count in UI
        case 2: //item 2
            if operation {
                //PLUS SELECTED
                shoppingListItem2Value = shoppingListItem2Value + 1
            }
            else {
                //MINUS SELECTED
                if (shoppingListItem2Value - 1) >= 0 {
                    shoppingListItem2Value = shoppingListItem2Value - 1
                }
                
            }
            shoppingListItem2CountLabel.text = ": " + String(shoppingListItem2Value) //display changed count in UI
        case 3: //item 3
            if operation {
                //PLUS SELECTED
                shoppingListItem3Value = shoppingListItem3Value + 1
            }
            else {
                //MINUS SELECTED
                if (shoppingListItem3Value - 1) >= 0 {
                    shoppingListItem3Value = shoppingListItem3Value - 1
                }
                
            }
            shoppingListItem3CountLabel.text = ": " + String(shoppingListItem3Value) //display changed count in UI
        case 4: //item 4
            if operation {
                //PLUS SELECTED
                shoppingListItem4Value = shoppingListItem4Value + 1
            }
            else {
                //MINUS SELECTED
                if (shoppingListItem4Value - 1) >= 0 {
                    shoppingListItem4Value = shoppingListItem4Value - 1
                }
                
            }
            shoppingListItem4CountLabel.text = ": " + String(shoppingListItem4Value) //display changed count in UI
        case 5: //item 5
            if operation {
                //PLUS SELECTED
                shoppingListItem5Value = shoppingListItem5Value + 1
            }
            else {
                //MINUS SELECTED
                if (shoppingListItem5Value - 1) >= 0 {
                    shoppingListItem5Value = shoppingListItem5Value - 1
                }
                
            }
            shoppingListItem5CountLabel.text = ": " + String(shoppingListItem5Value) //display changed count in UI
        default: break
        }
       
    }
    
    @IBAction func shoppingListFieldDoneAction(_ sender: UITextField) {
        //
        sender.resignFirstResponder()
    }
    
    @IBAction func onTapGestureRecognized(_ sender: AnyObject) {
        //
        shoppingListItem1.resignFirstResponder()
        shoppingListItem2.resignFirstResponder()
        shoppingListItem3.resignFirstResponder()
        shoppingListItem4.resignFirstResponder()
        shoppingListItem5.resignFirstResponder()
        shoppingListName.resignFirstResponder()
    }
    
    @IBAction func onStepperControlPress(_ sender: UIStepper)  {
        //Action to handle STEPPER press to change list count
        
        switch sender.value {
        case 0: //minus button pressed
            shoppingItemCountChange(itemNumber: sender.tag, operation: false)
        case 2: //plus button pressed
            shoppingItemCountChange(itemNumber: sender.tag, operation: true)
        default:
            break
        }
        sender.value = 1 //reset stepper state to default
    }
    
    @IBAction func onCancelButtonClick(_ sender: UIButton) {
        //Action to reset app to default state
        
        //Item count
        shoppingListItem1Value = 0
        shoppingListItem2Value = 0
        shoppingListItem3Value = 0
        shoppingListItem4Value = 0
        shoppingListItem5Value = 0
        
        //Item label count for UI
        shoppingListItem1CountLabel.text = "0"
        shoppingListItem2CountLabel.text = "0"
        shoppingListItem3CountLabel.text = "0"
        shoppingListItem4CountLabel.text = "0"
        shoppingListItem5CountLabel.text = "0"
        
        //Item names
        shoppingListItem1.text = " "
        shoppingListItem2.text = " "
        shoppingListItem3.text = " "
        shoppingListItem4.text = " "
        shoppingListItem5.text = " "
        shoppingListName.text = " "
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //default values
        
        //Item names
        shoppingListItem1.text = " "
        shoppingListItem2.text = " "
        shoppingListItem3.text = " "
        shoppingListItem4.text = " "
        shoppingListItem5.text = " "
        shoppingListName.text = " "
        
        //Item label count for UI
        shoppingListItem1CountLabel.text = "0"
        shoppingListItem2CountLabel.text = "0"
        shoppingListItem3CountLabel.text = "0"
        shoppingListItem4CountLabel.text = "0"
        shoppingListItem5CountLabel.text = "0"
        
        //Item count
        shoppingListItem1Value = 0
        shoppingListItem2Value = 0
        shoppingListItem3Value = 0
        shoppingListItem4Value = 0
        shoppingListItem5Value = 0
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

