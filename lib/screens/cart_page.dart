import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/cart_item.dart';
import '../services/business_service.dart';
import '../services/marketplace_service.dart';
import 'payment_submission_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
    required this.client,
    required this.isDhivehi,
  });

  final AppUser client;
  final bool isDhivehi;

  String text(String english, String dhivehi) => isDhivehi ? dhivehi : english;

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('My Cart', 'މަގޭ ކާޓް'),
            style: style(fontWeight: FontWeight.w900),
          ),
        ),
        body: StreamBuilder<List<CartItem>>(
          stream: MarketplaceService.instance.watchCartForClient(client.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString(), style: style()));
            }
            final cartItems = snapshot.data ?? const <CartItem>[];
            if (cartItems.isEmpty) return _empty(context);

            final total = cartItems.fold<double>(
              0,
              (sum, item) => sum + item.lineTotal,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _summaryCard(context, cartItems.length, total),
                const SizedBox(height: 12),
                ...cartItems.map((cartItem) => _CartItemCard(
                      cartItem: cartItem,
                      client: client,
                      isDhivehi: isDhivehi,
                      text: text,
                      style: style,
                    )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, int itemCount, double total) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.shopping_cart_checkout_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text('$itemCount product(s) in cart', '$itemCount މުދާ ކާޓްގައި'),
                    style: style(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    text(
                      'Pay each seller separately after opening the item checkout.',
                      'އެކި ސެލަރުންނަށް އެ ޗެކްއައުޓްގައި ވަކިން ފައިސާ ދޭ.',
                    ),
                    style: style(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              'MVR ${total.toStringAsFixed(2)}',
              style: style(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 78,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              text('Your cart is empty', 'ތިޔަ ކާޓް ހުސް'),
              style: style(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              text(
                'Open any product and tap Add to Cart.',
                'މުދަލެއް ހުޅުވާލައި Add to Cart ފިތާލާ.',
              ),
              textAlign: TextAlign.center,
              style: style(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  const _CartItemCard({
    required this.cartItem,
    required this.client,
    required this.isDhivehi,
    required this.text,
    required this.style,
  });

  final CartItem cartItem;
  final AppUser client;
  final bool isDhivehi;
  final String Function(String english, String dhivehi) text;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) style;

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _working = false;

  Future<void> _changeQuantity(int newQuantity) async {
    setState(() => _working = true);
    try {
      await MarketplaceService.instance.updateCartItemQuantity(
        cartItem: widget.cartItem,
        quantity: newQuantity,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
            style: widget.style(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _remove() => _changeQuantity(0);

  Future<void> _checkout(Business business) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSubmissionPage(
          client: widget.client,
          business: business,
          item: widget.cartItem.toCatalogItem(),
          quantity: widget.cartItem.quantity,
          isDhivehi: widget.isDhivehi,
        ),
      ),
    );
    if (result == true) {
      await _remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.cartItem;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: item.itemImageUrl.isEmpty
                        ? Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.inventory_2_rounded),
                          )
                        : Image.network(
                            item.itemImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded),
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: widget.style(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(item.businessName, style: widget.style(fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 7,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.hasPromotion)
                            Text(
                              item.oldPriceText,
                              style: widget.style(
                                color: Colors.red,
                                fontWeight: FontWeight.w800,
                              ).copyWith(
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.red,
                                decorationThickness: 2,
                              ),
                            ),
                          Text(
                            item.unitPriceText,
                            style: widget.style(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (item.lineDiscount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '- MVR ${item.lineDiscount.toStringAsFixed(2)} ${widget.text('discount', 'ޑިސްކައުންޓް')}',
                          style: widget.style(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: widget.text('Remove', 'ފުހެލާ'),
                  onPressed: _working ? null : _remove,
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _working || item.quantity <= 1
                            ? null
                            : () => _changeQuantity(item.quantity - 1),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text(
                        item.quantity.toString(),
                        style: widget.style(fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        onPressed: _working || item.quantity >= item.availableQuantity
                            ? null
                            : () => _changeQuantity(item.quantity + 1),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.subtotalText,
                    style: widget.style(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                StreamBuilder<Business?>(
                  stream: BusinessService.instance.watchBusiness(item.businessId),
                  builder: (context, snapshot) {
                    final business = snapshot.data;
                    return FilledButton.icon(
                      onPressed: _working || business == null || !item.isAvailable
                          ? null
                          : () => _checkout(business),
                      icon: const Icon(Icons.payment_rounded),
                      label: Text(
                        widget.text('Checkout', 'ޗެކްއައުޓް'),
                        style: widget.style(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
