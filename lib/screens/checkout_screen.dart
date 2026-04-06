import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_provider.dart';
import 'order_summary_screen.dart';
import 'payment_processing_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.initialCouponCode = ''});

  final String initialCouponCode;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _mobileAccountController =
      TextEditingController();

  bool _prefilled = false;
  String _paymentMethod = 'bKash';
  String _appliedCouponCode = '';
  String? _selectedAddressId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) {
      return;
    }

    final PharmacyProvider provider = context.read<PharmacyProvider>();
    _nameController.text = provider.fullName;
    _phoneController.text = provider.phone;
    _addressController.text =
        provider.defaultAddress?.address ?? provider.address;

    if (provider.defaultAddress != null) {
      _selectedAddressId = provider.defaultAddress!.id;
    }

    _appliedCouponCode = widget.initialCouponCode.trim().toUpperCase();
    _couponController.text = _appliedCouponCode;
    _prefilled = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    _noteController.dispose();
    _mobileAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PharmacyProvider provider = context.watch<PharmacyProvider>();
    final CheckoutAmount amount =
        provider.calculateCheckout(couponCode: _appliedCouponCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: <Widget>[
              const Text(
                'Delivery Details',
                style: TextStyle(
                  color: Color(0xFF173E6C),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _cardSection(
                children: <Widget>[
                  if (provider.savedAddresses.isNotEmpty)
                    Column(
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          key: ValueKey<String?>(_selectedAddressId),
                          initialValue: _selectedAddressId,
                          decoration: const InputDecoration(
                            labelText: 'Saved Address',
                            border: OutlineInputBorder(),
                          ),
                          items: provider.savedAddresses
                              .map(
                                (address) => DropdownMenuItem<String>(
                                  value: address.id,
                                  child: Text(
                                    '${address.label}: ${address.address}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            final SavedAddress selected = provider
                                .savedAddresses
                                .firstWhere((item) => item.id == value);
                            setState(() {
                              _selectedAddressId = value;
                              _addressController.text = selected.address;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  _buildInputField(
                    controller: _nameController,
                    label: 'Customer Name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Customer name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (value) {
                      final String phone = (value ?? '').trim();
                      if (phone.isEmpty) {
                        return 'Phone is required';
                      }
                      if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(phone)) {
                        return 'Enter valid BD phone (01XXXXXXXXX)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _addressController,
                    label: 'Delivery Address',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Delivery address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _showQuickAddressDialog(context, provider),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add this as new saved address'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Payment Method',
                style: TextStyle(
                  color: Color(0xFF173E6C),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _cardSection(
                children: <Widget>[
                  _buildPaymentRadio('bKash'),
                  _buildPaymentRadio('Nagad'),
                  _buildPaymentRadio('Cash on Delivery'),
                  if (_paymentMethod == 'bKash' || _paymentMethod == 'Nagad')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildInputField(
                        controller: _mobileAccountController,
                        label: '$_paymentMethod Account Number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (value) {
                          if (_paymentMethod == 'Cash on Delivery') {
                            return null;
                          }

                          final String account = (value ?? '').trim();
                          if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(account)) {
                            return 'Enter valid $_paymentMethod account number';
                          }
                          return null;
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Promo & Note',
                style: TextStyle(
                  color: Color(0xFF173E6C),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _cardSection(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildInputField(
                          controller: _couponController,
                          label: 'Coupon Code',
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          final String code =
                              _couponController.text.trim().toUpperCase();
                          _couponController.text = code;
                          final CheckoutAmount preview =
                              provider.calculateCheckout(couponCode: code);

                          setState(() {
                            _appliedCouponCode = code;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                preview.discount > 0
                                    ? 'Coupon applied: ৳ ${preview.discount.toStringAsFixed(2)} off'
                                    : 'Coupon invalid বা discount নেই',
                              ),
                            ),
                          );
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Available: SAVE10, HEALTH5, FIRST20',
                    style: TextStyle(
                      color: Color(0xFF5B77A0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _noteController,
                    label: 'Order Note',
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _cardSection(
                children: <Widget>[
                  _summaryRow('Subtotal', amount.subtotal),
                  const SizedBox(height: 6),
                  _summaryRow('Delivery', amount.delivery),
                  if (amount.discount > 0) ...<Widget>[
                    const SizedBox(height: 6),
                    _summaryRow('Discount', -amount.discount),
                  ],
                  const Divider(height: 20),
                  _summaryRow('Grand Total', amount.total, isBold: true),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: provider.cartLines.isEmpty
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        final String paymentDetails = _paymentMethod ==
                                'Cash on Delivery'
                            ? 'Pay on delivery'
                            : '$_paymentMethod ${_mobileAccountController.text.trim()}';

                        final String customerName = _nameController.text.trim();
                        final String phone = _phoneController.text.trim();
                        final String address = _addressController.text.trim();
                        final String couponCode =
                            _appliedCouponCode.trim().toUpperCase();
                        final String note = _noteController.text.trim();

                        if (_paymentMethod == 'Cash on Delivery') {
                          final OrderReceipt order = await provider.placeOrder(
                            customerName: customerName,
                            phone: phone,
                            deliveryAddress: address,
                            paymentMethod: _paymentMethod,
                            paymentDetails: paymentDetails,
                            couponCode: couponCode,
                            discount: amount.discount,
                            note: note,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          if (provider.lastOrderSyncError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFC73B3B),
                                content: Text(provider.lastOrderSyncError!),
                              ),
                            );
                          }

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => OrderSummaryScreen(order: order),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PaymentProcessingScreen(
                              customerName: customerName,
                              phone: phone,
                              deliveryAddress: address,
                              paymentMethod: _paymentMethod,
                              paymentDetails: paymentDetails,
                              couponCode: couponCode,
                              discount: amount.discount,
                              note: note,
                              amount: amount.total,
                            ),
                          ),
                        );
                      },
                child: const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardSection({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE8F9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPaymentRadio(String method) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      title: Text(method),
      value: method,
      groupValue: _paymentMethod,
      activeColor: const Color(0xFF0F5FC2),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _paymentMethod = value;
          if (_paymentMethod == 'Cash on Delivery') {
            _mobileAccountController.clear();
          }
        });
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    final TextStyle style = TextStyle(
      color: const Color(0xFF1E4470),
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
      fontSize: isBold ? 19 : 15,
    );

    return Row(
      children: <Widget>[
        Text(label, style: style),
        const Spacer(),
        Text(
          '${value < 0 ? '-' : ''}৳ ${value.abs().toStringAsFixed(2)}',
          style: style,
        ),
      ],
    );
  }

  Future<void> _showQuickAddressDialog(
    BuildContext context,
    PharmacyProvider provider,
  ) async {
    final TextEditingController labelController =
        TextEditingController(text: 'Home');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save Address'),
          content: TextField(
            controller: labelController,
            decoration: const InputDecoration(
              labelText: 'Address Label',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String address = _addressController.text.trim();
                if (address.isEmpty) {
                  return;
                }

                await provider.addSavedAddress(
                  label: labelController.text.trim(),
                  address: address,
                  setAsDefault: provider.savedAddresses.isEmpty,
                );

                if (!mounted) {
                  return;
                }

                setState(() {
                  _selectedAddressId = provider.defaultAddress?.id;
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    labelController.dispose();
  }
}
