//
// MAPD 714 - Mid Term Exam
//
// App name: Easy List
// Version: 0.01 - Basic prep
// Description: Shopping list application
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
    @IBAction func shoppingListFieldDoneAction(_ sender: UITextField) {
        //
    }
    
    @IBAction func onStepperControlPress(_ sender: UIStepper)  {
        //Action to handle STEPPER press to change list count
    }
    
    @IBAction func onCancelButtonClick(_ sender: UIButton) {
        //Action to reset app to default state
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

