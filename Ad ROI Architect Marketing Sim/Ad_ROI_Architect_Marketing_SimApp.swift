import SwiftUI

@main
struct Ad_ROI_Architect_Marketing_SimApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showStoreError = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onAppear {
                    if persistenceController.storeLoadError != nil {
                        showStoreError = true
                    }
                }
                .alert("Data Storage Issue", isPresented: $showStoreError) {
                    Button("OK") { }
                } message: {
                    Text("Campaign data could not be loaded. Previous campaigns may have been reset. New data will be saved normally.")
                }
        }
    }
}
