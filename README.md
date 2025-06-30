# Spys Food Ordering Platform

A comprehensive Flutter application for food ordering and delivery, featuring separate interfaces for students/staff (mobile) and administrators (web).

## 🚀 Features

### Single Codebase, Multiple Platforms
- **Web**: Admin dashboard with side navigation
- **Android/iOS**: Student/Staff app with bottom navigation
- Platform detection using `kIsWeb` for conditional UI

### Admin Dashboard (Web Only)
- **Dashboard**: Overview with statistics and analytics
- **Menu Management**: Add, edit, and manage menu items
- **Order Management**: Track and manage all orders
- **User Management**: Manage students and staff accounts
- **Feedback & Reports**: View customer feedback and analytics
- **Inventory**: Track stock levels and manage inventory
- **Settings**: App configuration and user preferences

### Student/Staff App (Mobile)
- **Home**: Welcome screen with quick actions and popular items
- **Menu**: Browse and search food items by category
- **Cart**: Manage cart items and proceed to checkout
- **Orders**: View order history and track current orders
- **Wallet**: Manage balance and view transaction history
- **Feedback**: Rate orders and provide feedback
- **Profile**: User profile and account settings

## 🏗️ Architecture

### Folder Structure
```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Platform detection and routing
├── core/
│   ├── constants.dart        # App constants and colors
│   └── theme.dart           # Material 3 theme configuration
├── features/
│   ├── admin/               # Admin web interface
│   │   ├── admin_app.dart
│   │   ├── dashboard/
│   │   ├── menu_management/
│   │   ├── order_management/
│   │   ├── user_management/
│   │   ├── feedback_reports/
│   │   ├── inventory/
│   │   └── settings/
│   └── student/             # Student/Staff mobile interface
│       ├── student_app.dart
│       ├── home/
│       ├── menu/
│       ├── cart/
│       ├── orders/
│       ├── wallet/
│       ├── feedback/
│       └── profile/
├── models/                  # Data models
│   ├── user.dart
│   ├── menu_item.dart
│   └── order.dart
└── widgets/                 # Shared widgets
    ├── loading_widget.dart
    └── error_widget.dart
```

## 🎨 Design System

### Material 3
- Modern Material Design 3 implementation
- Dark mode support
- Google Fonts integration
- Responsive layouts

### Color Palette
- **Primary**: Blue (#1976D2)
- **Secondary**: Light Blue (#42A5F5)
- **Accent**: Orange (#FF6B35)
- **Success**: Green (#388E3C)
- **Warning**: Orange (#F57C00)
- **Error**: Red (#D32F2F)

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Chrome (for web development)

### Installation
1. Clone the repository
```bash
git clone <repository-url>
cd spys
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the application

**For Web (Admin Dashboard):**
```bash
flutter run -d chrome
```

**For Android:**
```bash
flutter run -d android
```

**For iOS:**
```bash
flutter run -d ios
```

## 📱 Platform-Specific Features

### Web (Admin Dashboard)
- Side navigation with collapsible menu
- Responsive grid layouts
- Data tables and charts
- Bulk operations
- Real-time notifications

### Mobile (Student/Staff App)
- Bottom navigation bar
- Touch-optimized interfaces
- Swipe gestures
- Push notifications
- Offline support (planned)

## 🔧 Development Guidelines

### Adding New Screens
1. Create screen in appropriate feature folder (`admin/` or `student/`)
2. Add route to respective app file (`admin_app.dart` or `student_app.dart`)
3. Update navigation if needed
4. Document in this README

### Platform Detection
Use `kIsWeb` for platform-specific code:
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

### State Management
- Currently using basic StatefulWidget
- Ready for integration with Provider, Riverpod, or Bloc
- Models prepared for JSON serialization

## 📊 Current Status

### ✅ Completed
- [x] Project structure and architecture
- [x] Platform detection and routing
- [x] Material 3 theme with dark mode
- [x] Admin dashboard layout and navigation
- [x] Student app layout and navigation
- [x] All screen placeholders with basic UI
- [x] Data models (User, MenuItem, Order)
- [x] Shared widgets (Loading, Error)
- [x] Responsive design

### 🚧 In Progress
- [ ] Backend integration
- [ ] Authentication system
- [ ] Real data implementation
- [ ] State management
- [ ] API services

### 📋 Planned Features
- [ ] Firebase/Supabase integration
- [ ] Push notifications
- [ ] Payment processing
- [ ] Real-time order tracking
- [ ] Offline support
- [ ] Analytics and reporting
- [ ] Multi-language support

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## 📦 Dependencies

### Core Dependencies
- `flutter`: ^3.7.0
- `google_fonts`: ^6.1.0
- `cupertino_icons`: ^1.0.8

### Development Dependencies
- `flutter_test`: SDK
- `flutter_lints`: ^5.0.0

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
