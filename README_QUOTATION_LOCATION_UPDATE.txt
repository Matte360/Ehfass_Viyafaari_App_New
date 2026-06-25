Viyafaari Town update: storefront location, delivery details, and quotation requests

Added features
--------------
1. Storefront location action
   - The business island/location chip is now tappable.
   - A new Location button was added in the business header.
   - It opens Google Maps using business latitude/longitude when available.
   - If coordinates are missing, it searches by business name + island + Maldives.

2. Delivery detail action
   - The Delivery/Pickup chip is now tappable.
   - It opens a bottom sheet with delivery details, island, phone, email, and an Open Location button.

3. Client quotation request
   - On the business storefront page, clients can tick multiple items/services.
   - After ticking, the client can increase/decrease quantity.
   - A bottom quotation bar appears.
   - Client can send a quotation request with an optional note to the seller.

4. Seller quotation management
   - Business portal now has a new Quotes tab.
   - Seller can see quotation requests from clients.
   - Seller can generate a quotation using the same shop name.
   - Seller can add delivery fee, discount, seller note, and optionally upload a quotation image.
   - Seller can also reject a quotation request with a reason.

5. Client quotation tracking
   - My Orders page now has two tabs: Orders and Quotations.
   - Client can see pending, quoted, or rejected quotation requests.
   - Client can view uploaded quotation image from seller.

Files changed / added
---------------------
Added:
- lib/models/quotation_request.dart
- lib/screens/quotation_requests_page.dart
- README_QUOTATION_LOCATION_UPDATE.txt

Changed:
- pubspec.yaml
- firestore.rules
- lib/services/marketplace_service.dart
- lib/screens/business_storefront_page.dart
- lib/screens/business_portal_page.dart
- lib/screens/client_orders_page.dart

Important commands
------------------
After replacing files, run:

flutter pub get
flutter analyze
flutter run

Firebase rules
--------------
Deploy updated Firestore rules:

firebase deploy --only firestore:rules

New package
-----------
This update added url_launcher for opening map location:

url_launcher: ^6.3.1

Supabase
--------
Quotation image uploads use the existing public business-media bucket.
Path format:
quotations/{businessId}/{quotationRequestId}.jpg/png/webp
