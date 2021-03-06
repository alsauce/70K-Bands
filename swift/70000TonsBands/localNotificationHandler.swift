//
//  localNotificationHandler.swift
//  70K Bands
//
//  Created by Ron Dorn on 2/6/15.
//  Copyright (c) 2015 Ron Dorn. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class localNoticationHandler {
    
    var schedule = scheduleHandler()
    var alertTextMessage = String()
    
    init(){
        schedule.populateSchedule()
    }

    func refreshAlerts(){
        if (isAlertGenerationRunning == true){
            var counter = 0;
            while (isAlertGenerationRunning == true){
                usleep(250000)
                if (counter == 5){
                    isAlertGenerationRunning = false;
                }
                counter = counter + 1;
            }
        } else {
            
            isAlertGenerationRunning = true
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                if #available(iOS 10.0, *) {
                    let localNotication = localNoticationHandler()
                    localNotication.addNotifications()
                } else {
                    // Fallback on earlier versions
                }
            }
            isAlertGenerationRunning = false
        }
    }
    
    func willAddToNotifications(_ bandName: String, eventType :String, startTime: String, location:String) -> Bool{
        
        let defaults = UserDefaults.standard
        let mustSeeAlert = defaults.bool(forKey: "mustSeeAlert")
        let mightSeeAlert = defaults.bool(forKey: "mightSeeAlert")
        let onlyAlertForAttended = defaults.bool(forKey: "onlyAlertForAttended")
        
        let alertForShows = defaults.bool(forKey: "alertForShows")
        let alertForSpecial = defaults.bool(forKey: "alertForSpecial")
        let alertForMandG = defaults.bool(forKey: "alertForMandG")
        let alertForClinics = defaults.bool(forKey: "alertForClinics")
        let alertForListening = defaults.bool(forKey: "alertForListening")
        let alertForUnoffical = defaults.bool(forKey: "alertForUnofficalEvents")
        
        print ("Checking for alert for bands " + bandName + " ... ", terminator: "")
        
        var alertStatus = false
        
        let attendedStatus = attendedHandler.getShowAttendedStatus(band: bandName, location: location, startTime: startTime, eventType: eventType);
        
        if (onlyAlertForAttended == true){
            if (attendedStatus != sawNoneStatus){
                alertStatus = true
            }
        } else {
            if (eventType == specialEventType && alertForSpecial == true){
                alertStatus = true
            }
            if (eventType == showType && alertForShows == true){
                alertStatus = checkBandPriority(bandName, mustSeeAlert: mustSeeAlert, mightSeeAlert: mightSeeAlert, attendedStatus:attendedStatus)
            }
            if (eventType == listeningPartyType && alertForListening == true){
                alertStatus = checkBandPriority(bandName, mustSeeAlert: mustSeeAlert, mightSeeAlert: mightSeeAlert, attendedStatus:attendedStatus)
            }
            if (eventType == meetAndGreetype && alertForMandG == true){
                alertStatus = checkBandPriority(bandName, mustSeeAlert: mustSeeAlert, mightSeeAlert: mightSeeAlert, attendedStatus:attendedStatus)
            }
            if (eventType == clinicType && alertForClinics == true){
                alertStatus = checkBandPriority(bandName, mustSeeAlert: mustSeeAlert, mightSeeAlert: mightSeeAlert, attendedStatus:attendedStatus)
            }
            if ((eventType == unofficalEventType || eventType == unofficalEventTypeOld) && alertForUnoffical == true){
                alertStatus = checkBandPriority(bandName, mustSeeAlert: mustSeeAlert, mightSeeAlert: mightSeeAlert, attendedStatus:attendedStatus)
                print ("alertUnofficial is set to \(alertStatus) for \(bandName)")
            }
        }
        
        return alertStatus
    }
    
    func checkBandPriority (_ bandName: String, mustSeeAlert: Bool, mightSeeAlert: Bool, attendedStatus: String)->Bool{
        
        if (mustSeeAlert == true && getPriorityData(bandName) == 1){
            print("Ok")
            return true
        }
        if (mightSeeAlert == true && getPriorityData(bandName) == 2){
            print("Ok")
            return true
        }
        
        if (mustSeeAlert == true && attendedStatus != sawNoneStatus){
            print("Ok")
            return true
        }
        
        return false
    }
    
    func getAlertMessage(_ name:String, indexValue: Date){
        
        let eventType = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: "Type")
        
        switch eventType {
            
        case showType:
            showMessage(name, indexValue: indexValue)
            
        case specialEventType:
            specialEventMessage(name, indexValue: indexValue)
            
        case meetAndGreetype:
            meetingAndGreetMessage(name, indexValue: indexValue)
            
        case clinicType:
            clinicMessage(name, indexValue: indexValue)
            
        case listeningPartyType:
            listeningPartyMessage (name, indexValue: indexValue)
        
        case unofficalEventType:
            unofficalEventMessage(name, indexValue: indexValue)
            
        default:
            print("Unknown type")
            
        }
    }
    
    func showMessage(_ name:String, indexValue: Date){
        
        let locationName = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: locationField)
        let startingTime = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: startTimeField)
        
        alertTextMessage = name + " will be playing the " + locationName + " at " + formatTimeValue(timeValue: startingTime)
    }
    
    func specialEventMessage(_ name:String, indexValue: Date){
        
        let locationName = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: locationField)
        let startingTime = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: startTimeField)
        
        alertTextMessage = "Special event '" + name + "' is taking place at the " + locationName + " starting at " + formatTimeValue(timeValue: startingTime)
    }

    func unofficalEventMessage(_ name:String, indexValue: Date){
        
        let locationName = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: locationField)
        let startingTime = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: startTimeField)
        
        alertTextMessage = "Unoffical event '" + name + "' is taking place at " + locationName + " starting at " + formatTimeValue(timeValue: startingTime)
    }
    
    func meetingAndGreetMessage(_ name:String, indexValue: Date){
        
        let locationName = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: locationField)
        let startingTime = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: startTimeField)
        
        alertTextMessage = name + " is holding a Meet and Greet at the " + locationName + " starting at " + formatTimeValue(timeValue: startingTime)
    }
    
    func listeningPartyMessage(_ name:String, indexValue: Date){
        
        let locationName = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: locationField)
        let startingTime = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: startTimeField)
        
        alertTextMessage = name + " is holding a new album listening party at the " + locationName + " starting at " + formatTimeValue(timeValue: startingTime)
    }
    
    func clinicMessage(_ name:String, indexValue: Date){
        
        let locationName = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: locationField)
        let startingTime = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: startTimeField)
        let note = schedule.getData(name, index: indexValue.timeIntervalSince1970, variable: notesField)
        
        alertTextMessage = note + " from " + name + " is holding a clinic at the " + locationName + " starting at " + formatTimeValue(timeValue: startingTime)
    }
    
    func addNotifications(){
        
        if (schedule.schedulingData.isEmpty == false){
            for bandName in schedule.schedulingData{
                for startTime in schedule.schedulingData[bandName.0]!{
                    let alertTime = NSDate(timeIntervalSince1970: startTime.0)
                    print ("Date provided is \(alertTime)")
                    if (startTime.0.isZero == false && bandName.0.isEmpty == false && typeField.isEmpty == false){
                        
                        if (schedule.schedulingData[bandName.0]?[startTime.0]?[typeField]?.isEmpty == false){
                            let eventTypeValue = (schedule.schedulingData[bandName.0]?[startTime.0]?[typeField])!
                            let startTimeValue = (schedule.schedulingData[bandName.0]?[startTime.0]?[startTimeField])!
                            let locationValue = (schedule.schedulingData[bandName.0]?[startTime.0]?[locationField])!
                            
                            let addToNoticication = willAddToNotifications(bandName.0, eventType: eventTypeValue, startTime: startTimeValue, location:locationValue)
                            
                            if (addToNoticication == true){
                                let compareResult = alertTime.compare(NSDate() as Date)
                                if compareResult == ComparisonResult.orderedDescending {
                                    
                                    getAlertMessage(bandName.0, indexValue: alertTime as Date)
                                    if #available(iOS 10.0, *) {
                                        addNotification(message: alertTextMessage, showTime: alertTime)
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @available(iOS 10.0, *)
    func addNotification(message: String, showTime: NSDate) {
        
        if (alertTracker.contains(message) == false){
            
            alertTracker.append(message)
            
            let minBeforeAlert = -defaults.integer(forKey: "minBeforeAlert")
            
            let alertTime = (Calendar.current as NSCalendar).date(
                byAdding: .minute,
                value: minBeforeAlert,
                to: showTime as Date,
                options: NSCalendar.Options(rawValue: 0))
            
            let epocAlertTime = alertTime?.timeIntervalSince1970;
            let epocCurrentTime = Date().timeIntervalSince1970
            
            let alertTimeInSeconds = epocAlertTime! - epocCurrentTime;
            
            if (alertTimeInSeconds > 0){
                print ("sendLocalAlert! \(String(describing: epocAlertTime)) minus \(epocCurrentTime) equals \(alertTimeInSeconds)")
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: alertTimeInSeconds, repeats: false)
                
                let content = UNMutableNotificationContent()
                content.body = message
                content.sound = UNNotificationSound.init(named: "OnMyWayToDeath.wav")
                
                let request = UNNotificationRequest(identifier: message, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
                
                print ("sendLocalAlert! Adding alert \(message) for alert at \(String(describing: alertTime))")
            }
        }
        
    }
    
    func clearNotifications(){
        if #available(iOS 10.0, *) {
            print ("sendLocalAlert! clearing all alerts")
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            UIApplication.shared.cancelAllLocalNotifications()
        };
        alertTracker = [String]()
    }
}
