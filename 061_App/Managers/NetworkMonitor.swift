import SwiftUI
import Network

class NetworkMonitor: ObservableObject {
  
  static let shared = NetworkMonitor()
  @Published var isConnected: Bool = true
  @Published var connectionType: NWInterface.InterfaceType?
  
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "NetworkMonitorQueue")
  
  private init() {
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        self?.isConnected = (path.status == .satisfied)
        self?.connectionType = path.availableInterfaces.first?.type
      }
    }
    
    monitor.start(queue: queue)
  }
  
  deinit {
    monitor.cancel()
  }
}
