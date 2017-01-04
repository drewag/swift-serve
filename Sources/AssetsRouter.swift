//
//  AssetsRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/23/16.
//
//

public struct AssetRouter: Router {
    public init() {}

    public var routes: [Route] {
        return [
            .getWithParam(consumeEntireSubPath: true, handler: { (request, path: String) in
                let filePath = "Assets/\(path)"
                do {
                    return .handled(try request.response(withFileAt: filePath, status: .ok))
                }
                catch {
                    return .unhandled
                }
            }),
        ]
    }
}
