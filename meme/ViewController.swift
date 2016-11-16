//
//  ViewController.swift
//  meme
//
//  Created by ALLAN James on 7/2/16.
//  Copyright © 2016 allanjames. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate ,
 UITextFieldDelegate{
    
  
    @IBOutlet weak var cameraButton: UIBarButtonItem!

    @IBOutlet weak var imageView : UIImageView!

    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var bottomToolBar: UIToolbar!
    
    @IBOutlet weak var topNavBar: UINavigationBar!
    
    
    
    let LABEL_TOP_TEXT:String = "TOP"
    let LABEL_BOTTOM_TEXT:String = "BOTTOM"
    
    var memes: [MemeModel]!
    var initialViewYPosition:CGFloat = 0.0
    var activeTextField : UITextField!
    var selectionType = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeTopBottomTexts(topText,labelText: LABEL_TOP_TEXT)
        initializeTopBottomTexts(bottomText,labelText: LABEL_BOTTOM_TEXT)
        
        //Image will not strech
        
        imageView.contentMode = .ScaleAspectFit
    }

    func initializeTopBottomTexts(textField:UITextField , labelText:String)
    {
        let memeTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSStrokeColorAttributeName : UIColor.blackColor(),
            NSFontAttributeName:UIFont(name:"HelveticaNeue-CondensedBlack",size: 40)!,
            NSStrokeWidthAttributeName:-2.0
        ]
        
        textField.delegate = self
        
        textField.autocapitalizationType = .AllCharacters

        //initialize top and bottom texts
        textField.text  = labelText
        
        //initialize text attributes
        textField.defaultTextAttributes = memeTextAttributes
        
        //text should be center-aligned
        textField.textAlignment = .Center
    }
    @IBAction func pickAnImage(sender: AnyObject) {
        
        print("Button pressed: ", sender.tag)
        selectionType = sender.tag
        
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        
        //1 for camera
        //0 for library
        if (selectionType == 1)
        {
            pickerController.sourceType = UIImagePickerControllerSourceType.Camera

        }
        else if (selectionType == 0)
        {
            pickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary

        }
        
        
        self.presentViewController(pickerController, animated: true, completion:nil)
        
    }
    
    @IBAction func cancelButtonAction(sender: AnyObject) {
        
        imageView.image = nil
        shareButton.enabled=false
        topText.text = LABEL_TOP_TEXT
        bottomText.text = LABEL_BOTTOM_TEXT
        self.activeTextField = nil
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            imageView.image = image
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        memes = appDelegate.memes
        
        initialViewYPosition = imageView.frame.origin.y
        
        //This is avaialble only in actual device and not on simulator
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(.Camera)
        
        //shared button will be avaialble if there is an image
        shareButton.enabled = (imageView.image != nil)
        
        //subscirbed for key borad
        subscribeToKeyboardNotifications()
        
        //Hide tool bar
        self.tabBarController?.tabBar.hidden = true


    }
    
    
    
    
    func textFieldDidEndEditing(textField: UITextField) {
            print("editing ended")
        
        if ( textField == topText && textField.text! == "" ) {
            textField.text = LABEL_TOP_TEXT
        }
        
        if ( textField == bottomText  && textField.text! == "" ) {
            textField.text = LABEL_BOTTOM_TEXT
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
       
        //Ref:http://stackoverflow.com/questions/30918732/how-to-determine-which-textfield-is-active-swift/30918882

        activeTextField = textField

        if (self.activeTextField.text == LABEL_TOP_TEXT)
        {
            topText.text = ""
        }
        
        if (self.activeTextField.text == LABEL_BOTTOM_TEXT)
        {
            bottomText.text = ""
        }
        
    }
    
    
    
    func textFieldShouldReturn(textField: UITextField)-> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func shareButtonAction(sender: AnyObject) {
        
        let memeImage = generateMemedImage()
        let activityController = UIActivityViewController(activityItems: [memeImage], applicationActivities: nil)
        
        presentViewController(activityController , animated: true, completion: nil)
        
        //Ref: http://stackoverflow.com/questions/25644054/uiactivityviewcontroller-crashing-on-ios8-ipads
        activityController.popoverPresentationController?.sourceView = self.view
        
        activityController.completionWithItemsHandler = {
            (activitype , completed: Bool, returnedItems:[AnyObject]?, error: NSError? ) in
            
            if(!completed)
            {
                return
            }
            
            //call save
            self.save()
            
            //dismiss viewcontroller
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        
    }
    // Unsubscribe
    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(animated)
        self.unsubscribeFromKeyboardNotifications()
        
        //Unhide tool Tab bar
        self.tabBarController?.tabBar.hidden = false
    }
    
    func subscribeToKeyboardNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.showKeyBoard(_:)),
                                                         name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.hideKeyboard(_:)),
                                                         name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object:nil)
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    func showKeyBoard(notification:NSNotification)
    {
        if bottomText.isFirstResponder()
        {
            view.frame.origin.y = getKeyboardHeight(notification) * (-1)
        }
    }
    
    func hideKeyboard(notification:NSNotification)
    {
        if bottomText.isFirstResponder()
        {
            self.view.frame.origin.y = 0
        }
    }
    
    func generateMemedImage() -> UIImage
    {
        topNavBar.hidden = true
        bottomToolBar.hidden = true
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        let memeImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        topNavBar.hidden = false
        bottomToolBar.hidden = false
        
        return memeImage
    }
    
    
    func save()
    {
        let meme = MemeModel(topLabel: topText.text!, bottomLabel: bottomText.text!, originalImage: imageView.image!, savedMemeImage: generateMemedImage())
        
        //meme is added to memes array in appdelegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.memes.append(meme)
    }

}

