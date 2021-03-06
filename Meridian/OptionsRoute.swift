//
//  OptionsRoute.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

struct RouterEnvironmentKey: EnvironmentKey {
    static var defaultValue = Router(routesByPrefix: [:], defaultErrorRenderer: BasicErrorRenderer())
}

extension EnvironmentValues {
    var router: Router {
        get {
            self[RouterEnvironmentKey.self]
        }
        set {
            self[RouterEnvironmentKey.self] = newValue
        }
    }
}

struct OptionsRoute: Responder {
    
    @Environment(\.router) var router

    @Path var path: String

    func execute() throws -> Response {

        let matchingMethods = try self.router.methods(for: path)

        return EmptyResponse()
            .additionalHeaders([
                "Allow": HTTPMethod.primaryMethods.filter(matchingMethods.contains).map({ $0.name }).joined(separator: ", ")
            ])
            .allowCORS()
    }
}
