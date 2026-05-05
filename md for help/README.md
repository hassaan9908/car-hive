# CarHive - Car Marketplace App

A Flutter application for buying and selling cars with user authentication and real-time data synchronization.

## Features

- **User Authentication**: Login/signup with Firebase Auth
- **Post Ads**: Users can post car ads with detailed information
- **Browse Cars**: View all available cars in the used cars section
- **My Ads**: Manage your own ads (active, pending, removed)
- **Real-time Updates**: All data is synchronized in real-time using Firestore

## Setup Instructions

### 1. Firebase Configuration

Make sure you have Firebase configured in your project:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your app to the Firebase project
3. Download and add the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files
4. Enable Authentication and Firestore in your Firebase project

### 2. Firestore Database Setup

The app uses Firestore for data storage. You may need to create indexes for optimal performance:

#### Required Indexes

If you encounter "failed-precondition" errors, you need to create the following composite indexes in your Firestore database:

1. **Collection**: `ads`
   - **Fields**: 
     - `status` (Ascending)
     - `createdAt` (Descending)

2. **Collection**: `ads`
   - **Fields**:
     - `userId` (Ascending)
     - `createdAt` (Descending)

3. **Collection**: `ads`
   - **Fields**:
     - `userId` (Ascending)
     - `status` (Ascending)
     - `createdAt` (Descending)

#### How to Create Indexes

1. Go to your [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Click on the "Indexes" tab
5. Click "Create Index"
6. Add the required fields as listed above
7. Wait for the index to be built (this may take a few minutes)

### 3. Running the App

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Troubleshooting

### "Error loading ads" or "Database configuration required"

This error occurs when Firestore indexes are missing. Follow the index creation steps above.

### "Access denied" error

This usually means:
1. Firestore security rules are too restrictive
2. User is not authenticated
3. User doesn't have permission to read/write data

### No ads showing up

1. Make sure you have posted some ads
2. Check if you're logged in
3. Verify that ads have `status: 'active'`
4. Check Firestore console to see if data exists

## Data Structure

### Ad Document Structure

```json
{
  "title": "Honda Civic 2018",
  "price": "2500000",
  "location": "Lahore",
  "year": "2018",
  "mileage": "50000",
  "fuel": "Petrol",
  "status": "active",
  "userId": "user_id_here",
  "createdAt": "timestamp",
  "description": "Well maintained car",
  "carBrand": "Honda",
  "bodyColor": "White",
  "kmsDriven": "50000",
  "registeredIn": "Lahore",
  "name": "John Doe",
  "phone": "+92-300-1234567"
}
```

## Security Rules

Make sure your Firestore security rules allow authenticated users to read and write their own data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /ads/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

## Dependencies

- `firebase_core`: Firebase core functionality
- `firebase_auth`: User authentication
- `cloud_firestore`: Real-time database
- `provider`: State management
- `image_picker`: Image selection
- `google_sign_in`: Google authentication

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
