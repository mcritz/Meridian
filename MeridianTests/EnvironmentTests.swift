//
//  EnvironmentTests.swift
//  
//
//  Created by Soroush Khanlou on 9/3/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

extension EnvironmentKey {
    static let formatter = EnvironmentKey()
}

struct EnvironmentKeyTestRoute: Route {
    static let route: RouteMatcher = "/environmentKey"
    
    @Environment(.formatter) var formatter: NumberFormatter
    
    func execute() throws -> Response {
        formatter.string(from: 343) ?? "formatter couldn't format"
    }
}

struct Todo: Encodable {
    let label: String
    let done: Bool
}

final class Database {
    let todos: [Todo]
    
    init() {
        todos = [
            Todo(label: "Finish environment property wrappers", done: true),
            Todo(label: "Implement an endpoint with a \"database\"", done: true),
            Todo(label: "Profit!", done: false),
        ]
    }
}

struct EnvironmentObjectTestRoute: Route {
    static let route: RouteMatcher = "/environmentObject"
    
    @EnvironmentObject var database: Database
    
    func execute() throws -> Response {
        JSON(database.todos)
    }
}

final class EnvironmentTests: XCTestCase {
    
    func makeChannel() throws -> EmbeddedChannel {
        let handler = HTTPHandler(routesByPrefix: ["": [
            EnvironmentKeyTestRoute.self,
            EnvironmentObjectTestRoute.self,
        ]], errorRenderer: BasicErrorRenderer.self)
        
        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(handler).wait()
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .spellOut
        EnvironmentStorage.shared.keyedObjects[.formatter] = formatter
        
        EnvironmentStorage.shared.objects.append(Database())
        
        return channel
    }
    
    func testEnvironmentKeys() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/environmentKey", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "three hundred forty-three")
    }
    
    func testEnivironmentObjects() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/environmentObject", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "[{\"label\":\"Finish environment property wrappers\",\"done\":true},{\"label\":\"Implement an endpoint with a \\\"database\\\"\",\"done\":true},{\"label\":\"Profit!\",\"done\":false}]")
    }
}