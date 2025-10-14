# Xcode Project Setup Guide

Since creating an Xcode project programmatically is complex, follow these steps to set up the project in Xcode manually.

## Step-by-Step Instructions

### 1. Create New Xcode Project

1. Open Xcode
2. Select **File → New → Project** (or press Cmd+Shift+N)
3. Choose **iOS → App**
4. Click **Next**

### 2. Configure Project Settings

Fill in the following:
- **Product Name**: `Planea`
- **Team**: Select your team (or leave as "None" for simulator testing)
- **Organization Identifier**: `com.yourname` (or any reverse domain)
- **Bundle Identifier**: Will auto-fill as `com.yourname.Planea`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: **None** (we'll add SwiftData later)
- **Include Tests**: Uncheck both boxes (optional)

Click **Next** and save the project in a temporary location (we'll move files later).

### 3. Set Minimum Deployment Target

1. Select the project in the navigator (blue icon at top)
2. Select the **Planea** target
3. Go to **General** tab
4. Under **Minimum Deployments**, set to **iOS 16.0**

### 4. Add Localization Support

1. Select the project (blue icon)
2. Go to **Info** tab
3. Under **Localizations**, click **+**
4. Add **French (fr)**
5. Keep **English** as the development language

### 5. Delete Default Files

In the Project Navigator, delete these files (Move to Trash):
- `ContentView.swift`
- `PlaneaApp.swift` (we'll replace it)
- `Assets.xcassets` (optional, keep if you want to add app icons later)

### 6. Add Project Files

#### Method A: Drag and Drop (Recommended)

1. Open Finder and navigate to `planea-starter/Planea-iOS/`
2. Select all Swift files and folders:
   - `PlaneaApp.swift`
   - `Models/` folder
   - `ViewModels/` folder
   - `Views/` folder
   - `Services/` folder
   - `Persistence/` folder
   - `Resources/` folder
3. Drag them into Xcode's Project Navigator
4. In the dialog:
   - ✅ Check **Copy items if needed**
   - ✅ Check **Create groups**
   - ✅ Check **Planea** target
   - Click **Finish**

#### Method B: Add Files Manually

1. Right-click on the **Planea** folder in Project Navigator
2. Select **Add Files to "Planea"...**
3. Navigate to `planea-starter/Planea-iOS/`
4. Select all files and folders
5. Ensure:
   - ✅ **Copy items if needed** is checked
   - ✅ **Create groups** is selected
   - ✅ **Planea** target is checked
6. Click **Add**

### 7. Configure Localization Files

1. Select `Localizable.strings` in the Project Navigator
2. Open the **File Inspector** (right panel, first tab)
3. Under **Localization**, click **Localize...**
4. Select **French** and click **Localize**
5. Now you should see checkboxes for both English and French
6. Ensure both are checked

Repeat for `Localizable-en.strings` if it exists separately.

### 8. Update Info.plist (if needed)

The project should already have the correct Info.plist settings, but verify:

1. Select the project → Target → Info tab
2. Ensure **Localizations** shows both English and French

### 9. Configure App Transport Security (for localhost)

Since the app connects to `http://localhost:8000`, we need to allow insecure connections:

1. Select the project → Target → Info tab
2. Hover over any key and click the **+** button
3. Add key: `App Transport Security Settings` (Dictionary)
4. Click the disclosure triangle to expand it
5. Click **+** next to it
6. Add key: `Allow Arbitrary Loads in Web Content` (Boolean) → Set to **YES**

Or add this to Info.plist directly:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 10. Build and Run

1. Select a simulator (e.g., iPhone 15 Pro)
2. Press **Cmd+B** to build
3. Fix any errors (there shouldn't be any)
4. Press **Cmd+R** to run

### 11. Start the Mock Server

Before testing the app, start the Python server:

```bash
cd planea-starter/mock-server
pip3 install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Keep this terminal window open while testing the app.

## Troubleshooting

### Build Errors

**"Cannot find type 'X' in scope"**
- Ensure all files are added to the target
- Check that files are in the correct groups
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)

**Localization issues**
- Ensure both .strings files are added to the project
- Check File Inspector → Target Membership is checked
- Verify Localizations are set up correctly

**Network errors**
- Ensure mock server is running on port 8000
- Check App Transport Security settings in Info.plist
- Verify the URL in PlanWeekView.swift and AdHocRecipeView.swift

### Runtime Issues

**App crashes on launch**
- Check console for error messages
- Ensure all ViewModels are properly initialized
- Verify @EnvironmentObject injections are correct

**"Connection refused" errors**
- Mock server must be running before testing AI features
- Check that server is on port 8000
- Try accessing http://localhost:8000/docs in a browser

## Testing the App

1. **Family Setup**: 
   - Go to "Famille" tab
   - Enter family name
   - Add members using the "Add Member" button

2. **Generate Meal Plan**:
   - Go to "Plan" tab
   - Toggle some meal slots (e.g., Monday breakfast, Tuesday dinner)
   - Tap "Generate Plan"
   - Wait for the mock server to respond
   - View generated meals

3. **View Recipe**:
   - Tap any meal in the plan
   - See full recipe details

4. **Shopping List**:
   - Go to "Épicerie" tab
   - See auto-generated shopping list
   - Tap items to check them off
   - Use "Export" to share the list

5. **Ad-hoc Recipe**:
   - Go to "Recette ad hoc" tab
   - Enter a recipe idea
   - Adjust servings
   - Generate recipe

## Next Steps

- Add app icon in Assets.xcassets
- Implement SwiftData for persistence
- Add more features from the roadmap
- Deploy to TestFlight for testing

## Need Help?

- Check the main README.md for more information
- Review the code comments in each file
- Consult Apple's SwiftUI documentation
