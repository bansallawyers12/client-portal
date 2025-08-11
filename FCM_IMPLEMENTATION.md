# Firebase Cloud Messaging (FCM) Implementation

This document explains the FCM implementation in the LegiComply Client Portal Flutter app.

## Overview

The app uses Firebase Cloud Messaging to receive push notifications from the server. The implementation includes:

- Automatic token registration with the server
- Token refresh handling
- Foreground and background message handling
- Notification tap handling
- Retry mechanism for failed registrations

## API Endpoint

The app registers FCM tokens with the following endpoint:

```
POST /api/register_token
Authorization: Bearer {token}
Content-Type: application/json

Request Body:
{
    "token": "fcm_device_token_here",
    "client_id": "CLI12345678"
}

Response:
{
    "message": "FCM token registered successfully"
}
```

## Implementation Details

### 1. FCM Service (`lib/fcm_service.dart`)

A dedicated service class that handles all FCM operations:

- **Singleton Pattern**: Ensures only one instance exists
- **Token Management**: Handles token generation, storage, and registration
- **Error Handling**: Comprehensive error handling with retry logic
- **Message Listeners**: Sets up listeners for different message types

### 2. Main App Integration (`lib/main.dart`)

The main app integrates FCM in several places:

- **App Initialization**: FCM is initialized when the app starts
- **Login Flow**: Token is registered after successful authentication
- **Logout Flow**: FCM data is cleared on logout
- **Message Handling**: Foreground and background message handling

### 3. Key Features

#### Automatic Token Registration
- Tokens are automatically registered after login
- Failed registrations are stored for retry
- Token refresh is handled automatically

#### Message Handling
- **Foreground Messages**: Displayed as in-app snackbars
- **Background Messages**: Handled by background handler
- **Notification Taps**: Navigation logic can be added based on message data

#### Error Recovery
- Failed registrations are retried
- Network errors are handled gracefully
- Local storage maintains token state

## Usage

### Basic Setup

The FCM service is automatically initialized when the app starts. No manual setup is required.

### Customizing Message Handling

You can customize how messages are handled by modifying the callback functions in `_setupNotifications()`:

```dart
fcmService.setupMessageListeners(
  onForegroundMessage: (RemoteMessage message) {
    // Custom foreground message handling
  },
  onBackgroundMessageTap: (RemoteMessage message) {
    // Custom background message tap handling
  },
);
```

### Adding Navigation Logic

To add navigation based on notification data, modify the message handlers:

```dart
onBackgroundMessageTap: (RemoteMessage message) {
  // Example: Navigate to specific page based on notification type
  if (message.data['type'] == 'appointment') {
    Navigator.pushNamed(context, '/appointments');
  } else if (message.data['type'] == 'document') {
    Navigator.pushNamed(context, '/documents');
  }
},
```

## Configuration

### Firebase Setup

Ensure your Firebase project is properly configured:

1. Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
2. Configure Firebase in your project
3. Enable Cloud Messaging in Firebase Console

### Server Configuration

The server should:

1. Accept the `/api/register_token` endpoint
2. Store FCM tokens with client associations
3. Send notifications using the stored tokens

## Testing

### Manual Testing

1. **Token Registration**: Check logs for successful token registration
2. **Foreground Messages**: Send a test notification while app is open
3. **Background Messages**: Send a test notification while app is closed
4. **Notification Taps**: Tap on notifications to test navigation

### Debug Information

The implementation includes comprehensive logging:

- Token registration success/failure
- Message reception
- Error conditions
- Token refresh events

## Troubleshooting

### Common Issues

1. **Token Not Registering**: Check authentication and client ID
2. **Messages Not Received**: Verify Firebase configuration
3. **Background Messages Not Working**: Check background handler setup

### Debug Steps

1. Check console logs for FCM-related messages
2. Verify Firebase project configuration
3. Test with Firebase Console test messages
4. Check network connectivity for token registration

## Security Considerations

- FCM tokens are stored locally with encryption
- Authentication is required for token registration
- Tokens are cleared on logout
- No sensitive data is included in notifications

## Future Enhancements

Potential improvements:

1. **Topic Subscription**: Subscribe to specific notification topics
2. **Rich Notifications**: Support for rich media in notifications
3. **Notification History**: Store notification history locally
4. **Custom Actions**: Add custom actions to notifications
5. **Analytics**: Track notification engagement 