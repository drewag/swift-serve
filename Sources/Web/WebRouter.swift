//
//  WebRouter.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 12/2/18.
//

class WebRouter: Router {
    let configuration: WebConfiguration

    var routes: [Route] {
        return []
    }

    init(configuration: WebConfiguration) {
        self.configuration = configuration
    }
}
