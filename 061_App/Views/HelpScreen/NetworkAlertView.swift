import SwiftUI

struct NetworkAlertView: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    var body: some View {
        if !networkMonitor.isConnected {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                    Text("No Internet Connection")
                        .foregroundColor(.white)
                        .font(.headline)
                }

                Text("Please check your internet settings")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black.opacity(0.8))
            .transition(.move(edge: .bottom))
        }
    }
} 
