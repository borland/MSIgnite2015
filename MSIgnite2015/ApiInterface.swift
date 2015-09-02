//
//  ApiInterface.swift
//  MSIgnite2015
//
//  Created by Orion Edwards on 2/09/15.
//  Copyright © 2015 Orion Edwards. All rights reserved.
//

import Foundation

class ApiInterface {
    let sessionsUrl = "https://msignite.nz/webapi/searchApi/GetAllConfirmedFilteredSessions"
    
    let _callbackQueue:dispatch_queue_t
    let _urlSession:NSURLSession
    
    init (callbackQueue:dispatch_queue_t) {
        _callbackQueue = callbackQueue
        _urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    private let _cacheQueue = dispatch_queue_create("apiInterfaceCache", nil)
    
    private func saveCacheForDay(dayId:Int, pageNumber:Int, data:NSData) {
        dispatch_async(_cacheQueue) {
            let fileManager = NSFileManager.defaultManager()
            let path = ApiInterface.filePathForDay(dayId, pageNumber: pageNumber)
            if fileManager.fileExistsAtPath(path) {
                do {
                    try fileManager.removeItemAtPath(path)
                } catch let error {
                    NSLog("can't delete existing file! \(error)")
                }
            }
            
            fileManager.createFileAtPath(path, contents: data, attributes: nil)
        }
    }
    
    class func filePathForDay(dayId:Int, pageNumber:Int) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if paths.count == 1 {
            return (paths[0] as NSString).stringByAppendingPathComponent("\(dayId)_\(pageNumber)")
        }
        return ""
    }
    
    private func loadCacheForDay(dayId:Int, pageNumber:Int) -> NSData? {
        var data:NSData?
        dispatch_sync(_cacheQueue) {
            let path = ApiInterface.filePathForDay(dayId, pageNumber:pageNumber)
            
            let fileManager = NSFileManager.defaultManager()
            if !fileManager.fileExistsAtPath(path) {
                return
            }
            
            data = fileManager.contentsAtPath(path)
        }
        return data
    }
    
    func cachedGetSessions(dayId:Int, pageNumber:Int, clearCache:Bool, callback:(GetSessionsResponse) -> ()) {
        let innerCallback = { (data:NSData) in
            do {
                if let x = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String:AnyObject] {
                    let response = GetSessionsResponse(dictionary: x)
                    dispatch_async(self._callbackQueue) {
                        callback(response)
                    }
                }
            } catch {
                NSLog("coudn't deserialize json response")
            }
        }

        // if clearCache is set we never load from cache
        if let data = clearCache ? nil : loadCacheForDay(dayId, pageNumber:pageNumber) {
            innerCallback(data)
        } else {
            internalGetSessions(dayId, pageNumber: pageNumber) { data in
                self.saveCacheForDay(dayId, pageNumber: pageNumber, data: data)
                innerCallback(data)
            }
        }
    }

    func getSessions(dayId:Int, pageNumber:Int, callback:(GetSessionsResponse) -> ()) {
        internalGetSessions(dayId, pageNumber: pageNumber) { data in
            do {
                if let x = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String:AnyObject] {
                    let response = GetSessionsResponse(dictionary: x)
                    dispatch_async(self._callbackQueue) {
                        callback(response)
                    }
                }
            } catch {
                NSLog("coudn't deserialize json response")
            }
        }
    }
    
    // callback will be called multiple times, once per "page"
    private func internalGetSessions(dayId:Int, pageNumber:Int, callback:(NSData) -> ()) {
        guard let url = NSURL(string: sessionsUrl) else {
            return
        }
        let request = NSMutableURLRequest(URL: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        
        let emptyArray = [AnyObject]()
        let requestBody:[String:AnyObject] = [
            "Topics":emptyArray,
            "Themes":emptyArray,
            "Audiences":emptyArray,
            "Products":emptyArray,
            "Levels":emptyArray,
            "Speakers":emptyArray,
            "Dates":[dayId],
            "SearchTerm":"",
            "PageNumber":pageNumber,
            "EncyrptedMemberId":"",
            "RegistrationId":"0"]
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(requestBody, options: NSJSONWritingOptions(rawValue:0))
        }catch {
            return
        }
        
        let task = _urlSession.dataTaskWithRequest(request) { data, response, error in
            // deserialise the response
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    NSLog("response was not 200: \(response)")
                    return
                }
            }
            if (error != nil) {
                NSLog("error submitting request: \(error)")
                return
            }
            
            // handle the data of the successful response here
            if let data = data {
                callback(data)
            }
        }
        task.resume()
    }
}

class Speaker {
    //{"Id":"0aVRnK0oxZF9up88dVfOpg%3D%3D","Name":"Alan Burchill","LastName":"B","FirstName":"Alan","IsMVP":false,"IsMicrosoftStaff":false
//    ,"PhotoPath":"","Twitterusername":"@alanburchill","LinkedInUrl":"","Website":null,"Bio":"Microsoft MVP
  //  in Group Policy and Author of the grouppolicy.biz web site.","Organisation":"Avanade Australia"}
    
    var id = ""
    var name = ""
    var photoPath = ""
    var twitterUsername = ""
    var bio = ""
    
    init(dictionary:[String:AnyObject]) {
        id = dictionary["Id"] as? String ?? ""
        name = dictionary["Name"] as? String ?? ""
        photoPath = dictionary["PhotoPath"] as? String ?? ""
        bio = dictionary["Bio"] as? String ?? ""
    }
}

class Schedule {
/* {
"StartDatetime":"2015-09-03T09:00:00", "EndDatetime":"2015-09-03T10:00:00", "Venue":"New Zealand 1 (SKYCITY)","EventSessionRegistrationId":0,"Status":"Scheduled","IsToday":false,"FormattedVenueString":"New Zealand 1 (SKYCITY)","FormattedStartDate":"Thu 3 Sept,  9:00 a.m."}, */
    var startDateTime = NSDate() // not using this so why bother parsing
    var endDateTime = ""  // not using this so why bother parsing
    var venue = ""
    var eventSessionRegistrationId = 0
    var status = ""
    var isToday = false
    var formattedVenueString = ""
    var formattedStartDate = ""
    
    required init () { }
    
    static let formatter = NSDateFormatter()
    static var onceToken:dispatch_once_t = 0
    
    class func parseDate(dateString:String) -> NSDate? {
        dispatch_once(&onceToken) {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        }
        return formatter.dateFromString(dateString)
    }
    
    init(dictionary:[String:AnyObject]) {
        if let x = dictionary["StartDatetime"] as? String, let y = Schedule.parseDate(x) {
            startDateTime = y
        } else {
            assertionFailure("can't parse date!")
        }
        venue = dictionary["Venue"] as? String ?? ""
        eventSessionRegistrationId = dictionary["EventSessionRegistrationId"] as? Int ?? 0
        status = dictionary["Status"] as? String ?? ""
        formattedVenueString = dictionary["FormattedVenueString"] as? String ?? ""
        formattedStartDate = dictionary["FormattedStartDate"] as? String ?? ""
    }
}

class SessionDetails {
/* {"Audience":"Architect, IT Implementer","Topic":"Usage & Adoption"
,"Theme":"Security & Compliance","Product":"Windows Client (Desktop & Mobile)","Level":"Level 300"} */
    var audience = ""
    var topic = ""
    var theme = ""
    var product = ""
    var level = ""
    
    required init () { }
    
    init(dictionary:[String:AnyObject]) {
        audience = dictionary["Audience"] as? String ?? ""
        topic = dictionary["Topic"] as? String ?? ""
        theme = dictionary["Theme"] as? String ?? ""
        product = dictionary["Product"] as? String ?? ""
        level = dictionary["Level"] as? String ?? ""
    }
}

class Session {
/* {
    "EventSessionId":0,
    "EventSessionRegistrationId":0,
    "SessionId":92,
    "Name":"Internet Explorer and Edge in the Enterprise [M336]",
    "Speakers":[...],
    "Schedule":{...}
    "Description":"...",
    "Details":{...},
    "IsCommonSession":false,
    "SessionCss":"",
    "EvaluationStatus":null,
    "EvaluationUrl":null}
*/

    var eventSessionId = 0
    var eventSessionRegistrationId = 0
    var sessionId = 0
    var name = ""
    var speakers = [Speaker]()
    var schedule = Schedule()
    var description = ""
    var details = SessionDetails()
    var isCommonSession = false
    
    required init() { }
    
    init(dictionary:[String:AnyObject]) {
        eventSessionId = dictionary["EventSessionId"] as? Int ?? 0
        eventSessionRegistrationId = dictionary["EventSessionRegistrationId"] as? Int ?? 0
        sessionId = dictionary["SessionId"] as? Int ?? 0
        name = dictionary["Name"] as? String ?? ""
        if let x = dictionary["Speakers"] as? [[String:AnyObject]] {
            self.speakers = x.map{ Speaker(dictionary:$0) }
        }
        if let x = dictionary["Schedule"] as? [String:AnyObject] {
            self.schedule = Schedule(dictionary: x)
        }
        description = dictionary["Description"] as? String ?? ""
        if let x = dictionary["Details"] as? [String:AnyObject] {
            self.details = SessionDetails(dictionary: x)
        }
    }
}

class GetSessionsResponse {
/*    {"PageNumber":1,"PagesCount":6,"RegistrationId":0,"Sessions":[Session] */
    var pageNumber = 0
    var pagesCount = 0
    var registrationId = 0
    var sessions = [Session]()
    
    init(dictionary:[String:AnyObject]) {
        pageNumber = dictionary["PageNumber"] as? Int ?? 0
        pagesCount = dictionary["PagesCount"] as? Int ?? 0
        registrationId = dictionary["RegistrationId"] as? Int ?? 0

        if let sd = dictionary["Sessions"] as? [[String:AnyObject]] {
            sessions = sd.map{ Session(dictionary: $0) }
        }
    }
}