//
//  BottomButtonsView.swift
//  xApiMac
//
//  Created by Douglas Adams on 7/28/20.
//  Copyright © 2020 Douglas Adams. All rights reserved.
//

import SwiftUI
import xClient

struct BottomButtonsView: View {
    @ObservedObject var tester: Tester
    @ObservedObject var radioManager: RadioManager
    @Environment(\.openURL) var openURL

    var body: some View {

        HStack(spacing: 40) {
            Stepper("Font Size", value: $tester.fontSize, in: 8...24)
            Spacer()
            Toggle("Clear on Connect", isOn: $tester.clearAtConnect)
            Toggle("Clear on Disconnect", isOn: $tester.clearAtDisconnect)
            Button("Clear Now") { tester.clearObjectsAndMessages() }
            Spacer()
            Button("Log Window") {
                    openURL(URL(string: "xApiMac://LoggerView")!)
            }.disabled(radioManager.loggerViewIsOpen)
        }
    }
}

struct BottomButtonsView_Previews: PreviewProvider {

    static var previews: some View {
        BottomButtonsView(tester: Tester(), radioManager: RadioManager(delegate: Tester() as RadioManagerDelegate) )
    }
}
