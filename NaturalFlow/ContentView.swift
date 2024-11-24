//
//  ContentView.swift
//  NaturalFlow
//
//  Created by FrankYin on 2024-11-08.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        LibraryView()
    }

}
