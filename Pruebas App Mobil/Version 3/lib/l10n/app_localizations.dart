import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get settings_title;

  /// No description provided for @my_account.
  ///
  /// In en, this message translates to:
  /// **'MY ACCOUNT'**
  String get my_account;

  /// No description provided for @nickname_bio.
  ///
  /// In en, this message translates to:
  /// **'Nickname & Bio'**
  String get nickname_bio;

  /// No description provided for @identity_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Public identity on the network'**
  String get identity_subtitle;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get security;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacy;

  /// No description provided for @map_visibility.
  ///
  /// In en, this message translates to:
  /// **'Map Visibility'**
  String get map_visibility;

  /// No description provided for @ghost_mode.
  ///
  /// In en, this message translates to:
  /// **'Ghost Mode'**
  String get ghost_mode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @legal_support.
  ///
  /// In en, this message translates to:
  /// **'LEGAL & SUPPORT'**
  String get legal_support;

  /// No description provided for @sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get sign_out;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account permanently'**
  String get delete_account;

  /// No description provided for @welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Create your own\nmagical adventure!'**
  String get welcome_title;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore secret places and bring them to life\nwith the magic of your colors.'**
  String get welcome_subtitle;

  /// No description provided for @start_playing.
  ///
  /// In en, this message translates to:
  /// **'START PLAYING!'**
  String get start_playing;

  /// No description provided for @login_now.
  ///
  /// In en, this message translates to:
  /// **'Login now'**
  String get login_now;

  /// No description provided for @join_adventure.
  ///
  /// In en, this message translates to:
  /// **'JOIN THE ADVENTURE'**
  String get join_adventure;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @explore_hidden.
  ///
  /// In en, this message translates to:
  /// **'Explore hidden places with us'**
  String get explore_hidden;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get username;

  /// No description provided for @username_hint.
  ///
  /// In en, this message translates to:
  /// **'Your artistic name'**
  String get username_hint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get password;

  /// No description provided for @register_button.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register_button;

  /// No description provided for @or_register_with.
  ///
  /// In en, this message translates to:
  /// **'OR REGISTER WITH'**
  String get or_register_with;

  /// No description provided for @already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get already_have_account;

  /// No description provided for @login_link.
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get login_link;

  /// No description provided for @hello_again.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get hello_again;

  /// No description provided for @enter_ar_world.
  ///
  /// In en, this message translates to:
  /// **'Enter your augmented reality world'**
  String get enter_ar_world;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot it?'**
  String get forgot_password;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @or_use_account.
  ///
  /// In en, this message translates to:
  /// **'OR USE YOUR ACCOUNT'**
  String get or_use_account;

  /// No description provided for @no_account_yet.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get no_account_yet;

  /// No description provided for @register_link.
  ///
  /// In en, this message translates to:
  /// **'Register here!'**
  String get register_link;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get nav_social;

  /// No description provided for @nav_map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get nav_map;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @home_hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String home_hello(Object name);

  /// No description provided for @home_creative_world.
  ///
  /// In en, this message translates to:
  /// **'Creative AR World'**
  String get home_creative_world;

  /// No description provided for @home_your_adventure.
  ///
  /// In en, this message translates to:
  /// **'Your Adventure'**
  String get home_your_adventure;

  /// No description provided for @home_view_map.
  ///
  /// In en, this message translates to:
  /// **'VIEW MAP'**
  String get home_view_map;

  /// No description provided for @home_contest.
  ///
  /// In en, this message translates to:
  /// **'CONTEST'**
  String get home_contest;

  /// No description provided for @home_scan_ar.
  ///
  /// In en, this message translates to:
  /// **'SCAN AR'**
  String get home_scan_ar;

  /// No description provided for @home_feed_social.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL FEED'**
  String get home_feed_social;

  /// No description provided for @home_my_gallery.
  ///
  /// In en, this message translates to:
  /// **'MY GALLERY'**
  String get home_my_gallery;

  /// No description provided for @home_my_profile.
  ///
  /// In en, this message translates to:
  /// **'MY PROFILE'**
  String get home_my_profile;

  /// No description provided for @home_exclusive_news.
  ///
  /// In en, this message translates to:
  /// **'EXCLUSIVE NEWS'**
  String get home_exclusive_news;

  /// No description provided for @home_paint_reality.
  ///
  /// In en, this message translates to:
  /// **'Paint your\nReality'**
  String get home_paint_reality;

  /// No description provided for @home_explore_desc.
  ///
  /// In en, this message translates to:
  /// **'Explore the world and add color with our creative AR.'**
  String get home_explore_desc;

  /// No description provided for @home_start_button.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get home_start_button;

  /// No description provided for @profile_my_pro.
  ///
  /// In en, this message translates to:
  /// **'MY PRO PROFILE'**
  String get profile_my_pro;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile_title;

  /// No description provided for @profile_user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get profile_user_not_found;

  /// No description provided for @profile_following_btn.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWING'**
  String get profile_following_btn;

  /// No description provided for @profile_follow_btn.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW'**
  String get profile_follow_btn;

  /// No description provided for @profile_total_points.
  ///
  /// In en, this message translates to:
  /// **'TOTAL POINTS'**
  String get profile_total_points;

  /// No description provided for @profile_progress.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS → {level}'**
  String profile_progress(Object level);

  /// No description provided for @profile_pts_needed.
  ///
  /// In en, this message translates to:
  /// **'You need {pts} pts for {level}'**
  String profile_pts_needed(Object level, Object pts);

  /// No description provided for @profile_followers.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWERS'**
  String get profile_followers;

  /// No description provided for @profile_following.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWING'**
  String get profile_following;

  /// No description provided for @profile_works.
  ///
  /// In en, this message translates to:
  /// **'WORKS'**
  String get profile_works;

  /// No description provided for @profile_medals.
  ///
  /// In en, this message translates to:
  /// **'Medals'**
  String get profile_medals;

  /// No description provided for @profile_view_ranking.
  ///
  /// In en, this message translates to:
  /// **'View Ranking'**
  String get profile_view_ranking;

  /// No description provided for @profile_portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get profile_portfolio;

  /// No description provided for @profile_no_works.
  ///
  /// In en, this message translates to:
  /// **'No works in portfolio yet'**
  String get profile_no_works;

  /// No description provided for @profile_opening_3d.
  ///
  /// In en, this message translates to:
  /// **'Opening 3D viewer...'**
  String get profile_opening_3d;

  /// No description provided for @social_no_posts.
  ///
  /// In en, this message translates to:
  /// **'No posts from friends yet'**
  String get social_no_posts;

  /// No description provided for @social_what_thinking.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get social_what_thinking;

  /// No description provided for @social_create_post.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get social_create_post;

  /// No description provided for @social_start_post.
  ///
  /// In en, this message translates to:
  /// **'Start a post...'**
  String get social_start_post;

  /// No description provided for @social_photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get social_photo;

  /// No description provided for @social_video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get social_video;

  /// No description provided for @social_event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get social_event;

  /// No description provided for @map_perm_denied.
  ///
  /// In en, this message translates to:
  /// **'Permanent Permission Denied'**
  String get map_perm_denied;

  /// No description provided for @map_perm_denied_desc.
  ///
  /// In en, this message translates to:
  /// **'You have permanently denied location permission. You must manually enable it in app settings to use the map.'**
  String get map_perm_denied_desc;

  /// No description provided for @map_cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get map_cancel;

  /// No description provided for @map_open_settings.
  ///
  /// In en, this message translates to:
  /// **'OPEN SETTINGS'**
  String get map_open_settings;

  /// No description provided for @map_allow_loc.
  ///
  /// In en, this message translates to:
  /// **'Allow Location'**
  String get map_allow_loc;

  /// No description provided for @map_loc_reason.
  ///
  /// In en, this message translates to:
  /// **'Aura AR needs your location to show you artwork near you on the radar.'**
  String get map_loc_reason;

  /// No description provided for @map_continue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get map_continue;

  /// No description provided for @map_later.
  ///
  /// In en, this message translates to:
  /// **'LATER'**
  String get map_later;

  /// No description provided for @map_getting_loc.
  ///
  /// In en, this message translates to:
  /// **'GETTING LOCATION...'**
  String get map_getting_loc;

  /// No description provided for @map_gps_required.
  ///
  /// In en, this message translates to:
  /// **'GPS REQUIRED'**
  String get map_gps_required;

  /// No description provided for @map_gps_desc.
  ///
  /// In en, this message translates to:
  /// **'Enable location to explore the art.'**
  String get map_gps_desc;

  /// No description provided for @map_connect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get map_connect;

  /// No description provided for @map_create.
  ///
  /// In en, this message translates to:
  /// **'CREATE'**
  String get map_create;

  /// No description provided for @map_all.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get map_all;

  /// No description provided for @map_friends.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get map_friends;

  /// No description provided for @map_mine.
  ///
  /// In en, this message translates to:
  /// **'MINE'**
  String get map_mine;

  /// No description provided for @map_ghost_mode.
  ///
  /// In en, this message translates to:
  /// **'GHOST MODE'**
  String get map_ghost_mode;

  /// No description provided for @map_near_you.
  ///
  /// In en, this message translates to:
  /// **'NEAR YOU'**
  String get map_near_you;

  /// No description provided for @map_no_sites.
  ///
  /// In en, this message translates to:
  /// **'No artwork nearby'**
  String get map_no_sites;

  /// No description provided for @map_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get map_distance;

  /// No description provided for @map_likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get map_likes;

  /// No description provided for @map_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get map_date;

  /// No description provided for @add_site_title_err.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get add_site_title_err;

  /// No description provided for @add_site_img_err.
  ///
  /// In en, this message translates to:
  /// **'Please add an image of your work.'**
  String get add_site_img_err;

  /// No description provided for @add_site_gps_err.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS coordinates...'**
  String get add_site_gps_err;

  /// No description provided for @add_site_section_details.
  ///
  /// In en, this message translates to:
  /// **'WORK DETAILS'**
  String get add_site_section_details;

  /// No description provided for @add_site_proj_title.
  ///
  /// In en, this message translates to:
  /// **'Project Title'**
  String get add_site_proj_title;

  /// No description provided for @add_site_proj_hint.
  ///
  /// In en, this message translates to:
  /// **'Give your creation a name'**
  String get add_site_proj_hint;

  /// No description provided for @add_site_desc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get add_site_desc;

  /// No description provided for @add_site_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'What does this work mean to you?'**
  String get add_site_desc_hint;

  /// No description provided for @add_site_section_geo.
  ///
  /// In en, this message translates to:
  /// **'GEOLOCATION'**
  String get add_site_section_geo;

  /// No description provided for @add_site_new_title.
  ///
  /// In en, this message translates to:
  /// **'New AR Work'**
  String get add_site_new_title;

  /// No description provided for @add_site_upload_capture.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD CAPTURE'**
  String get add_site_upload_capture;

  /// No description provided for @add_site_gallery_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose from gallery'**
  String get add_site_gallery_hint;

  /// No description provided for @add_site_select_source.
  ///
  /// In en, this message translates to:
  /// **'SELECT SOURCE'**
  String get add_site_select_source;

  /// No description provided for @add_site_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get add_site_camera;

  /// No description provided for @add_site_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get add_site_gallery;

  /// No description provided for @add_site_coords_fixed.
  ///
  /// In en, this message translates to:
  /// **'COORDINATES FIXED'**
  String get add_site_coords_fixed;

  /// No description provided for @add_site_searching_signal.
  ///
  /// In en, this message translates to:
  /// **'SEARCHING SIGNAL...'**
  String get add_site_searching_signal;

  /// No description provided for @add_site_stay_clear.
  ///
  /// In en, this message translates to:
  /// **'Stay in an open area'**
  String get add_site_stay_clear;

  /// No description provided for @add_site_submit.
  ///
  /// In en, this message translates to:
  /// **'SEND TO REVIEW'**
  String get add_site_submit;

  /// No description provided for @add_site_gps_off.
  ///
  /// In en, this message translates to:
  /// **'Turn on GPS'**
  String get add_site_gps_off;

  /// No description provided for @add_site_perm_denied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get add_site_perm_denied;

  /// No description provided for @add_site_gps_error.
  ///
  /// In en, this message translates to:
  /// **'GPS Error'**
  String get add_site_gps_error;

  /// No description provided for @add_site_no_title.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get add_site_no_title;

  /// No description provided for @rank_title.
  ///
  /// In en, this message translates to:
  /// **'ARTISTS RANKING'**
  String get rank_title;

  /// No description provided for @rank_sync_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync points'**
  String get rank_sync_tooltip;

  /// No description provided for @rank_syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing points for all users...'**
  String get rank_syncing;

  /// No description provided for @rank_sync_done.
  ///
  /// In en, this message translates to:
  /// **'Global synchronization complete!'**
  String get rank_sync_done;

  /// No description provided for @rank_no_artists.
  ///
  /// In en, this message translates to:
  /// **'No artists in the ranking yet.'**
  String get rank_no_artists;

  /// No description provided for @rank_points.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get rank_points;

  /// No description provided for @rank_how_earn.
  ///
  /// In en, this message translates to:
  /// **'HOW TO EARN POINTS?'**
  String get rank_how_earn;

  /// No description provided for @rank_item_contest_like.
  ///
  /// In en, this message translates to:
  /// **'Like on your contest work'**
  String get rank_item_contest_like;

  /// No description provided for @rank_item_post_like.
  ///
  /// In en, this message translates to:
  /// **'Like on your post'**
  String get rank_item_post_like;

  /// No description provided for @rank_item_ar_gen.
  ///
  /// In en, this message translates to:
  /// **'Generate AR model'**
  String get rank_item_ar_gen;

  /// No description provided for @rank_item_contest_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload contest work'**
  String get rank_item_contest_upload;

  /// No description provided for @rank_item_new_post.
  ///
  /// In en, this message translates to:
  /// **'Create new post'**
  String get rank_item_new_post;

  /// No description provided for @tutorial_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorial_skip;

  /// No description provided for @tutorial_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorial_next;

  /// No description provided for @tutorial_start.
  ///
  /// In en, this message translates to:
  /// **'Get Started!'**
  String get tutorial_start;

  /// No description provided for @tutorial_title_1.
  ///
  /// In en, this message translates to:
  /// **'Explore the AR World'**
  String get tutorial_title_1;

  /// No description provided for @tutorial_desc_1.
  ///
  /// In en, this message translates to:
  /// **'Discover augmented reality artwork around you and notice every magical detail.'**
  String get tutorial_desc_1;

  /// No description provided for @tutorial_title_2.
  ///
  /// In en, this message translates to:
  /// **'Paint your Own Reality'**
  String get tutorial_title_2;

  /// No description provided for @tutorial_desc_2.
  ///
  /// In en, this message translates to:
  /// **'Create and share your own 3D models and artistic captures with our powerful artificial intelligence.'**
  String get tutorial_desc_2;

  /// No description provided for @tutorial_title_3.
  ///
  /// In en, this message translates to:
  /// **'Connect with the Community'**
  String get tutorial_title_3;

  /// No description provided for @tutorial_desc_3.
  ///
  /// In en, this message translates to:
  /// **'Level up in the artist ranking, earn medals and share your creations on the social feed.'**
  String get tutorial_desc_3;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
