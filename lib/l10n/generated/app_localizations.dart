import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sharely'**
  String get appName;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @actionSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get actionSending;

  /// No description provided for @actionSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get actionSent;

  /// No description provided for @actionReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get actionReceive;

  /// No description provided for @actionReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get actionReceiving;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actionReject;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @actionReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get actionReview;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionScanNetwork.
  ///
  /// In en, this message translates to:
  /// **'Scan network'**
  String get actionScanNetwork;

  /// No description provided for @homeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get homeReady;

  /// No description provided for @homeVisibleTo.
  ///
  /// In en, this message translates to:
  /// **'On {network}, visible to {count} devices'**
  String homeVisibleTo(Object network, Object count);

  /// No description provided for @homePrivacyLine.
  ///
  /// In en, this message translates to:
  /// **'Nothing you send leaves this network.'**
  String get homePrivacyLine;

  /// No description provided for @homeNearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get homeNearbyDevices;

  /// No description provided for @homeScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get homeScanning;

  /// No description provided for @homeScanCount.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String homeScanCount(Object count);

  /// No description provided for @homeSendSomething.
  ///
  /// In en, this message translates to:
  /// **'Send something'**
  String get homeSendSomething;

  /// No description provided for @homeWaitForSomeone.
  ///
  /// In en, this message translates to:
  /// **'Wait for someone to send'**
  String get homeWaitForSomeone;

  /// No description provided for @homeNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Looking for nearby devices'**
  String get homeNothingFound;

  /// No description provided for @homeNothingFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the other device is on the same Wi-Fi and has Sharely open.'**
  String get homeNothingFoundHint;

  /// No description provided for @homeNoWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharely can\'t see other devices'**
  String get homeNoWifiTitle;

  /// No description provided for @homeNoWifiBody.
  ///
  /// In en, this message translates to:
  /// **'Sharely needs Wi-Fi to find devices, even though it never uses the internet. Connect to a network to continue.'**
  String get homeNoWifiBody;

  /// No description provided for @homeOpenWifiSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Wi-Fi settings'**
  String get homeOpenWifiSettings;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get tabFavourites;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @favouriteBadge.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favouriteBadge;

  /// No description provided for @linkStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get linkStrong;

  /// No description provided for @linkOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get linkOk;

  /// No description provided for @linkWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get linkWeak;

  /// No description provided for @sendToTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to {name}'**
  String sendToTitle(Object name);

  /// No description provided for @hubPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos & videos'**
  String get hubPhotos;

  /// No description provided for @hubPhotosSub.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String hubPhotosSub(Object count);

  /// No description provided for @hubFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get hubFiles;

  /// No description provided for @hubFilesSub.
  ///
  /// In en, this message translates to:
  /// **'Browse storage'**
  String get hubFilesSub;

  /// No description provided for @hubFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get hubFolders;

  /// No description provided for @hubFoldersSub.
  ///
  /// In en, this message translates to:
  /// **'Whole tree, nothing zipped'**
  String get hubFoldersSub;

  /// No description provided for @hubApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get hubApps;

  /// No description provided for @hubAppsSub.
  ///
  /// In en, this message translates to:
  /// **'APK, Android only'**
  String get hubAppsSub;

  /// No description provided for @hubText.
  ///
  /// In en, this message translates to:
  /// **'Send text'**
  String get hubText;

  /// No description provided for @hubTextSub.
  ///
  /// In en, this message translates to:
  /// **'Type it, or send what\'s on your clipboard'**
  String get hubTextSub;

  /// No description provided for @hubFavouriteNote.
  ///
  /// In en, this message translates to:
  /// **'{name} is a favourite, so nothing will need approving on the other end.'**
  String hubFavouriteNote(Object name);

  /// No description provided for @pickerCameraRoll.
  ///
  /// In en, this message translates to:
  /// **'Camera roll'**
  String get pickerCameraRoll;

  /// No description provided for @pickerSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String pickerSelectedCount(Object count);

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get reviewTitle;

  /// No description provided for @reviewGoingTo.
  ///
  /// In en, this message translates to:
  /// **'Going to'**
  String get reviewGoingTo;

  /// No description provided for @reviewFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String reviewFilesCount(Object count);

  /// No description provided for @sendingKeepOn.
  ///
  /// In en, this message translates to:
  /// **'Keep both screens on and stay on {network}.'**
  String sendingKeepOn(Object network);

  /// No description provided for @sendingSpeed.
  ///
  /// In en, this message translates to:
  /// **'{speed}/s'**
  String sendingSpeed(Object speed);

  /// No description provided for @sendingEta.
  ///
  /// In en, this message translates to:
  /// **'{eta} left'**
  String sendingEta(Object eta);

  /// No description provided for @completeTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} files landed on {name}'**
  String completeTitle(Object count, Object name);

  /// No description provided for @completeSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String completeSavedTo(Object path);

  /// No description provided for @completeSendElse.
  ///
  /// In en, this message translates to:
  /// **'Send something else'**
  String get completeSendElse;

  /// No description provided for @incomingTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to send {count} files'**
  String incomingTitle(Object name, Object count);

  /// No description provided for @incomingUntick.
  ///
  /// In en, this message translates to:
  /// **'Untick anything you don\'t want. Files land in {folder}.'**
  String incomingUntick(Object folder);

  /// No description provided for @incomingAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept {count}'**
  String incomingAccept(Object count);

  /// No description provided for @failedTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer stopped'**
  String get failedTitle;

  /// No description provided for @failedConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped. Both devices need to stay on the same Wi-Fi.'**
  String get failedConnectionLost;

  /// No description provided for @failedDiskFull.
  ///
  /// In en, this message translates to:
  /// **'There\'s no room left on the other device.'**
  String get failedDiskFull;

  /// No description provided for @failedGone.
  ///
  /// In en, this message translates to:
  /// **'The other device went away.'**
  String get failedGone;

  /// No description provided for @rejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get rejectedTitle;

  /// No description provided for @rejectedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} declined the files.'**
  String rejectedBody(Object name);

  /// No description provided for @cancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer cancelled'**
  String get cancelledTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transfers yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Files you send and receive will show up here.'**
  String get historyEmptyHint;

  /// No description provided for @historySent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get historySent;

  /// No description provided for @historyReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get historyReceived;

  /// No description provided for @favouritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favouritesTitle;

  /// No description provided for @favouritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet'**
  String get favouritesEmpty;

  /// No description provided for @favouritesAutoAccept.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept'**
  String get favouritesAutoAccept;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDeviceName.
  ///
  /// In en, this message translates to:
  /// **'This device is called'**
  String get settingsDeviceName;

  /// No description provided for @settingsSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Received files go to'**
  String get settingsSaveTo;

  /// No description provided for @settingsAskBeforeAccepting.
  ///
  /// In en, this message translates to:
  /// **'Ask before accepting'**
  String get settingsAskBeforeAccepting;

  /// No description provided for @settingsAskBeforeAcceptingSub.
  ///
  /// In en, this message translates to:
  /// **'Off means anyone nearby can drop files here'**
  String get settingsAskBeforeAcceptingSub;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsNetwork;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Sharely has no account and no server. Nothing you send is ever uploaded.'**
  String get settingsPrivacyNote;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @browserWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to receive'**
  String get browserWaitingTitle;

  /// No description provided for @browserWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'On the other phone, open the camera and scan this, or type the address into a browser.'**
  String get browserWaitingBody;

  /// No description provided for @browserNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody has connected yet'**
  String get browserNobody;

  /// No description provided for @browserConnected.
  ///
  /// In en, this message translates to:
  /// **'{count} connected'**
  String browserConnected(Object count);

  /// No description provided for @browserStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get browserStopSharing;

  /// No description provided for @pinSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get pinSetTitle;

  /// No description provided for @pinSetBody.
  ///
  /// In en, this message translates to:
  /// **'Only people who know this 6-digit code can send to you.'**
  String get pinSetBody;

  /// No description provided for @pinEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get pinEnterTitle;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'That PIN didn\'t match'**
  String get pinWrong;

  /// No description provided for @pinLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a moment and try again.'**
  String get pinLocked;

  /// No description provided for @troubleshootTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find a device?'**
  String get troubleshootTitle;

  /// No description provided for @troubleshootRouterIsolation.
  ///
  /// In en, this message translates to:
  /// **'Your router may be blocking devices from seeing each other (client isolation).'**
  String get troubleshootRouterIsolation;

  /// No description provided for @troubleshootGuestWifi.
  ///
  /// In en, this message translates to:
  /// **'Guest Wi-Fi networks usually block this. Use your main network.'**
  String get troubleshootGuestWifi;

  /// No description provided for @troubleshootVpn.
  ///
  /// In en, this message translates to:
  /// **'An active VPN can break discovery. Turn it off and try again.'**
  String get troubleshootVpn;

  /// No description provided for @troubleshootFirewall.
  ///
  /// In en, this message translates to:
  /// **'A firewall may be blocking Sharely. Allow it on port 53317.'**
  String get troubleshootFirewall;

  /// No description provided for @manualConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect by hand'**
  String get manualConnectTitle;

  /// No description provided for @manualConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the other device\'s IP address, or scan its QR code.'**
  String get manualConnectBody;

  /// No description provided for @manualConnectHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.0.0'**
  String get manualConnectHint;

  /// No description provided for @stateNoWifi.
  ///
  /// In en, this message translates to:
  /// **'No Wi-Fi'**
  String get stateNoWifi;

  /// No description provided for @statePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get statePermissionDenied;

  /// No description provided for @stateDiskFull.
  ///
  /// In en, this message translates to:
  /// **'Storage full'**
  String get stateDiskFull;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
