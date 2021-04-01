//
//  ContentView.swift
//  xApiMac
//
//  Created by Douglas Adams on 8/9/20.
//

import SwiftUI
import xClient

struct ContentView: View {
    @ObservedObject var tester: Tester
    @ObservedObject var radioManager: RadioManager
    @ObservedObject var meterManager: MeterManager

    @State var selectedTab = 1

    var body: some View {

        TabView {
            ApiTesterView()
                .environmentObject(tester)
                .environmentObject(radioManager)
                .tabItem {Text("Api Tester")}

            LogView()
                .environmentObject(LogManager.sharedInstance)
                .environmentObject(radioManager)
                .tabItem {Text("Log View")}

            MetersView()
                .environmentObject(meterManager)
                .tabItem {Text("Meters View")}
        }
        // Sheet presentation
       .sheet(item: $radioManager.activeView) { viewType in
           switch viewType {

           case .genericAlert:             GenericAlertView().environmentObject(radioManager)
           case .radioPicker:              RadioPickerView().environmentObject(radioManager)
           case .smartlinkAuthentication:  smartlinkAuthenticationView().environmentObject(radioManager)
           case .smartlinkStatus:          SmartlinkStatusView().environmentObject(radioManager)
           }
       }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tester: Tester(), radioManager: RadioManager(delegate: Tester() as RadioManagerDelegate), meterManager: MeterManager() )
    }
}
