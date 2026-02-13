import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ReviewView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("复习")
                }
                .tag(0)

            AddContentView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("添加")
                }
                .tag(1)

            InsightView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("洞察")
                }
                .tag(2)
        }
        .tint(.mpPrimary)
    }
}

#Preview {
    MainTabView()
}
