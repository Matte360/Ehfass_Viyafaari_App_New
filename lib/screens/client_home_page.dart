import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_language.dart';
import '../models/app_user.dart';
import '../models/business.dart';
import '../models/catalog_item.dart';
import '../models/home_advertisement.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../services/home_advertisement_service.dart';
import '../services/marketplace_service.dart';
import 'add_business_page.dart';
import 'business_storefront_page.dart';
import 'chat_list_page.dart';
import 'cart_page.dart';
import 'client_orders_page.dart';
import 'item_detail_page.dart';
import 'my_submissions_page.dart';
import 'notification_center_page.dart';
import 'settings_page.dart';
import '../widgets/notification_bell.dart';
import '../widgets/app_logo.dart';
import '../widgets/compact_app_icon_button.dart';
import '../widgets/user_avatar.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({
    super.key,
    required this.user,
    required this.language,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final AppUser user;
  final AppLanguage language;
  final bool isDarkMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final _searchController = TextEditingController();
  final _advertisementController = PageController();
  Timer? _advertisementTimer;

  Position? _position;
  bool _locationLoading = false;
  int _currentAdvertisement = 0;
  int _advertisementItemCount = _advertisements.length;
  int _pageIndex = 0;
  final Set<String> _favoriteBusinessIds = <String>{};
  final List<Business> _recentBusinesses = <Business>[];

  bool get isDhivehi => widget.language == AppLanguage.dhivehi;

  static const _advertisements = <_AdvertisementBanner>[
    _AdvertisementBanner(
      titleEnglish: 'Grow Your Business',
      titleDhivehi: 'ތިޔަ ވިޔަފާރި ކުރިއެރުވާ',
      descriptionEnglish:
          'Register your business and reach customers across the Maldives.',
      descriptionDhivehi:
          'ވިޔަފާރި ރަޖިސްޓަރކޮށް ރާއްޖޭގެ ކަސްޓަމަރުންނާ ގުޅޭ.',
      icon: Icons.trending_up_rounded,
      colors: [Color(0xFF00A878), Color(0xFF007A5E)],
    ),
    _AdvertisementBanner(
      titleEnglish: 'Find Shops Near You',
      titleDhivehi: 'ގާތުގައި ހުންނަ ފިހާރަތައް ހޯދާ',
      descriptionEnglish:
          'Allow location access to see the closest approved businesses.',
      descriptionDhivehi:
          'ގާތުގައި ހުންނަ ހުއްދަދެވިފައިވާ ވިޔަފާރިތައް ފެންނަން ލޮކޭޝަން ހުއްދަ ދޭ.',
      icon: Icons.near_me_rounded,
      colors: [Color(0xFF3F51B5), Color(0xFF283593)],
    ),
    _AdvertisementBanner(
      titleEnglish: 'Special Offers',
      titleDhivehi: 'ޚާއްޞަ އޮފަރުތައް',
      descriptionEnglish:
          'Approved advertisements and special offers can appear here.',
      descriptionDhivehi:
          'ހުއްދަދެވިފައިވާ އިޢުލާނާއި ޚާއްޞަ އޮފަރުތައް މިތާ ފެންނާނެ.',
      icon: Icons.local_offer_rounded,
      colors: [Color(0xFFFF8A00), Color(0xFFFF4D4D)],
    ),
  ];

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

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
  void initState() {
    super.initState();
    _advertisementTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!_advertisementController.hasClients) return;
        if (_advertisementItemCount <= 1) return;
        final next = (_currentAdvertisement + 1) % _advertisementItemCount;
        _advertisementController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectLocation();
    });
  }

  @override
  void dispose() {
    _advertisementTimer?.cancel();
    _advertisementController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    if (_locationLoading) return;
    setState(() {
      _locationLoading = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw StateError(
          text(
            'Location services are turned off.',
            'ލޮކޭޝަން ސާވިސް އޮފްކޮށްފައި ވެއެވެ.',
          ),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw StateError(
          text(
            'Location permission was denied.',
            'ލޮކޭޝަން ހުއްދަ ނުދެވުނު.',
          ),
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          text(
            'Location is permanently denied. Enable it in device settings.',
            'ލޮކޭޝަން ހުއްދަ ދާއިމީކޮށް ނުދެވިފައި. ޑިވައިސް ސެޓިންގްސްގައި އޮން ކުރޭ.',
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = position;
      });
    } catch (_) {
      // Location errors are handled silently because the status bar was removed.
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  double? _distanceTo(Business business) {
    if (_position == null ||
        business.latitude == null ||
        business.longitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          business.latitude!,
          business.longitude!,
        ) /
        1000;
  }

  List<_LocatedBusiness> _filterBusinesses(List<Business> businesses) {
    final query = _searchController.text.trim().toLowerCase();

    final results = businesses
        .where((business) {
          if (query.isEmpty) return true;
          return business.businessName.toLowerCase().contains(query) ||
              business.category.toLowerCase().contains(query) ||
              business.island.toLowerCase().contains(query) ||
              business.description.toLowerCase().contains(query);
        })
        .map(
          (business) => _LocatedBusiness(
            business: business,
            distanceKm: _distanceTo(business),
          ),
        )
        .toList();

    results.sort((a, b) {
      if (a.distanceKm != null && b.distanceKm != null) {
        return a.distanceKm!.compareTo(b.distanceKm!);
      }
      if (a.distanceKm != null) return -1;
      if (b.distanceKm != null) return 1;
      return a.business.businessName.toLowerCase().compareTo(
            b.business.businessName.toLowerCase(),
          );
    });

    return results;
  }

  void _openAddBusiness() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBusinessPage(
          user: widget.user,
          isDhivehi: isDhivehi,
        ),
      ),
    );
  }


  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          client: widget.user,
          isDhivehi: isDhivehi,
        ),
      ),
    );
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
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
                    .watchClientNotificationCount(widget.user.uid),
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
                        'Includes pending orders, quotations and unread messages.',
                        'ޕެންޑިންގް އޯޑަރ، ކޯޓޭޝަން، އަދި ނުކިޔާ މެސެޖްތައް ހިމެނޭ.',
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
                        currentUser: widget.user,
                        isDhivehi: isDhivehi,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text(text('My orders and quotations', 'މަގޭ އޯޑަރާއި ކޯޓޭޝަން'), style: style()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientOrdersPage(
                        client: widget.user,
                        isDhivehi: isDhivehi,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_rounded),
                title: Text(text('Messages', 'މެސެޖްތައް'), style: style()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatListPage(
                        currentUser: widget.user,
                        isDhivehi: isDhivehi,
                      ),
                    ),
                  );
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
      textDirection: TextDirection.ltr,
      child: Scaffold(
        endDrawer: _buildDrawer(),
        appBar: AppBar(
          toolbarHeight: 58,
          leadingWidth: 220,
          leading: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                UserAvatar(user: widget.user, radius: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: const SizedBox.shrink(),
          actions: [
            NotificationBell(
              countStream: MarketplaceService.instance
                  .watchClientNotificationCount(widget.user.uid),
              tooltip: text('Notifications', 'ނޮޓިފިކޭޝަން'),
              onPressed: _openNotifications,
            ),
            NotificationBell(
              countStream: MarketplaceService.instance
                  .watchCartCount(widget.user.uid),
              tooltip: text('Cart', 'ކާޓް'),
              icon: Icons.shopping_cart_rounded,
              onPressed: _openCart,
            ),
            Builder(
              builder: (scaffoldContext) {
                return CompactAppIconButton(
                  tooltip: text('Menu', 'މެނޫ'),
                  onPressed: () {
                    Scaffold.of(scaffoldContext).openEndDrawer();
                  },
                  icon: Icons.menu_rounded,
                );
              },
            ),
            const SizedBox(width: 7),
          ],
        ),
        body: Directionality(
          textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
          child: IndexedStack(
            index: _pageIndex,
            children: [
              _homeTab(),
              _categoriesTab(),
              ClientOrdersPage(
                client: widget.user,
                isDhivehi: isDhivehi,
                showAppBar: false,
              ),
              ChatListPage(
                currentUser: widget.user,
                isDhivehi: isDhivehi,
                showAppBar: false,
              ),
              _profileTab(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _pageIndex,
          onDestinationSelected: (index) => setState(() => _pageIndex = index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_rounded),
              label: text('Home', 'މައި'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.category_rounded),
              label: text('Categories', 'ބާވަތް'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.shopping_bag_rounded),
              label: text('Orders', 'އޯޑަރު'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_rounded),
              label: text('Messages', 'މެސެޖް'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_rounded),
              label: text('Profile', 'ޕްރޮފައިލް'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeTab() {
    return StreamBuilder<List<Business>>(
      stream: BusinessService.instance.watchApprovedBusinesses(),
      builder: (context, snapshot) {
        final businesses = snapshot.data ?? const <Business>[];
        final locatedBusinesses = _filterBusinesses(businesses);
        return RefreshIndicator(
          onRefresh: () => _detectLocation(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 35),
            children: [
              _buildWelcomeAndSearch(businesses: businesses),
              _buildQuickActions(),
              if (_searchController.text.trim().isEmpty)
                _buildFeaturedBusinesses(locatedBusinesses),
              if (_searchController.text.trim().isEmpty)
                _buildSaleItemsSection(businesses),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(snapshot.error.toString()),
                )
              else if (_searchController.text.trim().isNotEmpty)
                _buildSearchResults(locatedBusinesses)
              else
                _buildNearbyPreview(locatedBusinesses),
              _buildAdvertisements(),
              _buildCategoryPreview(),
              _buildTopBusinesses(locatedBusinesses),
              _buildAddBusinessSection(),
            ],
          ),
        );
      },
    );
  }


  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Row(
        children: [
          Expanded(
            child: _quickActionCard(
              icon: Icons.my_location_rounded,
              label: _locationLoading
                  ? text('Finding...', 'ހޯދަނީ...')
                  : text('Nearby', 'ގާތުގައި'),
              onTap: _detectLocation,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickActionCard(
              icon: Icons.local_offer_rounded,
              label: text('Today Offers', 'މިއަދު އޮފަރު'),
              onTap: () {
                _searchController.clear();
                setState(() => _pageIndex = 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      text(
                        'Today Offers are shown below.',
                        'މިއަދުގެ އޮފަރުތައް ތިރީގައި ފެންނާނެ.',
                      ),
                      style: style(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickActionCard(
              icon: Icons.shopping_cart_rounded,
              label: text('Cart', 'ކާޓް'),
              onTap: _openCart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPreview() {
    final categories = _homeCategories.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text('Browse Categories', 'ބާވަތްތައް ބަލާ'),
                  style: style(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _pageIndex = 1),
                child: Text(text('See all', 'ހުރިހާ'), style: style()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 24) / 4;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map((category) => SizedBox(
                          width: width,
                          child: _categoryIconCard(category, compact: true),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _categoriesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text(
          text('Categories', 'ބާވަތްތައް'),
          style: style(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          text(
            'Choose a category to find related shops, products and services.',
            'ގުޅޭ ފިހާރަ، މުދާ، އަދި ޚިދުމަތް ހޯދަން ބާވަތެއް ހޮވާ.',
          ),
          style: style(height: 1.45),
        ),
        const SizedBox(height: 18),
        Text(
          text('Product Categories', 'މުދާގެ ބާވަތް'),
          style: style(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _categoryGrid(_productCategoriesForHome),
        const SizedBox(height: 24),
        Text(
          text('Service Categories', 'ޚިދުމަތުގެ ބާވަތް'),
          style: style(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _categoryGrid(_serviceCategoriesForHome),
      ],
    );
  }

  Widget _categoryGrid(List<_HomeCategory> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 4
            : constraints.maxWidth >= 560
                ? 3
                : 2;
        final width =
            (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories
              .map((category) => SizedBox(
                    width: width,
                    child: _categoryIconCard(category),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _categoryIconCard(_HomeCategory category, {bool compact = false}) {
    return InkWell(
      onTap: () {
        _searchController.text = category.name;
        setState(() => _pageIndex = 0);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: compact ? 20 : 25,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                category.icon,
                size: compact ? 21 : 26,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: compact ? 7 : 10),
            Text(
              category.name,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTab() {
    final favorites = _recentBusinesses
        .where((business) => _favoriteBusinessIds.contains(business.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                UserAvatar(user: widget.user, radius: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(fontSize: 21, fontWeight: FontWeight.w900),
                      ),
                      Text('@${widget.user.username}', style: style()),
                      if (widget.user.phone.isNotEmpty)
                        Text(widget.user.phone, style: style()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _profileAction(
                Icons.settings_rounded,
                text('Settings', 'ސެޓިންގްސް'),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(
                      user: widget.user,
                      isDhivehi: isDhivehi,
                      isDarkMode: widget.isDarkMode,
                      onLanguageChanged: (useDhivehi) {
                        widget.onLanguageChanged(
                          useDhivehi
                              ? AppLanguage.dhivehi
                              : AppLanguage.english,
                        );
                      },
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _profileAction(
                Icons.add_business_rounded,
                text('Add Business', 'ވިޔަފާރި'),
                _openAddBusiness,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _profileSection(
          title: text('Favorite Shops', 'ފޭވަރިޓް ފިހާރަ'),
          icon: Icons.favorite_rounded,
          businesses: favorites,
          empty: text(
            'Tap the heart on a shop to save it here.',
            'ފިހާރައެއް ސޭވްކުރަން ހާޓް ބަޓަން ފިތާލާ.',
          ),
        ),
        const SizedBox(height: 20),
        _profileSection(
          title: text('Recently Viewed', 'ފަހުން ބެލިފައި'),
          icon: Icons.history_rounded,
          businesses: _recentBusinesses,
          empty: text(
            'Recently opened shops will show here.',
            'ފަހުން ހުޅުވި ފިހާރަތައް މިތާ ފެނޭނެ.',
          ),
        ),
      ],
    );
  }

  Widget _profileAction(IconData icon, String label, VoidCallback onTap) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, style: style(fontWeight: FontWeight.bold)),
    );
  }

  Widget _profileSection({
    required String title,
    required IconData icon,
    required List<Business> businesses,
    required String empty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: style(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (businesses.isEmpty)
          _emptyCard(empty)
        else
          ...businesses.map(
            (business) => _businessListCard(
              _LocatedBusiness(business: business, distanceKm: _distanceTo(business)),
            ),
          ),
      ],
    );
  }


  Widget _heroWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const AppLogo(height: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text('Everything near you', 'ތިޔަ ގާތުގެ ހުރިހާ ވިޔަފާރި'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  text(
                    'Search, buy, chat and request quotations from trusted shops.',
                    'ހޯދާ، ގަނޭ، ޗެޓްކުރޭ، އަދި ކޯޓޭޝަން ރިކުއެސްޓްކުރޭ.',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: style(fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeAndSearch({
    required List<Business> businesses,
  }) {
    final query = _searchController.text.trim().toLowerCase();
    final suggestions = query.isEmpty
        ? const <Business>[]
        : businesses
            .where(
              (business) =>
                  business.businessName.toLowerCase().contains(query) ||
                  business.category.toLowerCase().contains(query) ||
                  business.island.toLowerCase().contains(query),
            )
            .take(5)
            .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heroWelcomeCard(),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: text(
                'Search business, category or island',
                'ވިޔަފާރި، ބާވަތް ނުވަތަ ރަށް ހޯދާ',
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
          if (suggestions.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(top: 5),
              child: Column(
                children: suggestions.map((business) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.storefront_rounded),
                    title: Text(
                      business.businessName,
                      style: style(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${business.category} • ${business.island}',
                      style: style(),
                    ),
                    onTap: () {
                      _searchController.text = business.businessName;
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<_LocatedBusiness> results) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text(
              'Search Results (${results.length})',
              'ހޯދި ނަތީޖާ (${results.length})',
            ),
            style: style(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (results.isEmpty)
            _emptyCard(
              text(
                'No approved businesses match your search.',
                'ތިޔަ ހޯދާ ގޮތަށް ހުއްދަދެވިފައިވާ ވިޔަފާރިއެއް ނުފެނުނު.',
              ),
            )
          else
            ...results.map(_businessListCard),
        ],
      ),
    );
  }


  Widget _buildSaleItemsSection(List<Business> businesses) {
    final businessById = <String, Business>{
      for (final business in businesses) business.id: business,
    };

    return StreamBuilder<List<CatalogItem>>(
      stream: MarketplaceService.instance.watchSaleCatalog(),
      builder: (context, snapshot) {
        final saleItems = snapshot.data ?? const <CatalogItem>[];
        if (saleItems.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 0, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text('Today Sale Offers', 'މިއަދުގެ ސޭލް އޮފަރު'),
                        style: style(fontSize: 21, fontWeight: FontWeight.w900),
                      ),
                    ),
                    _softChip(
                      text('Sale', 'ސޭލް'),
                      Colors.red,
                      Icons.local_offer_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: saleItems.take(10).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = saleItems[index];
                    final business = businessById[item.businessId];
                    return _saleItemCard(item, business);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _saleItemCard(CatalogItem item, Business? business) {
    return SizedBox(
      width: 185,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (business == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    text(
                      'Business details are still loading. Please try again.',
                      'ވިޔަފާރީގެ ތަފްސީލު ލޯޑްވަނީ. އަލުން ޓްރައި ކުރޭ.',
                    ),
                  ),
                ),
              );
              return;
            }
            _rememberBusiness(business);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailPage(
                  client: widget.user,
                  business: business,
                  item: item,
                  isDhivehi: isDhivehi,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.imageUrl.isEmpty
                          ? Container(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: const Icon(Icons.inventory_2_rounded, size: 42),
                            )
                          : Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_rounded,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.promotionPercentOff > 0
                              ? '${item.promotionPercentOff}% OFF'
                              : text('SALE', 'ސޭލް'),
                          style: style(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      style: style(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      business?.businessName ?? item.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    _clientSalePriceLine(item),
                    if (item.hasBulkDiscount) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.bulkDiscountText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clientSalePriceLine(CatalogItem item) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 2,
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
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBusinesses(List<_LocatedBusiness> results) {
    final featured = results.where((item) => item.business.isFeatured).take(6).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 0, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text('Featured Shops', 'ފީޗަރޑް ފިހާރަ'),
                    style: style(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ),
                _softChip(
                  text('Sponsored', 'ސްޕޮންސަރ'),
                  Colors.orange,
                  Icons.campaign_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final result = featured[index];
                final business = result.business;
                return SizedBox(
                  width: 250,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showBusinessDetails(business, result.distanceKm),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: business.logoUrl.isEmpty
                                    ? Container(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        child: const Icon(Icons.storefront_rounded),
                                      )
                                    : Image.network(
                                        business.logoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    business.businessName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: style(fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${business.category} • ${business.island}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: style(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _softChip(
                                        business.promotionBadgeText,
                                        business.isSponsored ? Colors.orange : Colors.indigo,
                                        business.isSponsored ? Icons.campaign_rounded : Icons.star_rounded,
                                      ),
                                      _softChip(
                                        text('Verified', 'ވެރިފައިޑް'),
                                        Colors.green,
                                        Icons.verified_rounded,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _softChip(String label, Color color, IconData icon) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: style(fontSize: 10, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPreview(List<_LocatedBusiness> results) {
    final nearby = results.where((result) {
      return result.distanceKm != null && result.distanceKm! <= 25;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text('Available Near You', 'ތިޔަ ގާތުގައި ލިބެން ހުރި'),
                  style: style(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              if (nearby.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    text('${nearby.length} shops', '${nearby.length} ފިހާރަ'),
                    style: style(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (nearby.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              text(
                'Scroll inside this list to see more nearby shops.',
                'އިތުރު ގާތުގައި ހުރި ފިހާރަތައް ބަލަން މި ލިސްޓްގައި ސްކްރޯލް ކުރޭ.',
              ),
              style: style(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.62),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (_position == null)
            _emptyCard(
              text(
                'Turn on location to see nearby approved shops.',
                'ގާތުގައި ހުންނަ ހުއްދަދެވިފައިވާ ފިހާރަތައް ފެންނަން ލޮކޭޝަން އޮން ކުރޭ.',
              ),
            )
          else if (nearby.isEmpty)
            _emptyCard(
              text(
                'No approved shops with GPS locations were found within 25 km.',
                '25 ކިލޯމީޓަރު ތެރޭގައި GPS ލޮކޭޝަން ހުރި ހުއްދަދެވިފައިވާ ފިހާރައެއް ނުފެނުނު.',
              ),
            )
          else
            _scrollableNearbyList(nearby),
        ],
      ),
    );
  }

  Widget _scrollableNearbyList(List<_LocatedBusiness> nearby) {
    final visibleCount = nearby.length < 3 ? nearby.length : 3;
    final listHeight = nearby.length <= 3 ? visibleCount * 112.0 : 370.0;

    return Container(
      height: listHeight.clamp(112.0, 370.0).toDouble(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Scrollbar(
        child: ListView.builder(
          primary: false,
          padding: EdgeInsets.zero,
          physics: nearby.length > 3
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: nearby.length,
          itemBuilder: (context, index) => _businessListCard(nearby[index]),
        ),
      ),
    );
  }

  Widget _businessListCard(_LocatedBusiness result) {
    final business = result.business;
    final status = business.openStatus(DateTime.now());
    final favorite = _favoriteBusinessIds.contains(business.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showBusinessDetails(business, result.distanceKm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: business.logoUrl.isEmpty
                      ? Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.storefront_rounded),
                        )
                      : Image.network(
                          business.logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style(fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _toggleFavorite(business),
                          icon: Icon(
                            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: favorite ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${business.category} • ${business.island}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (business.isTrustedSeller)
                          _tinyStatusChip(
                            business.trustBadgeText,
                            Colors.green,
                            Icons.verified_rounded,
                          ),
                        if (business.isFeatured)
                          _tinyStatusChip(
                            business.promotionBadgeText,
                            business.isSponsored ? Colors.orange : Colors.indigo,
                            business.isSponsored ? Icons.campaign_rounded : Icons.star_rounded,
                          ),
                        _tinyStatusChip(
                          status.label(isDhivehi: isDhivehi),
                          status.isOpen ? Colors.green : Colors.red,
                          status.isOpen ? Icons.schedule_rounded : Icons.pause_circle_rounded,
                        ),
                        _tinyStatusChip(
                          business.deliveryAvailable
                              ? text('Delivery', 'ޑެލިވަރީ')
                              : text('Pickup', 'ޕިކްއަޕް'),
                          business.deliveryAvailable ? Colors.teal : Colors.blueGrey,
                          business.deliveryAvailable
                              ? Icons.delivery_dining_rounded
                              : Icons.storefront_rounded,
                        ),
                        if (result.distanceKm != null)
                          _tinyStatusChip(
                            '${result.distanceKm!.toStringAsFixed(1)} km',
                            Colors.indigo,
                            Icons.near_me_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tinyStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(fontSize: 10, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(Business business) {
    setState(() {
      if (_favoriteBusinessIds.contains(business.id)) {
        _favoriteBusinessIds.remove(business.id);
      } else {
        _favoriteBusinessIds.add(business.id);
        _rememberBusiness(business);
      }
    });
  }

  void _rememberBusiness(Business business) {
    _recentBusinesses.removeWhere((item) => item.id == business.id);
    _recentBusinesses.insert(0, business);
    if (_recentBusinesses.length > 10) {
      _recentBusinesses.removeRange(10, _recentBusinesses.length);
    }
  }

  Widget _emptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: style())),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertisements() {
    return StreamBuilder<List<HomeAdvertisement>>(
      stream: HomeAdvertisementService.instance.watchActive(),
      builder: (context, snapshot) {
        final liveAdvertisements = snapshot.data ?? const <HomeAdvertisement>[];
        final useLiveAdvertisements = liveAdvertisements.isNotEmpty;
        final itemCount = useLiveAdvertisements
            ? liveAdvertisements.length
            : _advertisements.length;

        _advertisementItemCount = itemCount;

        if (itemCount == 0) {
          return const SizedBox.shrink();
        }

        final activeIndex =
            _currentAdvertisement.clamp(0, itemCount - 1).toInt();

        return Column(
          children: [
            SizedBox(
              height: 205,
              child: PageView.builder(
                controller: _advertisementController,
                itemCount: itemCount,
                onPageChanged: (index) {
                  setState(() => _currentAdvertisement = index);
                },
                itemBuilder: (context, index) {
                  if (useLiveAdvertisements) {
                    return _buildLiveAdvertisementCard(
                      liveAdvertisements[index],
                    );
                  }

                  final advertisement = _advertisements[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.all(23),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: advertisement.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text('ADVERTISEMENT', 'އިޢުލާން'),
                                style: style(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                text(
                                  advertisement.titleEnglish,
                                  advertisement.titleDhivehi,
                                ),
                                style: style(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                text(
                                  advertisement.descriptionEnglish,
                                  advertisement.descriptionDhivehi,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: style(
                                  height: 1.4,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          advertisement.icon,
                          color: Colors.white,
                          size: 60,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                itemCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 7,
                  width: index == activeIndex ? 24 : 7,
                  decoration: BoxDecoration(
                    color: index == activeIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveAdvertisementCard(HomeAdvertisement advertisement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (advertisement.imageUrl.isNotEmpty)
            Image.network(
              advertisement.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00A878), Color(0xFF007A5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.66),
                  Colors.black.withValues(alpha: 0.22),
                ],
                begin: isDhivehi ? Alignment.centerRight : Alignment.centerLeft,
                end: isDhivehi ? Alignment.centerLeft : Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text('ADVERTISEMENT', 'އިޢުލާން'),
                  style: style(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text(
                    advertisement.titleEnglish,
                    advertisement.titleDhivehi.isEmpty
                        ? advertisement.titleEnglish
                        : advertisement.titleDhivehi,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text(
                    advertisement.descriptionEnglish,
                    advertisement.descriptionDhivehi.isEmpty
                        ? advertisement.descriptionEnglish
                        : advertisement.descriptionDhivehi,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: style(
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBusinesses(List<_LocatedBusiness> businesses) {
    final top = businesses.take(5).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              text('Top Approved Businesses',
                  'މޮޅު ހުއްދަދެވިފައިވާ ވިޔަފާރިތައް'),
              style: style(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _emptyCard(
                text(
                  'No businesses have been approved yet.',
                  'މިހާރު ހަމައަށް ހުއްދަދެވިފައިވާ ވިޔަފާރިއެއް ނެތް.',
                ),
              ),
            )
          else
            SizedBox(
              height: 225,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: top.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final result = top[index];
                  final business = result.business;

                  return SizedBox(
                    width: 245,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showBusinessDetails(
                          business,
                          result.distanceKm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: business.logoUrl.isEmpty
                                  ? Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: const Icon(
                                        Icons.storefront_rounded,
                                        size: 65,
                                      ),
                                    )
                                  : Image.network(
                                      business.logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image_rounded,
                                        size: 55,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(13),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    business.businessName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: style(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${business.category} • ${business.island}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: style(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddBusinessSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 34, 18, 0),
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_business_rounded,
            size: 55,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            text(
              'Add Your Business Now',
              'ތިޔަ ވިޔަފާރި މިހާރު އިތުރުކުރޭ',
            ),
            textAlign: TextAlign.center,
            style: style(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            text(
              'Submitted businesses become visible only after admin approval.',
              'ހުށަހަޅާ ވިޔަފާރިތައް ފެންނާނީ އެޑްމިން ހުއްދަދިނުމުންނެވެ.',
            ),
            textAlign: TextAlign.center,
            style: style(height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 51,
            child: FilledButton.icon(
              onPressed: _openAddBusiness,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                text('Add Business', 'ވިޔަފާރި އިތުރުކުރޭ'),
                style: style(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBusinessDetails(Business business, double? distanceKm) {
    setState(() => _rememberBusiness(business));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessStorefrontPage(
          client: widget.user,
          business: business,
          isDhivehi: isDhivehi,
          distanceKm: distanceKm,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  children: [
                    UserAvatar(user: widget.user, radius: 42),
                    const SizedBox(height: 11),
                    Text(
                      widget.user.fullName,
                      textAlign: TextAlign.center,
                      style: style(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    Text('@${widget.user.username}', style: style()),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: Text(text('Home', 'މައި ޞަފްޙާ'), style: style()),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: Text(text('Settings', 'ސެޓިންގްސް'), style: style()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        user: widget.user,
                        isDhivehi: isDhivehi,
                        isDarkMode: widget.isDarkMode,
                        onLanguageChanged: (useDhivehi) {
                          widget.onLanguageChanged(
                            useDhivehi
                                ? AppLanguage.dhivehi
                                : AppLanguage.english,
                          );
                        },
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_business_rounded),
                title: Text(
                  text('Add Business', 'ވިޔަފާރި އިތުރުކުރޭ'),
                  style: style(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openAddBusiness();
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag_rounded),
                title: Text(
                  text('My Orders', 'އަހަރެންގެ އޯޑަރުތައް'),
                  style: style(),
                ),
                subtitle: Text(
                  text(
                    'Check payment verification',
                    'ފައިސާ ވެރިފައިކުރިތޯ ބަލާ',
                  ),
                  style: style(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientOrdersPage(
                        client: widget.user,
                        isDhivehi: isDhivehi,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded),
                title: Text(text('Inform Me', 'އަންގާދީ'), style: style()),
                subtitle: Text(
                  text('Check approval status', 'ހުއްދަގެ ހާލަތު ބަލާ'),
                  style: style(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MySubmissionsPage(
                        user: widget.user,
                        isDhivehi: isDhivehi,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_rounded),
                title: Text(text('About Us', 'އަހަރެމެންގެ މަޢުލޫމާތު'),
                    style: style()),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'EHFASS Viyafaari',
                    applicationVersion: '1.0.0',
                    applicationIcon: const AppLogo(height: 52),
                    children: [
                      Text(
                        text(
                          'This app helps people discover approved businesses across the Maldives.',
                          'މި އެޕްއިން ރާއްޖޭގެ ހުއްދަދެވިފައިވާ ފިހާރަތައް ހޯދައިދެއެވެ.',
                        ),
                        style: style(),
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text(
                  text('Log Out', 'ލޮގްއައުޓް'),
                  style: style(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.instance.signOut();
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(18),
                child:
                    Text('v1.0.0', style: style(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocatedBusiness {
  const _LocatedBusiness({
    required this.business,
    required this.distanceKm,
  });

  final Business business;
  final double? distanceKm;
}

class _AdvertisementBanner {
  const _AdvertisementBanner({
    required this.titleEnglish,
    required this.titleDhivehi,
    required this.descriptionEnglish,
    required this.descriptionDhivehi,
    required this.icon,
    required this.colors,
  });

  final String titleEnglish;
  final String titleDhivehi;
  final String descriptionEnglish;
  final String descriptionDhivehi;
  final IconData icon;
  final List<Color> colors;
}

class _HomeCategory {
  const _HomeCategory(this.name, this.icon);

  final String name;
  final IconData icon;
}

const List<_HomeCategory> _productCategoriesForHome = <_HomeCategory>[
  _HomeCategory('Apparel & Accessories', Icons.checkroom_rounded),
  _HomeCategory('Electronics & Office', Icons.devices_rounded),
  _HomeCategory('Home, Garden & Tools', Icons.handyman_rounded),
  _HomeCategory('Health & Beauty', Icons.spa_rounded),
  _HomeCategory('Sports & Outdoors', Icons.sports_soccer_rounded),
  _HomeCategory('Toys & Hobbies', Icons.toys_rounded),
  _HomeCategory('Food and Beverage', Icons.restaurant_rounded),
  _HomeCategory('Other', Icons.category_rounded),
];

const List<_HomeCategory> _serviceCategoriesForHome = <_HomeCategory>[
  _HomeCategory('Accounting & Financial', Icons.account_balance_wallet_rounded),
  _HomeCategory('Legal Services', Icons.gavel_rounded),
  _HomeCategory('Consulting', Icons.groups_rounded),
  _HomeCategory('Administrative', Icons.assignment_rounded),
  _HomeCategory('IT & Cloud Services', Icons.cloud_rounded),
  _HomeCategory('Telecommunications', Icons.phone_in_talk_rounded),
  _HomeCategory('Marketing & Media', Icons.campaign_rounded),
  _HomeCategory('Construction & Engineering', Icons.engineering_rounded),
  _HomeCategory('Maintenance & Repair', Icons.build_circle_rounded),
  _HomeCategory('Cleaning Services', Icons.cleaning_services_rounded),
  _HomeCategory('Accommodation', Icons.hotel_rounded),
  _HomeCategory('Food & Beverage', Icons.local_dining_rounded),
  _HomeCategory('Transportation', Icons.local_shipping_rounded),
  _HomeCategory('Healthcare', Icons.health_and_safety_rounded),
  _HomeCategory('Social & Community Care', Icons.volunteer_activism_rounded),
  _HomeCategory('Education', Icons.school_rounded),
  _HomeCategory('Wellness & Beauty', Icons.self_improvement_rounded),
  _HomeCategory('Other', Icons.more_horiz_rounded),
];

const List<_HomeCategory> _homeCategories = <_HomeCategory>[
  _HomeCategory('Food and Beverage', Icons.restaurant_rounded),
  _HomeCategory('Electronics & Office', Icons.devices_rounded),
  _HomeCategory('Transportation', Icons.local_shipping_rounded),
  _HomeCategory('Health & Beauty', Icons.spa_rounded),
  _HomeCategory('Maintenance & Repair', Icons.build_circle_rounded),
  _HomeCategory('Education', Icons.school_rounded),
  _HomeCategory('Apparel & Accessories', Icons.checkroom_rounded),
  _HomeCategory('Accommodation', Icons.hotel_rounded),
];
