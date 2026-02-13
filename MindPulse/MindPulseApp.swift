import SwiftUI
import SwiftData

@main
struct MindPulseApp: App {
    @AppStorage("onboarding_complete") private var onboardingComplete = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Source.self,
            Card.self,
            ReviewLog.self,
            DailyStatus.self,
            Subscription.self,
            PromptLog.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // 确保有 Subscription 记录
            let context = container.mainContext
            let descriptor = FetchDescriptor<Subscription>()
            if (try? context.fetch(descriptor))?.isEmpty ?? true {
                context.insert(Subscription())
                try? context.save()
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if onboardingComplete {
                NavigationStack {
                    MainTabView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Image(systemName: "gearshape")
                                        .foregroundColor(.mpCaption)
                                }
                            }
                        }
                }
            } else {
                OnboardingView(isOnboardingComplete: $onboardingComplete)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
