# CarHive Admin Panel

A comprehensive web-only admin panel for managing the CarHive car buying and selling application. This admin panel provides administrators with tools to manage users, moderate ads, and monitor system activity.

## Features

### 🔐 Authentication & Security
- Secure admin login with role-based access control
- Support for multiple admin roles (admin, super_admin)
- Session management and secure logout

### 📊 Dashboard
- Real-time statistics overview
- User and ad counts
- Pending ads count
- Quick action buttons for common tasks

### 🚗 Ad Moderation
- Review pending ads before publication
- Approve or reject ads with reason tracking
- View detailed ad information
- Search and filter ads

### 👥 User Management
- View all registered users
- Update user roles and permissions
- Activate/deactivate user accounts
- Monitor user activity and ad statistics
- Search and filter users

### 🎨 Modern UI/UX
- Responsive web design
- Collapsible sidebar navigation
- Professional color scheme
- Mobile-friendly interface

## Technical Architecture

### Models
- `UserModel` - User information and statistics
- `AdModel` - Car advertisement data
- `AdminStatsModel` - Dashboard statistics

### Services
- `AdminService` - Core admin operations and Firebase interactions
- `AdminAuthService` - Authentication and authorization

### State Management
- `AdminProvider` - Centralized state management using Provider pattern

### Pages
- `AdminLoginPage` - Secure login interface
- `AdminDashboardPage` - Main dashboard with statistics
- `AdminAdsPage` - Ad moderation interface
- `AdminUsersPage` - User management interface
- `AdminLayout` - Main layout with navigation

## Setup Instructions

### 1. Firebase Configuration

Ensure your Firebase project has the following collections:

#### Users Collection
```json
{
  "email": "string",
  "displayName": "string",
  "role": "user|admin|super_admin",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "isActive": "boolean",
  "totalAdsPosted": "number",
  "activeAdsCount": "number",
  "rejectedAdsCount": "number"
}
```

#### Ads Collection
```json
{
  "title": "string",
  "price": "string",
  "location": "string",
  "year": "string",
  "mileage": "string",
  "fuel": "string",
  "status": "pending|active|rejected",
  "userId": "string",
  "createdAt": "timestamp",
  "description": "string",
  "carBrand": "string",
  "bodyColor": "string",
  "kmsDriven": "string",
  "registeredIn": "string",
  "name": "string",
  "phone": "string"
}
```

### 2. Create Admin Users

#### Option 1: Manual Creation
1. Create a user account through your app
2. Manually update the user's role to 'admin' or 'super_admin' in Firebase
3. Use these credentials to access the admin panel

#### Option 2: Super Admin Creation
1. Create the first super admin manually in Firebase
2. Use the super admin account to create additional admin users through the admin panel

### 3. Update Ad Status Logic

Modify your ad creation flow to set the initial status as 'pending':

```dart
// In your ad creation service
final adData = {
  // ... other ad fields
  'status': 'pending', // Set initial status as pending
  'createdAt': FieldValue.serverTimestamp(),
};
```

### 4. Add Admin Routes

Add the following routes to your main app:

```dart
// In your main.dart or routing configuration
'/admin': (context) => const AdminMain(),
'/admin/login': (context) => const AdminLoginPage(),
'/admin/dashboard': (context) => const AdminLayout(),
```

### 5. Update Provider Configuration

Ensure the AdminProvider is included in your app's provider setup:

```dart
MultiProvider(
  providers: [
    // ... other providers
    ChangeNotifierProvider(create: (_) => AdminProvider()),
  ],
  child: MyApp(),
)
```

## Usage

### Accessing the Admin Panel

1. Navigate to `/admin` in your web browser
2. Login with admin credentials
3. Use the sidebar navigation to access different sections

### Ad Moderation Workflow

1. **Review Pending Ads**: Navigate to "Ad Moderation" section
2. **View Ad Details**: Click on any ad to see full information
3. **Approve/Reject**: Use the action buttons to approve or reject ads
4. **Provide Feedback**: When rejecting, provide a reason for transparency

### User Management

1. **View Users**: Navigate to "User Management" section
2. **Update Roles**: Change user permissions as needed
3. **Monitor Activity**: Track user engagement and ad posting behavior
4. **Account Control**: Activate/deactivate user accounts

## Security Considerations

### Role-Based Access Control
- Only users with 'admin' or 'super_admin' roles can access the panel
- Super admins can create additional admin users
- Regular users cannot access admin functionality

### Data Validation
- All admin actions are validated server-side
- User input is sanitized and validated
- Firebase security rules should be configured appropriately

### Session Management
- Admin sessions are managed securely
- Automatic logout on session expiration
- Secure token handling

## Customization

### Adding New Features
1. Create new models in the `models/` directory
2. Add services in the `services/` directory
3. Create UI components in the `pages/admin/` directory
4. Update the `AdminProvider` for state management

### Styling
- Modify colors in the theme constants
- Update the color scheme in individual components
- Customize the sidebar appearance

### Extending Functionality
- Add new admin roles with specific permissions
- Implement additional moderation features
- Create custom analytics and reporting

## Troubleshooting

### Common Issues

1. **Admin Login Fails**
   - Verify user exists in Firebase
   - Check user role is set to 'admin' or 'super_admin'
   - Ensure Firebase configuration is correct

2. **Ads Not Showing as Pending**
   - Verify ad creation sets status to 'pending'
   - Check Firebase security rules allow admin access
   - Ensure proper indexing on status field

3. **User Management Not Working**
   - Verify admin permissions
   - Check Firebase security rules
   - Ensure proper user document structure

### Debug Mode

Enable debug logging by adding print statements in the admin services:

```dart
print('Debug: Loading users...');
print('Debug: User count: ${users.length}');
```

## Support

For technical support or feature requests:

1. Check the Firebase console for errors
2. Review the browser console for JavaScript errors
3. Verify all dependencies are properly installed
4. Ensure Firebase project configuration is correct

## Future Enhancements

- Advanced analytics and reporting
- Bulk operations for ads and users
- Email notifications for admins
- Audit logging for admin actions
- Mobile admin app (if needed)
- Integration with external moderation services

---

**Note**: This admin panel is designed to be web-only for security and usability reasons. Mobile access should be limited to view-only operations if required.


