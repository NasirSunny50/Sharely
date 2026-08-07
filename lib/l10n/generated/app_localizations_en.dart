// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sharely';

  @override
  String get actionSend => 'Send';

  @override
  String get actionSending => 'Sending';

  @override
  String get actionSent => 'Sent';

  @override
  String get actionReceive => 'Receive';

  @override
  String get actionReceiving => 'Receiving';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionDone => 'Done';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionChange => 'Change';

  @override
  String get actionReview => 'Review';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionScanNetwork => 'Scan network';

  @override
  String get homeReady => 'Ready';

  @override
  String homeVisibleTo(Object network, Object count) {
    return 'On $network, visible to $count devices';
  }

  @override
  String get homePrivacyLine => 'Nothing you send leaves this network.';

  @override
  String get homeNearbyDevices => 'Nearby devices';

  @override
  String get homeScanning => 'Scanning…';

  @override
  String homeScanCount(Object count) {
    return '$count found';
  }

  @override
  String get homeSendSomething => 'Send something';

  @override
  String get homeWaitForSomeone => 'Wait for someone to send';

  @override
  String get homeNothingFound => 'Looking for nearby devices';

  @override
  String get homeNothingFoundHint =>
      'Make sure the other device is on the same Wi-Fi and has Sharely open.';

  @override
  String get homeNoWifiTitle => 'Sharely can\'t see other devices';

  @override
  String get homeNoWifiBody =>
      'Sharely needs Wi-Fi to find devices, even though it never uses the internet. Connect to a network to continue.';

  @override
  String get homeOpenWifiSettings => 'Open Wi-Fi settings';

  @override
  String get tabHistory => 'History';

  @override
  String get tabFavourites => 'Favourites';

  @override
  String get tabSettings => 'Settings';

  @override
  String get favouriteBadge => 'Favourite';

  @override
  String get linkStrong => 'Strong';

  @override
  String get linkOk => 'OK';

  @override
  String get linkWeak => 'Weak';

  @override
  String sendToTitle(Object name) {
    return 'Send to $name';
  }

  @override
  String get hubPhotos => 'Photos & videos';

  @override
  String hubPhotosSub(Object count) {
    return '$count items';
  }

  @override
  String get hubFiles => 'Files';

  @override
  String get hubFilesSub => 'Browse storage';

  @override
  String get hubFolders => 'Folders';

  @override
  String get hubFoldersSub => 'Whole tree, nothing zipped';

  @override
  String get hubApps => 'Apps';

  @override
  String get hubAppsSub => 'APK, Android only';

  @override
  String get hubText => 'Send text';

  @override
  String get hubTextSub => 'Type it, or send what\'s on your clipboard';

  @override
  String hubFavouriteNote(Object name) {
    return '$name is a favourite, so nothing will need approving on the other end.';
  }

  @override
  String get pickerCameraRoll => 'Camera roll';

  @override
  String pickerSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get reviewTitle => 'Ready to send';

  @override
  String get reviewGoingTo => 'Going to';

  @override
  String reviewFilesCount(Object count) {
    return '$count files';
  }

  @override
  String sendingKeepOn(Object network) {
    return 'Keep both screens on and stay on $network.';
  }

  @override
  String sendingSpeed(Object speed) {
    return '$speed/s';
  }

  @override
  String sendingEta(Object eta) {
    return '$eta left';
  }

  @override
  String completeTitle(Object count, Object name) {
    return '$count files landed on $name';
  }

  @override
  String completeSavedTo(Object path) {
    return 'Saved to $path';
  }

  @override
  String get completeSendElse => 'Send something else';

  @override
  String incomingTitle(Object name, Object count) {
    return '$name wants to send $count files';
  }

  @override
  String incomingUntick(Object folder) {
    return 'Untick anything you don\'t want. Files land in $folder.';
  }

  @override
  String incomingAccept(Object count) {
    return 'Accept $count';
  }

  @override
  String get failedTitle => 'Transfer stopped';

  @override
  String get failedConnectionLost =>
      'The connection dropped. Both devices need to stay on the same Wi-Fi.';

  @override
  String get failedDiskFull => 'There\'s no room left on the other device.';

  @override
  String get failedGone => 'The other device went away.';

  @override
  String get rejectedTitle => 'Not this time';

  @override
  String rejectedBody(Object name) {
    return '$name declined the files.';
  }

  @override
  String get cancelledTitle => 'Transfer cancelled';

  @override
  String get historyTitle => 'History';

  @override
  String get historyToday => 'Today';

  @override
  String get historyEmpty => 'No transfers yet';

  @override
  String get historyEmptyHint =>
      'Files you send and receive will show up here.';

  @override
  String get historySent => 'Sent';

  @override
  String get historyReceived => 'Received';

  @override
  String get favouritesTitle => 'Favourites';

  @override
  String get favouritesEmpty => 'No favourites yet';

  @override
  String get favouritesAutoAccept => 'Auto-accept';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDeviceName => 'This device is called';

  @override
  String get settingsSaveTo => 'Received files go to';

  @override
  String get settingsAskBeforeAccepting => 'Ask before accepting';

  @override
  String get settingsAskBeforeAcceptingSub =>
      'Off means anyone nearby can drop files here';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNetwork => 'Network';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyNote =>
      'Sharely has no account and no server. Nothing you send is ever uploaded.';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get browserWaitingTitle => 'Scan to receive';

  @override
  String get browserWaitingBody =>
      'On the other phone, open the camera and scan this, or type the address into a browser.';

  @override
  String get browserNobody => 'Nobody has connected yet';

  @override
  String browserConnected(Object count) {
    return '$count connected';
  }

  @override
  String get browserStopSharing => 'Stop sharing';

  @override
  String get pinSetTitle => 'Set a PIN';

  @override
  String get pinSetBody =>
      'Only people who know this 6-digit code can send to you.';

  @override
  String get pinEnterTitle => 'Enter PIN';

  @override
  String get pinWrong => 'That PIN didn\'t match';

  @override
  String get pinLocked => 'Too many tries. Wait a moment and try again.';

  @override
  String get troubleshootTitle => 'Can\'t find a device?';

  @override
  String get troubleshootRouterIsolation =>
      'Your router may be blocking devices from seeing each other (client isolation).';

  @override
  String get troubleshootGuestWifi =>
      'Guest Wi-Fi networks usually block this. Use your main network.';

  @override
  String get troubleshootVpn =>
      'An active VPN can break discovery. Turn it off and try again.';

  @override
  String get troubleshootFirewall =>
      'A firewall may be blocking Sharely. Allow it on port 53317.';

  @override
  String get manualConnectTitle => 'Connect by hand';

  @override
  String get manualConnectBody =>
      'Enter the other device\'s IP address, or scan its QR code.';

  @override
  String get manualConnectHint => '192.168.0.0';

  @override
  String get stateNoWifi => 'No Wi-Fi';

  @override
  String get statePermissionDenied => 'Permission needed';

  @override
  String get stateDiskFull => 'Storage full';
}
