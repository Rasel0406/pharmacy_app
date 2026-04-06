import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  final List cart;

  const CartScreen({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    int total = 0;

    for (var item in cart) {
      total += item['price'] as int;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Your Cart"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  leading: Image.network(item['image'], width: 50),
                  title: Text(item['name']),
                  subtitle: Text("৳ ${item['price']}"),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Text("Total: ৳ $total",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {},
                  child: const Text("Checkout"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
