VIYAFAARI TOWN - COMPLETE FIREBASE CLIENT AND ADMIN UPDATE
==========================================================

IMPORTANT
---------
This package intentionally DOES NOT include lib/firebase_options.dart.
Keep the firebase_options.dart generated for your own Firebase project by:

  flutterfire configure

Do not replace that file with another project's Firebase settings.

WHAT THIS UPDATE INCLUDES
-------------------------
1. Firebase email/password authentication.
2. Login with email OR username.
3. Firestore client profiles with client/admin roles.
4. Client registration fields:
   - Full name
   - Username
   - Maldives phone number
   - Email
   - Password
5. Business submission with status = pending.
6. Business logo/image upload to Firebase Storage.
7. Search and autocomplete for approved businesses.
8. Nearby-business detection using GPS coordinates.
9. Client submission-status page (pending/approved/rejected).
10. Admin-only dashboard with:
    - Registered client count
    - All business count
    - Pending count
    - Active/approved count
    - Rejected count
    - Full client list
    - Full business details
    - Approve and reject controls
    - Advertisement request approval
11. English/Dhivehi and Faruma font support.
12. Light and dark mode.

COPY THE FILES
--------------
1. Back up your current project first.
2. Copy this package's lib folder into your Flutter project.
3. KEEP your existing:

   lib/firebase_options.dart

4. Replace your project's pubspec.yaml with the included pubspec.yaml.
5. Confirm this font exists:

   assets/fonts/Faruma.ttf

6. Keep the platform configuration files created by flutterfire configure,
   such as google-services.json and GoogleService-Info.plist.

FIREBASE CONSOLE SETTINGS
-------------------------
Authentication:
- Firebase Console > Authentication > Sign-in method
- Enable Email/Password.

Firestore:
- Firebase Console > Firestore Database > Rules
- Replace the rules with firestore.rules from this package.
- Click Publish.

Storage:
- Firebase Console > Storage > Rules
- Replace the rules with storage.rules from this package.
- Click Publish.

PLATFORM PERMISSIONS
--------------------
Follow ANDROID_SETUP.txt and IOS_SETUP.txt when using those platforms.

RUN THE PROJECT
---------------
From the project root:

  flutter clean
  flutter pub get
  flutter analyze
  flutter run

CREATE YOUR FIRST ADMIN
-----------------------
1. Register your own account through the app normally.
2. Firebase Console > Firestore Database > Data.
3. Open the users collection.
4. Open your own user document (document ID is the Firebase UID).
5. Change:

   role: client

   to:

   role: admin

6. Log out and log in again.
7. The app will now open the Admin Dashboard for that account.

Never place an Admin option on the public registration page.

BUSINESS APPROVAL FLOW
----------------------
Client submits business
       |
       v
Firestore stores status = pending
       |
       v
Admin Dashboard shows the request
       |
       +--> Approve --> status = approved --> shop appears on client Home/Search
       |
       +--> Reject  --> status = rejected --> client sees reason in Inform Me

IMPORTANT ABOUT NEARBY SEARCH
-----------------------------
Accurate distance requires the business owner to tap "Add Exact GPS Location"
when submitting the business. Businesses without latitude/longitude remain
searchable by name, category and island, but cannot be accurately sorted by
distance.

EXISTING LOCAL ACCOUNTS
-----------------------
Accounts created by the earlier temporary in-memory login code are not Firebase
accounts. Those users must register again after installing this Firebase update.
