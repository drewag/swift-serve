//
//  SubscribersRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/26/16.
//
//

import Swiftlier

struct SubscribersRouter: Router, ErrorGenerating {
    enum SubscriberField: String, HTMLFormField {
        case email

        static var action = "subscribing"
        static var all: [SubscriberField] = [.email]
    }

    private let configuration: BlogConfiguration

    init(configuration: BlogConfiguration) {
        self.configuration = configuration
    }

    var routes: [Route] {
        return [
            .any("new", handler: { request in
                let form: HTMLForm<SubscriberField> = request.parseForm(process: { form in
                    let email: String = try form.requiredValue(for: .email)
                    guard email.isValidEmail else {
                        throw SubscribersRouter.userError("subscribing", because: "the email is invalid")
                    }
                    let service = SubscriberService(connection: request.databaseConnection, configuration: self.configuration)
                    try service.addSubscriber(withEmail: email)
                    form.message = "Subscribed Successfully"
                    return nil
                })
                return try request.responseStatus(
                    template: "Views/Blog/NewSubscriber.html",
                    form: form
                )
            }),
            .get("unsubscribe", handler: { request in
                return .handled(try request.response(
                    template: "Views/Blog/Unsubscribe.html",
                    build: { context in
                        do {
                            let service = SubscriberService(connection: request.databaseConnection, configuration: self.configuration)
                            guard let token = request.formValues()["token"]
                                , let subscriber = try service.subscriber(withUnsubscribeToken: token)
                                else
                            {
                                context["error"] = "Invalid Token"
                                return
                            }

                            try service.unsubscribe(subscriber)
                            context["message"] = "Unsubscribed successfully. You will not recieve any additional emails and your email has been completely removed from our database."
                        }
                        catch let error as ReportableError {
                            context["error"] = error.description
                        }
                        catch let error as ReportableErrorConvertible {
                            context["error"] = error.reportableError.description
                        }
                        catch let error {
                            context["error"] = "\(error)"
                        }
                    }
                ))
            })
        ]
    }
}
