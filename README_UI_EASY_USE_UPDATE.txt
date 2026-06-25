Viyafaari Town UI + Easy Use Update
===================================

Added in this version:

1. Client bottom navigation
   - Home
   - Categories
   - Orders
   - Messages
   - Profile

2. Better home page
   - Quick action buttons
   - Nearby shops shortcut
   - Today offers shortcut
   - Quotation shortcut
   - Category preview with icons

3. Category icon grid
   - Product categories
   - Service categories
   - Tapping a category opens matching search on the home page

4. Better shop cards
   - Shop image/logo
   - Verified badge
   - Open/closed status
   - Delivery/pickup badge
   - Distance badge when location is available
   - Favorite heart button

5. Profile tab
   - User details
   - Favorite shops
   - Recently viewed shops
   - Settings and Add Business shortcuts

6. Opening hours
   - Business seller can edit opening hours from Business Portal -> Account
   - Seller can set open/closed days
   - Seller can set opening and closing times
   - Seller can mark shop temporarily closed
   - Client sees Open now / Closed status on home, shop and item pages

7. Better promotion display
   - Sale badge can show percentage off when old price is higher than new price
   - Item detail and shop grid show better sale presentation

Important after replacing project:

flutter clean
flutter pub get
flutter run

Deploy Firestore rules because opening hours update needs new rule permission:

firebase.cmd deploy --only "firestore:rules" --project viyafaari-town

