# TestFlight preparation — VisionBend iOS

## Current state
The project is a partial native SwiftUI port. It has not been verified to compile or run on a physical iPhone, and has not been uploaded to TestFlight. The signed archive workflow produces an **xcarchive**, not an IPA, and does not upload to App Store Connect.

## Prerequisites
1. Active Apple Developer Program membership and App Store Connect access.
2. App Store Connect app record with the **same bundle identifier** as `project.yml`: `com.visionbend.conduit` (verify this ID is available for your team; update it before first upload if not).
3. App Store distribution certificate (.p12 and password), App Store provisioning profile matching the bundle ID, and Apple Team ID.
4. GitHub Actions repository secrets:
   - `IOS_DISTRIBUTION_P12_BASE64`: base64 of the .p12 certificate
   - `IOS_DISTRIBUTION_P12_PASSWORD`: password for .p12
   - `IOS_APPSTORE_PROFILE_BASE64`: base64 of the App Store provisioning profile
   - `APPLE_TEAM_ID`: 10-character Apple Team ID

**Never commit certificates, profiles, passwords or App Store Connect API keys to GitHub.** The repository is currently public.

## Verify build
Open GitHub Actions > VisionBend iOS build verification and review simulator build and tests. Fix any failures before signing. Real-camera and motion testing requires an iPhone.

## Produce signed archive
After secrets are configured, run GitHub Actions > VisionBend iOS signed archive > Run workflow. Download the resulting `VisionBend-signed-archive` artifact if the workflow succeeds.

## Export and upload
On a Mac with Xcode, open the signed `.xcarchive` in Organizer, select Distribute App > App Store Connect > Upload. Confirm the provisioning profile and bundle ID. Alternatively configure a separately audited `xcodebuild -exportArchive` and App Store Connect API-key upload workflow.

## After upload
Complete TestFlight beta information, export compliance and any Apple review requirements. Add internal testers and test on real iPhones.

## Known blockers
- No verified successful Xcode build, device tests or signed archive
- Missing Apple account signing credentials
- No App Store Connect app record/upload confirmation
- Not feature-parity with Android (camera recognition, AR and other screens are not complete)

Do not describe the application as TestFlight-ready until a signed build is successfully uploaded and accepted for testing.
