# Spys Monorepo – Full Project Documentation

This repository contains the **Spys** project, managed as a **Melos monorepo**.
It houses multiple Flutter/Dart applications and shared packages in a single workspace, making it easier to maintain, develop, and share code across projects.

---

## Table of Contents

1. [Overview](#overview)
2. [Monorepo Structure](#monorepo-structure)
3. [Tech Stack](#tech-stack)
4. [What Each Package/App Does](#what-each-packageapp-does)
5. [Getting Started](#getting-started)
6. [Melos Commands](#melos-commands)
7. [Development Workflow](#development-workflow)
8. [Project Conventions](#project-conventions)
9. [Troubleshooting](#troubleshooting)
10. [Future Plans](#future-plans)

---

## 1. Overview

**Spys** is a digital food ordering and management platform designed for:

* **Mobile app users** (customers, students, or staff) to browse menus, place orders, and manage accounts.
* **Admin web users** (restaurant/canteen managers) to manage menus, orders, users, and system settings.

We use **Melos** to manage:

* Multiple applications (mobile, web)
* Shared core logic, models, and API clients
* Shared UI components

This ensures:

* **Code reuse** – One source of truth for shared logic and UI.
* **Consistency** – Apps stay in sync when we update shared packages.
* **Scalability** – Easy to add new apps or modules without code duplication.

---

## 2. Monorepo Structure

```
apps/
  admin_web/         # Web-based admin dashboard
  mobile/            # Flutter mobile app (iOS & Android)

packages/
  spys_ui_shared/    # Shared Flutter UI components/widgets
  spys_core/         # Core business/domain models & utilities
  spys_api_client/   # API client for backend communication
```

**Why this structure?**

* `apps` – End-user applications with their own Flutter entry points.
* `packages` – Reusable Dart/Flutter code that can be imported by any app.

---

## 3. Tech Stack

* **Flutter** – Cross-platform UI framework for mobile and web.
* **Dart** – Programming language for Flutter.
* **Melos** – Monorepo management tool for Dart/Flutter.
* **GoRouter** (planned) – For app navigation.
* **HTTP/Dio** (planned) – For API communication.
* **Shared UI** – Custom widgets/components stored in `spys_ui_shared`.

---

## 4. What Each Package/App Does

### **apps/mobile**

* The **customer-facing mobile app**.
* Lets users browse menus, add items to cart, checkout, and view past orders.
* Imports shared UI and core logic.

### **apps/admin\_web**

* The **web-based admin dashboard**.
* Accessible via Chrome.
* Used by staff to:

  * Manage menus
  * Track orders in real time
  * Manage user accounts
  * Access reports and analytics

### **packages/spys\_ui\_shared**

* Shared Flutter widgets & design system.
* Ensures visual consistency between mobile and web apps.
* Example: Buttons, cards, input fields, colors, typography.

### **packages/spys\_core**

* Core domain logic & models.
* Business rules and data structures (e.g., `Order`, `MenuItem`, `User`).
* Utilities for formatting, validation, and calculations.

### **packages/spys\_api\_client**

* Handles **all API/HTTP requests** to the backend.
* Provides an easy-to-use interface for fetching and sending data.
* Isolated so it can be swapped or updated without affecting app UI.

---

## 5. Getting Started

### Install Melos

```bash
dart pub global activate melos
# Make sure ~/.pub-cache/bin is in your PATH
```

### Bootstrap the Workspace

From the repo root:

```bash
melos run bootstrap
```

This:

* Installs dependencies for **all** packages/apps.
* Sets up local `path:` dependencies for shared packages.

---

## 6. Melos Commands

```bash
melos run analyze       # Run flutter analyze on all packages
melos run test          # Run tests across all packages
melos run format        # Format Dart code in every package
melos run run:mobile    # Run the mobile app
melos run run:admin_web # Run the admin web app in Chrome
melos run build:web     # Build the admin web app for production
```

---

## 7. Development Workflow

1. **Bootstrap workspace**

   ```bash
   melos run bootstrap
   ```
2. **Start an app**

   ```bash
   melos run run:mobile
   # or
   melos run run:admin_web
   ```
3. **Edit shared code** in `packages/` – both apps automatically pick up changes.
4. **Test changes**

   ```bash
   melos run test
   ```
5. **Commit & push** – Keep commits focused and descriptive.

---

## 8. Project Conventions

* **UI Components** – Always go in `spys_ui_shared` if they are reused.
* **Business Logic** – Always go in `spys_core`.
* **API Calls** – Always go in `spys_api_client`.
* **Import Rules**:

  ```dart
  import 'package:spys_ui_shared/components/...';
  import 'package:spys_core/...';
  import 'package:spys_api_client/...';
  ```
* **No direct API calls** from UI layers – always use `spys_api_client`.

---

## 9. Troubleshooting

* **"Target of URI doesn't exist"**
  → Run `melos run bootstrap` again.
* **Dependencies out of sync**
  → Run `flutter clean && melos run bootstrap`.
* **Tests failing due to missing imports**
  → Ensure `test` is added as a `dev_dependency` in relevant packages.

---

## 10. Future Plans

* Implement **GoRouter** navigation in both apps.
* Add **authentication** and role-based access.
* Integrate real backend API endpoints.
* Add **CI/CD pipeline** with GitHub Actions.
* Expand test coverage for packages.

---
