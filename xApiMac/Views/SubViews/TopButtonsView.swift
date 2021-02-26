//
//  TopButtonsView.swift
//  xApiMac
//
//  Created by Douglas Adams on 7/28/20.
//  Copyright © 2020 Douglas Adams. All rights reserved.
//

import SwiftUI
import xClientMac

struct TopButtonsView: View {
    @ObservedObject var tester: Tester
    @ObservedObject var radioManager: RadioManager

    var body: some View {

        HStack(spacing: 30) {
            Button(radioManager.isConnected ? "Stop" : "Start") {
                if radioManager.isConnected {
                    radioManager.stop()
                } else {
                    radioManager.start()
                }
            }
            .help("Using the Default connection type")
            
            Toggle("As Gui", isOn: $tester.enableGui)
            Toggle("Connect to First", isOn: $tester.connectToFirstRadio)
            Toggle("Show Times", isOn: $tester.showTimestamps)
            Toggle("Show Pings", isOn: $tester.showPings)
            Toggle("Show Replies", isOn: $tester.showReplies)
            
            Spacer()
            HStack(spacing: 10){
                Text("SmartLink").frame(width: 75)
                Button(action: {
                    if radioManager.smartlinkIsLoggedIn {
                        radioManager.smartlinkLogout()
                    } else {
                        radioManager.smartlinkLogin()
                    }
                }) {
                    Text(radioManager.smartlinkIsLoggedIn ? "Logout" : "Login").frame(width: 50)
                }
                Button("Status") { radioManager.showSheet(.smartlinkStatus) }
            }.disabled(radioManager.delegate.smartlinkEnabled == false || radioManager.isConnected)
            
            Spacer()
            Button("Defaults") { radioManager.chooseDefaults() }.disabled(radioManager.isConnected)
        }
    }
}

struct TopButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tester: Tester(), radioManager: RadioManager(delegate: Tester() as RadioManagerDelegate) )
    }
}
