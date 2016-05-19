//  Detail:  fixed bug where run button didn't read "Run" when
// run ends.

//  Request.swift
//  OKCapp_v1.0.4
//
//  Created by Stuart Kuredjian on 5/17/16.
//  Copyright © 2016 s.Ticky Games. All rights reserved.
//

import UIKit



class Request: NSOperation {
	private var URL = NSURL()
	private var method = String()
	private var params = String()
	public var username = String()
	public var password = String()
	var statusCode = Int()
	var requestHeaders = NSDictionary()
	var cookies = [NSHTTPCookie]()
	var responseHeaders = NSHTTPURLResponse()
	
	init(URL: NSURL, method: String, params: String) {
		self.URL = URL
		self.method = method
		self.params = params
	}
	
	public var contentsOfURL:NSString = ""
	public var isRequesting = false
	public var task = NSURLSessionDataTask()
	
	override func main() -> () {
		// TEST: whatever is done here will execute before anything else??
	}
	
	func execute() {
		let session = NSURLSession.sharedSession()
		
		let request = NSMutableURLRequest(URL: URL)
		request.HTTPMethod = self.method
		request.HTTPBody = self.params.dataUsingEncoding(NSUTF8StringEncoding)
		self.task = session.dataTaskWithRequest(request) {
			(data, response, error) in
			NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(self.cookies, forURL: self.URL, mainDocumentURL: nil)
			if error == nil {
				do {
					self.responseHeaders = response as! NSHTTPURLResponse
					self.cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(self.URL)!
					self.statusCode = self.responseHeaders.statusCode
					
					switch self.statusCode {
						
					case 200:
						self.contentsOfURL = try NSString(contentsOfURL: self.URL, encoding: NSUTF8StringEncoding)
					case 400:
						print("400: page not found")
						
					case 404:
						print("404: page not found")
						
					case 407:
						print("407:f failed authenticate proxy credentials")
						
					default:
						print("unable to get statusCode")
						
					}
				} catch {
					
				}
				self.isRequesting = false
			} else {
				print(error)
			}
		}
		self.task.resume()
	}
	
	func addRequestHeaders(requestHeaders: NSDictionary) {
		self.requestHeaders = requestHeaders
	}
	
	func getContentsOfURL(URL: NSURL) -> NSString {
		return self.contentsOfURL
	}
	
}
