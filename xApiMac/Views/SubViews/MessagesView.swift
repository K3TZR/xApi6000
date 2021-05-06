//
//  MessagesView.swift
//  xApiMac
//
//  Created by Douglas Adams on 7/28/20.
//  Copyright © 2020 Douglas Adams. All rights reserved.
//

import SwiftUI

struct MessagesView: View {
    let messages: [Message]
    let fontSize: Int

    @AppStorage("showTimestamps") var showTimestamps: Bool = false

    func timestamps(text: String) -> String {
        if showTimestamps {
            return text
        } else {
            return String(text.dropFirst(9))
        }
    }

    var body: some View {

        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading) {
                ForEach(messages) { message in
                    Text(timestamps(text: message.text))
                        .padding(.leading, 5)
                        .font(.system(size: CGFloat(fontSize), weight: .regular, design: .monospaced))
                        .foregroundColor( message.color )
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 3000, maxWidth: .infinity, alignment: .leading)
            }
            .frame(alignment: .leading)
        }
    }
}

struct MessagesView_Previews: PreviewProvider {

    static var previews: some View {
        let mockMessages = [
            Message(id: 0, text: "11:40:04 C  The first message", color: .red),
            Message(id: 1, text: "11:40:05 R  The second message", color: .orange),
            Message(id: 2, text: "11:40:06 S0 The third message", color: .yellow),
            Message(id: 3, text: "11:40:06    The fourth message", color: .green)
        ]
        MessagesView(messages: mockMessages, fontSize: 20)
    }
}
