//
//  ContentView.swift
//  Calpal-Codex
//
//  Created by Xuantong Yan on 3/27/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        switch AppLaunchMode.current {
        case .dashboard:
            ReadmeShowcaseView(mode: .dashboard)
        case .smartScheduling:
            ReadmeShowcaseView(mode: .smartScheduling)
        case .none:
            RootView()
        }
    }
}

#Preview {
    ContentView()
}
