//
//  RadarTaniMobileApp.swift
//  RadarTaniMobile
//
//  Created by Hendra Irawan on 08/07/26.
//

import SwiftUI

@main
struct RadarTaniApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(environment)
                .preferredColorScheme(.light)
        }
    }
}