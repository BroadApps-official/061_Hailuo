//import CoreData
//import SwiftUI
//
//class ProjectManager: ObservableObject {
//  static let shared = ProjectManager()
//  private init() {
//    loadProjects()
//  }
//  
//  private let context = CoreDataManager.shared.context
//  
//  @Published var presets: [Project] = []
//  @Published var artworks: [Project] = []
//  
//  func addToPreset(_ project: Project) {
//    saveToCoreData(project, category: "Preset")
//    loadProjects()
//  }
//  
//  func addToArtwork(_ project: Project) {
//    saveToCoreData(project, category: "Artwork")
//    loadProjects()
//  }
//  
//  func loadProjects() {
//    let fetchRequest: NSFetchRequest<CachedProject> = CachedProject.fetchRequest()
//    do {
//      let cachedProjects = try context.fetch(fetchRequest)
//      
//      DispatchQueue.main.async {
//        self.presets = cachedProjects
//          .filter { $0.category == "Preset" }
//          .map { Project(
//            id: $0.id ?? UUID().uuidString,
//            imageName: $0.imageName ?? "",
//            date: $0.date ?? "",
//            isSelected: $0.isSelected,
//            isLoading: false
//          )}
//        
//        self.artworks = cachedProjects
//          .filter { $0.category == "Artwork" }
//          .map { Project(
//            id: $0.id ?? UUID().uuidString,
//            imageName: $0.imageName ?? "",
//            date: $0.date ?? "",
//            isSelected: $0.isSelected,
//            isLoading: false
//          )}
//      }
//    } catch {
//      print("❌ \(error.localizedDescription)")
//    }
//  }
//  
//  func updateProjectImage(projectId: String, newImageUrl: String) {
//    let fetchRequest: NSFetchRequest<CachedProject> = CachedProject.fetchRequest()
//    fetchRequest.predicate = NSPredicate(format: "id == %@", projectId)
//    
//    do {
//      if let projectToUpdate = try context.fetch(fetchRequest).first {
//        projectToUpdate.imageName = newImageUrl
//        projectToUpdate.isLoading = false
//        try context.save()
//        
//        DispatchQueue.main.async {
//          if let index = self.presets.firstIndex(where: { $0.id == projectId }) {
//            self.presets[index].imageName = newImageUrl
//            self.presets[index].isLoading = false
//            self.objectWillChange.send()
//          } else if let index = self.artworks.firstIndex(where: { $0.id == projectId }) {
//            self.artworks[index].imageName = newImageUrl
//            self.artworks[index].isLoading = false
//            self.objectWillChange.send()
//          }
//        }
//      } else {
//      }
//    } catch {
//      print("❌\(error)")
//    }
//  }
//  
//  func deleteProject(_ project: Project) {
//    let fetchRequest: NSFetchRequest<CachedProject> = CachedProject.fetchRequest()
//    fetchRequest.predicate = NSPredicate(format: "id == %@", project.id)
//    
//    do {
//      let results = try context.fetch(fetchRequest)
//      results.forEach { context.delete($0) }
//      try context.save()
//      
//      if let index = presets.firstIndex(where: { $0.id == project.id }) {
//        presets.remove(at: index)
//      } else if let index = artworks.firstIndex(where: { $0.id == project.id }) {
//        artworks.remove(at: index)
//      }
//      
//    } catch {
//      print("❌ \(error.localizedDescription)")
//    }
//  }
//  
//  func saveToCoreData(_ project: Project, category: String) {
//    let cachedProject = CachedProject(context: context)
//    cachedProject.id = project.id
//    cachedProject.imageName = project.imageName
//    cachedProject.date = project.date
//    cachedProject.isSelected = project.isSelected
//    cachedProject.category = category
//    
//    do {
//      try context.save()
//    } catch {
//      print("❌ \(error.localizedDescription)")
//    }
//  }
//}
