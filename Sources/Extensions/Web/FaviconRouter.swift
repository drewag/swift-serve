//
//  FaviconRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/21/17.
//
//

class FaviconRouter: WebRouter {
    var assetRoot: String {
        var path = "Assets/img/favicons/"
        if !self.configuration.viewRoot.isEmpty {
            path += self.configuration.viewRoot + "/"
        }
        return path
    }

    override var routes: [Route] {
        return [
            .get("android-chrome-192x192.png", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)android-chrome-192x192.png", status: .ok))
            }),
            .get("android-chrome-512x512.png", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)android-chrome-512x512.png", status: .ok))
            }),
            .get("apple-touch-icon.png", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)apple-touch-icon.png", status: .ok))
            }),
            .get("browserconfig.xml", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)browserconfig.xml", status: .ok))
            }),
            .get("favicon-16x16.png", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)favicon-16x16.png", status: .ok))
            }),
            .get("favicon-32x32.png", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)favicon-32x32.png", status: .ok))
            }),
            .get("favicon.ico", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)favicon.ico", status: .ok))
            }),
            .get("manifest.json", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)manifest.json", status: .ok))
            }),
            .get("mstile-150x150.png", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)mstile-150x150.png", status: .ok))
            }),
            .get("safari-pinned-tab.svg", handler: { request in
                return .handled(try request.response(withFileAt: "\(self.assetRoot)safari-pinned-tab.svg", status: .ok))
            }),
        ]
    }
}