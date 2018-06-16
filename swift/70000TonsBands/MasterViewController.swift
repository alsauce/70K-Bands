//
//  MasterViewController.swift
//  70000TonsBands
//
//  Created by Ron Dorn on 1/2/15.
//  Copyright (c) 2015 Ron Dorn. All rights reserved.
//

import UIKit
import CoreData


class MasterViewController: UITableViewController, UISplitViewControllerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var titleButton: UINavigationItem!

    @IBOutlet weak var preferenceButton: UIBarButtonItem!
    @IBOutlet weak var mustSeeButton: UIButton!
    @IBOutlet weak var mightSeeButton: UIButton!
    @IBOutlet weak var willNotSeeButton: UIButton!
    @IBOutlet weak var wontSeeButton: UIButton!
    @IBOutlet weak var unknownButton: UIButton!
    
    @IBOutlet weak var Undefined: UIButton!

    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    @IBOutlet weak var contentController: UIView!
    @IBOutlet weak var scheduleButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var blankScreenActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var backgroundColor = UIColor.white;
    var textColor = UIColor.black;
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    var objects = NSMutableArray()
    var bands =  [String]()
    var bandsByTime = [String]()
    var bandsByName = [String]()
    var reloadTableBool = true
    
    @IBOutlet weak var titleLabel: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sortedBy = "time"
        
        //self.view.backgroundColor = UIColor.black;
        self.tableView.backgroundColor = backgroundColor;
        
        //have a reference to this controller for external refreshes
        masterView = self;
        
        // Do any additional setup after loading the view, typically from a nib.
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        
        blankScreenActivityIndicator.hidesWhenStopped = true
        
        //icloud change notification
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(MasterViewController.onSettingsChanged(_:)),
                                                         name: UserDefaults.didChangeNotification ,
                                                         object: nil)
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(MasterViewController.showReceivedMessage(_:)),
                                                         name: UserDefaults.didChangeNotification, object: nil)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MasterViewController.refreshData), for: UIControlEvents.valueChanged)
        self.refreshControl = refreshControl

        scheduleButton.setTitle(getBandIconSort(), for: UIControlState())
        
        readFiltersFile()
        setFilterButtons()
        refreshData()
        
        UserDefaults.standard.didChangeValue(forKey: "mustSeeAlert")
        
        NotificationCenter.default.addObserver(self, selector: #selector(MasterViewController.refreshDisplayAfterWake), name: NSNotification.Name(rawValue: "RefreshDisplay"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector:#selector(MasterViewController.refreshAlerts), name: UserDefaults.didChangeNotification, object: nil)
        
        if (eventCount != 0 && sortedBy == "name"){
            sortedBy = "time";
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        print ("The viewWillAppear was called");
        super.viewWillAppear(animated)
        refreshData()
        tableView.reloadData()
    }

    @IBAction func titleButtonAction(_ sender: AnyObject) {
        self.tableView.contentOffset = CGPoint(x: 0, y: 0 - self.tableView.contentInset.top);
    }
    
    @IBAction func menuButtonAction(_ sender: AnyObject) {

        let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "sortMenuNavigation")
        let window = UIApplication.shared.windows[0] as UIWindow
        UIView.transition(
            from: window.rootViewController!.view,
            to: secondViewController!.view,
            duration: 0.65,
            options: .transitionCrossDissolve,
            completion: {
                finished in window.rootViewController = secondViewController
        })
        
    }
    
    
    func showReceivedMessage(_ notification: Notification) {
        //print ("SendingAlert! recieved notification!! \(notification)")
        if let info = notification.userInfo as? Dictionary<String,AnyObject> {
            if let aps = info["aps"] as? Dictionary<String, String> {
                showAlert("Message received", message: aps["alert"]!)
            }
        } else {
            print("Software failure. Guru meditation.")
        }
    }
    
    func showAlert(_ title:String, message:String) {

            let alert = UIAlertController(title: title,
                                          message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)

    }
    
    func setFilterButtons(){
        
        print ("Status of getWontSeeOn = \(getWontSeeOn())")
        if (getMustSeeOn() == false){
            print ("Setting image to alt")
            mustSeeButton.setImage(UIImage(named: "mustSeeIconAlt"), for: UIControlState())
        }
        if (getMightSeeOn() == false){
            mightSeeButton.setImage(UIImage(named: "mightSeeIconAlt"), for: UIControlState())
        }
        if (getWontSeeOn() == false){
            wontSeeButton.setImage(UIImage(named: "willNotSeeAlt"), for: UIControlState())
        }
        if (getUnknownSeeOn() == false){
            unknownButton.setImage(UIImage(named: "unknownAlt"), for: UIControlState())
        }
    }
    
    func refreshDisplayAfterWake(){
        
        if (sortedBy == "time"){
            refreshFromCache()
            self.tableView.reloadData()
        } else {
            refreshData()
        }
    }
    
    func refreshAlerts(){
        if (isAlertGenerationRunning == false){
            
            isAlertGenerationRunning = true
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                if #available(iOS 10.0, *) {
                    let localNotication = localNoticationHandler()
                    localNotication.addNotifications()
                } else {
                    // Fallback on earlier versions
                }
                isAlertGenerationRunning = false
            }
        }
    }
    
    func refreshFromCache (){
        
        bands =  [String]()
        bandsByName = [String]()
        readBandFile()
        schedule.populateSchedule()
        bands = getFilteredBands(getBandNames(), schedule: schedule, sortedBy: sortedBy)
        bandsByName = bands
        
    }
    
    func ensureCorrectSorting(){
        
        if (eventCount == 0){
            print("Schedule is empty, stay hidden")
            self.scheduleButton.isHidden = true;
            sortedBy = "name"
            self.scheduleButton.setTitle(getScheduleIcon(), for: UIControlState())
            
        } else if (sortedBy == "name"){
            print("Sort By is Name, Show")
            self.scheduleButton.isHidden = false;
            self.scheduleButton.setTitle(getScheduleIcon(), for: UIControlState())
            
        } else {
            sortedBy = "time"
            print("Sort By is Time, Show")
            //self.sortBandsByTime()
            self.scheduleButton.isHidden = false;
            self.scheduleButton.setTitle(getBandIconSort(), for: UIControlState())
            
        }
        bands =  [String]()
        bands = getFilteredBands(getBandNames(), schedule: schedule, sortedBy: sortedBy)
    }
    
    func quickRefresh(){
        
        if (isLoadingBandData == false){
            isLoadingBandData = true
            self.bands = getFilteredBands(getBandNames(), schedule: schedule, sortedBy: sortedBy)
            self.bandsByName = self.bands
            ensureCorrectSorting()
            updateCountLable()
            
            self.tableView.reloadData()
            isLoadingBandData = false
        }
    }
    
    func refreshData(){
        
        internetAvailble = isInternetAvailable();
        print ("Internetavailable is  \(internetAvailble)");
        if (internetAvailble == false){
            self.refreshControl?.endRefreshing();
        }
        
        if (isLoadingBandData == false){
            
            isLoadingBandData = true
            refreshFromCache()
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                
                gatherData();
                
                if (offline == false){
                    schedule.DownloadCsv()
                    let validate = validateCSVSchedule()
                    validate.validateSchedule()
                
                    bandNotes.getAllDescriptions()
                    getAllImages()
                    
                }
                self.bandsByName = [String]()
                self.bands =  [String]()
                
                schedule.populateSchedule()
                self.bands = getFilteredBands(getBandNames(), schedule: schedule, sortedBy: sortedBy)
                self.bandsByName = self.bands
                
                DispatchQueue.main.async{
                    self.ensureCorrectSorting()
                    self.updateCountLable()
                    self.tableView.reloadData()
                    self.refreshAlerts()
                    self.refreshControl?.endRefreshing();
                }
                isLoadingBandData = false
            }
            
            updateCountLable()
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing();
        }
    } 
    
    func showHideFilterMenu(){
        print ("totalUpcomingEvents is " + String(totalUpcomingEvents))
        if (totalUpcomingEvents == 0){
            menuButton.title = "";
            menuButton.isEnabled = false;
        } else {
            menuButton.title = "Filters";
            menuButton.isEnabled = true;
        }
    }
    
    @IBAction func filterContent(_ sender: UIButton) {
        
        if (sender.titleLabel?.text == getMustSeeIcon()){
            
            if (getMustSeeOn() == true){
                setMustSeeOn(false)
                sender.setTitle(mustSeeIcon, for: UIControlState())
                sender.setImage(UIImage(named: "willSeeIconAlt"), for: UIControlState())
            
            } else {
                setMustSeeOn(true)
                sender.setTitle(mustSeeIcon, for: UIControlState())
                sender.setImage(UIImage(named: "willSeeIcon"), for: UIControlState())

            }

        } else if (sender.titleLabel?.text == getMightSeeIcon()){
            if (getMightSeeOn() == true){
                setMightSeeOn(false)
                sender.setImage(UIImage(named: "mightSeeIconAlt"), for: UIControlState())
            } else {
                setMightSeeOn(true)
                sender.setImage(UIImage(named: "mightSeeIcon"), for: UIControlState())
            }
            
        } else if (sender.titleLabel?.text == getWillNotSeeIcon()){
            if (getWontSeeOn() == true){
                setWontSeeOn(false)
                sender.setImage(UIImage(named: "willNotSeeAlt"), for: UIControlState())
            } else {
                setWontSeeOn(true)
                sender.backgroundColor = UIColor.clear
                sender.setImage(UIImage(named: "willNotSee"), for: UIControlState())
            }
            
        } else if (sender.titleLabel?.text == getUnknownIcon()){
            if (getUnknownSeeOn() == true){
                setUnknownSeeOn(false)
                sender.setImage(UIImage(named: "unknownAlt"), for: UIControlState())
            } else {
                setUnknownSeeOn(true)
                sender.setImage(UIImage(named: "unknown"), for: UIControlState())
            }
            
        } else {
            bands =  [String]()
            bands = getFilteredBands(getBandNames(), schedule: schedule,sortedBy: sortedBy)
            updateCountLable()
            tableView.reloadData()
            return
        }
        
        print("Sorted  by is " + sortedBy)
        bands =  [String]()
        quickRefresh()
        bands = getFilteredBands(getBandNames(), schedule: schedule,sortedBy: sortedBy)
        
        updateCountLable()
        tableView.reloadData()
    }
    
    func updateCountLable(){
        
        var lableCounterString = String();
        var labeleCounter = Int()
        
        if eventCount == 0 {
            labeleCounter = bandsByName.count
            lableCounterString = " bands";
            
        } else {
            labeleCounter = eventCount
            lableCounterString = " events";
        }
        print ("labeleCounter:" + String(labeleCounter))
        print ("lableCounterString:" + lableCounterString)
        
        print ("titleButtonTitle:" + String(describing: titleButton.title))
        titleButton.title = "70,000 Tons " + String(labeleCounter) + lableCounterString        
        //titleButton.setTitleColor(UIColor.black, for: UIControlState())
        
        showHideFilterMenu()
        
    }
    
    @IBAction func shareButtonClicked(_ sender: UIBarButtonItem){
        
        var intro = "These are the bands I MUST see on the 70,000 Tons Cruise\n"
        var favoriteBands = "\n"
        
        if (schedule.scheduleReleased == true){
            intro = "These are the events I attended on the 70,000 Tons Cruise\n"
            let reportHandler = showAttendenceReport()
            reportHandler.assembleReport()
            
            favoriteBands += reportHandler.buildMessage()
            
        } else {
            bands = getBandNames()
            for band in bands {
                if (getPriorityData(band) == 1){
                    print ("Adding band " + band)
                    favoriteBands += "\t" + getMustSeeIcon() + "\t" +  band + "\n"
                }
            }
        }
        
        let outtro =  "\n\nhttp://www.facebook.com/70kBands\n"
        
        let objectsToShare = [intro, favoriteBands, outtro]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: [])
        
        activityVC.modalPresentationStyle = .popover
        activityVC.preferredContentSize = CGSize(width: 50, height: 100)
        activityVC.popoverPresentationController?.barButtonItem = shareButton
        
        let popoverMenuViewController = activityVC.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = .any

        popoverMenuViewController?.sourceView = unknownButton
        popoverMenuViewController?.sourceRect = CGRect()


        self.present(activityVC, animated: true, completion: nil)
    }

    func adaptivePresentationStyleForPresentationController(
        _ controller: UIPresentationController!) -> UIModalPresentationStyle {
            return .none
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bands.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = UIColor.clear;
        cell.textLabel?.textColor = textColor;
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    //swip code start
    
    func currentlySectionBandName(_ rowNumber: Int) -> String{
        
        var bandName = "";
    
        print ("SelfBandCount is " + String(self.bands.count) + " rowNumber is " + String(rowNumber));
        if (self.bands.count > rowNumber){
            bandName = self.bands[rowNumber]
        }
        
        return bandName
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: 10, y: self.view.frame.size.height-250, width: self.view.frame.size.width - 10, height: 45))
        
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let sawAllShow = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: attendedShowIcon , handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            let currentCel = tableView.cellForRow(at: indexPath)
            
            let cellText = currentCel?.textLabel?.text;
            let cellData = getScheduleIndexByCall();
            
            let cellBandName = cellData[cellText!]!["bandName"]
            let cellStartTime = cellData[cellText!]!["startTime"]
            let cellEventType = cellData[cellText!]!["event"]
            let cellLocation = cellData[cellText!]!["location"]
            
            let status = attendedHandler.addShowsAttended(band: cellBandName!, location: cellLocation!, startTime: cellStartTime!, eventType: cellEventType!);
            
            let empty : UITextField = UITextField();
            let message = attendedHandler.setShowsAttendedStatus(empty, status: status)
            
            self.showToast(message: message);
            self.quickRefresh()
        })
 
        let mustSeeAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: getMustSeeIcon() , handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            print ("Changing the priority of " + self.currentlySectionBandName(indexPath.row) + " to 1")
            let bandName = getNameFromSortable(self.currentlySectionBandName(indexPath.row) as String, sortedBy: sortedBy)
            addPriorityData(bandName, priority: 1);
            print ("Offline is offline");
            self.quickRefresh()

        })

        let mightSeeAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: getMightSeeIcon() , handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            
            print ("Changing the priority of " + self.currentlySectionBandName(indexPath.row) + " to 2")
            let bandName = getNameFromSortable(self.currentlySectionBandName(indexPath.row) as String, sortedBy: sortedBy)
            addPriorityData(bandName, priority: 2);
            self.quickRefresh()
            
        })
        
        let wontSeeAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: getWillNotSeeIcon() , handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            
            print ("Changing the priority of " + self.currentlySectionBandName(indexPath.row) + " to 3")
            let bandName = getNameFromSortable(self.currentlySectionBandName(indexPath.row) as String, sortedBy: sortedBy)
            addPriorityData(bandName, priority: 3);
            self.quickRefresh()
            
        })
        
        let setUnknownAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: getUnknownIcon() , handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            
            print ("Changing the priority of " + self.currentlySectionBandName(indexPath.row) + " to 0")
            let bandName = getNameFromSortable(self.currentlySectionBandName(indexPath.row) as String, sortedBy: sortedBy)
            addPriorityData(bandName, priority: 0);
            self.quickRefresh()
            
        })
        
        if (hasScheduleData == true){
            print ("show menu ALL")
            return [sawAllShow, setUnknownAction, wontSeeAction, mightSeeAction, mustSeeAction]
            
        } else {
            
            return [setUnknownAction, wontSeeAction, mightSeeAction, mustSeeAction]
        }
    }
    
    //swip code end
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        
        setBands(bands)
        setScheduleButton(scheduleButton.isHidden)
        
        cell.textLabel!.text = getCellValue(indexPath.row, schedule: schedule, sortBy: sortedBy)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Getting Details")
        
        self.splitViewController!.delegate = self;
        
        self.splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let bandName = getNameFromSortable(currentlySectionBandName(indexPath.row) as String, sortedBy: sortedBy);
                 if (bandName.isEmpty == false){
                    print ("Bands size is " + String(bands.count) + " Index is  " + String(indexPath.row))
                    bandListIndexCache = indexPath.row
                    let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                
                        print ("Bands size is " + String(bands.count) + " Index is  " + String(indexPath.row))

                        controller.detailItem = bandName as AnyObject
                        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                        controller.navigationItem.leftItemsSupplementBackButton = true
                } else {
                    print ("Found an issue with the selection");
                    return
                }
            }
        }
        tableView.reloadData()
    }
    
    func resortBandsByTime(){
        schedule.populateSchedule()
    }
    
    @IBAction func resortBands(_ sender: UIButton) {
        
        if (sortedBy == "name"){
            sortedBy = "time"
            ensureCorrectSorting()
            
        } else {
            
            sortedBy = "name"
            ensureCorrectSorting()
            
        }
        
        self.tableView.reloadData()
    
    }
    
    //iCloud data loading
    func onSettingsChanged(_ notification: Notification) {
        writeiCloudData()
    }

}

