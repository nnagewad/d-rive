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
            Button("Get Location") {
                locationManager.requestLocation()
            }

            if let lat = locationManager.latitude,
               let lon = locationManager.longitude {
                Text("Lat: \(lat)")
                Text("Lon: \(lon)")
            } else {
                Text("No location yet")
            }
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
