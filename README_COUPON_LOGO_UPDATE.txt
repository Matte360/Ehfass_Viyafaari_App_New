Viyafaari Town - Coupon + Logo Update

Added:
1. Seller coupon settings
   Business Portal -> Account -> Coupon Offer -> Edit Coupon Offer
   Seller can enable coupons, set minimum purchase amount, reward amount, title and terms.

2. Client coupon generation
   Client Orders page shows Generate Coupon after seller verifies an eligible order.
   One coupon can be generated per order. After generating, the generate option is disabled.

3. Seller coupon list
   Business Portal -> Account -> Coupon Offer -> View Client Coupons
   Seller can see coupon code, client name, order item, purchase total and reward.

4. Coupon image save/download
   After client generates coupon, app creates a coupon PNG image.
   On web it downloads the PNG.
   On Android it tries to save under Pictures/ViyafaariTown; if blocked, it saves to app temp memory.

5. Logo update
   Uploaded EHFASS Viyafaari logo added at assets/images/ehfassviyafaari_logo.png.
   Login, register and home header now use logo instead of text title.

Important:
Deploy Firestore rules after replacing project:
firebase.cmd deploy --only "firestore:rules" --project viyafaari-town

Then run:
flutter clean
flutter pub get
flutter run
