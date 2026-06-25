Viyafaari Town - Seller Item Management Update

Added for seller:

1. Delete old item/service
   - Business portal -> Catalog tab -> 3-dot menu -> Delete item.
   - This is a safe delete: the item is removed from seller/client lists, but old orders and quotations remain safe.

2. Mark out of stock
   - Business portal -> Catalog tab -> 3-dot menu -> Mark out of stock.
   - Quantity becomes 0.
   - Client shop page can show the item as Out of stock and client cannot buy/request it.

3. Hide/Publish item
   - Business portal -> Catalog tab -> 3-dot menu -> Hide from clients / Publish to clients.

4. Add or edit sale promotion
   - Business portal -> Catalog tab -> 3-dot menu -> Add sale / discount.
   - Enable Sale promotion, enter old price and new price.
   - Client sees old price with red crossed line and new price.

5. Add or edit bulk discount
   - Business portal -> Catalog tab -> 3-dot menu -> Add sale / discount.
   - Enter minimum quantity, discount amount, and/or discount percentage.
   - Example: minimum quantity 10, discount amount MVR 5, discount percentage 5%.

Run after replacing project:

flutter clean
flutter pub get
flutter analyze
flutter run

Firestore rules:
No new collection was added. This update uses existing catalog_items update permission.
If your deployed rules are not the latest safe rules, deploy again:

firebase deploy --only firestore:rules --project viyafaari-town
