import SwiftUI

// MARK: - Main Content View (Tab Navigation)

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CampaignHubView()
                .tabItem {
                    Label("Campaigns", systemImage: "megaphone.fill")
                }
                .tag(0)

            ReverseEngineerView()
                .tabItem {
                    Label("Reverse", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
                }
                .tag(1)

            CompareToolView()
                .tabItem {
                    Label("Compare", systemImage: "arrow.triangle.branch")
                }
                .tag(2)

            GlossaryView()
                .tabItem {
                    Label("Glossary", systemImage: "book.fill")
                }
                .tag(3)

            SettingsExportView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(AppColors.accentBlue)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
