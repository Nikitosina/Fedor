import Hummingbird
import Foundation
import ArgumentParser
@preconcurrency import TelegramBotSDK

let tgBot = TelegramBot(token: "7869692240:AAGHGwd2B-wyXEqbdzF6c4UfJdXzelx2Nfc")
let tgBotRouter = TelegramBotSDK.Router(bot: tgBot)
let chatId: Int64 = 369172417

@main
struct HummingbirdArguments: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "0.0.0.0"

    @Option(name: .shortAndLong)
    var port: Int = 8060

    func run() async throws {
        let app = buildApplication(
            configuration: .init(
                address: .hostname(self.hostname, port: self.port),
                serverName: "Hummingbird"
            )
        )
        tgBotRouter["start", .slashRequired] = { context in
            print(context.chatId)
            return true
        }
        Task {
            do {
                while let update = tgBot.nextUpdateSync() {
                    try tgBotRouter.process(update: update)
                }
            } catch {}
        }
        try await app.runService()
    }
}

func buildApplication(configuration: ApplicationConfiguration) -> some ApplicationProtocol {
    let router = Router()

    router.get("/") { _, _ in
        return "Fedor API - Feedback collector"
    }
    router.post("/store_feedback", use: storeFeedback)

    let app = Application(
        router: router,
        configuration: configuration
    )
    return app
}

func storeFeedback(_ request: Request, context: any RequestContext) async throws -> Response {
    guard let userId = request.uri.queryParameters.get("user_id") else { return Response(status: .badRequest) }
    guard let feedback = try? await request.decode(as: Feedback.self, context: context) else {
        return Response(status: .badRequest)
    }
    let logsDoc = InputFile(filename: "logs.txt", data: feedback.logs.data(using: .utf8) ?? Data())
    if let chatLogs = feedback.chatLogs {
        let chatLogsDoc = InputFile(filename: "chatLogs.txt", data: chatLogs.data(using: .utf8) ?? Data())
        tgBot.sendDocumentSync(chatId: .chat(chatId), document: .inputFile(chatLogsDoc))
    }

    let messageContent = "UserID: \(userId)\nComment: \(feedback.comment)"
    tgBot.sendDocumentSync(chatId: .chat(chatId), document: .inputFile(logsDoc), caption: messageContent)
    return Response(status: .ok)
}

struct Feedback: Codable {
    let comment: String
    let logs: String
    let chatLogs: String?
}
