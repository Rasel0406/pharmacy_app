import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_provider.dart';
import 'admin_order_list_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  bool _notifications = true;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) {
      return;
    }

    final PharmacyProvider provider = context.read<PharmacyProvider>();
    _nameController = TextEditingController(text: provider.fullName);
    _phoneController = TextEditingController(text: provider.phone);
    _emailController = TextEditingController(text: provider.email);
    _addressController = TextEditingController(text: provider.address);
    _notifications = provider.notificationsEnabled;
    _hydrated = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE8F9)),
              ),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF0F5FC2),
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          provider.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF163D6A),
                          ),
                        ),
                        Text(
                          provider.phone.isEmpty
                              ? 'Phone not set'
                              : provider.phone,
                          style: const TextStyle(color: Color(0xFF4C688A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _metricCard('Wishlist', '${provider.wishlistCount}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard('Orders', '${provider.orders.length}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard('Cart', '${provider.cartCount}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE8F9)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.admin_panel_settings_rounded,
                      color: Color(0xFF0F5FC2)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Admin Order Panel',
                      style: TextStyle(
                        color: Color(0xFF173E6C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminOrderListScreen(),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFF0F5FC2)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Loyalty Points: ${provider.orders.length * 10} pts',
                      style: const TextStyle(
                        color: Color(0xFF254D79),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _inputField(
                    controller: _nameController,
                    label: 'Full Name',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Phone required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _addressController,
                    label: 'Address',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _notifications,
                    title: const Text('Enable Notifications'),
                    onChanged: (value) {
                      setState(() => _notifications = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        await provider.saveProfile(
                          fullName: _nameController.text,
                          phone: _phoneController.text,
                          email: _emailController.text,
                          address: _addressController.text,
                          notificationsEnabled: _notifications,
                        );

                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile saved successfully')),
                        );
                      },
                      child: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Saved Addresses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF183E6B),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddressDialog(context, provider),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (provider.savedAddresses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No saved address yet.',
                  style: TextStyle(color: Color(0xFF48658A)),
                ),
              )
            else
              ...provider.savedAddresses.map(
                (addr) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDE8F9)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Radio<String>(
                        value: addr.id,
                        groupValue: provider.defaultAddress?.id,
                        onChanged: (_) => provider.setDefaultAddress(addr.id),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              addr.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF163D6B),
                              ),
                            ),
                            Text(
                              addr.address,
                              style: const TextStyle(color: Color(0xFF4C688A)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddressDialog(
                          context,
                          provider,
                          edit: addr,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => provider.deleteSavedAddress(addr.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFE44B67),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Wishlist Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183E6B),
              ),
            ),
            const SizedBox(height: 8),
            if (provider.wishlistMedicines.isEmpty)
              const Text(
                'No favorite medicines yet.',
                style: TextStyle(color: Color(0xFF48658A)),
              )
            else
              ...provider.wishlistMedicines.take(5).map(
                    (m) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(m.name),
                      subtitle: Text(m.genericName),
                      trailing: Text('৳ ${m.priceBdt.toStringAsFixed(2)}'),
                    ),
                  ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF183E6B),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Order History')),
                          body: const SafeArea(child: OrderHistoryScreen()),
                        ),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.orders.isEmpty)
              const Text(
                'No orders yet.',
                style: TextStyle(color: Color(0xFF48658A)),
              )
            else
              ...provider.orders.take(4).map(
                    (order) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(order.orderId),
                      subtitle: Text(
                        '${order.items.length} items • ${order.paymentMethod}',
                      ),
                      trailing: Text('৳ ${order.total.toStringAsFixed(2)}'),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _metricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F5FC2),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF45658C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddressDialog(
    BuildContext context,
    PharmacyProvider provider, {
    SavedAddress? edit,
  }) async {
    final TextEditingController labelController =
        TextEditingController(text: edit?.label ?? 'Home');
    final TextEditingController addressController =
        TextEditingController(text: edit?.address ?? '');
    bool asDefault = edit?.isDefault ?? provider.savedAddresses.isEmpty;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(edit == null ? 'Add Address' : 'Edit Address'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: asDefault,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set as default'),
                      onChanged: (value) {
                        setModalState(() => asDefault = value ?? false);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String label = labelController.text.trim();
                    final String address = addressController.text.trim();
                    if (address.isEmpty) {
                      return;
                    }

                    if (edit == null) {
                      await provider.addSavedAddress(
                        label: label,
                        address: address,
                        setAsDefault: asDefault,
                      );
                    } else {
                      await provider.updateSavedAddress(
                        id: edit.id,
                        label: label,
                        address: address,
                        setAsDefault: asDefault,
                      );
                    }

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    addressController.dispose();
  }
}
