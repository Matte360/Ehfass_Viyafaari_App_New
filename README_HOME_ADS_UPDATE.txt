VIYAFAARI TOWN - ADMIN HOME ADVERTISEMENTS UPDATE
=================================================

WHAT THIS UPDATE ADDS
---------------------
Admin can create advertisements directly from the Admin Dashboard.
Those advertisements appear on the Client Home Page banner carousel.

ADDED TO ADMIN PAGE
-------------------
New tab: Home Ads

Admin can:
- choose a banner image
- add English title
- add Dhivehi title
- add English description
- add Dhivehi description
- set sort order
- show/hide advertisement
- delete advertisement

ADDED TO CLIENT HOME PAGE
-------------------------
The old fixed advertisement banners are still used as fallback.
When admin-created ads exist, the client home page shows those ads instead.

FILES REPLACED
--------------
lib/screens/admin_page.dart
lib/screens/client_home_page.dart
firestore.rules

FILES ADDED
-----------
lib/models/home_advertisement.dart
lib/services/home_advertisement_service.dart
SUPABASE_HOME_ADS_SETUP.sql

INSTALLATION
------------
1. Extract the ZIP.
2. Double-click INSTALL_HOME_ADS_UPDATE.bat.
3. Wait for flutter analyze.

The installer uses this project path:
C:\Users\mahir\Desktop\viyafaari_town

Backup is saved outside the Flutter project at:
C:\Users\mahir\Desktop\viyafaari_town_home_ads_backup

FIREBASE RULES
--------------
After installing, open:
C:\Users\mahir\Desktop\viyafaari_town\firestore.rules

Then Firebase Console:
Firestore Database -> Rules -> paste all -> Publish

SUPABASE SETUP
--------------
Open:
C:\Users\mahir\Desktop\viyafaari_town\SUPABASE_HOME_ADS_SETUP.sql

Then Supabase:
SQL Editor -> New query -> paste all -> Run

This allows image uploads to:
business-media/admin_ads/

REQUIRED PUBSPEC PACKAGES
-------------------------
Your project already needs these:

supabase_flutter: 2.14.2
image_picker:

Keep supabase_flutter locked to 2.14.2 because you previously had the Passkeys Web SDK problem with newer versions.

HOW TO USE
----------
1. Log in as admin.
2. Open Home Ads tab.
3. Click Add Home Advertisement.
4. Choose image.
5. Fill title and description.
6. Keep Show on Client Home Page enabled.
7. Create.
8. Log in as client and open the home page.

IMAGE RECOMMENDATION
--------------------
Use JPG, PNG, or WEBP.
Recommended banner ratio: 1200 x 500 or 1000 x 450.
Max size: 5 MB.
