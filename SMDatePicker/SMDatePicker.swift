//
//  SMDatePicker.swift
//  Countapp
//
//  Created by Anatoliy Voropay on 5/12/15.
//  Copyright (c) 2015 Smartarium.com. All rights reserved.
//

import UIKit

@objc public protocol SMDatePickerDelegate: class {
    
    @objc optional func datePickerWillAppear(_ picker: SMDatePicker)
    @objc optional func datePickerDidAppear(_ picker: SMDatePicker)
    
    @objc optional func datePicker(_ picker: SMDatePicker, didPickDate date: Date)
    @objc optional func datePicker(_ picker: SMDatePicker, didPickDate date: Date, score: String)
    @objc optional func datePickerDidCancel(_ picker: SMDatePicker)
    
    @objc optional func datePickerWillDisappear(_ picker: SMDatePicker)
    @objc optional func datePickerDidDisappear(_ picker: SMDatePicker)
    
}

@objc open class SMDatePicker: UIView {
    /// Score
    public typealias Score = (title: String, value: String)
    open var scores: [Score] {
        get {
            return _scores
        }
        set {
            _scores = newValue
        }
    }
    /// UI mode
    public enum Mode {
        case `default`
        case score
    }
    open var mode: Mode = .default
    
    /// Picker's delegate that conforms to SMDatePickerDelegate protocol
    open weak var delegate: SMDatePickerDelegate?
    
    /// UIToolbar title
    open var title: String?
    open var titleFont: UIFont = UIFont.systemFont(ofSize: 13)
    open var titleColor: UIColor = UIColor.gray
    
    /// You can define your own toolbar height. By default it's 44 pixels.
    open var toolbarHeight: CGFloat = 44.0
    
    /// Specify different UIDatePicker mode. By default it's UIDatePickerMode.DateAndTime
    open var pickerMode: UIDatePickerMode = UIDatePickerMode.dateAndTime {
        didSet { picker.datePickerMode = pickerMode }
    }
    
    /// You can set up different color for picker and toolbar.
    open var toolbarBackgroundColor: UIColor? {
        didSet {
            toolbar.backgroundColor = toolbarBackgroundColor
            toolbar.barTintColor = toolbarBackgroundColor
        }
    }
    
    /// You can set up different color for picker and toolbar.
    open var pickerBackgroundColor: UIColor? {
        didSet { picker.backgroundColor = pickerBackgroundColor }
    }
    
    /// Initial picker's date
    open var pickerDate: Date = Date() {
        didSet { picker.date = pickerDate }
    }
    
    open var minuteInterval: Int {
        set {
            picker.minuteInterval = newValue
        }
        get {
            return picker.minuteInterval
        }
    }
    
    /// Minimum date selectable
    open var minimumDate: Date? {
        set {
            picker.minimumDate = newValue
        }
        get {
            return picker.minimumDate
        }
    }
    
    /// Maximum date selectable
    open var maximumDate: Date? {
        set {
            picker.maximumDate = newValue
        }
        get {
            return picker.maximumDate
        }
    }
    
    /// Array of UIBarButtonItem's that will be placed on left side of UIToolbar. By default it has only 'Cancel' bytton.
    open var leftButtons: [UIBarButtonItem] = []
    
    /// Array of UIBarButtonItem's that will be placed on right side of UIToolbar. By default it has only 'Done' bytton.
    open var rightButtons: [UIBarButtonItem] = []
    
    // Privates
    
    fileprivate var toolbar: UIToolbar = UIToolbar()
    fileprivate var picker: UIDatePicker = UIDatePicker()
    fileprivate var scorePicker = UIPickerView()
    
    // MARK: Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        
        addSubview(picker)
        addSubview(toolbar)
        
        setupDefaultButtons()
        customize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        addSubview(picker)
        addSubview(toolbar)
        
        setupDefaultButtons()
        customize()
    }
    
    // MARK: Customization
    
    fileprivate func setupDefaultButtons() {
        let doneButton = UIBarButtonItem(title: "Done",
            style: UIBarButtonItemStyle.plain,
            target: self,
            action: #selector(SMDatePicker.pressedDone(_:)))

        let cancelButton = UIBarButtonItem(title: "Cancel",
            style: UIBarButtonItemStyle.plain,
            target: self,
            action: #selector(SMDatePicker.pressedCancel(_:)))
        
        leftButtons = [ cancelButton ]
        rightButtons = [ doneButton ]
    }
    
    fileprivate func customize() {
        toolbar.barStyle = UIBarStyle.blackTranslucent
        toolbar.isTranslucent = false
        
        backgroundColor = UIColor.white
        
        if let toolbarBackgroundColor = toolbarBackgroundColor {
            toolbar.backgroundColor = toolbarBackgroundColor
        } else {
            toolbar.backgroundColor = backgroundColor
        }
        
        if let pickerBackgroundColor = pickerBackgroundColor {
            picker.backgroundColor = pickerBackgroundColor
        } else {
            picker.backgroundColor = backgroundColor
        }
        
        scorePicker.dataSource = self
        scorePicker.delegate = self
    }
    
    fileprivate func toolbarItems() -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []
        
        for button in leftButtons {
            items.append(button)
        }
        
        if let title = toolbarTitle() {
            let spaceLeft = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            let spaceRight = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            let titleItem = UIBarButtonItem(customView: title)
            
            items.append(spaceLeft)
            items.append(titleItem)
            items.append(spaceRight)
        } else {
            let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            items.append(space)
        }
        
        for button in rightButtons {
            items.append(button)
        }
        
        return items
    }
    
    fileprivate func toolbarTitle() -> UILabel? {
        if let title = title {
            let label = UILabel()
            label.text = title
            label.font = titleFont
            label.textColor = titleColor
            label.sizeToFit()
            
            return label
        }
        
        return nil
    }
    
    // MARK: Showing and hiding picker
    
    /// Shows picker in view with animation if it's required.
    ///
    /// - Parameter view: is a UIView where we want to show our picker
    /// - Parameter animated: will show with animation if it's true
    open func showPickerInView(_ view: UIView, animated: Bool) {
        if mode == .score {
            rightButtons.first?.title = "Next"
        }
        toolbar.items = toolbarItems()
        
        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: toolbarHeight)
        picker.frame = CGRect(x: 0, y: toolbarHeight, width: view.frame.size.width, height: picker.frame.size.height)
        self.frame = CGRect(x: 0, y: view.frame.size.height - picker.frame.size.height - toolbar.frame.size.height,
            width: view.frame.size.width, height: picker.frame.size.height + toolbar.frame.size.height)

        view.addSubview(self)
        becomeFirstResponder()
        
        showPickerAnimation(animated)
    }
    
    /// Hide visible picker animated.
    ///
    /// - Parameter animated: will hide with animation if `true`
    open func hidePicker(_ animated: Bool) {
        hidePickerAnimation(true)
    }
    
    // MARK: Animation
    
    fileprivate func hidePickerAnimation(_ animated: Bool) {
        delegate?.datePickerWillDisappear?(self)
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.frame = self.frame.offsetBy(dx: 0, dy: self.picker.frame.size.height + self.toolbar.frame.size.height)
            }, completion: { (finished) -> Void in
                self.delegate?.datePickerDidDisappear?(self)
            }) 
        } else {
            self.frame = self.frame.offsetBy(dx: 0, dy: self.picker.frame.size.height + self.toolbar.frame.size.height)
            delegate?.datePickerDidDisappear?(self)
        }
    }
    
    fileprivate func showPickerAnimation(_ animated: Bool) {
        delegate?.datePickerWillAppear?(self)
        
        if animated {
            self.frame = self.frame.offsetBy(dx: 0, dy: self.frame.size.height)
            
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.frame = self.frame.offsetBy(dx: 0, dy: -1 * self.frame.size.height)
            }, completion: { (finished) -> Void in
                self.delegate?.datePickerDidAppear?(self)
            }) 
        } else {
            delegate?.datePickerDidAppear?(self)
        }
    }
    
    // MARK: Actions
    
    /// Default Done action for picker. It will hide picker with animation and call's delegate datePicker(:didPickDate) method.
    open func pressedDone(_ sender: AnyObject) {
        switch mode {
        case .default:
            hidePickerAnimation(true)
            delegate?.datePicker?(self, didPickDate: picker.date)
        case .score:
            if picker.isHidden {
                hidePickerAnimation(true)
                delegate?.datePicker?(self, didPickDate: picker.date, score: scorePicker.score)
            } else {
                picker.isHidden = true
                scorePicker.frame = picker.frame
                addSubview(scorePicker)
                rightButtons.first?.title = "Done"
            }
        }
    }
    
    /// Default Cancel actions for picker.
    open func pressedCancel(_ sender: AnyObject) {
        hidePickerAnimation(true)
        
        delegate?.datePickerDidCancel?(self)
    }
}

extension SMDatePicker: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return scores.count
    }
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return scores[row].title
    }
}

fileprivate var _scores: [SMDatePicker.Score] = []
fileprivate extension UIPickerView {
    var score: String {
        guard !_scores.isEmpty else { return "" }
        return _scores[selectedRow(inComponent: 0)].value
    }
}
