VIYAFAARI TOWN — MARKETPLACE, PRODUCTS, SERVICES, BANK TRANSFER & STOCK UPDATE
================================================================================

WHAT THIS UPDATE ADDS
---------------------
CLIENT SIDE
1. Selecting an approved business opens a dedicated storefront.
2. Storefront design includes:
   - Business banner and logo
   - Search box
   - Category filters
   - Responsive item/service grid
   - Product and service images
   - Maldives currency price format: MVR 125.00
   - Available quantity or service slots
3. Selecting an item/service opens a full detail page.
4. The detail page shows:
   - Image
   - Name
   - Type
   - Category
   - Full description
   - Unit price
   - Quantity selector
   - Total amount
   - Buy button
5. The client sees the business bank-transfer account.
6. The client uploads the bank-transfer receipt.
7. The client can open My Orders to see:
   - Waiting for verification
   - Payment verified
   - Payment rejected and reason

BUSINESS LOGIN SIDE
1. Dashboard with:
   - Active catalog count
   - Low-stock count
   - Pending transfer count
   - Verified sales total
2. Catalog management:
   - Add product or service
   - Upload image
   - Category
   - MVR price
   - Quantity / available service slots
   - Full description
   - Edit item
   - Publish or hide item
3. Transfer verification:
   - View client details
   - View temporary signed receipt image
   - Verify payment
   - Reject payment and enter reason
4. Money-transfer account settings:
   - Bank name
   - Account holder name
   - Account number
   - Payment instructions
5. When the business verifies a transfer, a Firestore transaction:
   - Rechecks available stock
   - Prevents the same order from being verified twice
   - Reduces quantity automatically
   - Marks the order as verified

STORAGE
-------
Public product, service and business images:
  Supabase bucket: business-media

Private bank-transfer receipt images:
  Supabase bucket: payment-proofs

The receipt bucket is private. The business dashboard displays receipts using
temporary 10-minute signed URLs.

FILES INCLUDED
--------------
REPLACE:
  lib/models/business.dart
  lib/screens/business_portal_page.dart
  lib/screens/client_home_page.dart
  firestore.rules

ADD:
  lib/models/catalog_item.dart
  lib/models/purchase_order.dart
  lib/services/marketplace_service.dart
  lib/screens/add_catalog_item_page.dart
  lib/screens/business_payment_settings_page.dart
  lib/screens/business_storefront_page.dart
  lib/screens/client_orders_page.dart
  lib/screens/item_detail_page.dart
  lib/screens/payment_submission_page.dart
  SUPABASE_STORAGE_SETUP.sql

KEEP YOUR EXISTING FILES
------------------------
Do not replace:
  lib/main.dart
  lib/firebase_options.dart
  lib/services/auth_service.dart
  lib/services/business_service.dart
  lib/screens/admin_page.dart
  pubspec.yaml
  assets/fonts/Faruma.ttf

Your main.dart must already initialize Supabase with your real values:

await Supabase.initialize(
  url: 'YOUR_REAL_SUPABASE_URL',
  publishableKey: 'YOUR_REAL_SUPABASE_PUBLISHABLE_KEY',
);

Your Supabase import in main.dart can remain:

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

REQUIRED DEPENDENCIES
---------------------
Your existing pubspec.yaml must contain these packages:

firebase_core:
firebase_auth:
cloud_firestore:
supabase_flutter: 2.14.2
image_picker:
geolocator:

No new package is required for this marketplace update.

EASIEST INSTALLATION
--------------------
1. Back up your Flutter project.
2. Download and extract this ZIP.
3. Open the extracted folder.
4. Double-click INSTALL_MARKETPLACE_UPDATE.bat.
5. Wait for flutter analyze to finish.

The installer expects your project at:

C:\Users\mahir\Desktop\viyafaari_town

It backs up replaced files into:

C:\Users\mahir\Desktop\viyafaari_town\marketplace_update_backup

FIRESTORE SETUP
---------------
1. Open Firebase Console.
2. Open Firestore Database.
3. Open Rules.
4. Copy all content from the included firestore.rules.
5. Replace the current rules.
6. Click Publish.

SUPABASE SETUP
--------------
1. Open your Supabase project.
2. Open SQL Editor.
3. Open the included SUPABASE_STORAGE_SETUP.sql.
4. Copy all SQL.
5. Paste it into SQL Editor.
6. Press Run.

This creates/configures:
  business-media  — public image bucket
  payment-proofs  — private receipt bucket

TESTING WORKFLOW
----------------
A. BUSINESS
1. Log in with the approved business login.
2. Open Account.
3. Add the business bank name, account name and account number.
4. Open Catalog.
5. Add a product or service.
6. Enter image, category, MVR price, quantity and description.

B. CLIENT
1. Log in as a client.
2. Select the approved business.
3. Open an item/service.
4. Select quantity.
5. Press Buy.
6. Transfer money using the displayed account details.
7. Upload the receipt.
8. Submit it for verification.
9. Open the menu and select My Orders.

C. BUSINESS VERIFICATION
1. Log in with the business account.
2. Open Transfers.
3. Open the receipt.
4. Press Verify.
5. The catalog quantity decreases automatically.

IMPORTANT STOCK BEHAVIOUR
-------------------------
Stock is not reduced when a client uploads a receipt.
Stock is reduced only after the business verifies the payment.

If several clients submit receipts for the final item, the verification
transaction allows only orders that still have enough stock. A later order
must be rejected when stock is no longer sufficient.

SECURITY NOTE
-------------
The app currently uses Firebase Authentication while Supabase is used only for
storage. Supabase therefore sees Flutter uploads as the publishable/anonymous
role. The payment-proofs bucket is private and receipt paths are protected in
Firestore, but a production payment system should use a trusted backend or
Supabase Edge Function that verifies the Firebase ID token before creating
receipt upload/read permissions.

This update is suitable for building and testing the requested workflow. Do not
treat manual receipt verification as the same as direct bank API verification.
