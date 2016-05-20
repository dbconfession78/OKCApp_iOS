//  Detail:  fixed bug where run button didn't read "Run" when
// run ends.

//  ViewController.swift
//  OKCapp_v1.0.3
//
//  Created by Stuart Kuredjian on 5/17/16.
//  Copyright © 2016 s.Ticky Games. All rights reserved.
//

import UIKit

let queue = NSOperationQueue()
var cookies = [NSHTTPCookie]()

class ViewController: UIViewController {
	@IBOutlet weak var UIOutputToolbar: UIToolbar!
	@IBOutlet weak var UIOutputBarItem: UIBarButtonItem!
	@IBOutlet weak var loginButton: UIButton!
	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var proxyHostTextField: UITextField!
	@IBOutlet weak var proxyPortTextField: UITextField!
	@IBOutlet weak var proxyUserTextField: UITextField!
	@IBOutlet weak var proxyPasswordTextField: UITextField!
	@IBOutlet weak var toVisitTextField: UITextField!
	@IBOutlet weak var visitedLabel: UILabel!
	@IBOutlet weak var runButton: UIButton!
	@IBOutlet weak var visitLimitTextField: UITextField!
	@IBOutlet weak var shouldHideProfilesSwitch: UISwitch!
	@IBOutlet weak var proxySwitch: UISwitch!
	
	var isLoggedIn = false
	var isLogging = false
	var isRunning = false
	var isVisiting = false
	var shouldHideProfiles = false
	var accessToken: String = String()
	var cookies = [NSHTTPCookie]()
	var totalProfilesVisited:Int = 0
	var backgroundUpdateTask = UIBackgroundTaskIdentifier()
	
	@IBAction func testButtonSelected(sender: AnyObject) {
		
	}
	
	@IBAction func loginButtonSelected(sender: AnyObject) {
		if !isLoggedIn {
			login()
		} else {
			logout()
		}
	}
	
	@IBAction func shouldHideProfilesSwitchSelected(sender: AnyObject) {
		if !shouldHideProfiles {
			shouldHideProfiles = true
			shouldHideProfilesSwitch.setOn(true, animated: true)
		} else {
			shouldHideProfiles = false
			shouldHideProfilesSwitch.setOn(false, animated: true)
		}
	}
	
	@IBAction func proxySwitchSelected(sender: AnyObject) {
		
	}
	
	@IBAction func runButtonSelected(sender: AnyObject) {
		let limit = Int(self.visitLimitTextField.text!)!
		var cycles:Int!
		var finalCycleLimit:Int!
		
		let thread1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
		dispatch_async(thread1, {
			if !self.isRunning {
				self.runButton.setTitle("Stop Run", forState: UIControlState.Normal)
			} else {
				self.runButton.setTitle("Run", forState: UIControlState.Normal)
			}
		})
		
		NSThread.sleepForTimeInterval(0.5)
		let thread2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
		dispatch_async(thread2, {
			let maxLimitsPerCycle = 100
			if limit <= maxLimitsPerCycle {
				self.isRunning = true
				self.run(limit)
			} else {
				cycles = (limit / maxLimitsPerCycle) + 1
				finalCycleLimit = limit % maxLimitsPerCycle
				
				for i in 1..<cycles {
					self.isRunning = true
					self.run(maxLimitsPerCycle)
				}
				
				if finalCycleLimit > 0 {
					self.isRunning = true
					self.run(finalCycleLimit)
				}
			}
			dispatch_async(dispatch_get_main_queue(), {
				self.runButton.setTitle("Run", forState: UIControlState.Normal)
			})
			
			print("Visited \(self.totalProfilesVisited) profile(s)")
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		shouldHideProfilesSwitch.setOn(false, animated: true)
		
		loginButton.layer.borderWidth = 1.0
		loginButton.layer.cornerRadius = 5.0
		
		runButton.layer.borderWidth = 1.0
		runButton.layer.cornerRadius = 5.0
		
		login()
		
	}
	
	func hideProfile(profile: String) {
		// parse userID from profile page
		var userID = String()
		let URL1 = NSURL(string: "https://www.okcupid.com/profile/\(profile)")
		let request1 = Request(URL: URL1!, method: "GET", params: "")
		request1.isRequesting = true
		queue.addOperation(request1)
		request1.threadPriority = 0
		request1.completionBlock = {() -> () in
			request1.execute()
		}
		while request1.isRequesting {
			NSThread.sleepForTimeInterval(0.0)
			//			if !request1.isRequesting {
			//				break
			//			}
		}
		//		print(request.contentsOfURL)
		
		do {
			let regex = try NSRegularExpression(pattern: "userid: '([0-9]+)'", options: [])
			let matches = regex.matchesInString(request1.contentsOfURL as String, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, request1.contentsOfURL.length))
			userID = request1.contentsOfURL.substringWithRange(matches[0].rangeAtIndex(1))
			print(userID)
		} catch {
			
		}
		
		// hide user
		let url = "https://www.okcupid.com/apitun/profile/runnergabriel/hide"
		let URL2 = NSURL(string: url)!
		print(URL2)
		let params = "&access_token=\(self.accessToken)"
		let request2 = Request(URL: URL2, method: "POST", params: params)
		//		let requestHeaders: [String:String] = [
		//			"Authorization":"Bearer \(accessToken)"
		//		]
		//		request2.addRequestHeaders(requestHeaders)
		request2.isRequesting = true
		queue.addOperation(request2)
		request2.threadPriority = 0
		request2.completionBlock = {() -> () in
			request2.execute()
		}
		
		while request2.isRequesting {
			NSThread.sleepForTimeInterval(0.0)
			//			if !request2.isRequesting {
			//				break
			//			}
		}
		
		
	}
	
	func login() {
		let thread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
		isLogging = true
		dispatch_async(thread, {
			//			self.clearCookies()
			self.cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
			//			print(self.cookies)
			let URL = NSURL(string: "https://www.okcupid.com/login")
			let method = "POST"
			let username = self.usernameTextField.text!
			let password = self.passwordTextField.text!
			let params = "&username=\(username)&password=\(password)&okc_api=1"
			let request = Request(URL: URL!, method: method, params: params)
			request.username = username
			request.password = password
			request.isRequesting = true
			
			queue.addOperation(request) // 1.
			request.threadPriority = 0
			request.completionBlock = {() -> () in
				request.execute() // 3.
			}
			while request.isRequesting {
				NSThread.sleepForTimeInterval(0.0)
				//				if !request.isRequesting {
				//					break // 5.
				//				}
			}
			print(request.responseHeaders)
			
			
			do {
				let contentsOfURL = request.getContentsOfURL(URL!)
				let regex = try NSRegularExpression(pattern: "ACCESS_TOKEN = \"([0-9A-Za-z\\W.]+)\";", options: [])
				
				let matches = regex.matchesInString(contentsOfURL as String, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.length))
				
				switch matches.count {
					
				case 0:
					print("login failed:  unable to parse access token")
					self.isLoggedIn = false
					
				case 1:
					self.accessToken = (contentsOfURL).substringWithRange(matches[0].rangeAtIndex(1))
					print("Logged in!")
					print("\nACCESS_TOKEN=\(self.accessToken)\n")
					self.isLoggedIn = true
					
				default:
					print("login failed:  multiples access tokens found")
					self.isLoggedIn = false
				}
				
				self.isLogging = false
			} catch {
				
			}
		})
		
		while isLogging {
			NSThread.sleepForTimeInterval(0.0)
			//			if !isLogging {
			//				break
			//			}
		}
		
		if isLoggedIn {
			self.loginButton.setTitle("Logout", forState: UIControlState.Normal)
		}
	}
	
	func logout() {
		isLoggedIn = false
		clearCookies()
		loginButton.setTitle("Login", forState: UIControlState.Normal)
	}
	
	func visitProfile(profile: NSString) -> Bool {
		var didVisitProfile: Bool?

			// =========================================
			let url = "https://www.okcupid.com/profile/\(profile)"
			let encodedURL = url.stringByAddingPercentEncodingWithAllowedCharacters(
				NSCharacterSet.URLFragmentAllowedCharacterSet()),
			URL = NSURL(string: encodedURL!)
			
			// ==========================================
			
			//		let URL = NSURL(string: "https://www.okcupid.com/profile/\(profile)")
			
			if URL != nil {
				let request = Request(URL: URL!, method: "GET", params: "")
				
				request.isRequesting = true
				queue.addOperation(request)
				request.threadPriority = 0
				request.completionBlock = {() -> () in
					request.execute()
				}
				while request.isRequesting {
					NSThread.sleepForTimeInterval(1.0)
				}
				
				NSThread.sleepForTimeInterval(1)
				if request.contentsOfURL.containsString("<title>\(profile) /") {
					//					profilesVisited += 1
					didVisitProfile = true
				} else {
					didVisitProfile = false
				}
				self.isVisiting = false
			}
		
		
		return didVisitProfile!
	}
	
	func run(limit: Int) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.beginBackgroundUpdateTask()

		var previouslyVisitedProfileCount = Int()
		var profilesVisited = 0
		let visitInterval: NSTimeInterval = 6
		let thread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
		var secondsPerVisit = NSTimeInterval()
		
		dispatch_async(thread, {
			var JSON = "{\"gentation\":[17],\"gender_tags\":\"2\",\"last_login\":\"3600\",\"located_anywhere\":\"1\",\"limit\":\"\(limit)\"}"
			var url = "https://www.okcupid.com/apitun/match/search?"
			
			var params = "&access_token=\(self.accessToken)&_json=\(JSON)"
			params = self.addPercentEscapes(params)
			var request = Request(URL: NSURL(string: url+params)!, method: "GET", params: "")
			request.isRequesting = true
			
			queue.addOperation(request)
			request.threadPriority = 0
			request.completionBlock = {() -> () in
				request.execute()
			}
			while request.isRequesting {
				NSThread.sleepForTimeInterval(0.5)
			}
			
			let pattern = "(\"username\") : \"([\\w\\\\ÆÐƎƏƐƔĲŊŒ\\u1E9EÞǷȜæðǝəɛɣĳŋœĸſßþƿȝĄƁÇĐƊĘĦĮƘŁØƠŞȘŢȚŦŲƯY̨Ƴąɓçđɗęħįƙłøơşșţțŧųưy̨ƴÁÀÂÄǍĂĀÃÅǺĄÆǼǢƁĆĊĈČÇĎḌĐƊÐÉÈĖÊËĚĔĒĘẸƎƏƐĠĜįịĳĵķƙĸĺļłľŀŉńn̈ňñņŋóòôöǒŏōõőọøǿơœŔŘŖŚŜŠŞȘṢ\\u1E9EŤŢṬŦÞÚÙÛÜǓŬŪŨŰŮŲỤƯẂẀŴẄǷÝỲŶŸȲỸƳŹŻŽẒŕřŗſśŝšşșṣßťţṭŧþúùûüǔŭūũűůųụưẃẁŵẅƿýỳŷÿȳỹƴźżžẓ±-]+)\","
			
			let contentsOfURL = request.contentsOfURL as String
			
			//parse profiles
			var profiles: [NSString] = [NSString]()
			do {
				let regex = try NSRegularExpression(pattern: pattern, options: [])
				let matches = regex.matchesInString(contentsOfURL, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.characters.count))
				for match in matches {
					profiles.append((contentsOfURL as NSString).substringWithRange(match.rangeAtIndex(2)))
				}
			} catch {
				
			}
			
			// B. TODO: Create CLASS: RunManager
			/* visit user profiles based on match results */
			var didVisitProfile = false
			for (index, profile) in profiles.enumerate() {
				
				//TODO try putting visit profile into a thread and looping after it
				let thread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
				print("\(index+1). \(profiles[index]): ", terminator: "")
				dispatch_async(dispatch_get_main_queue(), {
					self.UIOutputBarItem.title = ("\(profile as String):")
				})
				self.isVisiting = true
				

				if self.readFile("profilesVisited.txt").containsString(profile as String) {
					previouslyVisitedProfileCount += 1
				} else {
					
//					dispatch_async(thread, {
						dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
							self.beginBackgroundUpdateTask()
							didVisitProfile = self.visitProfile(profile)
							self.endBackgroundUpdateTask()
						})
//					})
					secondsPerVisit = 0.0
					while self.isVisiting {
						NSThread.sleepForTimeInterval(0.5)
						secondsPerVisit += 0.5
					}
					
					if didVisitProfile {
						print("OK")
						dispatch_async(dispatch_get_main_queue(), {
							self.UIOutputBarItem.title = ("\(profile): OK" as String)
						})
						profilesVisited += 1
						self.totalProfilesVisited += 1
						if self.shouldHideProfiles {
							self.writeTextToFile(profile as String, fileName: "profilesVisited.txt")
							
						}
						dispatch_async(dispatch_get_main_queue(), {
							self.visitedLabel.text = String(self.totalProfilesVisited)
						})
					} else {
						print("FAIL")
						dispatch_async(dispatch_get_main_queue(), {
							self.UIOutputBarItem.title = ("\(profile): FAIL" as String)
						})
						
					}
					
					if limit != index+1 {
						NSThread.sleepForTimeInterval(visitInterval)
					} else {
						break
					}
				}
			}
			self.isRunning = false
		})
		
		while self.isRunning {
			NSThread.sleepForTimeInterval(0.0)
			if secondsPerVisit > 5.0 && self.isRunning ==  true {
				print("\ntime to complete visit: \(secondsPerVisit)")
				self.isRunning = false
				break
			}
		}
		self.endBackgroundUpdateTask()
		})
	}
	
	func writeTextToFile(content: String, fileName: String) {
		let contentToAppend = content + "\n"
		let filePath = NSHomeDirectory() + "/Documents/" + fileName
		
		//check if the file exists
		if let fileHandle = NSFileHandle(forWritingAtPath: filePath) {
			//Append to file
			fileHandle.seekToEndOfFile()
			fileHandle.writeData(contentToAppend.dataUsingEncoding(NSUTF8StringEncoding)!)
		}
		else {
			//Create new file
			do {
				try contentToAppend.writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding)
			} catch {
				print("Error creating \(filePath)")
			}
		}
	}
	
	func readFile(file: String) -> NSString{
		var fileContents = NSString()
		
		do {
			let path = NSHomeDirectory() + "/Documents/" + file
			fileContents = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
		} catch {
			
		}
		
		return fileContents
	}
	
	func parseProfileNames(pattern:String, contentsOfURL: String) -> [NSString] {
		var profiles: [NSString] = [NSString]()
		do {
			let regex = try NSRegularExpression(pattern: pattern, options: [])
			let matches = regex.matchesInString(contentsOfURL, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.characters.count))
			for match in matches {
				profiles.append((contentsOfURL as! NSString).substringWithRange(match.rangeAtIndex(0)))
			}
		} catch {
			
		}
		return profiles
	}
	
	func clearCookies() {
		print("clearing cookies...")
		cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
		for cookie in cookies {
			print("Deleting: \(cookie.name)")
			NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
		}
		cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
		if (cookies.count == 0) {
			
			print("cookies have been cleared.\n")
		}
	}
	
	func addPercentEscapes(var string:  String) -> String {
		string = string.stringByReplacingOccurrencesOfString(",", withString: "%2C")
		string = string.stringByReplacingOccurrencesOfString(";", withString: "%3B")
		string = string.stringByReplacingOccurrencesOfString(":", withString: "%3A")
		string = string.stringByReplacingOccurrencesOfString("\"", withString: "%22")
		string = string.stringByReplacingOccurrencesOfString("{", withString: "%7B")
		string = string.stringByReplacingOccurrencesOfString("}", withString: "%7D")
		return string
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func beginBackgroundUpdateTask() {
		self.backgroundUpdateTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
			self.endBackgroundUpdateTask()
		})
	}
	
	func endBackgroundUpdateTask() {
		UIApplication.sharedApplication().endBackgroundTask(self.backgroundUpdateTask)
		self.backgroundUpdateTask = UIBackgroundTaskInvalid
	}
}

