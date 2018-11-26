//
//  FaviconRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/21/17.
//
//

public struct FaviconRouter: Router {
    public init() {}

    public let routes: [Route] = [
        .get("android-chrome-192x192.png", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/android-chrome-192x192.png", status: .ok))
        }),
        .get("android-chrome-512x512.png", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/android-chrome-512x512.png", status: .ok))
        }),
        .get("apple-touch-icon.png", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/apple-touch-icon.png", status: .ok))
        }),
        .get("browserconfig.xml", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/browserconfig.xml", status: .ok))
        }),
        .get("favicon-16x16.png", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/favicon-16x16.png", status: .ok))
        }),
        .get("favicon-32x32.png", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/favicon-32x32.png", status: .ok))
        }),
        .get("favicon.ico", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/favicon.ico", status: .ok))
        }),
        .get("manifest.json", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/manifest.json", status: .ok))
        }),
        .get("mstile-150x150.png", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/mstile-150x150.png", status: .ok))
        }),
        .get("safari-pinned-tab.svg", handler: { request in
            return .handled(try request.response(withFileAt: "Assets/img/favicons/safari-pinned-tab.svg", status: .ok))
        }),
    ]
}
