import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../services/business_service.dart';

class MySubmissionsPage extends StatelessWidget {
  const MySubmissionsPage({
    super.key,
    required this.user,
    required this.isDhivehi,
  });

  final AppUser user;
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

  Color statusColor(String status) {
    return switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };
  }

  String statusText(String status) {
    return switch (status) {
      'approved' => text('Approved and Active', 'ހުއްދަދީ އެކްޓިވް ކުރެވިފައި'),
      'rejected' => text('Rejected', 'ރިޖެކްޓް ކުރެވިފައި'),
      _ => text('Pending Admin Approval', 'އެޑްމިން ހުއްދައަށް ޕެންޑިންގް'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('My Business Submissions', 'އަހަރެންގެ ވިޔަފާރި ހުށަހެޅުންތައް'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: StreamBuilder<List<Business>>(
          stream: BusinessService.instance.watchBusinessesForOwner(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final businesses = snapshot.data ?? const <Business>[];
            if (businesses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_rounded, size: 75),
                      const SizedBox(height: 12),
                      Text(
                        text(
                          'You have not submitted a business yet.',
                          'ތިޔަ ހުށަހަޅާފައިވާ ވިޔަފާރިއެއް ނެތް.',
                        ),
                        textAlign: TextAlign.center,
                        style: style(fontSize: 17),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: businesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final business = businesses[index];
                final color = statusColor(business.status);

                return Card(
                  child: ExpansionTile(
                    leading: business.logoUrl.isEmpty
                        ? CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.14),
                            child: Icon(Icons.store_rounded, color: color),
                          )
                        : CircleAvatar(
                            backgroundImage: NetworkImage(business.logoUrl),
                          ),
                    title: Text(
                      business.businessName,
                      style: style(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      statusText(business.status),
                      style: style(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _detail(
                        Icons.category_rounded,
                        text('Category', 'ބާވަތް'),
                        business.category,
                      ),
                      _detail(
                        Icons.location_on_rounded,
                        text('Location', 'ތަން'),
                        business.island,
                      ),
                      _detail(
                        Icons.phone_rounded,
                        text('Contact', 'ގުޅޭނެ ނަންބަރު'),
                        business.contactNumber,
                      ),
                      if (business.isRejected &&
                          business.rejectionReason.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${text('Reason', 'ސަބަބު')}: ${business.rejectionReason}',
                            style: style(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: style(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: style()),
    );
  }
}
