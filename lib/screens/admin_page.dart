import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/advertisement_request.dart';
import '../models/app_user.dart';
import '../models/business.dart';
import '../models/home_advertisement.dart';
import '../models/promotion_request.dart';
import '../services/advertisement_service.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../services/home_advertisement_service.dart';
import '../services/promotion_service.dart';
import '../utils/image_crop_helper.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.admin,
    required this.isDhivehi,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final AppUser admin;
  final bool isDhivehi;
  final bool isDarkMode;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _businessFilter = 'all';
  bool _creatingHomeAdvertisement = false;

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

  Color statusColor(String status) {
    return switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };
  }

  String statusText(String status) {
    return switch (status) {
      'approved' => text('Approved', 'ހުއްދަދެވިފައި'),
      'rejected' => text('Rejected', 'ރިޖެކްޓް'),
      _ => text('Pending', 'ޕެންޑިންގް'),
    };
  }

  Future<void> _approveBusiness(Business business) async {
    final approved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _BusinessLoginApprovalPage(
          business: business,
          isDhivehi: widget.isDhivehi,
        ),
      ),
    );

    if (!mounted || approved != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          '${business.businessName} ${text('is active and its business login has been created.', 'އެކްޓިވްވެ، ވިޔަފާރީގެ ލޮގިން ހެދިއްޖެ.')} ',
          style: style(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _rejectBusiness(Business business) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection:
              widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              text('Reject Business', 'ވިޔަފާރި ރިޖެކްޓް ކުރޭ'),
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
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(dialogContext, controller.text.trim());
                },
                child: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();

    if (reason == null || reason.isEmpty) return;

    try {
      await BusinessService.instance.rejectBusiness(
        businessId: business.id,
        reason: reason,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _updateAdvertisement(
    AdvertisementRequestModel request,
    String status,
  ) async {
    String rejectionReason = '';

    if (status == 'rejected') {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              text('Reject Advertisement', 'އިޢުލާން ރިޖެކްޓް ކުރޭ'),
              style: style(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: text('Reason', 'ސަބަބު'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    Navigator.pop(dialogContext, controller.text.trim());
                  }
                },
                child: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
              ),
            ],
          );
        },
      );
      controller.dispose();
      if (result == null) return;
      rejectionReason = result;
    }

    try {
      await AdvertisementService.instance.updateStatus(
        requestId: request.id,
        status: status,
        rejectionReason: rejectionReason,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createHomeAdvertisement() async {
    final formKey = GlobalKey<FormState>();
    final titleEnglishController = TextEditingController();
    final titleDhivehiController = TextEditingController();
    final descriptionEnglishController = TextEditingController();
    final descriptionDhivehiController = TextEditingController();
    final sortOrderController = TextEditingController(text: '0');

    Uint8List? imageBytes;
    String? imageFileName;
    String? imageError;
    bool isActive = true;

    final result = await showDialog<_HomeAdvertisementDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickImage() async {
              final cropped = await pickImageCropAndSet(
                context: context,
                picker: ImagePicker(),
                isDhivehi: widget.isDhivehi,
                title: text('Crop Banner Image', 'ބެނަރ ފޮޓޯ ކްރޮޕް ކުރޭ'),
                initialMode: ImageCropMode.wide,
                imageQuality: 85,
                maxWidth: 1600,
              );

              if (cropped == null) return;

              setDialogState(() {
                imageBytes = cropped.bytes;
                imageFileName = cropped.fileName;
                imageError = null;
              });
            }

            return Directionality(
              textDirection:
                  widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                title: Text(
                  text('Create Home Advertisement', 'މައި އިޢުލާން ހަދާ'),
                  style: style(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: 520,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.image_rounded),
                            label: Text(
                              imageFileName == null
                                  ? text(
                                      'Choose Banner Image', 'ބެނަރ ފޮޓޯ ހޮވާ')
                                  : imageFileName!,
                              style: style(),
                            ),
                          ),
                          if (imageBytes != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                imageBytes!,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          if (imageError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              imageError!,
                              style: style(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: titleEnglishController,
                            decoration: InputDecoration(
                              labelText:
                                  text('English Title', 'އިނގިރޭސި ސުރުޚީ'),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return text(
                                    'Enter a title.', 'ސުރުޚީ ލިޔުއްވާ.');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: titleDhivehiController,
                            style: const TextStyle(fontFamily: 'Faruma'),
                            decoration: InputDecoration(
                              labelText: text('Dhivehi Title', 'ދިވެހި ސުރުޚީ'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionEnglishController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: text(
                                  'English Description', 'އިނގިރޭސި ތަފްސީލު'),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return text(
                                  'Enter a description.',
                                  'ތަފްސީލު ލިޔުއްވާ.',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionDhivehiController,
                            minLines: 2,
                            maxLines: 3,
                            style: const TextStyle(fontFamily: 'Faruma'),
                            decoration: InputDecoration(
                              labelText: text(
                                  'Dhivehi Description', 'ދިވެހި ތަފްސީލު'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sortOrderController,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: text('Sort Order', 'ތަރުތީބު'),
                              helperText: text(
                                'Lower number shows first.',
                                'ކުޑަ ނަންބަރު ކުރިން ފެންނާނެ.',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: isActive,
                            onChanged: (value) {
                              setDialogState(() => isActive = value);
                            },
                            title: Text(
                              text('Show on Client Home Page',
                                  'ކްލައިންޓް ހޯމްގައި ދައްކާ'),
                              style: style(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (imageBytes == null || imageFileName == null) {
                        setDialogState(() {
                          imageError = text(
                            'Choose a banner image before creating the advertisement.',
                            'އިޢުލާން ހެދުމުގެ ކުރިން ބެނަރ ފޮޓޯއެއް ހޮވާ.',
                          );
                        });
                        return;
                      }

                      if (!formKey.currentState!.validate()) return;

                      Navigator.pop(
                        dialogContext,
                        _HomeAdvertisementDraft(
                          titleEnglish: titleEnglishController.text,
                          titleDhivehi: titleDhivehiController.text,
                          descriptionEnglish: descriptionEnglishController.text,
                          descriptionDhivehi: descriptionDhivehiController.text,
                          imageBytes: imageBytes,
                          imageFileName: imageFileName,
                          isActive: isActive,
                          sortOrder:
                              int.tryParse(sortOrderController.text.trim()) ??
                                  0,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(text('Create', 'ހަދާ'), style: style()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleEnglishController.dispose();
    titleDhivehiController.dispose();
    descriptionEnglishController.dispose();
    descriptionDhivehiController.dispose();
    sortOrderController.dispose();

    if (result == null) return;

    setState(() => _creatingHomeAdvertisement = true);

    try {
      await HomeAdvertisementService.instance.createAdvertisement(
        admin: widget.admin,
        titleEnglish: result.titleEnglish,
        titleDhivehi: result.titleDhivehi,
        descriptionEnglish: result.descriptionEnglish,
        descriptionDhivehi: result.descriptionDhivehi,
        imageBytes: result.imageBytes,
        imageFileName: result.imageFileName,
        isActive: result.isActive,
        sortOrder: result.sortOrder,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text('Advertisement added to client home page.',
                'އިޢުލާން ކްލައިންޓް ހޯމްއަށް އިތުރުވެއްޖެ.'),
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _creatingHomeAdvertisement = false);
    }
  }

  Future<void> _deleteHomeAdvertisement(
    HomeAdvertisement advertisement,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            text('Delete Advertisement', 'އިޢުލާން ޑިލީޓް ކުރޭ'),
            style: style(fontWeight: FontWeight.bold),
          ),
          content: Text(
            text(
              'Are you sure you want to delete this advertisement?',
              'މި އިޢުލާން ޑިލީޓްކުރަން ޔަގީންތޯ؟',
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
              child: Text(text('Delete', 'ޑިލީޓް'), style: style()),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await HomeAdvertisementService.instance.deleteAdvertisement(
        advertisement,
      );
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('$error', style: style(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text('Admin Dashboard', 'އެޑްމިން ޑޭޝްބޯޑް'),
                  style: style(fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.admin.fullName,
                  style: style(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: text('Change mode', 'މޯޑް ބަދަލުކުރޭ'),
                onPressed: () {
                  widget.onThemeChanged(!widget.isDarkMode);
                },
                icon: Icon(
                  widget.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
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
                icon: const Icon(Icons.language_rounded),
              ),
              IconButton(
                tooltip: text('Log Out', 'ލޮގްއައުޓް'),
                onPressed: () async {
                  await AuthService.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(
                  icon: const Icon(Icons.dashboard_rounded),
                  text: text('Overview', 'ޚުލާޞާ'),
                ),
                Tab(
                  icon: const Icon(Icons.store_rounded),
                  text: text('Businesses', 'ވިޔަފާރިތައް'),
                ),
                Tab(
                  icon: const Icon(Icons.people_rounded),
                  text: text('Clients', 'ކްލައިންޓުން'),
                ),
                Tab(
                  icon: const Icon(Icons.campaign_rounded),
                  text: text('Advertisements', 'އިޢުލާންތައް'),
                ),
                Tab(
                  icon: const Icon(Icons.slideshow_rounded),
                  text: text('Home Ads', 'މައި އިޢުލާން'),
                ),
                Tab(
                  icon: const Icon(Icons.workspace_premium_rounded),
                  text: text('Promotions', 'ޕްރޮމޯޝަން'),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildOverview(),
              _buildBusinesses(),
              _buildClients(),
              _buildAdvertisements(),
              _buildHomeAdvertisements(),
              _buildPromotionRequests(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return StreamBuilder<List<AppUser>>(
      stream: BusinessService.instance.watchClients(),
      builder: (context, userSnapshot) {
        return StreamBuilder<List<Business>>(
          stream: BusinessService.instance.watchAllBusinesses(),
          builder: (context, businessSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting ||
                businessSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasError) {
              return Center(child: Text(userSnapshot.error.toString()));
            }
            if (businessSnapshot.hasError) {
              return Center(child: Text(businessSnapshot.error.toString()));
            }

            final clients = userSnapshot.data ?? const <AppUser>[];
            final businesses = businessSnapshot.data ?? const <Business>[];
            final pending = businesses.where((item) => item.isPending).toList();
            final approved = businesses.where((item) => item.isApproved).length;
            final rejected = businesses.where((item) => item.isRejected).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cardWidth = width >= 900
                        ? (width - 36) / 4
                        : width >= 520
                            ? (width - 12) / 2
                            : width;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _summaryCard(
                          width: cardWidth,
                          icon: Icons.people_rounded,
                          title: text(
                              'Registered Clients', 'ރަޖިސްޓަރޑް ކްލައިންޓުން'),
                          value: clients.length,
                          color: Colors.blue,
                        ),
                        _summaryCard(
                          width: cardWidth,
                          icon: Icons.storefront_rounded,
                          title: text('All Businesses', 'ހުރިހާ ވިޔަފާރި'),
                          value: businesses.length,
                          color: Colors.purple,
                        ),
                        _summaryCard(
                          width: cardWidth,
                          icon: Icons.pending_actions_rounded,
                          title:
                              text('Pending Approval', 'ހުއްދައަށް ޕެންޑިންގް'),
                          value: pending.length,
                          color: Colors.orange,
                        ),
                        _summaryCard(
                          width: cardWidth,
                          icon: Icons.verified_rounded,
                          title: text('Active Businesses', 'އެކްޓިވް ވިޔަފާރި'),
                          value: approved,
                          color: Colors.green,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                Text(
                  text('Additional Status', 'އިތުރު ހާލަތު'),
                  style: style(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.cancel_rounded, color: Colors.red),
                    title: Text(
                      text('Rejected Businesses', 'ރިޖެކްޓް ވިޔަފާރިތައް'),
                      style: style(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      rejected.toString(),
                      style: style(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  text('Waiting for Approval', 'ހުއްދައަށް މަޑުކުރާ'),
                  style: style(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (pending.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        text(
                          'No pending business requests.',
                          'ޕެންޑިންގް ވިޔަފާރި ރިކުއެސްޓެއް ނެތް.',
                        ),
                        style: style(),
                      ),
                    ),
                  )
                else
                  ...pending.take(5).map(_businessTile),
              ],
            );
          },
        );
      },
    );
  }

  Widget _summaryCard({
    required double width,
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: style(fontSize: 29, fontWeight: FontWeight.w900),
                    ),
                    Text(title, style: style(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinesses() {
    return StreamBuilder<List<Business>>(
      stream: BusinessService.instance.watchAllBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final all = snapshot.data ?? const <Business>[];
        final filtered = _businessFilter == 'all'
            ? all
            : all.where((item) => item.status == _businessFilter).toList();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
              child: Row(
                children: [
                  _filterChip('all', text('All', 'ހުރިހާ')),
                  _filterChip('pending', text('Pending', 'ޕެންޑިންގް')),
                  _filterChip('approved', text('Approved', 'ހުއްދަދެވިފައި')),
                  _filterChip('rejected', text('Rejected', 'ރިޖެކްޓް')),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        text('No businesses found.', 'ވިޔަފާރިއެއް ނުފެނުނު.'),
                        style: style(fontSize: 17),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) => _businessTile(filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        type: MaterialType.transparency,
        child: ChoiceChip(
          selected: _businessFilter == value,
          label: Text(label, style: style()),
          onSelected: (_) => setState(() => _businessFilter = value),
        ),
      ),
    );
  }

  Widget _businessTile(Business business) {
    final color = statusColor(business.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: business.logoUrl.isEmpty
            ? CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(Icons.store_rounded, color: color),
              )
            : CircleAvatar(backgroundImage: NetworkImage(business.logoUrl)),
        title: Text(
          business.businessName,
          style: style(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${business.ownerName} • ${statusText(business.status)}',
          style: style(color: color, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _adminDetail(Icons.person_rounded, text('Owner', 'ވެރިޔާ'),
              business.ownerName),
          _adminDetail(Icons.email_rounded,
              text('Owner Email', 'ވެރިޔާގެ އީމެއިލް'), business.ownerEmail),
          _adminDetail(Icons.category_rounded, text('Category', 'ބާވަތް'),
              business.category),
          _adminDetail(Icons.location_on_rounded, text('Island', 'ރަށް'),
              business.island),
          _adminDetail(Icons.phone_rounded, text('Contact', 'ގުޅޭނެ ނަންބަރު'),
              business.contactNumber),
          _adminDetail(Icons.email_outlined,
              text('Business Email', 'ވިޔަފާރީގެ އީމެއިލް'), business.email),
          if (business.businessLoginEmail.isNotEmpty)
            _adminDetail(
              Icons.admin_panel_settings_rounded,
              text('Business Login Email', 'ވިޔަފާރީގެ ލޮގިން އީމެއިލް'),
              business.businessLoginEmail,
            ),
          _adminDetail(
            Icons.delivery_dining_rounded,
            text('Delivery', 'ޑެލިވަރީ'),
            business.deliveryAvailable
                ? (business.deliveryDetails.isEmpty
                    ? text('Available', 'ލިބެން ހުރޭ')
                    : business.deliveryDetails)
                : text('Not available', 'ލިބެން ނެތް'),
          ),
          _adminDetail(Icons.description_rounded,
              text('Description', 'ތަފްޞީލު'), business.description),
          if (business.rejectionReason.isNotEmpty)
            _adminDetail(
                Icons.report_rounded,
                text('Rejection Reason', 'ރިޖެކްޓް ސަބަބު'),
                business.rejectionReason),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: business.hasBusinessLogin
                      ? null
                      : () => _approveBusiness(business),
                  icon: Icon(
                    business.hasBusinessLogin
                        ? Icons.verified_user_rounded
                        : Icons.check_circle_rounded,
                  ),
                  label: Text(
                    business.hasBusinessLogin
                        ? text('Login Created', 'ލޮގިން ހެދިފައި')
                        : business.isApproved
                            ? text('Create Login', 'ލޮގިން ހަދާ')
                            : text(
                                'Approve & Create Login',
                                'ހުއްދަދީ ލޮގިން ހަދާ',
                              ),
                    style: style(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: business.isRejected || business.hasBusinessLogin
                      ? null
                      : () => _rejectBusiness(business),
                  icon: const Icon(Icons.cancel_rounded),
                  label: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminDetail(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: style(fontWeight: FontWeight.bold)),
      subtitle: Text(value.isEmpty ? '-' : value, style: style()),
    );
  }

  Widget _buildClients() {
    return StreamBuilder<List<AppUser>>(
      stream: BusinessService.instance.watchClients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final clients = snapshot.data ?? const <AppUser>[];
        if (clients.isEmpty) {
          return Center(
            child: Text(
              text('No registered clients.', 'ރަޖިސްޓަރޑް ކްލައިންޓެއް ނެތް.'),
              style: style(fontSize: 17),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: clients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final client = clients[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    client.fullName.isNotEmpty
                        ? client.fullName[0].toUpperCase()
                        : 'U',
                  ),
                ),
                title: Text(
                  client.fullName,
                  style: style(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '@${client.username}\n${client.email}\n${client.phone}',
                  style: style(),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeAdvertisements() {
    return StreamBuilder<List<HomeAdvertisement>>(
      stream: HomeAdvertisementService.instance.watchAll(),
      builder: (context, snapshot) {
        final advertisements = snapshot.data ?? const <HomeAdvertisement>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      text('Client Home Advertisements',
                          'ކްލައިންޓް ހޯމް އިޢުލާންތައް'),
                      style: style(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text(
                        'Advertisements created here will appear in the banner carousel on the client home page.',
                        'މިތާ ހަދާ އިޢުލާންތައް ކްލައިންޓް ހޯމް ޕޭޖްގެ ބެނަރގައި ފެންނާނެ.',
                      ),
                      style: style(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _creatingHomeAdvertisement
                            ? null
                            : _createHomeAdvertisement,
                        icon: _creatingHomeAdvertisement
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate_rounded),
                        label: Text(
                          text('Add Home Advertisement',
                              'މައި އިޢުލާން އިތުރުކުރޭ'),
                          style: style(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snapshot.error.toString(), style: style()),
                ),
              )
            else if (advertisements.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    text(
                      'No home advertisements have been added yet.',
                      'މިހާރު ހަމައަށް މައި އިޢުލާނެއް އިތުރުކޮށްފައެއް ނެތް.',
                    ),
                    style: style(),
                  ),
                ),
              )
            else
              ...advertisements.map((advertisement) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 110,
                            height: 80,
                            child: advertisement.imageUrl.isEmpty
                                ? Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: const Icon(Icons.campaign_rounded),
                                  )
                                : Image.network(
                                    advertisement.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_rounded,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                advertisement.titleEnglish,
                                style: style(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (advertisement.titleDhivehi.isNotEmpty)
                                Text(
                                  advertisement.titleDhivehi,
                                  style: const TextStyle(fontFamily: 'Faruma'),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                advertisement.descriptionEnglish,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: style(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${text('Sort order', 'ތަރުތީބު')}: ${advertisement.sortOrder}',
                                style: style(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Switch(
                              value: advertisement.isActive,
                              onChanged: (value) async {
                                try {
                                  await HomeAdvertisementService.instance
                                      .updateActive(
                                    advertisementId: advertisement.id,
                                    isActive: value,
                                  );
                                } catch (error) {
                                  _showError(error);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: text('Delete', 'ޑިލީޓް'),
                              onPressed: () => _deleteHomeAdvertisement(
                                advertisement,
                              ),
                              icon: const Icon(
                                Icons.delete_rounded,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }


  Widget _buildPromotionRequests() {
    return StreamBuilder<List<PromotionRequestModel>>(
      stream: PromotionService.instance.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString(), style: style()));
        }
        final requests = snapshot.data ?? const <PromotionRequestModel>[];
        if (requests.isEmpty) {
          return Center(
            child: Text(
              text('No promotion requests.', 'ޕްރޮމޯޝަން ރިކުއެސްޓެއް ނެތް.'),
              style: style(fontSize: 17),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final color = request.isApproved
                ? Colors.green
                : request.isRejected
                    ? Colors.red
                    : Colors.orange;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(Icons.workspace_premium_rounded, color: color),
                ),
                title: Text(request.planLabel, style: style(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${request.businessName} • ${statusText(request.status)}',
                  style: style(color: color, fontWeight: FontWeight.w700),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _adminDetail(Icons.storefront_rounded, text('Business', 'ވިޔަފާރި'), request.businessName),
                  _adminDetail(Icons.workspace_premium_rounded, text('Plan', 'ޕްލޭން'), request.planLabel),
                  if (request.note.isNotEmpty)
                    _adminDetail(Icons.notes_rounded, text('Seller note', 'ސެލަރ ނޯޓް'), request.note),
                  if (request.rejectionReason.isNotEmpty)
                    _adminDetail(Icons.report_rounded, text('Rejection Reason', 'ރިޖެކްޓް ސަބަބު'), request.rejectionReason),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: request.isApproved
                              ? null
                              : () => _updatePromotionRequest(request, 'approved'),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(text('Approve', 'ހުއްދަދޭ'), style: style()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: request.isRejected
                              ? null
                              : () => _updatePromotionRequest(request, 'rejected'),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updatePromotionRequest(
    PromotionRequestModel request,
    String status,
  ) async {
    var rejectionReason = '';
    if (status == 'rejected') {
      final controller = TextEditingController();
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(text('Reject Promotion', 'ޕްރޮމޯޝަން ރިޖެކްޓް'), style: style(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(labelText: text('Reason', 'ސަބަބު')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
            ),
          ],
        ),
      );
      controller.dispose();
      if (reason == null || reason.isEmpty) return;
      rejectionReason = reason;
    }

    try {
      await PromotionService.instance.updateStatus(
        request: request,
        status: status,
        rejectionReason: rejectionReason,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Widget _buildAdvertisements() {
    return StreamBuilder<List<AdvertisementRequestModel>>(
      stream: AdvertisementService.instance.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final requests = snapshot.data ?? const <AdvertisementRequestModel>[];
        if (requests.isEmpty) {
          return Center(
            child: Text(
              text('No advertisement requests.',
                  'އިޢުލާނުގެ ރިކުއެސްޓެއް ނެތް.'),
              style: style(fontSize: 17),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (_, index) {
            final request = requests[index];
            final color = statusColor(request.status);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(Icons.campaign_rounded, color: color),
                ),
                title: Text(
                  request.title,
                  style: style(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${request.businessName} • ${statusText(request.status)}',
                  style: style(color: color),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _adminDetail(
                      Icons.person_rounded,
                      text('Requested By', 'ރިކުއެސްޓް ކުރީ'),
                      request.ownerName),
                  _adminDetail(
                      Icons.phone_rounded,
                      text('Contact', 'ގުޅޭނެ ނަންބަރު'),
                      request.contactNumber),
                  _adminDetail(Icons.schedule_rounded,
                      text('Duration', 'މުއްދަތު'), request.duration),
                  _adminDetail(Icons.description_rounded,
                      text('Details', 'ތަފްޞީލު'), request.details),
                  if (request.rejectionReason.isNotEmpty)
                    _adminDetail(
                        Icons.report_rounded,
                        text('Rejection Reason', 'ރިޖެކްޓް ސަބަބު'),
                        request.rejectionReason),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: request.status == 'approved'
                              ? null
                              : () => _updateAdvertisement(request, 'approved'),
                          icon: const Icon(Icons.check_rounded),
                          label:
                              Text(text('Approve', 'ހުއްދަދޭ'), style: style()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: request.status == 'rejected'
                              ? null
                              : () => _updateAdvertisement(request, 'rejected'),
                          icon: const Icon(Icons.close_rounded),
                          label:
                              Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


class _BusinessLoginApprovalPage extends StatefulWidget {
  const _BusinessLoginApprovalPage({
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  @override
  State<_BusinessLoginApprovalPage> createState() =>
      _BusinessLoginApprovalPageState();
}

class _BusinessLoginApprovalPageState extends State<_BusinessLoginApprovalPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.business.businessLoginEmail.isNotEmpty
          ? widget.business.businessLoginEmail
          : widget.business.email,
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _submitting) return;

    setState(() => _submitting = true);

    try {
      await BusinessService.instance.approveBusinessAndCreateLogin(
        business: widget.business,
        loginEmail: _emailController.text.trim(),
        temporaryPassword: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
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

  @override
  Widget build(BuildContext context) {
    final business = widget.business;

    return Directionality(
      textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            business.isApproved
                ? text('Create Business Login', 'ވިޔަފާރީގެ ލޮގިން ހަދާ')
                : text('Approve and Create Login', 'ހުއްދަދީ ލޮގިން ހަދާ'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: business.logoUrl.isEmpty
                                    ? null
                                    : NetworkImage(business.logoUrl),
                                child: business.logoUrl.isEmpty
                                    ? const Icon(Icons.storefront_rounded)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      business.businessName,
                                      style: style(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${business.category} • ${business.island}',
                                      style: style(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.45),
                            ),
                            child: Text(
                              text(
                                'This page creates a separate seller login without changing the current admin login session.',
                                'މި ޕޭޖުން އެޑްމިން ލޮގިން ބަދަލުނުކޮށް ވަކި ސެލަރ ލޮގިން ހަދާނެ.',
                              ),
                              style: style(fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            enabled: !_submitting,
                            decoration: InputDecoration(
                              labelText: text(
                                'Business Login Email',
                                'ވިޔަފާރީގެ ލޮގިން އީމެއިލް',
                              ),
                              prefixIcon: const Icon(Icons.email_rounded),
                            ),
                            validator: (value) {
                              final clean = value?.trim() ?? '';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(clean)) {
                                return text(
                                  'Enter a valid email.',
                                  'ރަނގަޅު އީމެއިލެއް ލިޔުއްވާ.',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            textDirection: TextDirection.ltr,
                            enabled: !_submitting,
                            decoration: InputDecoration(
                              labelText: text(
                                'Temporary Password',
                                'ވަގުތީ ޕާސްވޯޑް',
                              ),
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _hidePassword = !_hidePassword;
                                        });
                                      },
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').length < 8) {
                                return text(
                                  'Use at least 8 characters.',
                                  'މަދުވެގެން 8 އަކުރު ބޭނުންކުރައްވާ.',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _hideConfirmPassword,
                            textDirection: TextDirection.ltr,
                            enabled: !_submitting,
                            decoration: InputDecoration(
                              labelText: text(
                                'Confirm Password',
                                'ޕާސްވޯޑް ޔަގީންކުރޭ',
                              ),
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _hideConfirmPassword =
                                              !_hideConfirmPassword;
                                        });
                                      },
                                icon: Icon(
                                  _hideConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return text(
                                  'Passwords do not match.',
                                  'ދެ ޕާސްވޯޑް އެއްގޮތެއް ނޫން.',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.verified_user_rounded),
                              label: Text(
                                _submitting
                                    ? text('Creating...', 'ހަދަނީ...')
                                    : business.isApproved
                                        ? text('Create Login', 'ލޮގިން ހަދާ')
                                        : text(
                                            'Approve & Create Login',
                                            'ހުއްދަދީ ލޮގިން ހަދާ',
                                          ),
                                style: style(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAdvertisementDraft {
  const _HomeAdvertisementDraft({
    required this.titleEnglish,
    required this.titleDhivehi,
    required this.descriptionEnglish,
    required this.descriptionDhivehi,
    required this.imageBytes,
    required this.imageFileName,
    required this.isActive,
    required this.sortOrder,
  });

  final String titleEnglish;
  final String titleDhivehi;
  final String descriptionEnglish;
  final String descriptionDhivehi;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final bool isActive;
  final int sortOrder;
}
