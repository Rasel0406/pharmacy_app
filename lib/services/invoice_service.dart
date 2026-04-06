import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/pharmacy_provider.dart';

class InvoiceService {
  InvoiceService._();

  static final InvoiceService instance = InvoiceService._();

  Future<void> shareInvoicePdf(OrderReceipt order) async {
    final pw.Document doc = pw.Document();

    final String dateText =
        DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return <pw.Widget>[
            pw.Text(
              'LazzPharma Invoice',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Order ID: ${order.orderId}'),
            pw.Text('Date: $dateText'),
            pw.Text('Customer: ${order.customerName}'),
            pw.Text('Phone: ${order.phone}'),
            pw.Text('Address: ${order.deliveryAddress}'),
            pw.Text('Payment: ${order.paymentMethod}'),
            if (order.couponCode.isNotEmpty)
              pw.Text('Coupon: ${order.couponCode}'),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue100),
              headers: const <String>[
                'Medicine',
                'Qty',
                'Unit Price',
                'Line Total'
              ],
              data: order.items
                  .map(
                    (item) => <String>[
                      item.medicineName,
                      item.quantity.toString(),
                      'BDT ${item.unitPrice.toStringAsFixed(2)}',
                      'BDT ${item.lineTotal.toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('Subtotal: BDT ${order.subtotal.toStringAsFixed(2)}'),
                  pw.Text(
                      'Delivery: BDT ${order.deliveryFee.toStringAsFixed(2)}'),
                  if (order.discount > 0)
                    pw.Text(
                        'Discount: -BDT ${order.discount.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total: BDT ${order.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'invoice_${order.orderId}.pdf',
    );
  }
}
