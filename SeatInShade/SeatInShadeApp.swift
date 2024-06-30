//
//  SeatInShadeApp.swift
//  SeatInShade
//
//  Created by Kunal Kamble on 30/06/24.
//

import SwiftUI

@main
struct SeatInShadeApp: App {
    let mapState = MapState()

    var body: some Scene {
        WindowGroup {
            ContentView(mapState: mapState)
        }
    }
}
