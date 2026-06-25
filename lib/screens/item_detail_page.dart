import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/catalog_item.dart';
import 'chat_page.dart';
import 'payment_submission_page.dart';
import '../services/marketplace_service.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({
    super.key,
    required this.client,
    required this.business,
    required this.item,
    required this.isDhivehi,
  });

  final AppUser client;
  final Business business;
  final CatalogItem item;
  final bool isDhivehi;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  int _quantity = 1;

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  void _increase() {
    if (_quantity >= widget.item.quantity) return;
    setState(() => _quantity++);
  }

  void _decrease() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          currentUser: widget.client,
          business: widget.business,
          item: widget.item,
          isDhivehi: widget.isDhivehi,
        ),
      ),
    );
  }

  void _buy() {
    if (!widget.business.hasPaymentAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text(
            text(
              'This business has not added money transfer details yet.',
              'މި ވިޔަފާރިން ފައިސާ ޓްރާންސްފަރ މަޢުލޫމާތު އަދި ނުލައެވެ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSubmissionPage(
          client: widget.client,
          business: widget.business,
          item: widget.item,
          quantity: _quantity,
          isDhivehi: widget.isDhivehi,
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    try {
      await MarketplaceService.instance.addProductToCart(
        client: widget.client,
        business: widget.business,
        item: widget.item,
        quantity: _quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text('Added to cart.', 'ކާޓަށް އިތުރުވެއްޖެ.'),
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
            style: style(color: Colors.white),
          ),
        ),
      );
    }
  }


  Widget _priceBlock(CatalogItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.hasPromotion) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.oldPriceText,
                style: style(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ).copyWith(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.red,
                  decorationThickness: 2.4,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  widget.isDhivehi ? 'ސޭލް' : item.promotionBadgeText,
                  style: style(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Text(
          item.priceText,
          style: style(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (item.hasBulkDiscount) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: Text(
              item.bulkDiscountText,
              style: style(
                fontWeight: FontWeight.w900,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final total = item.lineTotalForQuantity(_quantity);

    return Directionality(
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              SizedBox(
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_rounded),
                  label: Text(
                    text('Chat', 'ޗެޓް'),
                    style: style(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (item.isProduct) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 58,
                  child: OutlinedButton.icon(
                    onPressed: item.isAvailable ? _addToCart : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(
                      text('Cart', 'ކާޓް'),
                      style: style(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: item.isAvailable ? _buy : null,
                    icon: const Icon(Icons.shopping_bag_rounded),
                    label: Text(
                      item.isAvailable
                          ? '${text('Buy', 'ގަނޭ')} • MVR ${total.toStringAsFixed(2)}'
                          : text('Out of stock', 'ސްޓޮކް ނެތް'),
                      style: style(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        item.isService
                            ? Icons.design_services_rounded
                            : Icons.inventory_2_rounded,
                        size: 90,
                      ),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.broken_image_rounded, size: 70),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(
                          item.isService
                              ? Icons.design_services_rounded
                              : Icons.inventory_2_rounded,
                          size: 18,
                        ),
                        label: Text(
                          item.isService
                              ? text('Service', 'ޚިދުމަތް')
                              : text('Product', 'މުދާ'),
                          style: style(),
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.category_rounded, size: 18),
                        label: Text(item.category, style: style()),
                      ),
                      Chip(
                        avatar: Icon(
                          widget.business.openStatus(DateTime.now()).isOpen
                              ? Icons.schedule_rounded
                              : Icons.pause_circle_rounded,
                          size: 18,
                        ),
                        label: Text(
                          widget.business
                              .openStatus(DateTime.now())
                              .label(isDhivehi: widget.isDhivehi),
                          style: style(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    item.name,
                    style: style(fontSize: 29, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  _priceBlock(item),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 19),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          widget.business.businessName,
                          style: style(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 34),
                  Text(
                    text('Description', 'ތަފްޞީލު'),
                    style: style(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(item.description, style: style(fontSize: 16, height: 1.6)),
                  const Divider(height: 34),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.isService
                                  ? text('Available slots', 'ލިބެން ހުރި ޖާގަ')
                                  : text('Available quantity', 'ލިބެން ހުރި ޢަދަދު'),
                              style: style(fontSize: 13),
                            ),
                            Text(
                              item.quantity.toString(),
                              style: style(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.isAvailable)
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _quantity > 1 ? _decrease : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Text(
                                _quantity.toString(),
                                style: style(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    _quantity < item.quantity ? _increase : null,
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
