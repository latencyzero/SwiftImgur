//
//  ImgurTests.swift
//  ImgurTests
//
//  Created by Rick Mann on 2019-06-27.
//  Copyright © 2019 Latency: Zero, LLC. All rights reserved.
//

import XCTest
@testable import SwiftImgur

import PromiseKit

/**

	https://imgur.com/#access_token=03ec22b840a07423614b2dee0564e5a93c499bc4&expires_in=315360000&token_type=bearer&refresh_token=34a8357807e88cc386b405500575aabcc28291f7&account_username=JetForMe&account_id=21792681

*/

class
ImgurTests: XCTestCase
{
	override
	func
	setUp()
	{
	}

	override
	func
	tearDown()
	{
	}

	func
	testCreaetOauth2URL()
	{
		let im = Imgur(id: "84bfefee03d957a", secret: "8cf87c61e927a90a70e7cc1c347957761784548f")
		let url = im.oauthURL()
		print(url)
	}
	
	func
	testCompleteOAuth2()
		throws
	{
		let exp = expectation(description: "testCompleteOAuth2");
		
		let im = Imgur(id: "84bfefee03d957a", secret: "8cf87c61e927a90a70e7cc1c347957761784548f")
		try im.handleOauth2(callback: "imager://oauth2#access_token=ac73d84cd37cdc9ad54a26e9e177582540e8835e&expires_in=315360000&token_type=bearer&refresh_token=ee72885c475f927242aebc356d9d0296f5232f7f&account_username=JetForMe&account_id=21792681")
		
		firstly
		{
			try im.albums(user: "JetForMe", page: 0)
		}
		.done
		{ inAlbums in
			print("Albums: \(inAlbums)")
			exp.fulfill()
		}
		.catch
		{ inError in
			XCTFail("Error: \(inError)")
		}
		
		waitForExpectations(timeout: 10.0)
	}
}
