//
//  scheduleHandler.swift
//  70K Bands
//
//  Created by Ron Dorn on 1/31/15.
//  Copyright (c) 2015 Ron Dorn. All rights reserved.
//

import Foundation

open class scheduleHandler {
    
    var schedulingData: [String : [TimeInterval : [String : String]]] = [String : [TimeInterval : [String : String]]]()
    var schedulingDataByTime: [TimeInterval : [String : String]] = [TimeInterval : [String : String]]()
    var scheduleReleased = false
    
    var customDescrip = CustomBandDescription();
    
    func populateSchedule(){

        if (isLoadingSchedule == true){
            var counter = 0;
            while (isLoadingSchedule == true){
                usleep(250000)
                if (counter == 5){
                    isLoadingSchedule = false;
                }
                counter = counter + 1;
            }
        } else {

            isLoadingSchedule = true;
            
            schedulingData.removeAll();
            schedulingDataByTime.removeAll();
            
            if (FileManager.default.fileExists(atPath: scheduleFile) == false){
                DownloadCsv();
            }
            
            if let csvDataString = try? String(contentsOfFile: scheduleFile, encoding: String.Encoding.utf8) {
                
                var unuiqueIndex = Dictionary<TimeInterval, Int>()
                var csvData: CSV
                
                csvData = try! CSV(csvStringToParse: csvDataString)
                
                for lineData in csvData.rows {
                    if (lineData[dateField]?.isEmpty == false && lineData[startTimeField]?.isEmpty == false){
                        
                        var dateIndex = getDateIndex(lineData[dateField]!, timeString: lineData[startTimeField]!, band: lineData["Band"]!)
                        
                        //ensures all dateIndex's are unuique
                        while (unuiqueIndex[dateIndex] == 1){
                            dateIndex = dateIndex + 1;
                        }
                        
                        unuiqueIndex[dateIndex] = 1
                        
                        let dateFormatter = DateFormatter();
                        dateFormatter.dateFormat = "YYYY-M-d HH:mm"
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        
                        print("Adding index for band " + lineData[bandField]! + " ")
                        print (dateIndex)
                        
                        if (schedulingData[lineData[bandField]!] == nil){
                            scheduleReleased = true
                            schedulingData[lineData[bandField]!] = [TimeInterval : [String : String]]()
                        }
                        if (schedulingData[lineData[bandField]!]?[dateIndex] == nil){
                            schedulingData[lineData[bandField]!]?[dateIndex] = [String : String]()
                        }
                    
                        print ("Adding location of " + lineData[locationField]!)
                        
                        //doing this double for unknown reason, it wont work if the first entry is single
                        print ("adding dayField");
                        setData(bandName: lineData[bandField]!, index:dateIndex, variable:dayField, value: lineData[dayField]!)
                        setData(bandName: lineData[bandField]!, index:dateIndex, variable:dayField, value: lineData[dayField]!)
                        
                        print ("adding startTimeField");
                        setData(bandName: lineData[bandField]!, index:dateIndex, variable:startTimeField, value: lineData[startTimeField]!)
                        setData(bandName: lineData[bandField]!, index:dateIndex, variable:endTimeField, value: lineData[endTimeField]!)
                        
                        print ("adding dateField");
                        setData(bandName: lineData[bandField]!, index:dateIndex, variable:dateField, value: lineData[dateField]!)
                        
                        print ("adding typeField");
                        var eventType = lineData[typeField]!;
                        if (eventType == unofficalEventTypeOld){
                            eventType = unofficalEventType;
                        }
                        setData(bandName: lineData[bandField]!, index:dateIndex, variable:typeField, value: eventType)
                        
                        print ("adding notesField");
                        if let noteValue = lineData[notesField] {
                            setData(bandName: lineData[bandField]!, index:dateIndex, variable:notesField, value: noteValue)
                        }
                        
                        print ("adding locationField");
                        setData(bandName: lineData[bandField]!, index:dateIndex, variable:locationField, value: lineData[locationField]!)
                        
                        print ("adding descriptionUrlField \(lineData)")

                        if let descriptUrl = lineData[descriptionUrlField] {
                            if (descriptUrl.isEmpty == false && descriptUrl.count >= 2){
                                print ("adding descriptionUrlField for \(descriptionUrlField) \(lineData[bandField]!) - \(lineData[descriptionUrlField])");
                                setData(bandName: lineData[bandField]!, index:dateIndex, variable:descriptionUrlField, value: descriptUrl)
                                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                                    _ = self.customDescrip.getDescriptionFromUrl(bandName: lineData[bandField]!, descriptionUrl: lineData[descriptionUrlField]!);
                                }
                            }
                        } else {
                            print ("field descriptionUrlField not present for " + lineData[bandField]!);
                        }
                        
                        if let imageUrl = lineData[imageUrlField] {
                            if (imageUrl.isEmpty == false && imageUrl.count >= 2){
                                imageUrls[lineData[bandField]!] = imageUrl
                                //save inmage in background
                                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                                    _ = displayImage(urlString: imageUrl, bandName: lineData[bandField]!)
                                }
                            }
                            
                        }
                    } else {
                        print ("Unable to parse schedule file")
                    }
                }
            } else {
                print ("Encountered an error could not open schedule file ")
            }
            isLoadingSchedule = false;
        }
    }
    
    
    func DownloadCsv (){
        
        var scheduleUrl = "";
        
        print ("working with scheduleFile " + scheduleFile)
        if (defaults.string(forKey: "scheduleUrl") == lastYearsScheduleUrlDefault){
            scheduleUrl = lastYearsScheduleUrlDefault;
        } else {
            scheduleUrl = defaults.string(forKey: "scheduleUrl")!
        }
        
        if (scheduleUrl.isEmpty == true){
            scheduleUrl = "Default"
        }
    
        print ("Downloading Schedule URL " + scheduleUrl);
        if (scheduleUrl == "Default"){
            scheduleUrl = getPointerUrlData(keyValue: scheduleUrlpointer)
            
        } else if (scheduleUrl == "lastYear"){
            scheduleUrl = getPointerUrlData(keyValue: lastYearscheduleUrlpointer)
        
        }
        
        print("scheduleUrl = " + scheduleUrl)
        
        let httpData = getUrlData(scheduleUrl)
        
        print("This will be making HTTP Calls for schedule " + httpData);
        
        if (httpData.isEmpty == false){
            do {
                try FileManager.default.removeItem(atPath: scheduleFile)
            
            } catch let error as NSError {
                print ("Encountered an error removing old schedule file " + error.debugDescription)
                isLoadingBandData = false
            }
            do {
                try httpData.write(toFile: scheduleFile, atomically: false, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                print ("Encountered an error writing schedule file " + error.debugDescription)
                isLoadingBandData = false
            }
            
        }
    }

    func getDateIndex (_ dateString: String, timeString: String, band:String) -> TimeInterval{
        
        var startTimeIndex = TimeInterval()
        let fullTimeString: String = dateString + " " + timeString;
        
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "M-d-yy HH:mm"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if (fullTimeString.isEmpty == false){
            print(dateFormatter.date(from: fullTimeString) as Any)
            if (dateFormatter.date(from: fullTimeString) != nil){
                startTimeIndex = dateFormatter.date(from: fullTimeString)!.timeIntervalSince1970
                print(startTimeIndex)
                
                print ("timeString \(band) '" + fullTimeString + "' \(startTimeIndex)");
            } else {
                print ("What the hell!!")
                print(dateFormatter.date(from: fullTimeString) as Any)
            }
        }
                
        return startTimeIndex
    }
    
    func getCurrentIndex (_ bandName: String) -> TimeInterval {
        
        let dateIndex = NSTimeIntervalSince1970
        
        if (schedulingData[bandName]?.isEmpty == false){
        
            let keyValues = schedulingData[bandName]!.keys
            let sortedArray = keyValues.reversed()
            
            if (schedulingData[bandName] != nil){
                for dateIndexTemp in sortedArray {
                    if (schedulingData[bandName]![dateIndexTemp]![typeField]! == showType){
                        let currentTime =  Date().timeIntervalSince1970
                        let currentTimePlusAnHour = currentTime - 3600
                        
                        print ("time comparison of scheduledate " + dateIndexTemp.description + " vs " + currentTimePlusAnHour.description)
                        if dateIndexTemp > currentTimePlusAnHour{
                            print("Returning dateIndex of " + dateIndexTemp.description )
                            return dateIndexTemp
                        }
                    }
                }
            }
        }
        return dateIndex
    }
    
    func setData (bandName:String, index:TimeInterval, variable:String, value:String){
    
        if (variable.isEmpty == false && value.isEmpty == false && schedulingData.isEmpty == false){
            if (bandName.isEmpty == false && index.isZero == false && (schedulingData[bandName]?.isEmpty)! == false){
                if (schedulingData[bandName]?.isEmpty == false){
                    //schedulingData[bandName]![index]?[variable] = ""
                    if (value.isEmpty == false){
                        schedulingData[bandName]?[index]?[variable] = value as String;
                    }
                }
            }
        }
    }
    
    func getData(_ bandName:String, index:TimeInterval, variable:String) -> String{
        
        print ("schedule value lookup. Getting variable " + variable + " for " + bandName + " - " + index.description);
        print (schedulingData[bandName] as Any)
        if (schedulingData[bandName] != nil && variable.isEmpty == false){
            print ("schedule value lookup. loop 1")
            if (schedulingData[bandName]![index]?.isEmpty == false){
                print ("schedule value lookup. loop 2")
                if (schedulingData[bandName]![index]![variable]?.isEmpty == false){
                    print ("schedule value lookup. loop 3")
                    print ("schedule value lookup. Returning " + schedulingData[bandName]![index]![variable]!)
                    return schedulingData[bandName]![index]![variable]!
                }
            }
        }
        print ("schedule value lookup. Returning nothing for " + variable + " - " + bandName)
        return String()
    }

    func buildTimeSortedSchedulingData () {
        
        for bandName in schedulingData.keys {
            if (schedulingData[bandName]?.isEmpty == false){
                for timeIndex in (schedulingData[bandName]?.keys)!{
                    print ("timeSortadding timeIndex:" + String(timeIndex) + " bandName:" + bandName);
                    schedulingDataByTime[timeIndex] = [bandName:bandName]
                    
                }
            }
        }
        
        print ("schedulingDataByTime is")
        print (schedulingDataByTime);
        
    }
    
    func getTimeSortedSchedulingData () -> [TimeInterval : [String : String]] {
        return schedulingDataByTime
    }
    
    func getBandSortedSchedulingData () -> [String : [TimeInterval : [String : String]]] {
    
        return schedulingData;
    
    }
    
    func convertStringToNSDate(_ dateStr: String) -> Date {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "yyyy'-'MM'-'dd HH':'mm':'ss '+0000'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let date = dateFormatter.date(from: dateStr)
        
        return date!
    }
}


