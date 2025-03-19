import SwiftUI

@MainActor
class GenerationManager: ObservableObject {
    static let shared = GenerationManager()
    
    private let maxActiveGenerations = 2
    private var activeGenerations: Set<String> = []
    
    private init() {}
    
    func canStartNewGeneration() -> Bool {
        return activeGenerations.count < maxActiveGenerations
    }
    
    func addGeneration(_ generationId: String) {
        activeGenerations.insert(generationId)
    }
    
    func removeGeneration(_ generationId: String) {
        activeGenerations.remove(generationId)
    }
    
    var activeGenerationsCount: Int {
        return activeGenerations.count
    }
    
    var maxGenerations: Int {
        return maxActiveGenerations
    }
} 