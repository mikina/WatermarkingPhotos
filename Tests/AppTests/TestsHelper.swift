import XCTest
import Foundation
@testable import Vapor

public extension Application {
  // MARK: Static
  static func makeTest(configure: (inout Config, inout Services) throws -> () = { _, _ in }, routes: (Router) throws -> ()) throws -> Application {
    var services = Services.default()
    var config = Config.default()
    try configure(&config, &services)
    
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    return try Application.asyncBoot(config: config, environment: .xcode, services: services).wait()
  }
  
  @discardableResult
  func test(
    _ method: HTTPMethod,
    _ path: String,
    beforeSend: @escaping (Request) throws -> () = { _ in },
    afterSend: @escaping (Response) throws -> ()
    ) throws  -> Application {
    let http = HTTPRequest(method: method, url: URL(string: path)!)
    return try test(http, beforeSend: beforeSend, afterSend: afterSend)
  }
  
  @discardableResult
  func test(
    _ http: HTTPRequest,
    beforeSend: @escaping (Request) throws -> () = { _ in },
    afterSend: @escaping (Response) throws -> ()
    ) throws -> Application {
    let promise = eventLoop.newPromise(Void.self)
    eventLoop.execute {
      let req = Request(http: http, using: self)
      do {
        try beforeSend(req)
        try self.make(Responder.self).respond(to: req).map { res in
          try afterSend(res)
          }.cascade(promise: promise)
      } catch {
        promise.fail(error: error)
      }
    }
    try promise.futureResult.wait()
    return self
  }
  
  // MARK: Live
  static func runningTest(port: Int, configure: (Router) throws -> ()) throws -> Application {
    let router = EngineRouter.default()
    try configure(router)
    var services = Services.default()
    services.register(router, as: Router.self)
    let serverConfig = NIOServerConfig(
      hostname: "localhost",
      port: port,
      backlog: 8,
      workerCount: 1,
      maxBodySize: 128_000,
      reuseAddress: true,
      tcpNoDelay: true,
      webSocketMaxFrameSize: 1 << 14
    )
    services.register(serverConfig)
    let app = try Application.asyncBoot(config: .default(), environment: .xcode, services: services).wait()
    try app.asyncRun().wait()
    return app
  }
  
  func clientTest(
    _ method: HTTPMethod,
    _ path: String,
    beforeSend: (Request) throws -> () = { _ in },
    afterSend: (Response) throws -> ()
    ) throws {
    let config = try make(NIOServerConfig.self)
    let path = path.hasPrefix("/") ? path : "/\(path)"
    let req = Request(
      http: .init(method: method, url: "http://localhost:\(config.port)" + path),
      using: self
    )
    try beforeSend(req)
    let res = try FoundationClient.default(on: self).send(req).wait()
    try afterSend(res)
  }
  
  func clientTest(_ method: HTTPMethod, _ path: String, equals: String) throws {
    return try clientTest(method, path) { res in
      XCTAssertEqual(res.http.body.string, equals)
    }
  }
}

private extension Environment {
  static var xcode: Environment {
    return .init(name: "xcode", isRelease: false, arguments: ["xcode"])
  }
}

private extension HTTPBody {
  var string: String {
    guard let data = self.data else {
      return "<streaming>"
    }
    return String(data: data, encoding: .ascii) ?? "<non-ascii>"
  }
}

private extension Data {
  var utf8: String? {
    return String(data: self, encoding: .utf8)
  }
}
