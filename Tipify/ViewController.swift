//
//  ViewController.swift
//  Tipify
//
//  Created by Sujith Vishwajith on 10/16/15.
//  Copyright © 2015 Sujith Vishwajith. All rights reserved.
//

import UIKit
import CoreText
import MessageUI
import AssetsLibrary

class ViewController: UIViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, NumericKeypadDelegate {
    @IBOutlet weak var numericKeypadView: NumericKeypadView!
    @IBOutlet weak var billCostTextLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var centerLineConstraint: NSLayoutConstraint!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var percent15Label: UIButton!
    @IBOutlet weak var percent20Label: UIButton!
    @IBOutlet weak var percent10Label: UIButton!
    @IBOutlet weak var per10line: UIImageView!
    @IBOutlet weak var per15line: UIImageView!
    @IBOutlet weak var per20line: UIImageView!
    @IBOutlet weak var partySizeLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    @IBOutlet weak var aboutView: DesignableView!
    @IBOutlet weak var heightLayout: NSLayoutConstraint!
    
    var keypadString = ""
    var billedAmount : Decimal = Decimal(0)
    var currentRate : Decimal = Settings.tippingRate.toDecimal()
    var currentTip : Tip = Tip()
    var currencyFormatter = NSNumberFormatter()
    var percentageFormatter = NSNumberFormatter()
    
    var requestCurrencyFormatter = NSNumberFormatter()
    var requestingMoney = false
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.`
        
        let screenSize : Style.ScreenSize = .Normal
        
        numericKeypadView.gridView.gridColor = Style.dividingLineColor
        numericKeypadView.keyPadTextColor = Style.textColor
        numericKeypadView.keyPadHighlightColor = Style.keypadHighlightColor
        numericKeypadView.setLabelFonts(Style.keypadLabelFonts[screenSize]!, clearFont: Style.keypadSmallLabelFonts[screenSize]!)
        numericKeypadView.setClearLabelInset(UIEdgeInsetsMake(-1.0, 0, 0.0, 0))
        numericKeypadView.setBackspaceLabelInset(UIEdgeInsetsMake(-1.0, 0, 0.0, 0))
        numericKeypadView.delegate = self
        
        stepper.value = 2
        stepper.autorepeat = true
        stepper.maximumValue = 10
        stepper.minimumValue = 1
        
        per10line.hidden = true
        per15line.hidden = false
        per20line.hidden = true
        aboutView.hidden = true
        partySizeLabel.text = "2"
        
        var rate : Settings.TippingRate
        rate = .Tip15Percent
        Settings.tippingRate = rate
        currentRate = rate.toDecimal()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateFormatters()
        update()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    func update() {
        if keypadString.isEmpty {
            billedAmount = Decimal(0)
        } else {
            billedAmount = Decimal(keypadString) / Decimal("100")
        }
        
        if billedAmount < Decimal("1.00") {
            payButton.enabled = false
        } else {
            payButton.enabled = true
        }
        
        billCostTextLabel.text = billedAmount.string(currencyFormatter)
        currentTip = bestTip(billedAmount, rate: currentRate)
        tipLabel.text = currentTip.tip.string(currencyFormatter)
        tipLabel.accessibilityLabel = String(format: Utilities.L("Tips: %@"), tipLabel.text!)
        totalLabel.text = currentTip.total.string(currencyFormatter)
        totalLabel.accessibilityLabel = String(format: Utilities.L("Total: %@"), totalLabel.text!)
        
        let rate = currentTip.effectiveRate
        if rate == Decimal(0) {
            percentLabel.text = "–"
            percentLabel.accessibilityLabel = Utilities.L("No effective rate")
        } else {
            percentLabel.text = currentTip.effectiveRate.string(percentageFormatter)
            percentLabel.accessibilityLabel = String(format: Utilities.L("Effective Rate: %@"), percentLabel.text!)
        }
    }

    func numberTapped(number: Int) {
        if number == 0 && keypadString.isEmpty {
            return
        }
        
        if keypadString.characters.count < 6 {
            keypadString = keypadString + String(format: "%d", number)
            update()
        }
    }
    
    func backspaceTapped() {
        if !keypadString.isEmpty {
            keypadString = keypadString.substringToIndex(keypadString.endIndex.predecessor())
            update()
        }
    }

    func clearTapped() {
        keypadString = ""
        update()
    }

    @IBAction func percent15(sender: AnyObject) {
        per10line.hidden = true
        per15line.hidden = false
        per20line.hidden = true
        var rate : Settings.TippingRate
        rate = .Tip15Percent
        Settings.tippingRate = rate
        currentRate = rate.toDecimal()
        update()
    }
    
    @IBAction func percent10(sender: AnyObject) {
        per10line.hidden = false
        per15line.hidden = true
        per20line.hidden = true
        var rate : Settings.TippingRate
        rate = .Tip10Percent
        Settings.tippingRate = rate
        currentRate = rate.toDecimal()
        update()
    }
    
    @IBAction func percent20(sender: AnyObject) {
        per10line.hidden = true
        per15line.hidden = true
        per20line.hidden = false
        var rate : Settings.TippingRate
        rate = .Tip20Percent
        Settings.tippingRate = rate
        currentRate = rate.toDecimal()
        update()
    }
    
    @IBAction func payButton(sender: AnyObject) {
        let sheet = UIAlertController(title: Utilities.L("Split with Square® Cash?\nYou can adjust the amount later."), message: nil, preferredStyle: .ActionSheet)
        
        let amount = (currentTip.total / Decimal(partySizeLabel.text!)).string(requestCurrencyFormatter)
        let requestTitle = String(format: Utilities.L("Request %@"), amount)
        let payTitle = String(format: Utilities.L("Pay %@"), amount)
        
        let requestAction = UIAlertAction(title: requestTitle, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.requestingMoney = true
            self.payReqeuestAction()
        })
        let payAction = UIAlertAction(title: payTitle, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.requestingMoney = false
            self.payReqeuestAction()
        })
        let cancelAction = UIAlertAction(title: Utilities.L("Cancel"), style: .Cancel, handler: nil)
        
        sheet.addAction(payAction)
        sheet.addAction(requestAction)
        sheet.addAction(cancelAction)
        presentViewController(sheet, animated: true, completion: nil)
    }
    
    func payReqeuestAction() {
        let splitAmount = (currentTip.total / Decimal(partySizeLabel.text!)).string(requestCurrencyFormatter)
        
        let addr =  requestingMoney ? "request@square.com" : "cash@square.com"
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = self
        controller.setSubject(splitAmount)
        controller.setCcRecipients([addr])
        presentViewController(controller, animated: true, completion: {})
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: {})
        
        if result.rawValue == MFMailComposeResultSent.rawValue {
            let title = Utilities.L("Check Your Email")
            let message : String
            if requestingMoney {
                message = Utilities.L("You will receive an email from Square® to confirm your request.")
            } else {
                message = Utilities.L("You will receive an email from Square® to confirm your payment.")
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let action = UIAlertAction(title: Utilities.L("Dismiss"), style: .Default, handler: nil)
            alert.addAction(action)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func currentLocaleDidChange(notification: NSNotification!) {
        updateFormatters()
        update()
    }
    
    func updateFormatters() {
        var locale : NSLocale? = nil
        if Settings.boolForKey(Settings.UseDecimalPointKey) {
            locale = NSLocale(localeIdentifier: "en-us")
        }
        
        currencyFormatter.numberStyle = .DecimalStyle
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.locale = locale
        
        percentageFormatter.numberStyle = .PercentStyle
        percentageFormatter.roundingMode = .RoundHalfUp
        percentageFormatter.minimumFractionDigits = 1
        percentageFormatter.locale = locale
        
        let requestLocale = NSLocale(localeIdentifier: "en-us")
        requestCurrencyFormatter.numberStyle = .CurrencyStyle
        requestCurrencyFormatter.minimumFractionDigits = 2
        requestCurrencyFormatter.locale = requestLocale
    }
    
    @IBAction func infoButton(sender: AnyObject) {
        aboutView.hidden = false
        aboutView.animation = "fadeIn"
        aboutView.animate()
    }
    
    @IBAction func closeButton(sender: AnyObject) {
        aboutView.animation = "fadeOut"
        aboutView.animate()
    }
    
    @IBAction func stepperIncrement(sender: AnyObject) {
        partySizeLabel.text = "\(Int(stepper.value))"
    }
    
}

