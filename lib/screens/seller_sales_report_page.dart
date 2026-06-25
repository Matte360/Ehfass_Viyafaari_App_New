import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/purchase_order.dart';
import '../models/quotation_request.dart';
import '../services/marketplace_service.dart';

class SellerSalesReportPage extends StatelessWidget {
  const SellerSalesReportPage({
    super.key,
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
    return StreamBuilder<List<PurchaseOrder>>(
      stream: MarketplaceService.instance.watchOrdersForBusiness(business.id),
      builder: (context, orderSnapshot) {
        return StreamBuilder<List<QuotationRequest>>(
          stream: MarketplaceService.instance.watchQuotationRequestsForBusiness(
            business.id,
          ),
          builder: (context, quoteSnapshot) {
            if (orderSnapshot.connectionState == ConnectionState.waiting ||
                quoteSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (orderSnapshot.hasError || quoteSnapshot.hasError) {
              return Center(
                child: Text(
                  (orderSnapshot.error ?? quoteSnapshot.error).toString(),
                ),
              );
            }

            final orders = orderSnapshot.data ?? const <PurchaseOrder>[];
            final quotes = quoteSnapshot.data ?? const <QuotationRequest>[];
            final countedOrders = orders.where((order) => order.isSaleCounted).toList();
            final pendingOrders = orders.where((order) => order.isPending).length;
            final rejectedOrders = orders.where((order) => order.isRejected).length;
            final totalSales = countedOrders.fold<double>(
              0,
              (sum, order) => sum + order.totalMvr,
            );
            final soldQty = countedOrders.fold<int>(
              0,
              (sum, order) => sum + order.quantity,
            );
            final acceptedQuotes = quotes.where((quote) => quote.isAccepted).toList();
            final quoteValue = acceptedQuotes.fold<double>(
              0,
              (sum, quote) => sum + quote.finalTotalMvr,
            );

            final itemTotals = <String, _ItemSale>{};
            for (final order in countedOrders) {
              final current = itemTotals[order.itemId] ??
                  _ItemSale(name: order.itemName, quantity: 0, amount: 0);
              itemTotals[order.itemId] = current.copyWith(
                quantity: current.quantity + order.quantity,
                amount: current.amount + order.totalMvr,
              );
            }
            final topItems = itemTotals.values.toList()
              ..sort((a, b) => b.amount.compareTo(a.amount));

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  text('Sales Report', 'ސޭލްސް ރިޕޯޓް'),
                  style: style(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  text(
                    'Live report from verified and progressed orders.',
                    'ވެރިފައިޑް އަދި ކުރިއަށްދާ އޯޑަރުތަކުން ލައިވް ރިޕޯޓް.',
                  ),
                  style: style(height: 1.45),
                ),
                const SizedBox(height: 16),
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
                          Icons.payments_rounded,
                          text('Order sales', 'އޯޑަރ ސޭލްސް'),
                          'MVR ${totalSales.toStringAsFixed(2)}',
                          Colors.green,
                        ),
                        _stat(
                          context,
                          width,
                          Icons.inventory_2_rounded,
                          text('Sold quantity', 'ވިއްކި ޢަދަދު'),
                          soldQty.toString(),
                          Colors.blue,
                        ),
                        _stat(
                          context,
                          width,
                          Icons.hourglass_top_rounded,
                          text('Pending orders', 'ޕެންޑިންގް އޯޑަރ'),
                          pendingOrders.toString(),
                          Colors.orange,
                        ),
                        _stat(
                          context,
                          width,
                          Icons.request_quote_rounded,
                          text('Accepted quotes', 'އެކްސެޕްޓް ކޯޓް'),
                          'MVR ${quoteValue.toStringAsFixed(2)}',
                          Colors.purple,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _sectionTitle(text('Order status', 'އޯޑަރ ސްޓޭޓަސް')),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row(text('Verified / active orders', 'ވެރިފައިޑް / އެކްޓިވް'), countedOrders.length.toString()),
                        _row(text('Pending verification', 'ވެރިފިކޭޝަނަށް ޕެންޑިންގް'), pendingOrders.toString()),
                        _row(text('Rejected orders', 'ރިޖެކްޓް އޯޑަރ'), rejectedOrders.toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _sectionTitle(text('Top selling items', 'އެންމެ ގިނަ ވިއްކޭ މުދާ')),
                if (topItems.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        text(
                          'No verified sales yet.',
                          'އަދި ވެރިފައިޑް ސޭލެއް ނެތް.',
                        ),
                        textAlign: TextAlign.center,
                        style: style(),
                      ),
                    ),
                  )
                else
                  ...topItems.take(10).map(
                        (item) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.trending_up_rounded),
                            ),
                            title: Text(
                              item.name,
                              style: style(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text(
                              '${text('Quantity', 'ޢަދަދު')}: ${item.quantity}',
                              style: style(),
                            ),
                            trailing: Text(
                              'MVR ${item.amount.toStringAsFixed(2)}',
                              style: style(fontWeight: FontWeight.w900),
                            ),
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
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.13),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 11),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              Text(label, style: style(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: style(fontSize: 19, fontWeight: FontWeight.w900)),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style(fontWeight: FontWeight.bold))),
          Text(value, style: style(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ItemSale {
  const _ItemSale({
    required this.name,
    required this.quantity,
    required this.amount,
  });

  final String name;
  final int quantity;
  final double amount;

  _ItemSale copyWith({int? quantity, double? amount}) {
    return _ItemSale(
      name: name,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
    );
  }
}
