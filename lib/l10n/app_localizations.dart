import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('af'),
    Locale('en')
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Spys'**
  String get app_title;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @dark_theme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get dark_theme;

  /// No description provided for @light_theme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get light_theme;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get help;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @error_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get error_required;

  /// No description provided for @error_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get error_email;

  /// No description provided for @error_password_length.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get error_password_length;

  /// No description provided for @order_ready.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready for pickup.'**
  String get order_ready;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Spys!'**
  String get welcome;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get change_language;

  /// No description provided for @afrikaans.
  ///
  /// In en, this message translates to:
  /// **'Afrikaans'**
  String get afrikaans;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get email_required;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get password_required;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalid_email;

  /// No description provided for @password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get password_too_short;

  /// No description provided for @confirm_password_required.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get confirm_password_required;

  /// No description provided for @passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_do_not_match;

  /// No description provided for @terms_required.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions'**
  String get terms_required;

  /// No description provided for @registration_success.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful!'**
  String get registration_success;

  /// No description provided for @registration_success_desc.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created. A verification email has been sent.'**
  String get registration_success_desc;

  /// No description provided for @continue_label.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_label;

  /// No description provided for @reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password;

  /// No description provided for @name_required.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get name_required;

  /// No description provided for @phone_required.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phone_required;

  /// No description provided for @invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalid_phone;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get login_failed;

  /// No description provided for @register_failed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get register_failed;

  /// No description provided for @accept_terms.
  ///
  /// In en, this message translates to:
  /// **'I accept the terms and conditions *'**
  String get accept_terms;

  /// No description provided for @read_terms.
  ///
  /// In en, this message translates to:
  /// **'Read terms and conditions'**
  String get read_terms;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @aboutSpysAdmin.
  ///
  /// In en, this message translates to:
  /// **'About Spys Admin'**
  String get aboutSpysAdmin;

  /// No description provided for @aboutSpysAdminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description for Spys Admin.'**
  String get aboutSpysAdminDescription;

  /// No description provided for @aboutSpysAdminTeam.
  ///
  /// In en, this message translates to:
  /// **'Spys Admin Team'**
  String get aboutSpysAdminTeam;

  /// No description provided for @aboutSpysAdminTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team members info.'**
  String get aboutSpysAdminTeamMembers;

  /// No description provided for @aboutSpysAdminContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutSpysAdminContact;

  /// No description provided for @aboutSpysAdminContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details info.'**
  String get aboutSpysAdminContactDetails;

  /// No description provided for @rateThisApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app'**
  String get rateThisApp;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @todoTermsOfServicePrivacyPolicyMeerSpanlede.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service, Privacy Policy, More team members (TODO)'**
  String get todoTermsOfServicePrivacyPolicyMeerSpanlede;

  /// No description provided for @addInventory.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory'**
  String get addInventory;

  /// No description provided for @editInventory.
  ///
  /// In en, this message translates to:
  /// **'Edit Inventory'**
  String get editInventory;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @nameAndQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and quantity required.'**
  String get nameAndQuantityRequired;

  /// No description provided for @deleteInventory.
  ///
  /// In en, this message translates to:
  /// **'Delete Inventory'**
  String get deleteInventory;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @lastAdded.
  ///
  /// In en, this message translates to:
  /// **'Last Added'**
  String get lastAdded;

  /// No description provided for @backendIntegrationInventory.
  ///
  /// In en, this message translates to:
  /// **'Backend integration for inventory (TODO)'**
  String get backendIntegrationInventory;

  /// No description provided for @addMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add Menu Item'**
  String get addMenuItem;

  /// No description provided for @editMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Menu Item'**
  String get editMenuItem;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @allergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergens;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @nameAndPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and price required.'**
  String get nameAndPriceRequired;

  /// No description provided for @deleteMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Menu Item'**
  String get deleteMenuItem;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get areYouSureYouWantToDelete;

  /// No description provided for @menuManagement.
  ///
  /// In en, this message translates to:
  /// **'Menu Management'**
  String get menuManagement;

  /// No description provided for @menuItems.
  ///
  /// In en, this message translates to:
  /// **'Menu Items'**
  String get menuItems;

  /// No description provided for @backendIntegrationForMenuManagement.
  ///
  /// In en, this message translates to:
  /// **'Backend integration for menu management (TODO)'**
  String get backendIntegrationForMenuManagement;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTitle;

  /// No description provided for @contactSupportMessage.
  ///
  /// In en, this message translates to:
  /// **'Contact support message.'**
  String get contactSupportMessage;

  /// No description provided for @yourMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get yourMessageLabel;

  /// No description provided for @messageSentDummy.
  ///
  /// In en, this message translates to:
  /// **'Message sent (dummy)'**
  String get messageSentDummy;

  /// No description provided for @howSeeActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'How to see active orders?'**
  String get howSeeActiveOrders;

  /// No description provided for @howSeeActiveOrdersDescription.
  ///
  /// In en, this message translates to:
  /// **'Description for seeing active orders.'**
  String get howSeeActiveOrdersDescription;

  /// No description provided for @howAddNewProducts.
  ///
  /// In en, this message translates to:
  /// **'How to add new products?'**
  String get howAddNewProducts;

  /// No description provided for @howAddNewProductsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description for adding new products.'**
  String get howAddNewProductsDescription;

  /// No description provided for @howContactTechnicalSupport.
  ///
  /// In en, this message translates to:
  /// **'How to contact technical support?'**
  String get howContactTechnicalSupport;

  /// No description provided for @howContactTechnicalSupportDescription.
  ///
  /// In en, this message translates to:
  /// **'Description for contacting technical support.'**
  String get howContactTechnicalSupportDescription;

  /// No description provided for @todoMoreQuestions.
  ///
  /// In en, this message translates to:
  /// **'More questions (TODO)'**
  String get todoMoreQuestions;

  /// No description provided for @scrollToTop.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get scrollToTop;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @sendMessageOrContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Send a message or contact admin.'**
  String get sendMessageOrContactAdmin;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get yourMessage;

  /// No description provided for @howToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'How to place an order?'**
  String get howToPlaceOrder;

  /// No description provided for @goToSpysCard.
  ///
  /// In en, this message translates to:
  /// **'Go to Spys card.'**
  String get goToSpysCard;

  /// No description provided for @howToLoadMyWallet.
  ///
  /// In en, this message translates to:
  /// **'How to load my wallet?'**
  String get howToLoadMyWallet;

  /// No description provided for @goToWallet.
  ///
  /// In en, this message translates to:
  /// **'Go to wallet.'**
  String get goToWallet;

  /// No description provided for @whoToContactForHelp.
  ///
  /// In en, this message translates to:
  /// **'Who to contact for help?'**
  String get whoToContactForHelp;

  /// No description provided for @useSupportScreenOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Use support screen or email.'**
  String get useSupportScreenOrEmail;

  /// No description provided for @addMoreQuestions.
  ///
  /// In en, this message translates to:
  /// **'Add more questions.'**
  String get addMoreQuestions;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @clearAllItems.
  ///
  /// In en, this message translates to:
  /// **'Clear all items?'**
  String get clearAllItems;

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared.'**
  String get cartCleared;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @viewMenu.
  ///
  /// In en, this message translates to:
  /// **'View Menu'**
  String get viewMenu;

  /// No description provided for @yourCartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get yourCartIsEmpty;

  /// No description provided for @addItemsFromMenu.
  ///
  /// In en, this message translates to:
  /// **'Add items from menu.'**
  String get addItemsFromMenu;

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get yourBalance;

  /// No description provided for @loadUp.
  ///
  /// In en, this message translates to:
  /// **'Load up'**
  String get loadUp;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @shortfall.
  ///
  /// In en, this message translates to:
  /// **'Shortfall'**
  String get shortfall;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @payDifference.
  ///
  /// In en, this message translates to:
  /// **'Pay difference'**
  String get payDifference;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get confirmOrder;

  /// No description provided for @orderReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Order ready for pickup.'**
  String get orderReadyForPickup;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @orderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get orderDetailTitle;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get orderNotFound;

  /// No description provided for @orderInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Info'**
  String get orderInfoTitle;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderIdLabel;

  /// No description provided for @orderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDateLabel;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @orderedItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ordered Items'**
  String get orderedItemsTitle;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @vatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @pickupInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup Info'**
  String get pickupInfoTitle;

  /// No description provided for @readyUntil.
  ///
  /// In en, this message translates to:
  /// **'Ready until'**
  String get readyUntil;

  /// No description provided for @yourOrderIsReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready for pickup.'**
  String get yourOrderIsReadyForPickup;

  /// No description provided for @showYourQRCodeAtTheCounter.
  ///
  /// In en, this message translates to:
  /// **'Show your QR code at the counter.'**
  String get showYourQRCodeAtTheCounter;

  /// No description provided for @allergyWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Allergy Warning'**
  String get allergyWarningTitle;

  /// No description provided for @allergiesWarningDescription.
  ///
  /// In en, this message translates to:
  /// **'Allergies warning description.'**
  String get allergiesWarningDescription;

  /// No description provided for @showQRCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get showQRCodeButton;

  /// No description provided for @cancelOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrderButton;

  /// No description provided for @giveFeedbackButton.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback'**
  String get giveFeedbackButton;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get specialInstructions;

  /// No description provided for @qrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCodeTitle;

  /// No description provided for @qrCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCodeLabel;

  /// No description provided for @showThisCodeAt.
  ///
  /// In en, this message translates to:
  /// **'Show this code at'**
  String get showThisCodeAt;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @qrCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'QR code copied.'**
  String get qrCodeCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrderTitle;

  /// No description provided for @areYouSureToCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to cancel order?'**
  String get areYouSureToCancelOrder;

  /// No description provided for @yourMoneyWillBeRefundedToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your money will be refunded to your account.'**
  String get yourMoneyWillBeRefundedToYourAccount;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled.'**
  String get orderCancelled;

  /// No description provided for @moneyRefunded.
  ///
  /// In en, this message translates to:
  /// **'Money refunded.'**
  String get moneyRefunded;

  /// No description provided for @couldNotCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel order.'**
  String get couldNotCancelOrder;

  /// No description provided for @yesCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel order'**
  String get yesCancelOrder;

  /// No description provided for @giveFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback'**
  String get giveFeedbackTitle;

  /// No description provided for @howWasYourExperienceWithOrder.
  ///
  /// In en, this message translates to:
  /// **'How was your experience with order?'**
  String get howWasYourExperienceWithOrder;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// No description provided for @thankYouForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback.'**
  String get thankYouForFeedback;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @readyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get readyForPickup;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @pendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Pending description.'**
  String get pendingDescription;

  /// No description provided for @processingDescription.
  ///
  /// In en, this message translates to:
  /// **'Processing description.'**
  String get processingDescription;

  /// No description provided for @readyDescription.
  ///
  /// In en, this message translates to:
  /// **'Ready description.'**
  String get readyDescription;

  /// No description provided for @deliveredDescription.
  ///
  /// In en, this message translates to:
  /// **'Delivered description.'**
  String get deliveredDescription;

  /// No description provided for @cancelledDescription.
  ///
  /// In en, this message translates to:
  /// **'Cancelled description.'**
  String get cancelledDescription;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unknown.'**
  String get statusUnknown;

  /// No description provided for @aboutSpysAdminTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms for Spys Admin (TODO)'**
  String get aboutSpysAdminTerms;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmailFormat;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMinLength;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get noAccount;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts'**
  String get demoAccounts;

  /// No description provided for @demoStudent.
  ///
  /// In en, this message translates to:
  /// **'Demo student'**
  String get demoStudent;

  /// No description provided for @demoAdmin.
  ///
  /// In en, this message translates to:
  /// **'Demo admin'**
  String get demoAdmin;

  /// No description provided for @nameMustBeAtLeastTwoCharacters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least two characters.'**
  String get nameMustBeAtLeastTwoCharacters;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required.'**
  String get phoneNumberRequired;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number.'**
  String get invalidPhoneNumber;

  /// No description provided for @passwordMustBeAtLeastEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMustBeAtLeastEightCharacters;

  /// No description provided for @youMustAcceptTheTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions.'**
  String get youMustAcceptTheTermsAndConditions;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// No description provided for @yourAccountHasBeenSuccessfullyCreated.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully created.'**
  String get yourAccountHasBeenSuccessfullyCreated;

  /// No description provided for @aVerificationEmailHasBeenSentToYourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to your email address.'**
  String get aVerificationEmailHasBeenSentToYourEmailAddress;

  /// No description provided for @forDemoPurposesYouAreAutomaticallyLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'For demo purposes, you are automatically logged in.'**
  String get forDemoPurposesYouAreAutomaticallyLoggedIn;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get registrationFailed;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @fillInYourDetailsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details to get started.'**
  String get fillInYourDetailsToGetStarted;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name required.'**
  String get fullNameRequired;

  /// No description provided for @exampleEmail.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get exampleEmail;

  /// No description provided for @examplePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'0123456789'**
  String get examplePhoneNumber;

  /// No description provided for @userTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'User type required.'**
  String get userTypeRequired;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @lecturer.
  ///
  /// In en, this message translates to:
  /// **'Lecturer'**
  String get lecturer;

  /// No description provided for @external.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get external;

  /// No description provided for @allergiesOptional.
  ///
  /// In en, this message translates to:
  /// **'Allergies (optional)'**
  String get allergiesOptional;

  /// No description provided for @iAcceptTheTermsAndConditionsRequired.
  ///
  /// In en, this message translates to:
  /// **'I accept the terms and conditions (required)'**
  String get iAcceptTheTermsAndConditionsRequired;

  /// No description provided for @termsAndConditionsWillBeDisplayedHere.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions will be displayed here.'**
  String get termsAndConditionsWillBeDisplayedHere;

  /// No description provided for @readTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Read terms and conditions'**
  String get readTermsAndConditions;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @todoSkakelNaAppStoreOfGeeSterGradering.
  ///
  /// In en, this message translates to:
  /// **'TODO: Link to App Store or give star rating.'**
  String get todoSkakelNaAppStoreOfGeeSterGradering;

  /// No description provided for @sluit.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sluit;

  /// No description provided for @jouTerugvoer.
  ///
  /// In en, this message translates to:
  /// **'Your feedback'**
  String get jouTerugvoer;

  /// No description provided for @kanselleer.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get kanselleer;

  /// No description provided for @terugvoerGestuurDummy.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent (dummy)'**
  String get terugvoerGestuurDummy;

  /// No description provided for @stuur.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get stuur;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required.'**
  String get confirmPasswordRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get loginFailed;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequired;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['af', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af': return AppLocalizationsAf();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
