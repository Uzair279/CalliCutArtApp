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
    func saveIsFirstTime(_ model: IsFirstTime) {
        let user = User(context: context)
        if let jsonData = try? JSONEncoder().encode(model),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            user.data = jsonString
            saveContext()
        } else {
            print("Failed to encode model")
        }
    }
    

    // MARK: Fetch all models
    func fetchFirstTimeModel() -> [IsFirstTime] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try context.fetch(request)
            return users.compactMap {
                guard let json = $0.data?.data(using: .utf8) else { return nil }
                return try? JSONDecoder().decode(IsFirstTime.self, from: json)
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
extension CoreDataManager {
    
    // MARK: Save page count model
    func saveUserSettings(_ model: UserSettings) {
        let user = User(context: context)
        user.page = String(model.count)
        saveContext()
    }
    
    // MARK: Fetch page count model
    func fetchUserSettings() -> [UserSettings] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try context.fetch(request)
            return users.compactMap {
                guard let pageString = $0.page, let count = Int(pageString) else { return nil }
                return UserSettings(count: count)
            }
        } catch {
            print("❌ Failed to fetch user settings:", error)
            return []
        }
    }


        func updateOrCreatePageCount(newValue: Int) {
            let request: NSFetchRequest<User> = User.fetchRequest()
            do {
                let users = try context.fetch(request)

                if let user = users.first {
                    // ✅ Only update the page attribute
                    user.page = String(newValue)
                } else {
                    // ✅ Create a new record if none exists
                    let newUser = User(context: context)
                    newUser.page = String(newValue)
                    // Keep other attributes nil or initialize as needed
                }

                saveContext()
                print("✅ Page count saved/updated to \(newValue)")
            } catch {
                print("❌ Failed to update page count:", error)
            }
        }



    // MARK: Fetch current page count (returns Int)
    func getCurrentPageCount() -> Int {
            let request: NSFetchRequest<User> = User.fetchRequest()
            do {
                let users = try context.fetch(request)
                if let user = users.first, let pageStr = user.page, let page = Int(pageStr) {
                    return page
                }
            } catch {
                print("❌ Failed to fetch page count:", error)
            }
            return 0
        }
}
