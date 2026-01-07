# Flutter Zitadel Integration Setup Guide

## Overview
Complete Flutter integration with Zitadel authentication using OAuth 2.0 / OIDC flow.

## What's Included

### Core Files
- **pubspec.yaml** - All dependencies
- **lib/config/zitadel_config.dart** - Zitadel configuration
- **lib/models/user.dart** - User data model
- **lib/services/secure_storage_service.dart** - Secure token storage
- **lib/services/zitadel_auth_service.dart** - Main auth service
- **lib/providers/auth_provider.dart** - Riverpod state management
- **lib/screens/login_screen.dart** - Login UI
- **lib/screens/home_screen.dart** - Home screen with user profile
- **lib/main.dart** - App entry point with auth gate

### Platform Configuration
- **android/app/src/main/AndroidManifest.xml** - Android deep linking
- **ios/Runner/Info.plist** - iOS deep linking
- **.env.flutter** - Environment variables

## Step 1: Create Flutter Project

```bash
# Create new Flutter project (if you don't have one)
flutter create freightlearn
cd freightlearn

# Or use your existing project
```

## Step 2: Copy Files

Copy all the provided files to your Flutter project:

```
freightlearn/
├── lib/
│   ├── config/
│   │   └── zitadel_config.dart
│   ├── models/
│   │   └── user.dart
│   ├── services/
│   │   ├── secure_storage_service.dart
│   │   └── zitadel_auth_service.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   └── home_screen.dart
│   └── main.dart
├── android/app/src/main/AndroidManifest.xml
├── ios/Runner/Info.plist
├── .env (rename from .env.flutter)
└── pubspec.yaml
```

## Step 3: Install Dependencies

```bash
flutter pub get
```

## Step 4: Configure Zitadel Application

### 4.1 Login to Zitadel Console
Go to: https://auth.open-hwy.com/ui/console

### 4.2 Create Project
1. Click **Projects** → **Create New Project**
2. Name: "FreightLearn"
3. Click **Continue**

### 4.3 Create Application
1. In your project, click **New** → **Application**
2. Configure:
   - **Name**: FreightLearn Mobile
   - **Type**: Native
   - **Authentication Method**: PKCE

3. Click **Continue**

### 4.4 Configure Redirect URIs
Add these URIs:
- **Redirect URIs**: 
  - `com.openhwy.freightlearn://callback`
- **Post Logout Redirect URIs**:
  - `com.openhwy.freightlearn://logout`

### 4.5 Save Client ID
Copy your **Client ID** (looks like: `123456789@freightlearn`)

## Step 5: Configure Environment Variables

Edit `.env` file:

```bash
# Zitadel Configuration
ZITADEL_DOMAIN=auth.open-hwy.com
ZITADEL_CLIENT_ID=123456789@freightlearn  # <- Your actual Client ID
ZITADEL_REDIRECT_URI=com.openhwy.freightlearn://callback
ZITADEL_LOGOUT_URI=com.openhwy.freightlearn://logout

# API Configuration (your Rust backend)
API_BASE_URL=https://api.open-hwy.com
```

## Step 6: Update Android Package Name (Optional)

If you want to change the package name:

1. Edit `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.openhwy.freightlearn"
        // ... other config
    }
}
```

2. Update redirect URIs in Zitadel console to match

## Step 7: Update iOS Bundle Identifier (Optional)

If you want to change the bundle identifier:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** → **General**
3. Change **Bundle Identifier** to: `com.openhwy.freightlearn`
4. Update redirect URIs in Zitadel console to match

## Step 8: Run the App

### Android
```bash
flutter run
```

### iOS
```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..

flutter run
```

## How It Works

### Authentication Flow

1. **User taps "Sign In"** → App calls `ZitadelAuthService.login()`
2. **OAuth flow starts** → Opens Zitadel login page in system browser
3. **User authenticates** → Enters credentials on Zitadel
4. **Callback** → Zitadel redirects to `com.openhwy.freightlearn://callback`
5. **Token exchange** → App exchanges auth code for tokens
6. **Tokens stored** → Saved securely using FlutterSecureStorage
7. **User info fetched** → App gets user profile from Zitadel
8. **Navigation** → User navigated to HomeScreen

### Token Management

- **Access Token**: Short-lived (usually 1 hour), used for API calls
- **Refresh Token**: Long-lived, used to get new access tokens
- **ID Token**: Contains user identity information

Tokens are automatically refreshed when expired.

### State Management

Uses Riverpod for reactive state management:

```dart
// Check if authenticated
final isAuthenticated = ref.watch(isAuthenticatedProvider);

// Get current user
final user = ref.watch(currentUserProvider);

// Login
await ref.read(authProvider.notifier).login();

// Logout
await ref.read(authProvider.notifier).logout();
```

## Usage Examples

### Check Authentication Status

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  if (isAuthenticated) {
    return HomeScreen();
  } else {
    return LoginScreen();
  }
}
```

### Get Current User

```dart
final user = ref.watch(currentUserProvider);

if (user != null) {
  print('Welcome ${user.displayName}!');
  print('Email: ${user.email}');
}
```

### Make Authenticated API Calls

```dart
import 'package:http/http.dart' as http;
import '../services/zitadel_auth_service.dart';
import '../config/zitadel_config.dart';

Future<void> fetchUserData() async {
  final authService = ZitadelAuthService();
  final accessToken = await authService.getAccessToken();
  
  if (accessToken == null) {
    // User not authenticated
    return;
  }
  
  final response = await http.get(
    Uri.parse('${ZitadelConfig.apiBaseUrl}/api/user/profile'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );
  
  if (response.statusCode == 200) {
    // Handle success
  }
}
```

### Protect Routes

```dart
class ProtectedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    
    if (!isAuthenticated) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Protected Content')),
      body: Center(child: Text('Only authenticated users see this')),
    );
  }
}
```

## Customization

### Change App Theme

Edit `lib/main.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue, // Change this
    brightness: Brightness.light,
  ),
  useMaterial3: true,
),
```

### Add Custom Scopes

Edit `lib/config/zitadel_config.dart`:

```dart
static const List<String> scopes = [
  'openid',
  'profile',
  'email',
  'offline_access',
  'urn:zitadel:iam:org:project:id:zitadel:aud',
  'custom:scope', // Add your custom scopes
];
```

Then add the scope in Zitadel console under your application.

### Customize Login Screen

Edit `lib/screens/login_screen.dart` to match your brand.

## Troubleshooting

### "Client not found" Error
- Verify `ZITADEL_CLIENT_ID` in `.env` matches your Zitadel application
- Ensure you copied the Client ID, not the Project ID

### Redirect URI Not Working
- Check Android package name matches redirect URI
- Check iOS bundle identifier matches redirect URI
- Verify redirect URIs are configured in Zitadel console
- Make sure URIs match EXACTLY (case-sensitive)

### Token Expired
- Tokens are automatically refreshed
- If refresh fails, user will be logged out
- Check that `offline_access` scope is included

### Can't Login on Android
- Check `AndroidManifest.xml` has correct intent filters
- Verify package name is correct
- Check Chrome/default browser is set

### Can't Login on iOS
- Check `Info.plist` has correct URL schemes
- Verify bundle identifier is correct
- Test in Simulator and real device

### Secure Storage Issues
- Android: Check minimum SDK version is 18+
- iOS: Check deployment target is iOS 11+
- Clear app data and try again

## Security Best Practices

1. **Never commit .env file** - Add to .gitignore
2. **Use HTTPS only** - All API calls should use HTTPS
3. **Validate tokens** - Always verify token expiration
4. **Secure storage** - Uses platform secure storage (Keychain/Keystore)
5. **PKCE flow** - Recommended for mobile apps (already configured)
6. **Short access tokens** - Use refresh tokens for long sessions
7. **Logout properly** - Always call logout to revoke tokens

## Next Steps

1. ✅ Zitadel authentication working
2. Integrate with Rust backend API
3. Add Google Play Billing for in-app purchases
4. Implement feature flags with Flagship
5. Build course/scenario widgets
6. Add leaderboard and community features

## Additional Resources

- [Zitadel Flutter Docs](https://zitadel.com/docs/sdk-examples/flutter)
- [Flutter AppAuth Package](https://pub.dev/packages/flutter_appauth)
- [Riverpod Documentation](https://riverpod.dev)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)

## Support

For issues:
1. Check Zitadel console logs
2. Check Flutter debug console
3. Verify all configuration matches
4. Test with fresh app install
