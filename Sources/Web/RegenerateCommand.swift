//
//  RegenerateCommand.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/24/17.
//
//

import CommandLineParser

struct RegenerateCommand {
    static func handler(generators: [StaticPagesGenerator]) -> ((_ parser: Parser) throws -> ()) {
        return { parser in
            let domain = parser.string(named: "domain")
            try parser.parse()

            StaticPagesGenerator.removeDirectory(at: "Generated-working")
            StaticPagesGenerator.createDirectory(at: "Generated-working")

            for generator in generators {
                do {
                    var domain = domain.parsedValue
                    if domain.hasSuffix("/") {
                        domain.removeLast()
                    }
                    try generator.generate(forDomain: domain)
                }
                catch let error {
                    print("error\n\(error)")
                }
            }

            print("Replacing production version...", terminator: "")
            StaticPagesGenerator.removeDirectory(at: "Generated")
            try StaticPagesGenerator.moveItem(from: "Generated-working", to: "Generated")
            print("done")
        }
    }
}
