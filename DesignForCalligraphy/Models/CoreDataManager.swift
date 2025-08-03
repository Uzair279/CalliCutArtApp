import Foundation
import CoreData

final class CoreDataManager {
    
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "StorageData")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: Save model
    func saveUserModel(_ model: UserSaveModel) {
        let user = User(context: context)
        if let jsonData = try? JSONEncoder().encode(model),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            user.info = jsonString
            saveContext()
        } else {
            print("Failed to encode model")
        }
    }

    // MARK: Fetch all models
    func fetchUserModels() -> [UserSaveModel] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try context.fetch(request)
            return users.compactMap {
                guard let json = $0.info?.data(using: .utf8) else { return nil }
                return try? JSONDecoder().decode(UserSaveModel.self, from: json)
            }
        } catch {
            print("Failed to fetch users: \(error)")
            return []
        }
    }

    // MARK: Update (find first matching model)
    func updateUserModel(matching match: (UserSaveModel) -> Bool, update: (inout UserSaveModel) -> Void) {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try context.fetch(request)
            for user in users {
                guard let info = user.info,
                      let data = info.data(using: .utf8),
                      var model = try? JSONDecoder().decode(UserSaveModel.self, from: data)
                else { continue }

                if match(model) {
                    update(&model)
                    if let updatedData = try? JSONEncoder().encode(model),
                       let updatedString = String(data: updatedData, encoding: .utf8) {
                        user.info = updatedString
                        saveContext()
                    }
                    break
                }
            }
        } catch {
            print("Failed to update user model: \(error)")
        }
    }

    // MARK: Save context
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Context save error: \(error)")
            }
        }
    }
}
