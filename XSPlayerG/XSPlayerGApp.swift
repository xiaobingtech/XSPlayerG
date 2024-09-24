//
//  XSPlayerGApp.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/12.
//

import SwiftUI
import SwiftData

var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        XS_SDAnalyze.self,
        XS_SDAnalyzeCollect.self,
        XS_SDChannel.self,
        XS_SDIptv.self,
        XS_SDSite.self,
        XS_SDSiteGroup.self,
        XS_SDSiteSearch.self,
        XS_SDSiteCollect.self,
        XS_SDSiteHistory.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

@main
struct XSPlayerGApp: App {
    var body: some Scene {
        WindowGroup {
            XS_RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
