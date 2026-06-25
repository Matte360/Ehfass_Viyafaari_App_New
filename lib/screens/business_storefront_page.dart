import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/catalog_item.dart';
import '../models/review.dart';
import '../services/marketplace_service.dart';
import 'chat_page.dart';
import 'item_detail_page.dart';

class BusinessStorefrontPage extends StatefulWidget {
  const BusinessStorefrontPage({
    super.key,
    required this.client,
    required this.business,
    required this.isDhivehi,
    this.distanceKm,
  });

  final AppUser client;
  final Business business;
  final bool isDhivehi;
  final double? distanceKm;

  @override
  State<BusinessStorefrontPage> createState() =>
      _BusinessStorefrontPageState();
}

class _BusinessStorefrontPageState extends State<BusinessStorefrontPage> {
  final _searchController = TextEditingController();
  final Map<String, _QuoteSelection> _quoteSelections = {};
  String _selectedCategory = 'All';
  bool _requestingQuote = false;

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

  int get _selectedItemCount => _quoteSelections.length;

  int get _selectedQuantity => _quoteSelections.values.fold<int>(
        0,
        (total, selection) => total + selection.quantity,
      );

  double get _selectedTotal => _quoteSelections.values.fold<double>(
        0,
        (total, selection) =>
            total + selection.item.lineTotalForQuantity(selection.quantity),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CatalogItem> _filter(List<CatalogItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      final categoryMatches =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final queryMatches = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return categoryMatches && queryMatches;
    }).toList();
  }

  void _openItem(CatalogItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(
          client: widget.client,
          business: widget.business,
          item: item,
          isDhivehi: widget.isDhivehi,
        ),
      ),
    );
  }

  void _openChat({CatalogItem? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          currentUser: widget.client,
          business: widget.business,
          item: item,
          isDhivehi: widget.isDhivehi,
        ),
      ),
    );
  }

  void _toggleQuoteSelection(CatalogItem item, bool selected) {
    setState(() {
      if (selected) {
        _quoteSelections[item.id] = _QuoteSelection(item: item, quantity: 1);
      } else {
        _quoteSelections.remove(item.id);
      }
    });
  }

  void _increaseQuoteQuantity(CatalogItem item) {
    final selection = _quoteSelections[item.id];
    if (selection == null || selection.quantity >= item.quantity) return;
    setState(() {
      _quoteSelections[item.id] = selection.copyWith(
        quantity: selection.quantity + 1,
      );
    });
  }

  void _decreaseQuoteQuantity(CatalogItem item) {
    final selection = _quoteSelections[item.id];
    if (selection == null) return;
    if (selection.quantity <= 1) {
      _toggleQuoteSelection(item, false);
      return;
    }
    setState(() {
      _quoteSelections[item.id] = selection.copyWith(
        quantity: selection.quantity - 1,
      );
    });
  }

  Future<void> _openMap() async {
    final business = widget.business;
    Uri uri;

    if (business.mapUrl.trim().isNotEmpty) {
      uri = Uri.tryParse(business.mapUrl.trim()) ?? Uri.parse('https://www.google.com/maps');
    } else {
      final query = business.latitude != null && business.longitude != null
          ? '${business.latitude},${business.longitude}'
          : '${business.businessName}, ${business.island}, Maldives';
      uri = Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': query},
      );
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showError(text(
        'Could not open the map on this device.',
        'މި ޑިވައިސްގައި މެޕް ނުހުޅުނު.',
      ));
    }
  }

  Future<void> _showDeliveryDetails() async {
    final business = widget.business;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Directionality(
        textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    business.deliveryAvailable
                        ? Icons.delivery_dining_rounded
                        : Icons.storefront_rounded,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      business.deliveryAvailable
                          ? text('Delivery Details', 'ޑެލިވަރީ ތަފްޞީލު')
                          : text('Pickup Details', 'ޕިކްއަޕް ތަފްޞީލު'),
                      style: style(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                business.deliveryAvailable
                    ? (business.deliveryDetails.trim().isEmpty
                        ? text(
                            'This shop offers delivery, but detailed delivery information has not been added yet.',
                            'މި ފިހާރައިން ޑެލިވަރީ ދެއެވެ، އެކަމަކު ތަފްޞީލު އަދި ނުލައެވެ.',
                          )
                        : business.deliveryDetails)
                    : text(
                        'This shop is marked as pickup only.',
                        'މި ފިހާރަ ޕިކްއަޕް އެކަނި ކަމަށް ލައެވިފައިވެއެވެ.',
                      ),
                style: style(fontSize: 16, height: 1.55),
              ),
              const SizedBox(height: 14),
              _deliveryRow(Icons.location_on_rounded, business.island),
              _deliveryRow(Icons.phone_rounded, business.contactNumber),
              if (business.email.trim().isNotEmpty)
                _deliveryRow(Icons.email_rounded, business.email),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openMap();
                },
                icon: const Icon(Icons.map_rounded),
                label: Text(text('Open Location', 'ލޮކޭޝަން ހުޅުވާ'), style: style()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deliveryRow(IconData icon, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 9),
          Expanded(child: SelectableText(value, style: style())),
        ],
      ),
    );
  }

  Future<void> _requestQuotation() async {
    if (_quoteSelections.isEmpty || _requestingQuote) return;

    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          text('Request Quotation', 'ކޯޓޭޝަން ރިކުއެސްޓް'),
          style: style(fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text(
                    'Selected items and quantities',
                    'ހޮވިފައިވާ މުދާ އަދި ޢަދަދު',
                  ),
                  style: style(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._quoteSelections.values.map((selection) {
                  final item = selection.item;
                  final total = item.lineTotalForQuantity(selection.quantity);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} × ${selection.quantity}',
                            style: style(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          'MVR ${total.toStringAsFixed(2)}',
                          style: style(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        text('Approximate total', 'ލަފާ ޖުމްލަ'),
                        style: style(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'MVR ${_selectedTotal.toStringAsFixed(2)}',
                      style: style(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: text('Message to seller', 'ސެލަރަށް މެސެޖް'),
                    hintText: text(
                      'Example: Need delivery price and final quotation.',
                      'މިސާލު: ޑެލިވަރީ އަގާއި ފައިނަލް ކޯޓޭޝަން ބޭނުން.',
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.send_rounded),
            label: Text(text('Send Request', 'ރިކުއެސްޓް ފޮނުވާ'), style: style()),
          ),
        ],
      ),
    );

    if (confirm != true) {
      noteController.dispose();
      return;
    }

    setState(() => _requestingQuote = true);
    try {
      final selections = <CatalogItem, int>{
        for (final selection in _quoteSelections.values)
          selection.item: selection.quantity,
      };
      await MarketplaceService.instance.createQuotationRequest(
        client: widget.client,
        business: widget.business,
        selections: selections,
        note: noteController.text,
      );
      noteController.dispose();
      if (!mounted) return;
      setState(() => _quoteSelections.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text(
              'Quotation request sent to the seller.',
              'ކޯޓޭޝަން ރިކުއެސްޓް ސެލަރަށް ފޮނުވިއްޖެ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      noteController.dispose();
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _requestingQuote = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
        content: Text(message, style: style(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;

    return Directionality(
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            business.businessName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar:
            _quoteSelections.isEmpty ? null : _quotationBottomBar(),
        body: StreamBuilder<List<CatalogItem>>(
          stream: MarketplaceService.instance.watchPublicCatalog(business.id),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <CatalogItem>[];
            final categories = items
                .map((item) => item.category)
                .where((category) => category.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final filtered = _filter(items);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _reviewsSection()),
                SliverToBoxAdapter(child: _search()),
                SliverToBoxAdapter(child: _categories(categories)),
                SliverToBoxAdapter(child: _sectionHeader(filtered.length)),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(snapshot.error.toString()),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 70),
                            const SizedBox(height: 12),
                            Text(
                              text(
                                'No matching items or services are available.',
                                'ގުޅޭ މުދަލެއް ނުވަތަ ޚިދުމަތެއް ނުފެނުނު.',
                              ),
                              textAlign: TextAlign.center,
                              style: style(fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final columns = width >= 1100
                            ? 5
                            : width >= 780
                                ? 4
                                : width >= 520
                                    ? 3
                                    : 2;

                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                            childAspectRatio: width >= 780 ? 0.62 : 0.48,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _itemCard(filtered[index]),
                            childCount: filtered.length,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _quotationBottomBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text('Quotation selected', 'ކޯޓޭޝަން ހޮވިފައި'),
                      style: style(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '$_selectedItemCount ${text('item(s)', 'އައިޓަމް')} • $_selectedQuantity ${text('qty', 'ޢަދަދު')} • MVR ${_selectedTotal.toStringAsFixed(2)}',
                      style: style(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _requestingQuote ? null : _requestQuotation,
                icon: _requestingQuote
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.request_quote_rounded),
                label: Text(text('Request', 'ރިކުއެސްޓް'), style: style()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final business = widget.business;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                business.businessName,
                style: style(
                  fontSize: compact ? 27 : 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                business.description,
                maxLines: compact ? 3 : 4,
                overflow: TextOverflow.ellipsis,
                style: style(color: Colors.white, height: 1.45),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _heroChip(Icons.verified_rounded, business.trustBadgeText),
                  if (business.isFeatured)
                    _heroChip(
                      business.isSponsored
                          ? Icons.campaign_rounded
                          : Icons.star_rounded,
                      business.promotionBadgeText,
                    ),
                  _heroChip(Icons.category_rounded, business.category),
                  _heroChip(
                    business.openStatus(DateTime.now()).isOpen
                        ? Icons.schedule_rounded
                        : Icons.pause_circle_rounded,
                    business.openStatus(DateTime.now()).label(isDhivehi: widget.isDhivehi),
                  ),
                  _heroChip(
                    Icons.location_on_rounded,
                    business.island,
                    onTap: _openMap,
                  ),
                  _heroChip(
                    Icons.map_rounded,
                    text('Location', 'ލޮކޭޝަން'),
                    onTap: _openMap,
                  ),
                  if (widget.distanceKm != null)
                    _heroChip(
                      Icons.near_me_rounded,
                      '${widget.distanceKm!.toStringAsFixed(1)} km',
                    ),
                  _heroChip(
                    Icons.delivery_dining_rounded,
                    business.deliveryAvailable
                        ? text('Delivery', 'ޑެލިވަރީ')
                        : text('Pickup', 'ޕިކްއަޕް'),
                    onTap: _showDeliveryDetails,
                  ),
                  _heroChip(
                    Icons.chat_rounded,
                    text('Chat Seller', 'ސެލަރާ ޗެޓް'),
                    onTap: () => _openChat(),
                  ),
                ],
              ),
            ],
          );

          final logo = Container(
            width: compact ? 105 : 170,
            height: compact ? 105 : 170,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: business.logoUrl.isEmpty
                ? const Icon(
                    Icons.storefront_rounded,
                    size: 75,
                    color: Colors.white,
                  )
                : Image.network(
                    business.logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [logo, const SizedBox(height: 18), details],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 24),
              logo,
            ],
          );
        },
      ),
    );
  }

  Widget _heroChip(IconData icon, String label, {VoidCallback? onTap}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: onTap == null ? 0.17 : 0.24),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: style(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: chip,
    );
  }

  Widget _reviewsSection() {
    return StreamBuilder<List<BusinessReview>>(
      stream: MarketplaceService.instance.watchBusinessReviews(widget.business.id),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <BusinessReview>[];
        final reviewCount = reviews.length;
        final totalRating = reviews.fold<double>(
          0,
          (total, review) => total + review.rating.toDouble(),
        );
        final average = reviewCount == 0 ? 0.0 : totalRating / reviewCount;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber.shade700,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text('Reviews & Ratings', 'ރިވިއު އަދި ރޭޓިން'),
                        style: style(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      reviewCount == 0
                          ? text('No rating', 'ރޭޓިން ނެތް')
                          : '${average.toStringAsFixed(1)} ★ ($reviewCount)',
                      style: style(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                if (snapshot.connectionState == ConnectionState.waiting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ] else if (snapshot.hasError) ...[
                  const SizedBox(height: 10),
                  Text(
                    text(
                      'Reviews could not be loaded now.',
                      'ރިވިއުތައް މިހާރު ލޯޑް ނުކުރެވުނު.',
                    ),
                    style: style(color: Colors.red, fontWeight: FontWeight.w700),
                  ),
                ] else if (reviews.isEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    text(
                      'No customer reviews yet. Reviews will show here after verified orders.',
                      'އަދި ކަސްޓަމަރ ރިވިއު ނެތް. ވެރިފައިޑް އޯޑަރުތަކަށް ފަހު ރިވިއުތައް މިތާ ފެނޭނެ.',
                    ),
                    style: style(height: 1.4),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  ...reviews.take(3).map(_reviewTile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reviewTile(BusinessReview review) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.clientName.isEmpty
                      ? text('Customer', 'ކަސްޓަމަރ')
                      : review.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(fontWeight: FontWeight.w900),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 17,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: style(height: 1.4),
            ),
          ],
          const Divider(height: 18),
        ],
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: text(
            'Search items and services',
            'މުދަލާއި ޚިދުމަތްތައް ހޯދާ',
          ),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }

  Widget _categories(List<String> categories) {
    return SizedBox(
      height: 58,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip('All', text('All', 'ހުރިހާ')),
          ...categories.map((category) => _categoryChip(category, category)),
        ],
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        type: MaterialType.transparency,
        child: ChoiceChip(
          selected: selected,
          onSelected: (_) => setState(() => _selectedCategory = value),
          avatar: selected ? const Icon(Icons.check_rounded, size: 17) : null,
          label: Text(label, style: style(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _sectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 8, 17, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text('Items & Services', 'މުދާ އަދި ޚިދުމަތް'),
              style: style(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          Text('$count', style: style(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  Widget _priceBlock(CatalogItem item, {bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.hasPromotion) ...[
          Text(
            item.oldPriceText,
            style: style(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ).copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.red,
              decorationThickness: 2.2,
            ),
          ),
          const SizedBox(height: 1),
        ],
        Text(
          item.priceText,
          style: style(
            fontSize: compact ? 16 : 25,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (item.hasBulkDiscount) ...[
          const SizedBox(height: 2),
          Text(
            item.bulkDiscountText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _itemCard(CatalogItem item) {
    final selected = _quoteSelections.containsKey(item.id);
    final selectedQuantity = _quoteSelections[item.id]?.quantity ?? 1;
    final canSelect = item.isAvailable;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openItem(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl.isEmpty
                      ? Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            item.isService
                                ? Icons.design_services_rounded
                                : Icons.inventory_2_rounded,
                            size: 55,
                          ),
                        )
                      : Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.broken_image_rounded),
                          ),
                        ),
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.isService
                            ? text('Service', 'ޚިދުމަތް')
                            : text('Product', 'މުދާ'),
                        style: style(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (item.hasPromotion)
                    PositionedDirectional(
                      bottom: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.isDhivehi ? 'ސޭލް' : item.promotionBadgeText,
                          style: style(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: 5,
                    end: 5,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.86),
                      shape: const CircleBorder(),
                      child: Checkbox(
                        value: selected,
                        onChanged: canSelect
                            ? (value) => _toggleQuoteSelection(
                                  item,
                                  value == true,
                                )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  _priceBlock(item, compact: true),
                  const SizedBox(height: 4),
                  Text(
                    item.quantity > 0
                        ? '${text('Available', 'ލިބެން ހުރޭ')}: ${item.quantity}'
                        : text('Out of stock', 'ސްޓޮކް ނެތް'),
                    maxLines: 1,
                    style: style(
                      fontSize: 11,
                      color: item.quantity > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(item: item),
                      icon: const Icon(Icons.chat_rounded, size: 15),
                      label: Text(
                        text('Chat', 'ޗެޓް'),
                        style: style(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (selected)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _decreaseQuoteQuantity(item),
                            borderRadius: BorderRadius.circular(30),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.remove_rounded, size: 18),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Text(
                              selectedQuantity.toString(),
                              style: style(fontWeight: FontWeight.w900),
                            ),
                          ),
                          InkWell(
                            onTap: selectedQuantity < item.quantity
                                ? () => _increaseQuoteQuantity(item)
                                : null,
                            borderRadius: BorderRadius.circular(30),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.add_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      text('Tick for quotation', 'ކޯޓޭޝަނަށް ޓިކްކުރޭ'),
                      style: style(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: canSelect
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
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

class _QuoteSelection {
  const _QuoteSelection({required this.item, required this.quantity});

  final CatalogItem item;
  final int quantity;

  _QuoteSelection copyWith({int? quantity}) {
    return _QuoteSelection(
      item: item,
      quantity: quantity ?? this.quantity,
    );
  }
}
