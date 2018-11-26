//
//  RegenerateCommand.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/24/17.
//
//

import CommandLineParser

public struct RegenerateCommand {
    public static func handler(configuration: BlogConfiguration) -> ((_ parser: Parser) throws -> ()) {
        return { parser in
            let domain = parser.string(named: "domain")
            try parser.parse()

            let generator = StaticPagesGenerator(configuration: configuration)
            do {
                try generator.generate(forDomain: domain.parsedValue)
            }
            catch let error {
                print("error\n\(error)")
            }
        }
    }
}
