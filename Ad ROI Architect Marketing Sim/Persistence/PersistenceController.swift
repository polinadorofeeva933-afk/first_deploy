import CoreData

// MARK: - Persistence Controller

final class PersistenceController {
    static let shared = PersistenceController()
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()

    let container: NSPersistentContainer

    /// Indicates whether the persistent store loaded successfully.
    private(set) var storeLoadError: NSError?

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        container = NSPersistentContainer(name: "AdROIArchitect", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                self?.storeLoadError = error
                #if DEBUG
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
                #else
                // In production: attempt to delete the corrupted store and recreate
                self?.attemptStoreRecovery()
                #endif
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save

    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            #if DEBUG
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
            #endif
            // Rollback unsaved changes to prevent inconsistent state
            context.rollback()
        }
    }

    // MARK: - Store Recovery

    /// Attempts to recover from a corrupted persistent store by removing it and reloading.
    private func attemptStoreRecovery() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }

        do {
            try FileManager.default.removeItem(at: storeURL)
            // Also remove journal files if they exist
            let walURL = storeURL.appendingPathExtension("wal")
            let shmURL = storeURL.appendingPathExtension("shm")
            try? FileManager.default.removeItem(at: walURL)
            try? FileManager.default.removeItem(at: shmURL)
        } catch {
            return
        }

        // Reload store after cleanup
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                self?.storeLoadError = error
            } else {
                self?.storeLoadError = nil
            }
        }
    }

    // MARK: - Programmatic Core Data Model

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: Campaign Entity

        let campaignEntity = NSEntityDescription()
        campaignEntity.name = "CampaignEntity"
        campaignEntity.managedObjectClassName = "CampaignEntity"

        let campaignID = NSAttributeDescription()
        campaignID.name = "id"
        campaignID.attributeType = .UUIDAttributeType
        campaignID.isOptional = false

        let campaignName = NSAttributeDescription()
        campaignName.name = "name"
        campaignName.attributeType = .stringAttributeType
        campaignName.isOptional = false
        campaignName.defaultValue = "Untitled Campaign"

        let campaignBudget = NSAttributeDescription()
        campaignBudget.name = "budget"
        campaignBudget.attributeType = .doubleAttributeType
        campaignBudget.defaultValue = 0.0

        let campaignCPM = NSAttributeDescription()
        campaignCPM.name = "cpm"
        campaignCPM.attributeType = .doubleAttributeType
        campaignCPM.defaultValue = 0.0

        let campaignCTR = NSAttributeDescription()
        campaignCTR.name = "ctr"
        campaignCTR.attributeType = .doubleAttributeType
        campaignCTR.defaultValue = 0.0

        let campaignCR = NSAttributeDescription()
        campaignCR.name = "cr"
        campaignCR.attributeType = .doubleAttributeType
        campaignCR.defaultValue = 0.0

        let campaignAvgCheck = NSAttributeDescription()
        campaignAvgCheck.name = "avgCheck"
        campaignAvgCheck.attributeType = .doubleAttributeType
        campaignAvgCheck.defaultValue = 0.0

        let campaignCurrency = NSAttributeDescription()
        campaignCurrency.name = "currency"
        campaignCurrency.attributeType = .stringAttributeType
        campaignCurrency.isOptional = false
        campaignCurrency.defaultValue = "$"

        let campaignPlatform = NSAttributeDescription()
        campaignPlatform.name = "platform"
        campaignPlatform.attributeType = .stringAttributeType
        campaignPlatform.isOptional = true

        let campaignCreatedAt = NSAttributeDescription()
        campaignCreatedAt.name = "createdAt"
        campaignCreatedAt.attributeType = .dateAttributeType
        campaignCreatedAt.isOptional = false

        let campaignUpdatedAt = NSAttributeDescription()
        campaignUpdatedAt.name = "updatedAt"
        campaignUpdatedAt.attributeType = .dateAttributeType
        campaignUpdatedAt.isOptional = false

        let campaignNotes = NSAttributeDescription()
        campaignNotes.name = "notes"
        campaignNotes.attributeType = .stringAttributeType
        campaignNotes.isOptional = true

        // MARK: Comparison Scenario Entity

        let scenarioEntity = NSEntityDescription()
        scenarioEntity.name = "ComparisonScenarioEntity"
        scenarioEntity.managedObjectClassName = "ComparisonScenarioEntity"

        let scenarioID = NSAttributeDescription()
        scenarioID.name = "id"
        scenarioID.attributeType = .UUIDAttributeType
        scenarioID.isOptional = false

        let scenarioName = NSAttributeDescription()
        scenarioName.name = "name"
        scenarioName.attributeType = .stringAttributeType
        scenarioName.isOptional = false
        scenarioName.defaultValue = "Scenario"

        let scenarioBudget = NSAttributeDescription()
        scenarioBudget.name = "budget"
        scenarioBudget.attributeType = .doubleAttributeType
        scenarioBudget.defaultValue = 0.0

        let scenarioCPM = NSAttributeDescription()
        scenarioCPM.name = "cpm"
        scenarioCPM.attributeType = .doubleAttributeType
        scenarioCPM.defaultValue = 0.0

        let scenarioCTR = NSAttributeDescription()
        scenarioCTR.name = "ctr"
        scenarioCTR.attributeType = .doubleAttributeType
        scenarioCTR.defaultValue = 0.0

        let scenarioCR = NSAttributeDescription()
        scenarioCR.name = "cr"
        scenarioCR.attributeType = .doubleAttributeType
        scenarioCR.defaultValue = 0.0

        let scenarioAvgCheck = NSAttributeDescription()
        scenarioAvgCheck.name = "avgCheck"
        scenarioAvgCheck.attributeType = .doubleAttributeType
        scenarioAvgCheck.defaultValue = 0.0

        let scenarioCreatedAt = NSAttributeDescription()
        scenarioCreatedAt.name = "createdAt"
        scenarioCreatedAt.attributeType = .dateAttributeType
        scenarioCreatedAt.isOptional = false

        // Relationship: Scenario -> Campaign
        let scenarioCampaignRelation = NSRelationshipDescription()
        scenarioCampaignRelation.name = "campaign"
        scenarioCampaignRelation.destinationEntity = campaignEntity
        scenarioCampaignRelation.minCount = 0
        scenarioCampaignRelation.maxCount = 1
        scenarioCampaignRelation.isOptional = true
        scenarioCampaignRelation.deleteRule = .nullifyDeleteRule

        // Inverse: Campaign -> Scenarios
        let campaignScenariosRelation = NSRelationshipDescription()
        campaignScenariosRelation.name = "scenarios"
        campaignScenariosRelation.destinationEntity = scenarioEntity
        campaignScenariosRelation.minCount = 0
        campaignScenariosRelation.maxCount = 0
        campaignScenariosRelation.isOptional = true
        campaignScenariosRelation.deleteRule = .cascadeDeleteRule

        scenarioCampaignRelation.inverseRelationship = campaignScenariosRelation
        campaignScenariosRelation.inverseRelationship = scenarioCampaignRelation

        campaignEntity.properties = [
            campaignID, campaignName, campaignBudget, campaignCPM,
            campaignCTR, campaignCR, campaignAvgCheck, campaignCurrency,
            campaignPlatform, campaignCreatedAt, campaignUpdatedAt,
            campaignNotes, campaignScenariosRelation
        ]

        scenarioEntity.properties = [
            scenarioID, scenarioName, scenarioBudget, scenarioCPM,
            scenarioCTR, scenarioCR, scenarioAvgCheck, scenarioCreatedAt,
            scenarioCampaignRelation
        ]

        model.entities = [campaignEntity, scenarioEntity]
        return model
    }
}

// MARK: - CampaignEntity

@objc(CampaignEntity)
public class CampaignEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var budget: Double
    @NSManaged public var cpm: Double
    @NSManaged public var ctr: Double
    @NSManaged public var cr: Double
    @NSManaged public var avgCheck: Double
    @NSManaged public var currency: String
    @NSManaged public var platform: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var notes: String?
    @NSManaged public var scenarios: NSSet?

    var metrics: CampaignMetrics {
        MarketingEngine.calculate(
            budget: budget, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck
        )
    }

    var scenariosArray: [ComparisonScenarioEntity] {
        let set = scenarios as? Set<ComparisonScenarioEntity> ?? []
        return set.sorted { ($0.createdAt) < ($1.createdAt) }
    }
}

extension CampaignEntity {
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        budget: Double,
        cpm: Double,
        ctr: Double,
        cr: Double,
        avgCheck: Double,
        currency: String = "$",
        platform: String? = nil,
        notes: String? = nil
    ) -> CampaignEntity {
        let entity = CampaignEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.budget = budget
        entity.cpm = cpm
        entity.ctr = ctr
        entity.cr = cr
        entity.avgCheck = avgCheck
        entity.currency = currency
        entity.platform = platform
        entity.notes = notes
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
}

// MARK: - ComparisonScenarioEntity

@objc(ComparisonScenarioEntity)
public class ComparisonScenarioEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var budget: Double
    @NSManaged public var cpm: Double
    @NSManaged public var ctr: Double
    @NSManaged public var cr: Double
    @NSManaged public var avgCheck: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var campaign: CampaignEntity?

    var metrics: CampaignMetrics {
        MarketingEngine.calculate(
            budget: budget, cpm: cpm, ctr: ctr, cr: cr, avgCheck: avgCheck
        )
    }
}
