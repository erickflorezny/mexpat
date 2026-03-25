#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-Mexpat}"

mkdir -p "$APP_NAME"/{
  App/{DI,Routing,Config},
  Features/Auth/{Views,ViewModels,Models,Services},
  Features/Map/{Views,ViewModels,Models,Services},
  Features/Directory/{Views,ViewModels,Models,Services},
  Features/Legal/{Views,ViewModels,Models,Services},
  Core/Network/{Supabase,API,Models},
  UI/Components/{Glass,Buttons,Haptics},
  Resources/{Assets.xcassets,Fonts,Localization},
  Supporting/{Extensions,Utilities}
}

# Starter files
cat > "$APP_NAME/App/AppEntry.swift" <<'EOF'
import SwiftUI

@main
struct MexpatApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Text("Mexpat")
            }
        }
    }
}
EOF

touch "$APP_NAME/App/DI/AppContainer.swift"
touch "$APP_NAME/Core/Network/Supabase/SupabaseService.swift"
touch "$APP_NAME/Features/Directory/ViewModels/DirectoryViewModel.swift"
touch "$APP_NAME/Features/Directory/Views/DirectoryView.swift"
touch "$APP_NAME/UI/Components/Glass/GlassCard.swift"
touch "$APP_NAME/UI/Components/Haptics/HapticFeedback.swift"

echo "✅ Mexpat scaffold created at: $APP_NAME"
