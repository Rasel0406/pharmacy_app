import 'package:flutter/material.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List cart = [];

  final List<Map<String, dynamic>> medicines = [
    {"name": "Napa", "price": 10, "image": "https://i.imgur.com/8Km9tLL.png"},
    {
      "name": "Paracetamol",
      "price": 12,
      "image": "https://i.imgur.com/5Aqgz7o.png"
    },
    {
      "name": "Seclo 20",
      "price": 15,
      "image": "https://i.imgur.com/1bX5QH6.png"
    },
    {"name": "Ace", "price": 8, "image": "https://i.imgur.com/8Km9tLL.png"},
    {
      "name": "Napa Extra",
      "price": 20,
      "image": "https://i.imgur.com/5Aqgz7o.png"
    },
  ];

  List filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = medicines;
  }

  void search(String value) {
    if (value.isEmpty) {
      filtered = medicines;
    } else {
      filtered = medicines
          .where((e) => e['name'].toLowerCase().contains(value.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void addToCart(Map item) {
    cart.add(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item['name']} added")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Pharmacy Store"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen(cart: cart)),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: search,
              decoration: InputDecoration(
                hintText: "Search medicine...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // 🟢 Banner
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "Fast Medicine Delivery 🚀",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🛒 Products
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = filtered[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade300, blurRadius: 5)
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          item['image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(item['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("৳ ${item['price']}"),
                            const SizedBox(height: 5),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              onPressed: () => addToCart(item),
                              child: const Text("Add to Cart"),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
