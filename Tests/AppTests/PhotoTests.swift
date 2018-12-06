import XCTest
@testable import Vapor
@testable import App

final class PhotoTests: XCTestCase {
  func testGetWatermakedPhoto() throws {
    let app = try Application.makeTest(routes: routes)
    
    try app.test(.GET, "/photos/show/barcelona") { response in
      XCTAssertEqual(response.http.status, .ok)
      XCTAssertEqual(response.http.contentType, MediaType.jpeg)
      let length = response.http.headers["content-length"].first!
      XCTAssertGreaterThan(Int(length)!, 0)
    }
  }
  
  static let allTests = [
    ("testGetWatermakedPhoto", testGetWatermakedPhoto)
  ]
}
