//
//  Tester.swift
//
//
//  Created by Douglas Adams on 8/9/20.
//

import xLib6001
import SwiftUI
import xClient6001

#if os(macOS)
let kAppName = "xApiMac"
#elseif os(iOS)
let kAppName = "xApiIos"
#endif

struct Message: Identifiable {
    var id = 0
    var text = ""
    var color = Color(.textColor)
}

enum ObjectFilters: String, CaseIterable {
    case none
    case sliceMeters
    case otherMeters
    case allMeters
    case slices
    case streams
}
enum MessageFilters: String, CaseIterable {
    case none
    case prefix
    case includes
    case excludes
    case command
    case status
    case reply
    case S0
}

final class Tester: ObservableObject {
    // ----------------------------------------------------------------------------
    // MARK: - Published properties

    @Published var cmdToSend                    = ""
    @Published var filteredMessages             = [Message]()

    // ----------------------------------------------------------------------------
    // MARK: - Defaults properties

    @AppStorage("clearOnSend") var clearOnSend: Bool = false
    @AppStorage("clearAtConnect") var clearAtConnect: Bool = false
    @AppStorage("clearAtDisconnect") var clearAtDisconnect: Bool = false
    @AppStorage("clientId") var clientId: String = ""
    @AppStorage("fontSize") var fontSize: Int = 12
    @AppStorage("fontMaxSize") var fontMaxSize: Int = 16
    @AppStorage("fontMinSize") var fontMinSize: Int = 8
    @AppStorage("messagesFilterBy") var messagesFilterBy: String = "none"
    @AppStorage("messagesFilterText") var messagesFilterText: String = ""
    @AppStorage("showPings") var showPings: Bool = false
    @AppStorage("showReplies") var showReplies: Bool = false

    // ----------------------------------------------------------------------------
    // MARK: - Internal properties

    var activePacket: DiscoveryPacket?
    var isConnected = false
    var stationName = ""

    // ----------------------------------------------------------------------------
    // MARK: - Private properties

    private var _api = Api.sharedInstance
    private var _commandsIndex = 0
    private var _commandHistory = [String]()
    private lazy var _log = LogManager.sharedInstance.logMessage
    private var _messageNumber = 0
    private let _objectQ  = DispatchQueue(label: kAppName + ".objectQ", attributes: [.concurrent])
    private var _radios: [Radio] { Discovery.sharedInstance.radios }
    private var _previousCommand = ""
    private var _startTimestamp: Date?

    private let commandsColor = Color(.systemGreen)
    private let repliesColor = Color(.systemGray)
    private let repliesWithErrorsColor = Color(.systemGray)
    private let standardColor = Color(.textColor)
    private let statusColor = Color(.systemOrange)

    // ----------------------------------------------------------------------------
    // MARK: - Private properties with concurrency protection

    private var messages: [Message] {
        get { return _objectQ.sync { _messages } }
        set { _objectQ.sync(flags: .barrier) { _messages = newValue } } }

    // ----- Backing store, do not use -----
    private var _messages = [Message]()

    // ----------------------------------------------------------------------------
    // MARK: - Initialization

    init() {
        // give the Api access to the logger
        LogProxy.sharedInstance.delegate = LogManager.sharedInstance

        // is there a saved Client ID?
        if clientId.isEmpty {
            // NO, assign one
            clientId = UUID().uuidString
            _log("Tester: ClientId created - \(clientId)", .debug, #function, #file, #line)
        }
        _api.testerModeEnabled = true

        // receive delegate actions from the Api
        _api.testerDelegate = self
    }

    // ----------------------------------------------------------------------------
    // MARK: - Internal methods

    /// A command  was sent to the Radio
    func sent(command: String) {
        guard command.isEmpty == false else { return }

        if command != _previousCommand { _commandHistory.append(command) }

        _previousCommand = command
        _commandsIndex = _commandHistory.count - 1

        // optionally clear the Command field
        if clearOnSend { DispatchQueue.main.async { self.cmdToSend = "" }}
    }

    /// Clear the messages area
    func clearMessages() {
        DispatchQueue.main.async {  [self] in
            _messageNumber = 0
            messages.removeAll()
            filterUpdate(filterBy: messagesFilterBy, filterText: messagesFilterText)        }
    }

    /// Send a command to the Radio
    func sendCommand(_ command: String) {
        guard command.isEmpty == false else { return }

        // send the command to the Radio via TCP
        _api.send( command )

        if command != _previousCommand { _commandHistory.append(command) }

        _previousCommand = command
        _commandsIndex = _commandHistory.count - 1

        // optionally clear the Command field
        if clearOnSend { DispatchQueue.main.async { self.cmdToSend = "" }}
    }

    /// Adjust the font size larger or smaller (within limits)
    /// - Parameter larger:           larger?
    func fontSize(larger: Bool) {
        // incr / decr the size
        var newSize =  fontSize + (larger ? +1 : -1)
        // subject to limits
        if larger {
            if newSize > fontMaxSize { newSize = fontMaxSize }
        } else {
            if newSize < fontMinSize { newSize = fontMinSize }
        }
        fontSize = newSize
    }

    // ----------------------------------------------------------------------------
    // MARK: - Private methods

    /// Filter the message collection
    /// - Parameter type:     object type
    func filterUpdate(filterBy: String, filterText: String) {

        switch (filterBy, filterText) {

        case (MessageFilters.none.rawValue, _):       filteredMessages = messages
        case (MessageFilters.prefix.rawValue, ""):    filteredMessages = messages
        case (MessageFilters.prefix.rawValue, _):     filteredMessages =  messages.filter { $0.text.localizedCaseInsensitiveContains("|" + filterText) }
        case (MessageFilters.includes.rawValue, ""):  filteredMessages = [Message]()
        case (MessageFilters.includes.rawValue, _):   filteredMessages =  messages.filter { $0.text.localizedCaseInsensitiveContains(filterText) }
        case (MessageFilters.excludes.rawValue, ""):  filteredMessages = messages
        case (MessageFilters.excludes.rawValue, _):   filteredMessages =  messages.filter { !$0.text.localizedCaseInsensitiveContains(filterText) }
        case (MessageFilters.command.rawValue, _):    filteredMessages =  messages.filter { $0.text.dropFirst(9).prefix(1) == "C" }
        case (MessageFilters.S0.rawValue, _):         filteredMessages =  messages.filter { $0.text.dropFirst(9).prefix(2) == "S0" }
        case (MessageFilters.status.rawValue, _):     filteredMessages =  messages.filter { $0.text.dropFirst(9).prefix(1) == "S" && $0.text.dropFirst(10).prefix(1) != "0"}
        case (MessageFilters.reply.rawValue, _):      filteredMessages =  messages.filter { $0.text.dropFirst(9).prefix(1) == "R" }
        default: break
        }
    }

    /// Add an entry to the messages collection
    /// - Parameter text:       the text of the entry
    private func populateMessages(_ text: String) {
        DispatchQueue.main.async { [self] in
            // guard that a session has been started
            if _startTimestamp == nil { _startTimestamp = Date() }

            // add the Timestamp to the Text
            let timeInterval = Date().timeIntervalSince(_startTimestamp!)
            let stampedText = String( format: "%8.3f", timeInterval) + " " + text

            _messageNumber += 1
            messages.append( Message(id: _messageNumber, text: stampedText, color: lineColor(text)))

            filterUpdate(filterBy: messagesFilterBy, filterText: messagesFilterText)
        }
    }

    /// Assign each text line a color
    /// - Parameter text:   the text line
    /// - Returns:          a Color
    private func lineColor(_ text: String) -> Color {

        if text.prefix(1) == "C" { return commandsColor }                                   // Commands
        if text.prefix(1) == "R" && text.contains("|0|") { return repliesColor }            // Replies no error
        if text.prefix(1) == "R" && !text.contains("|0|") { return repliesWithErrorsColor } // Replies w/error
        if text.prefix(2) == "S0" { return statusColor }                                    // Status

        return standardColor
    }

    /// Parse a Reply message. format: <sequenceNumber>|<hexResponse>|<message>[|<debugOutput>]
    /// - parameter commandSuffix:    a Command Suffix
    private func parseReplyMessage(_ commandSuffix: String) {
        // separate it into its components
        let components = commandSuffix.components(separatedBy: "|")

        // ignore incorrectly formatted replies
        guard components.count >= 2 else { populateMessages("ERROR: R\(commandSuffix)") ; return }

        if showReplies || components[1] != "0" || (components.count >= 3 && components[2] != "") {
            populateMessages("R\(commandSuffix)")
        }
    }
}

// ----------------------------------------------------------------------------
// MARK: - RadioManagerDelegate extension

extension Tester: RadioManagerDelegate {
    func willConnect() { if clearAtConnect { clearMessages() } }
    func willDisconnect() { if clearAtDisconnect { clearMessages() } }

    // unused RadioManagerDelegate methods
    func didConnect() { /* unused */ }
    func didFailToConnect() { /* unused */ }
}

// ----------------------------------------------------------------------------
// MARK: - ApiDelegate extension

extension Tester: ApiDelegate {
    public func sentMessage(_ text: String) {
        if !text.hasSuffix("|ping") { populateMessages(text) }
        if text.hasSuffix("|ping") && showPings { populateMessages(text) }
    }

    public func receivedMessage(_ text: String) {
        // get all except the first character
        let suffix = String(text.dropFirst())

        // switch on the first character
        switch text[text.startIndex] {

        case "C":   populateMessages(text)       // Commands
        case "H":   populateMessages(text)       // Handle type
        case "M":   populateMessages(text)       // Message Type
        case "R":   parseReplyMessage(suffix)    // Reply Type
        case "S":   populateMessages(text)       // Status type
        case "V":   populateMessages(text)       // Version Type
        default:    populateMessages("Tester: Unknown Message type, \(text[text.startIndex]) ") // Unknown Type
        }
    }

    // unused ApiDelegate methods
    func addReplyHandler(_ sequenceNumber: SequenceNumber, replyTuple: ReplyTuple) { /* unused */ }
    func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) { /* unused */ }
    func vitaParser(_ vitaPacket: Vita) { /* unused */ }
}
