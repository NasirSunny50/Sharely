// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'Sharely';

  @override
  String get actionSend => 'পাঠান';

  @override
  String get actionSending => 'পাঠানো হচ্ছে';

  @override
  String get actionSent => 'পাঠানো হয়েছে';

  @override
  String get actionReceive => 'গ্রহণ করুন';

  @override
  String get actionReceiving => 'গ্রহণ করা হচ্ছে';

  @override
  String get actionCancel => 'বাতিল';

  @override
  String get actionReject => 'ফিরিয়ে দিন';

  @override
  String get actionDone => 'হয়ে গেছে';

  @override
  String get actionRetry => 'আবার চেষ্টা করুন';

  @override
  String get actionOpen => 'খুলুন';

  @override
  String get actionChange => 'বদলান';

  @override
  String get actionReview => 'দেখে নিন';

  @override
  String get actionContinue => 'এগিয়ে যান';

  @override
  String get actionSkip => 'বাদ দিন';

  @override
  String get actionRemove => 'সরান';

  @override
  String get actionScanNetwork => 'নেটওয়ার্ক খুঁজুন';

  @override
  String get homeReady => 'প্রস্তুত';

  @override
  String homeVisibleTo(Object network, Object count) {
    return '$network-এ আছেন, $countটি ডিভাইস আপনাকে দেখতে পাচ্ছে';
  }

  @override
  String get homePrivacyLine =>
      'আপনি যা পাঠান তা এই নেটওয়ার্কের বাইরে যায় না।';

  @override
  String get homeNearbyDevices => 'কাছের ডিভাইস';

  @override
  String get homeScanning => 'খোঁজা হচ্ছে…';

  @override
  String homeScanCount(Object count) {
    return '$countটি পাওয়া গেছে';
  }

  @override
  String get homeSendSomething => 'কিছু পাঠান';

  @override
  String get homeWaitForSomeone => 'কেউ পাঠানোর জন্য অপেক্ষা করুন';

  @override
  String get homeNothingFound => 'কাছের ডিভাইস খোঁজা হচ্ছে';

  @override
  String get homeNothingFoundHint =>
      'অন্য ডিভাইসটি একই Wi-Fi-তে আছে এবং Sharely খোলা আছে কিনা দেখে নিন।';

  @override
  String get homeNoWifiTitle => 'Sharely অন্য ডিভাইস দেখতে পাচ্ছে না';

  @override
  String get homeNoWifiBody =>
      'ইন্টারনেট ছাড়াই কাজ করলেও ডিভাইস খুঁজতে Sharely-এর Wi-Fi লাগে। এগিয়ে যেতে একটি নেটওয়ার্কে যুক্ত হন।';

  @override
  String get homeOpenWifiSettings => 'Wi-Fi সেটিংস খুলুন';

  @override
  String get tabHistory => 'ইতিহাস';

  @override
  String get tabFavourites => 'প্রিয়';

  @override
  String get tabSettings => 'সেটিংস';

  @override
  String get favouriteBadge => 'প্রিয়';

  @override
  String get linkStrong => 'শক্তিশালী';

  @override
  String get linkOk => 'মোটামুটি';

  @override
  String get linkWeak => 'দুর্বল';

  @override
  String sendToTitle(Object name) {
    return '$name-এ পাঠান';
  }

  @override
  String get hubPhotos => 'ছবি ও ভিডিও';

  @override
  String hubPhotosSub(Object count) {
    return '$countটি আইটেম';
  }

  @override
  String get hubFiles => 'ফাইল';

  @override
  String get hubFilesSub => 'স্টোরেজ ঘাঁটুন';

  @override
  String get hubFolders => 'ফোল্ডার';

  @override
  String get hubFoldersSub => 'পুরো ফোল্ডার, জিপ ছাড়াই';

  @override
  String get hubApps => 'অ্যাপ';

  @override
  String get hubAppsSub => 'APK, শুধু Android';

  @override
  String get hubText => 'লেখা পাঠান';

  @override
  String get hubTextSub => 'টাইপ করুন, বা ক্লিপবোর্ডের লেখা পাঠান';

  @override
  String hubFavouriteNote(Object name) {
    return '$name প্রিয় তালিকায় আছে, তাই ওপাশে কিছু অনুমোদন করতে হবে না।';
  }

  @override
  String get pickerCameraRoll => 'ক্যামেরা রোল';

  @override
  String pickerSelectedCount(Object count) {
    return '$countটি বাছাই';
  }

  @override
  String get reviewTitle => 'পাঠানোর জন্য প্রস্তুত';

  @override
  String get reviewGoingTo => 'যাচ্ছে';

  @override
  String reviewFilesCount(Object count) {
    return '$countটি ফাইল';
  }

  @override
  String sendingKeepOn(Object network) {
    return 'দুটি স্ক্রিন চালু রাখুন এবং $network-এ থাকুন।';
  }

  @override
  String sendingSpeed(Object speed) {
    return '$speed/সে';
  }

  @override
  String sendingEta(Object eta) {
    return '$eta বাকি';
  }

  @override
  String completeTitle(Object count, Object name) {
    return '$countটি ফাইল $name-এ পৌঁছেছে';
  }

  @override
  String completeSavedTo(Object path) {
    return '$path-এ সংরক্ষিত';
  }

  @override
  String get completeSendElse => 'আরও কিছু পাঠান';

  @override
  String incomingTitle(Object name, Object count) {
    return '$name $countটি ফাইল পাঠাতে চায়';
  }

  @override
  String incomingUntick(Object folder) {
    return 'যা চান না তার টিক তুলে দিন। ফাইল $folder-এ যাবে।';
  }

  @override
  String incomingAccept(Object count) {
    return '$countটি নিন';
  }

  @override
  String get failedTitle => 'পাঠানো থেমে গেছে';

  @override
  String get failedConnectionLost =>
      'সংযোগ ছুটে গেছে। দুটি ডিভাইসকে একই Wi-Fi-তে থাকতে হবে।';

  @override
  String get failedDiskFull => 'অন্য ডিভাইসে আর জায়গা নেই।';

  @override
  String get failedGone => 'অন্য ডিভাইসটি চলে গেছে।';

  @override
  String get rejectedTitle => 'এবার নয়';

  @override
  String rejectedBody(Object name) {
    return '$name ফাইলগুলো নেয়নি।';
  }

  @override
  String get cancelledTitle => 'পাঠানো বাতিল হয়েছে';

  @override
  String get historyTitle => 'ইতিহাস';

  @override
  String get historyToday => 'আজ';

  @override
  String get historyEmpty => 'এখনও কোনো লেনদেন নেই';

  @override
  String get historyEmptyHint => 'আপনার পাঠানো ও পাওয়া ফাইল এখানে দেখা যাবে।';

  @override
  String get historySent => 'পাঠানো';

  @override
  String get historyReceived => 'পাওয়া';

  @override
  String get favouritesTitle => 'প্রিয়';

  @override
  String get favouritesEmpty => 'এখনও কোনো প্রিয় নেই';

  @override
  String get favouritesAutoAccept => 'স্বয়ংক্রিয় গ্রহণ';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsDeviceName => 'এই ডিভাইসের নাম';

  @override
  String get settingsSaveTo => 'পাওয়া ফাইল যাবে';

  @override
  String get settingsAskBeforeAccepting => 'গ্রহণের আগে জিজ্ঞাসা';

  @override
  String get settingsAskBeforeAcceptingSub =>
      'বন্ধ থাকলে কাছের যে কেউ ফাইল পাঠাতে পারবে';

  @override
  String get settingsLanguage => 'ভাষা';

  @override
  String get settingsAppearance => 'চেহারা';

  @override
  String get settingsNetwork => 'নেটওয়ার্ক';

  @override
  String get settingsSecurity => 'নিরাপত্তা';

  @override
  String get settingsAbout => 'সম্পর্কে';

  @override
  String get settingsPrivacyNote =>
      'Sharely-র কোনো অ্যাকাউন্ট বা সার্ভার নেই। আপনি যা পাঠান তা কখনও আপলোড হয় না।';

  @override
  String get settingsThemeLight => 'উজ্জ্বল';

  @override
  String get settingsThemeDark => 'অন্ধকার';

  @override
  String get settingsThemeSystem => 'সিস্টেম';

  @override
  String get browserWaitingTitle => 'নিতে স্ক্যান করুন';

  @override
  String get browserWaitingBody =>
      'অন্য ফোনে ক্যামেরা খুলে এটি স্ক্যান করুন, বা ঠিকানাটি ব্রাউজারে টাইপ করুন।';

  @override
  String get browserNobody => 'এখনও কেউ যুক্ত হয়নি';

  @override
  String browserConnected(Object count) {
    return '$count জন যুক্ত হয়েছে';
  }

  @override
  String get browserStopSharing => 'শেয়ার বন্ধ করুন';

  @override
  String get pinSetTitle => 'একটি PIN দিন';

  @override
  String get pinSetBody =>
      'শুধু যারা এই ৬-সংখ্যার কোড জানে তারাই আপনাকে পাঠাতে পারবে।';

  @override
  String get pinEnterTitle => 'PIN দিন';

  @override
  String get pinWrong => 'PIN মিলল না';

  @override
  String get pinLocked => 'অনেকবার হয়ে গেছে। একটু পরে আবার চেষ্টা করুন।';

  @override
  String get troubleshootTitle => 'ডিভাইস খুঁজে পাচ্ছেন না?';

  @override
  String get troubleshootRouterIsolation =>
      'আপনার রাউটার হয়তো ডিভাইসগুলোকে একে অপরকে দেখতে বাধা দিচ্ছে (client isolation)।';

  @override
  String get troubleshootGuestWifi =>
      'গেস্ট Wi-Fi সাধারণত এটি বন্ধ রাখে। মূল নেটওয়ার্ক ব্যবহার করুন।';

  @override
  String get troubleshootVpn =>
      'চালু VPN খোঁজা নষ্ট করতে পারে। বন্ধ করে আবার চেষ্টা করুন।';

  @override
  String get troubleshootFirewall =>
      'ফায়ারওয়াল হয়তো Sharely বন্ধ রাখছে। পোর্ট 53317-এ অনুমতি দিন।';

  @override
  String get manualConnectTitle => 'হাতে যুক্ত হন';

  @override
  String get manualConnectBody =>
      'অন্য ডিভাইসের IP ঠিকানা লিখুন, বা তার QR কোড স্ক্যান করুন।';

  @override
  String get manualConnectHint => '192.168.0.0';

  @override
  String get stateNoWifi => 'Wi-Fi নেই';

  @override
  String get statePermissionDenied => 'অনুমতি দরকার';

  @override
  String get stateDiskFull => 'স্টোরেজ ভর্তি';
}
