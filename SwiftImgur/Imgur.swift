//
//  Imgur.swift
//  SwiftImgur
//
//  Created by Rick Mann on 2019-06-27.
//  Copyright © 2019 Latency: Zero, LLC. All rights reserved.
//

import Foundation

import Marshal
import PMKFoundation
import PromiseKit








enum
ImgurError : Error
{
	case invalidOAuthCompletionURL(String)
	case accessDenied
	case invalidParameter(String)
}

public
class
Imgur
{
	public
	init(id inID: String, secret inSecret: String)
	{
		self.clientID = inID
		self.clientSecret = inSecret
		
		let config = URLSessionConfiguration.default
		self.session = URLSession(configuration: config)
	}
	
	/**
		Presents a browser to the user to authorize use.
	*/
	
	public
	func
	oauthURL(context inContext: String? = nil)
		-> URL
	{
		var url = URLComponents(string: "https://api.imgur.com/oauth2/authorize")!
		var qi = [URLQueryItem]()
		qi.append(URLQueryItem(name: "client_id", value: self.clientID))
		qi.append(URLQueryItem(name: "response_type", value: "token"))
		if let ctx = inContext
		{
			qi.append(URLQueryItem(name: "state", value: ctx))
		}
		url.queryItems = qi
		return url.url!
	}
	
	/**
		When the OAuth2 flow completes, pass the resulting redirect URL
		to this method to complete authorization.
	
		@return		Returns the context parameter passed to `oauthURL(context:)`.
	*/
	
	public
	func
	handleOauth2(callback inURL: String)
		throws
		-> String?
	{
		//	Check for an error…
		
		guard
			let url = URLComponents(string: inURL)
		else
		{
			throw ImgurError.invalidOAuthCompletionURL(inURL)
		}
		
		if let qi1 = url.queryItems,
			let _ = qi1.filter({ $0.name == "error" }).first
		{
			throw ImgurError.accessDenied
		}
		
		//	Extract the fragment, and create a dummy URL using that fragment
		//	as a query string to let URLComponents parse out the items…
		
		guard
			let frag = url.fragment,
			let url2 = URLComponents(string: "ignore:?\(frag)"),
			let qi2 = url2.queryItems,
			let accessToken = qi2.filter({ $0.name == "access_token" }).first,
			let refreshToken = qi2.filter({ $0.name == "refresh_token" }).first
		else
		{
			throw ImgurError.invalidOAuthCompletionURL(inURL)
		}
		
		self.accessToken = accessToken.value
		self.refreshToken = refreshToken.value
		
		
		let contexts = qi2.filter { $0.name == "state" }
		return contexts.first?.value
	}
	
	public
	func
	albums(user inUser: String? = nil, page inPage: Int = 0)
		throws
		->Promise<[Album]>
	{
		guard
			let user = inUser ?? self.userName,
			let url = URL(string: "https://api.imgur.com/3/account/\(user)/albums/\(inPage)"),
			let accessToken = self.accessToken
		else
		{
			throw ImgurError.invalidParameter("user")
		}
		
		var req = URLRequest(url: url)
		req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		
		return firstly
		{
			self.session.dataTask(.promise, with: req).validate()
		}
		.map()
		{ inArg in
			let (data, resp) = inArg
			let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
			let albums: [Album] = try json.value(for: "data")
			return albums
		}
	}
	
	let				clientID				:	String
	let				clientSecret			:	String
	var				accessToken				:	String?
	var				refreshToken			:	String?
	var				userName				:	String?
	
	var				session					:	URLSession!
}


public
struct
Album : Unmarshaling
{
	public
	init(object inObject: MarshaledObject)
		throws
	{
		self.id = try inObject.value(for: "id")
		self.link = try inObject.value(for: "link")
		self.title = try inObject.value(for: "title")
		self.description = try inObject.value(for: "description")
		self.views = try inObject.value(for: "views")
	}
	
	var		id				:	String
	var		link			:	String
	var		title			:	String
	var		description		:	String
	var		views			:	Int
}
