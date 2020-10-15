//
//  LogViewer.swift
//  xLibClient package
//
//  Created by Douglas Adams on 10/10/20.
//

import SwiftUI

struct LogView: View {
  let logViewerWindow : NSWindow?
  @EnvironmentObject var logger: Logger

  let width : CGFloat = 1000
  
  var body: some View {

    VStack {
      ScrollView {
        VStack {
          ForEach(logger.logLines) { line in
            Text(line.text)
              .font(.system(.subheadline, design: .monospaced))
              .frame(minWidth: width, maxWidth: .infinity, alignment: .leading)
          }
          .padding(.leading, 5)
        }
      }
      HStack {
        Picker(selection: $logger.level, label: Text("")) {
          ForEach(Logger.LogLevel.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }
        .frame(width: 150, height: 18, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        .padding(.leading, 10)
        .padding(.trailing, 20)
        
        Picker(selection: $logger.filterBy, label: Text("Filter By")) {
          ForEach(Logger.LogFilter.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }
        .frame(width: 150, height: 18, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        
        TextField("Filter text", text: $logger.filterByText)
          .background(Color(.gray))
          .frame(width: 200, alignment: .leading)
          .padding(.trailing, 20)
        
        Toggle("Timestamps", isOn: $logger.showTimestamps).frame(width: 150, alignment: .leading)
        Spacer()
        
        Button(action: {logger.loadLog() }) {Text("Load") }.padding(.trailing, 20)
        Button(action: {logger.saveLog() }) {Text("Save")}.padding(.trailing, 10)
//        Button(action: {logger.openLogWindow = false}) {Text("Close")}.padding(.trailing, 20)

      }
      .padding(.bottom, 10)
    }
    .frame(minWidth: width, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 400, maxHeight: .infinity)
  }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
      LogView(logViewerWindow: NSWindow()).environmentObject( Logger.sharedInstance)
    }
}
