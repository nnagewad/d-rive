//
//  ContentView.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 16) {
            if let lat = locationManager.latitude,
               let lon = locationManager.longitude {
                Text("Lat: \(lat)")
                Text("Lon: \(lon)")
            } else {
                Text("Waiting for location…")
            }
        }
        .padding()
        .onAppear {
            locationManager.start()
        }
        .onDisappear {
            locationManager.stop()
        }
    }
}


#Preview {
    ContentView()
}
