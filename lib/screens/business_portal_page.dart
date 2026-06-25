import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/catalog_item.dart';
import '../models/purchase_order.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../services/marketplace_service.dart';
import 'add_catalog_item_page.dart';
import 'business_payment_settings_page.dart';
import 'business_location_settings_page.dart';
import 'business_hours_settings_page.dart';
import 'business_coupons_page.dart';
import 'business_coupon_settings_page.dart';
import 'business_promotion_request_page.dart';
import 'chat_list_page.dart';
import 'quotation_requests_page.dart';
import 'seller_sales_report_page.dart';
import 'notification_center_page.dart';
import '../widgets/notification_bell.dart';
import '../widgets/compact_app_icon_button.dart';

class BusinessPortalPage extends StatefulWidget {
  const BusinessPortalPage({
    super.key,
    required this.businessUser,
    required this.isDhivehi,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final AppUser businessUser;
  final bool isDhivehi;
  final bool isDarkMode;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<BusinessPortalPage> createState() => _BusinessPortalPageState();
}

class _BusinessPortalPageState extends State<BusinessPortalPage> {
  int _pageIndex = 0;

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


  void _openBusinessNotifications(Business business) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text('Notifications', 'ނޮޓިފިކޭޝަން'),
                style: style(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              StreamBuilder<int>(
                stream: MarketplaceService.instance
                    .watchBusinessNotificationCount(business.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return ListTile(
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: Text(
                      count == 0
                          ? text('No pending notifications', 'ޕެންޑިންގް ނޮޓިފިކޭޝަނެއް ނެތް')
                          : text('$count pending notification(s)', '$count ޕެންޑިންގް ނޮޓިފިކޭޝަން'),
                      style: style(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      text(
                        'Includes transfer verification, quotation requests and unread messages.',
                        'ޓްރާންސްފަރ ވެރިފިކޭޝަން، ކޯޓޭޝަން ރިކުއެސްޓް، އަދި ނުކިޔާ މެސެޖްތައް ހިމެނޭ.',
                      ),
                      style: style(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications_rounded),
                title: Text(text('Open notification center', 'ނޮޓިފިކޭޝަން ސެންޓަރ ހުޅުވާ'), style: style()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationCenterPage(
                        currentUser: widget.businessUser,
                        business: business,
                        isDhivehi: widget.isDhivehi,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text(text('Pending transfers', 'ޕެންޑިންގް ޓްރާންސްފަރ'), style: style()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _pageIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.request_quote_rounded),
                title: Text(text('Quotation requests', 'ކޯޓޭޝަން ރިކުއެސްޓް'), style: style()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _pageIndex = 3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_rounded),
                title: Text(text('Messages', 'މެސެޖްތައް'), style: style()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _pageIndex = 4);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: StreamBuilder<Business?>(
        stream: BusinessService.instance.watchBusiness(
          widget.businessUser.businessId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text(snapshot.error.toString())),
            );
          }

          final business = snapshot.data;
          if (business == null) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.businessUser.businessName)),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    text(
                      'The linked business document could not be found.',
                      'ގުޅުވާފައިވާ ވިޔަފާރީގެ ޑޮކިއުމަންޓް ނުފެނުނު.',
                    ),
                    textAlign: TextAlign.center,
                    style: style(fontSize: 17),
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                business.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style(fontWeight: FontWeight.w900),
              ),
              actions: [
                NotificationBell(
                  countStream: MarketplaceService.instance
                      .watchBusinessNotificationCount(business.id),
                  tooltip: text('Notifications', 'ނޮޓިފިކޭޝަން'),
                  onPressed: () => _openBusinessNotifications(business),
                ),
                CompactAppIconButton(
                  tooltip: text('Change mode', 'މޯޑް ބަދަލުކުރޭ'),
                  onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
                  icon: widget.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                PopupMenuButton<bool>(
                  tooltip: text('Language', 'ބަސް'),
                  onSelected: widget.onLanguageChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: false, child: Text('English')),
                    PopupMenuItem(
                      value: true,
                      child: Text(
                        'ދިވެހި',
                        style: TextStyle(fontFamily: 'Faruma'),
                      ),
                    ),
                  ],
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.isDhivehi ? 'ދވ' : 'EN',
                      style: TextStyle(
                        fontFamily: widget.isDhivehi ? 'Faruma' : null,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                CompactAppIconButton(
                  tooltip: text('Log Out', 'ލޮގްއައުޓް'),
                  onPressed: AuthService.instance.signOut,
                  icon: Icons.logout_rounded,
                ),
              ],
            ),
            body: IndexedStack(
              index: _pageIndex,
              children: [
                _DashboardTab(
                  business: business,
                  isDhivehi: widget.isDhivehi,
                ),
                _CatalogTab(
                  business: business,
                  isDhivehi: widget.isDhivehi,
                ),
                _TransferTab(
                  business: business,
                  isDhivehi: widget.isDhivehi,
                ),
                QuotationRequestsPage(
                  business: business,
                  isDhivehi: widget.isDhivehi,
                ),
                ChatListPage(
                  currentUser: widget.businessUser,
                  business: business,
                  isDhivehi: widget.isDhivehi,
                  showAppBar: false,
                ),
                SellerSalesReportPage(
                  business: business,
                  isDhivehi: widget.isDhivehi,
                ),
                _AccountTab(
                  business: business,
                  isDhivehi: widget.isDhivehi,
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _pageIndex,
              onDestinationSelected: (index) {
                setState(() => _pageIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_rounded),
                  label: text('Dashboard', 'ޑޭޝްބޯޑް'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: text('Catalog', 'މުދާ'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: text('Transfers', 'ޓްރާންސްފަރ'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.request_quote_rounded),
                  label: text('Quotes', 'ކޯޓޭޝަން'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.chat_rounded),
                  label: text('Messages', 'މެސެޖް'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.analytics_rounded),
                  label: text('Report', 'ރިޕޯޓް'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_rounded),
                  label: text('Account', 'އެކައުންޓް'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CatalogItem>>(
      stream: MarketplaceService.instance.watchBusinessCatalog(business.id),
      builder: (context, itemSnapshot) {
        return StreamBuilder<List<PurchaseOrder>>(
          stream: MarketplaceService.instance.watchOrdersForBusiness(
            business.id,
          ),
          builder: (context, orderSnapshot) {
            final items = itemSnapshot.data ?? const <CatalogItem>[];
            final orders = orderSnapshot.data ?? const <PurchaseOrder>[];
            final active = items.where((item) => item.active).length;
            final lowStock = items
                .where((item) => item.active && item.quantity <= 5)
                .length;
            final pending = orders.where((order) => order.isPending).length;
            final verified = orders.where((order) => order.isSaleCounted).toList();
            final sales = verified.fold<double>(
              0,
              (total, order) => total + order.totalMvr,
            );

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _businessBanner(context),
                const SizedBox(height: 20),
                Text(
                  text('Business Overview', 'ވިޔަފާރީގެ ޚުލާޞާ'),
                  style: style(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final width = wide
                        ? (constraints.maxWidth - 36) / 4
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _stat(
                          context,
                          width,
                          Icons.inventory_2_rounded,
                          text('Active items', 'އެކްޓިވް މުދާ'),
                          active.toString(),
                          Colors.blue,
                        ),
                        _stat(
                          context,
                          width,
                          Icons.warning_amber_rounded,
                          text('Low stock', 'ސްޓޮކް ކުޑަ'),
                          lowStock.toString(),
                          Colors.orange,
                        ),
                        _stat(
                          context,
                          width,
                          Icons.hourglass_top_rounded,
                          text('Pending transfers', 'ޕެންޑިންގް ޓްރާންސްފަރ'),
                          pending.toString(),
                          Colors.purple,
                        ),
                        _stat(
                          context,
                          width,
                          Icons.payments_rounded,
                          text('Verified sales', 'ވެރިފައިޑް ފިޔަވަޅު'),
                          'MVR ${sales.toStringAsFixed(2)}',
                          Colors.green,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        text('Latest Catalog', 'ފަހުގެ މުދާ'),
                        style: style(fontSize: 21, fontWeight: FontWeight.w900),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openAddItem(context),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(text('Add', 'އިތުރު'), style: style()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _empty(
                    context,
                    Icons.inventory_2_outlined,
                    text(
                      'No items or services have been added.',
                      'އަދި މުދަލެއް ނުވަތަ ޚިދުމަތެއް ނުލައެވެ.',
                    ),
                  )
                else
                  SizedBox(
                    height: 225,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.take(8).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) => _previewCard(
                        context,
                        items[index],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _businessBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: business.logoUrl.isEmpty
                ? const Icon(
                    Icons.storefront_rounded,
                    size: 50,
                    color: Colors.white,
                  )
                : Image.network(
                    business.logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.businessName,
                  style: style(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${business.category} • ${business.island}',
                  style: style(color: Colors.white),
                ),
                const SizedBox(height: 7),
                Text(
                  text(
                    'Approved business account',
                    'ހުއްދަދެވިފައިވާ ވިޔަފާރި އެކައުންޓް',
                  ),
                  style: style(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    double width,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.13),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(label, maxLines: 2, style: style(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewCard(BuildContext context, CatalogItem item) {
    return SizedBox(
      width: 175,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.inventory_2_rounded, size: 45),
                    )
                  : Image.network(item.imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style(fontWeight: FontWeight.bold),
                  ),
                  _sellerPriceLine(context, item),
                  Text(
                    '${text('Qty', 'ޢަދަދު')}: ${item.quantity}',
                    style: style(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sellerPriceLine(BuildContext context, CatalogItem item) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      children: [
        if (item.hasPromotion)
          Text(
            item.oldPriceText,
            style: style(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ).copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.red,
              decorationThickness: 2,
            ),
          ),
        Text(
          item.priceText,
          style: style(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, IconData icon, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 55),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: style()),
          ],
        ),
      ),
    );
  }

  void _openAddItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCatalogItemPage(
          business: business,
          isDhivehi: isDhivehi,
        ),
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({required this.business, required this.isDhivehi});

  final Business business;
  final bool isDhivehi;

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CatalogItem>>(
      stream: MarketplaceService.instance.watchBusinessCatalog(business.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CatalogItem>[];
        return Scaffold(
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? Center(child: Text(snapshot.error.toString()))
                  : items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(26),
                            child: Text(
                              text(
                                'Add your first product or service.',
                                'ފުރަތަމަ މުދާ ނުވަތަ ޚިދުމަތް އިތުރުކުރޭ.',
                              ),
                              textAlign: TextAlign.center,
                              style: style(fontSize: 18),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                          itemCount: items.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _managementHelpCard(context);
                            }
                            final item = items[index - 1];
                            return _catalogItemCard(context, item);
                          },
                        ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(text('Add Item', 'މުދާ އިތުރުކުރޭ'), style: style()),
          ),
        );
      },
    );
  }

  Widget _managementHelpCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tips_and_updates_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text(
                  'Use the 3-dot menu to edit price, add sale promotion, add bulk discount, mark out of stock, hide/publish, or delete old items.',
                  '3 ޑޮޓް މެނޫން އަގު ބަދަލުކުރުން، ސޭލް، ޑިސްކައުންޓް، ސްޓޮކް ނެތް ކުރުން، ފޮރުވުން/ޝާއިޢުކުރުން، ނުވަތަ ޑިލީޓް ކުރުން ކުރެވޭ.',
                ),
                style: style(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogItemCard(BuildContext context, CatalogItem item) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 62,
            height: 62,
            child: item.imageUrl.isEmpty
                ? Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      item.isService
                          ? Icons.design_services_rounded
                          : Icons.inventory_2_rounded,
                    ),
                  )
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style(fontWeight: FontWeight.bold),
              ),
            ),
            if (item.hasPromotion) _smallChip(context, text('SALE', 'ސޭލް'), Colors.red),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.category, style: style(fontSize: 12)),
              const SizedBox(height: 3),
              _sellerPriceLine(context, item),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _smallChip(
                    context,
                    item.quantity > 0
                        ? '${text('Qty', 'ޢަދަދު')}: ${item.quantity}'
                        : text('Out of stock', 'ސްޓޮކް ނެތް'),
                    item.quantity > 0 ? Colors.green : Colors.red,
                  ),
                  if (!item.active)
                    _smallChip(context, text('Hidden', 'ފޮރުވިފައި'), Colors.grey),
                  if (item.hasBulkDiscount)
                    _smallChip(context, item.bulkDiscountText, Colors.deepOrange),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          tooltip: text('Manage item', 'މުދާ މެނޭޖްކުރޭ'),
          onSelected: (action) async => _handleAction(context, item, action),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: _menuRow(Icons.edit_rounded, text('Edit item', 'ބަދަލުކުރޭ')),
            ),
            PopupMenuItem(
              value: 'promotion',
              child: _menuRow(
                Icons.local_offer_rounded,
                text('Add sale / discount', 'ސޭލް / ޑިސްކައުންޓް'),
              ),
            ),
            PopupMenuItem(
              value: 'out_of_stock',
              child: _menuRow(
                Icons.remove_shopping_cart_rounded,
                text('Mark out of stock', 'ސްޓޮކް ނެތް ކުރޭ'),
              ),
            ),
            PopupMenuItem(
              value: 'active',
              child: _menuRow(
                item.active ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                item.active
                    ? text('Hide from clients', 'ކްލައިންޓުން ފޮރުވާ')
                    : text('Publish to clients', 'ކްލައިންޓަށް ޝާއިޢުކުރޭ'),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: _menuRow(
                Icons.delete_forever_rounded,
                text('Delete item', 'ޑިލީޓް ކުރޭ'),
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sellerPriceLine(BuildContext context, CatalogItem item) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      children: [
        if (item.hasPromotion)
          Text(
            item.oldPriceText,
            style: style(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ).copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.red,
              decorationThickness: 2,
            ),
          ),
        Text(
          item.priceText,
          style: style(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _smallChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: style(color: color))),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    CatalogItem item,
    String action,
  ) async {
    try {
      if (action == 'edit' || action == 'promotion') {
        _openEditor(context, item: item);
        return;
      }

      if (action == 'active') {
        await MarketplaceService.instance.setCatalogItemActive(
          business: business,
          item: item,
          active: !item.active,
        );
        if (!context.mounted) return;
        _showSnack(
          context,
          item.active
              ? text('Item hidden from clients.', 'މުދާ ކްލައިންޓުން ފޮރުވިއްޖެ.')
              : text('Item published to clients.', 'މުދާ ކްލައިންޓަށް ޝާއިޢުކުރެވިއްޖެ.'),
        );
        return;
      }

      if (action == 'out_of_stock') {
        await MarketplaceService.instance.markCatalogItemOutOfStock(
          business: business,
          item: item,
        );
        if (!context.mounted) return;
        _showSnack(
          context,
          text('Item marked as out of stock.', 'މުދާ ސްޓޮކް ނެތް ކޮށްފި.'),
        );
        return;
      }

      if (action == 'delete') {
        final confirmed = await _confirmDelete(context, item);
        if (confirmed != true) return;
        await MarketplaceService.instance.deleteCatalogItem(
          business: business,
          item: item,
        );
        if (!context.mounted) return;
        _showSnack(
          context,
          text('Item deleted.', 'މުދާ ޑިލީޓް ކުރެވިއްޖެ.'),
          color: Colors.red,
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(
        context,
        error.toString().replaceFirst('Bad state: ', ''),
        color: Colors.red,
      );
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, CatalogItem item) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text('Delete item?', 'މުދާ ޑިލީޓް ކުރަން؟'), style: style(fontWeight: FontWeight.bold)),
        content: Text(
          text(
            'This will remove "${item.name}" from your seller list and client shop page. Old orders will still be kept safely.',
            'މިއިން "${item.name}" ސެލަރ ލިސްޓްއާއި ކްލައިންޓް ޝޮޕް ޕޭޖުން ނައްތާލެވޭ. ކުރީގެ އޯޑަރތައް ސޭފް ކޮށް ބެހެއްޓޭނެ.',
          ),
          style: style(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(text('Delete', 'ޑިލީޓް'), style: style(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, {CatalogItem? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCatalogItemPage(
          business: business,
          isDhivehi: isDhivehi,
          item: item,
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message, style: style(color: Colors.white)),
      ),
    );
  }
}

class _TransferTab extends StatefulWidget {
  const _TransferTab({required this.business, required this.isDhivehi});

  final Business business;
  final bool isDhivehi;

  @override
  State<_TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<_TransferTab> {
  String _filter = 'pending_verification';
  String? _workingOrderId;

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PurchaseOrder>>(
      stream: MarketplaceService.instance.watchOrdersForBusiness(
        widget.business.id,
      ),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <PurchaseOrder>[];
        final orders = _filter == 'all'
            ? all
            : all.where((order) => order.status == _filter).toList();

        return Column(
          children: [
            SizedBox(
              height: 62,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                children: [
                  _filterChip('pending_verification', text('Pending', 'ޕެންޑިންގް')),
                  _filterChip('verified', text('Verified', 'ވެރިފައިޑް')),
                  _filterChip('processing', text('Processing', 'ޕްރޮސެސް')),
                  _filterChip('ready', text('Ready', 'ރެޑީ')),
                  _filterChip('delivered', text('Delivered', 'ޑެލިވަރޑް')),
                  _filterChip('completed', text('Completed', 'ނިމިއްޖެ')),
                  _filterChip('rejected', text('Rejected', 'ރިޖެކްޓް')),
                  _filterChip('all', text('All', 'ހުރިހާ')),
                ],
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : snapshot.hasError
                      ? Center(child: Text(snapshot.error.toString()))
                      : orders.isEmpty
                          ? Center(
                              child: Text(
                                text(
                                  'No transfer records in this section.',
                                  'މި ބައިގައި ޓްރާންސްފަރ ރެކޯޑެއް ނެތް.',
                                ),
                                style: style(fontSize: 17),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                              itemCount: orders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) => _orderCard(orders[index]),
                            ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        type: MaterialType.transparency,
        child: ChoiceChip(
          selected: _filter == value,
          onSelected: (_) => setState(() => _filter = value),
          label: Text(label, style: style(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _orderCard(PurchaseOrder order) {
    final working = _workingOrderId == order.id;
    final statusColor = order.isVerified
        ? Colors.green
        : order.isRejected
            ? Colors.red
            : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.itemName,
                    style: style(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _status(order),
                    style: style(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _detail(Icons.person_rounded, order.clientName),
            _detail(Icons.phone_rounded, order.clientPhone),
            _detail(
              Icons.shopping_bag_rounded,
              '${text('Quantity', 'ޢަދަދު')}: ${order.quantity}',
            ),
            _detail(Icons.payments_rounded, order.totalText),
            if (order.transferReference.isNotEmpty)
              _detail(Icons.tag_rounded, order.transferReference),
            if (order.rejectionReason.isNotEmpty)
              _detail(Icons.info_outline_rounded, order.rejectionReason),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: working ? null : () => _viewReceipt(order),
              icon: const Icon(Icons.receipt_long_rounded),
              label: Text(
                text('View Transfer Receipt', 'ޓްރާންސްފަރ ރަސީދު ބަލާ'),
                style: style(),
              ),
            ),
            if (order.isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: working ? null : () => _verify(order),
                      icon: working
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: Text(
                        text('Verify Payment', 'ފައިސާ ވެރިފައިކުރޭ'),
                        style: style(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: working ? null : () => _reject(order),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
                    ),
                  ),
                ],
              ),
            ] else if (!order.isRejected && _nextStatus(order) != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: working ? null : () => _advanceStatus(order),
                icon: working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.local_shipping_rounded),
                label: Text(
                  '${text('Move to', 'ބަދަލުކުރޭ')}: ${_statusLabel(_nextStatus(order)!)}',
                  style: style(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _status(PurchaseOrder order) {
    return _statusLabel(order.status);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified':
        return text('Verified', 'ވެރިފައިޑް');
      case 'processing':
        return text('Processing', 'ޕްރޮސެސްކުރަނީ');
      case 'ready':
        return text('Ready', 'ރެޑީ');
      case 'delivered':
        return text('Delivered', 'ޑެލިވަރޑް');
      case 'completed':
        return text('Completed', 'ނިމިއްޖެ');
      case 'rejected':
        return text('Rejected', 'ރިޖެކްޓް');
      default:
        return text('Pending', 'ޕެންޑިންގް');
    }
  }

  String? _nextStatus(PurchaseOrder order) {
    if (order.isVerified) return 'processing';
    if (order.isProcessing) return 'ready';
    if (order.isReady) return 'delivered';
    if (order.isDelivered) return 'completed';
    return null;
  }

  Widget _detail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: style())),
        ],
      ),
    );
  }

  Future<void> _viewReceipt(PurchaseOrder order) async {
    setState(() => _workingOrderId = order.id);
    try {
      final url = await MarketplaceService.instance
          .createReceiptSignedUrl(order.receiptPath);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          text('Transfer Receipt', 'ޓްރާންސްފަރ ރަސީދު'),
                          style: style(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 5,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(30),
                        child: Icon(Icons.broken_image_rounded, size: 70),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingOrderId = null);
    }
  }

  Future<void> _verify(PurchaseOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          text('Verify Payment?', 'ފައިސާ ވެރިފައިކުރަން؟'),
          style: style(fontWeight: FontWeight.bold),
        ),
        content: Text(
          text(
            'Confirm only after checking that the money reached your account. This will automatically reduce the item quantity by ${order.quantity}.',
            'ފައިސާ އެކައުންޓަށް ވަންކަން ޔަގީންކޮށްގެން ކަންފަރމްކުރޭ. މިއިން މުދަލުގެ ޢަދަދު ${order.quantity} އަކުން ކުޑަވާނެ.',
          ),
          style: style(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(text('Verify', 'ވެރިފައި'), style: style()),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _workingOrderId = order.id);
    try {
      await MarketplaceService.instance.verifyOrder(
        business: widget.business,
        order: order,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text(
              'Payment verified and quantity reduced automatically.',
              'ފައިސާ ވެރިފައިކޮށް މުދަލުގެ ޢަދަދު އޮޓޯމެޓިކްކޮށް ކުޑަކުރެވިއްޖެ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingOrderId = null);
    }
  }

  Future<void> _reject(PurchaseOrder order) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          text('Reject Transfer', 'ޓްރާންސްފަރ ރިޖެކްޓްކުރޭ'),
          style: style(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: text('Reason', 'ސަބަބު'),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;

    setState(() => _workingOrderId = order.id);
    try {
      await MarketplaceService.instance.rejectOrder(
        business: widget.business,
        order: order,
        reason: reason,
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingOrderId = null);
    }
  }

  Future<void> _advanceStatus(PurchaseOrder order) async {
    final nextStatus = _nextStatus(order);
    if (nextStatus == null) return;

    setState(() => _workingOrderId = order.id);
    try {
      await MarketplaceService.instance.updateOrderStatus(
        business: widget.business,
        order: order,
        status: nextStatus,
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingOrderId = null);
    }
  }

  void _showError(Object error) {
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

class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.business, required this.isDhivehi});

  final Business business;
  final bool isDhivehi;

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text(
                          'Money Transfer Account',
                          'ފައިސާ ޓްރާންސްފަރ އެކައުންޓް',
                        ),
                        style: style(fontSize: 21, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                _row(text('Bank', 'ބޭންކް'), business.bankName),
                _row(
                  text('Account name', 'އެކައުންޓްގެ ނަން'),
                  business.accountName,
                ),
                _row(
                  text('Account number', 'އެކައުންޓް ނަންބަރު'),
                  business.accountNumber,
                ),
                if (business.paymentInstructions.isNotEmpty) ...[
                  const Divider(height: 28),
                  Text(business.paymentInstructions, style: style()),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessPaymentSettingsPage(
                          business: business,
                          isDhivehi: isDhivehi,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(
                    business.hasPaymentAccount
                        ? text('Edit Account', 'އެކައުންޓް ބަދަލުކުރޭ')
                        : text('Add Account', 'އެކައުންޓް އިތުރުކުރޭ'),
                    style: style(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text('Shop Location', 'ފިހާރައިގެ ލޮކޭޝަން'),
                        style: style(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _row(text('Island', 'ރަށް'), business.island),
                _row(
                  text('Map point', 'މެޕް ޕޮއިންޓް'),
                  business.latitude == null || business.longitude == null
                      ? text('Not set', 'ސެޓްނުކުރެވި')
                      : '${business.latitude!.toStringAsFixed(6)}, ${business.longitude!.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessLocationSettingsPage(
                          business: business,
                          isDhivehi: isDhivehi,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_location_alt_rounded),
                  label: Text(
                    text('Edit Shop Location', 'ފިހާރައިގެ ލޮކޭޝަން ބަދަލުކުރޭ'),
                    style: style(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text('Opening Hours', 'ހުޅުވާ ގަޑި'),
                        style: style(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _row(
                  text('Status now', 'މިހާރު'),
                  business.openStatus(DateTime.now()).label(isDhivehi: isDhivehi),
                ),
                _row(text('Hours', 'ގަޑި'), business.hoursSummary(isDhivehi: isDhivehi)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessHoursSettingsPage(
                          business: business,
                          isDhivehi: isDhivehi,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar_rounded),
                  label: Text(text('Edit Opening Hours', 'ހުޅުވާ ގަޑި ބަދަލުކުރޭ'), style: style(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_activity_rounded, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text('Coupon Offer', 'ކޫޕަން އޮފަރ'),
                        style: style(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _row(
                  text('Status', 'ސްޓޭޓަސް'),
                  business.couponEnabled
                      ? text('Enabled', 'އެނޭބަލް')
                      : text('Disabled', 'ޑިސޭބަލް'),
                ),
                _row(text('Minimum order', 'މިނިމަމް އޯޑަރ'), business.couponMinimumSpendText),
                _row(text('Reward', 'ރިވޯޑް'), business.couponRewardText),
                if (business.couponTitle.isNotEmpty)
                  _row(text('Title', 'ޓައިޓަލް'), business.couponTitle),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessCouponSettingsPage(
                              business: business,
                              isDhivehi: isDhivehi,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(
                        text('Edit Coupon Offer', 'ކޫޕަން ބަދަލުކުރޭ'),
                        style: style(fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessCouponsPage(
                              business: business,
                              isDhivehi: isDhivehi,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people_alt_rounded),
                      label: Text(
                        text('View Client Coupons', 'ކްލައިންޓް ކޫޕަންތައް'),
                        style: style(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text('Featured / Sponsored', 'ފީޗަރޑް / ސްޕޮންސަރ'),
                        style: style(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _row(
                  text('Trust badge', 'ޓްރަސްޓް ބެޖް'),
                  business.trustBadgeText,
                ),
                _row(
                  text('Promotion', 'ޕްރޮމޯޝަން'),
                  business.promotionBadgeText.isEmpty
                      ? text('Not active', 'އެކްޓިވްއެއް ނޫން')
                      : business.promotionBadgeText,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessPromotionRequestPage(
                          business: business,
                          isDhivehi: isDhivehi,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.campaign_rounded),
                  label: Text(
                    text('Request Promotion', 'ޕްރޮމޯޝަން ރިކުއެސްޓްކުރޭ'),
                    style: style(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text('Business Information', 'ވިޔަފާރީގެ މަޢުލޫމާތު'),
                  style: style(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _row(text('Business', 'ވިޔަފާރި'), business.businessName),
                _row(text('Category', 'ބާވަތް'), business.category),
                _row(text('Island', 'ރަށް'), business.island),
                _row(text('Phone', 'ފޯނު'), business.contactNumber),
                _row(text('Email', 'އީމެއިލް'), business.email),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: style(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: style(),
            ),
          ),
        ],
      ),
    );
  }
}
