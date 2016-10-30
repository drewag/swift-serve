//
//  Status.swift
//  SwiftServe
//
//  Created by Andrew Wagner on 10/29/16.
//
//

public enum HTTPStatus: Int {
    // Successful
    case ok = 200
    case created = 201
    case accepted = 202
    case noContent = 204

    // Client Error
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404

    // Server Error
    case internalServerError = 500
    case notImplemented = 501
}
