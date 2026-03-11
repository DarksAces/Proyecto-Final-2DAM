import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../screens/features/product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/features/cart_screen.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: 70, // Increase height for the search bar
        automaticallyImplyLeading: false, // Remove default back button
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: "Buscar en Jovi...",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey.shade400, size: 22),
                        suffixIcon: Icon(Icons.camera_alt_rounded,
                            color: Colors.grey.shade400, size: 22),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.black, size: 28),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CartScreen()));
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 5),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.joviRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Text("3",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _CategoryItem(
                      icon: Icons.local_offer_rounded,
                      label: "Ofertas",
                      color: AppTheme.joviRed,
                      isLight: true),
                  SizedBox(width: 20),
                  _CategoryItem(
                      icon: Icons.palette, label: "Arte", color: Colors.grey),
                  SizedBox(width: 20),
                  _CategoryItem(
                      icon: Icons.category, // Placeholder for pyramid
                      label: "Plastilina",
                      color: Colors.grey),
                  SizedBox(width: 20),
                  _CategoryItem(
                      icon: Icons.view_in_ar,
                      label: "Kits AR",
                      color: Colors.grey),
                  SizedBox(width: 20),
                  _CategoryItem(
                      icon: Icons.edit, label: "Lápices", color: Colors.grey),
                  SizedBox(width: 20),
                  _CategoryItem(
                      icon: Icons.brush, label: "Pinceles", color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Countdown Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: AppTheme.joviYellow,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "ENVÍO GRATIS EN PEDIDOS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                      Text(
                        "+15€",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TERMINA\nEN:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  Row(
                    children: [
                      _TimerBox(label: "02"),
                      Text(" : ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _TimerBox(label: "45"),
                      Text(" : ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _TimerBox(label: "12"),
                    ],
                  )
                ],
              ),
            ),

            // Offers Banner (Top of grid in the design, but let's stick to the grid directly)
            // Or maybe the design has a header above the grid?
            // Checking design: It seems the first two items are featured in the grid.

            const SizedBox(height: 10),

            // Product Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child:
                            CircularProgressIndicator(color: AppTheme.joviRed),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay productos disponibles por ahora',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data!.docs;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final doc = products[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return _ProductCard(
                        title: data['title'] ?? 'Producto Jovi',
                        rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
                        reviews: data['reviews'] ?? 0,
                        price: data['price'] ?? '0,00€',
                        oldPrice: data['oldPrice'] ?? '',
                        discount: data['discount'] ?? '',
                        tag: data['tag'],
                        subTag: data['subTag'],
                        subTagIcon:
                            data['subTag'] != null ? Icons.view_in_ar : null,
                        imageUrl: data['imageUrl'] ?? '',
                        isRedButton: data['isRedButton'] ?? true,
                        buttonText: data['isRedButton'] == true
                            ? "Añadir al carrito"
                            : "Elegir opciones",
                        extraTag: data['extraTag'],
                        greenTruck: data['greenTruck'] ?? false,
                        isBestPrice: data['isBestPrice'] ?? false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(productData: data),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Recently Viewed Header
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("VISTO RECIENTEMENTE",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    Text("Ver más",
                        style: TextStyle(
                            color: AppTheme.joviRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                )),

            const SizedBox(height: 16),

            // Recently Viewed List
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _RecentItem(
                      title: "Pack 12 Lápices",
                      price: "3,50€",
                      imageUrl:
                          "https://m.media-amazon.com/images/I/81+0+q-0+L._AC_UF894,1000_QL80_.jpg"),
                  SizedBox(width: 12),
                  _RecentItem(
                      title: "Kit Escultura",
                      price: "15,90€",
                      imageUrl:
                          "https://m.media-amazon.com/images/I/81x+m+y-0XL._AC_UF894,1000_QL80_.jpg"),
                  SizedBox(width: 12),
                  _RecentItem(
                      title: "Plastilina Neon",
                      price: "8,50€",
                      imageUrl:
                          "https://m.media-amazon.com/images/I/71wF7+0QhFL._AC_UF894,1000_QL80_.jpg"),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLight;

  const _CategoryItem(
      {required this.icon,
      required this.label,
      required this.color,
      this.isLight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLight
                ? AppTheme.joviRed.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: isLight ? AppTheme.joviRed : Colors.grey.shade600,
              size: 24),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TimerBox extends StatelessWidget {
  final String label;
  const _TimerBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final double rating;
  final int reviews;
  final String price;
  final String oldPrice;
  final String discount;
  final String? tag;
  final String? subTag;
  final IconData? subTagIcon;
  final String imageUrl;
  final bool isRedButton;
  final String buttonText;
  final String? extraTag;
  final bool greenTruck;
  final bool isBestPrice;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.title,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.oldPrice,
    required this.discount,
    this.tag,
    this.subTag,
    this.subTagIcon,
    required this.imageUrl,
    required this.isRedButton,
    required this.buttonText,
    this.extraTag,
    this.greenTruck = false,
    this.isBestPrice = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade50, // Placeholder BG
                  child: Image.network(
                    imageUrl, // Using network image for now, or placeholder
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                if (tag != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tag == "TOP VENTAS"
                            ? AppTheme.joviBlue
                            : AppTheme.joviRed,
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8)),
                      ),
                      child: Text(tag!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (subTag != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.joviBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(children: [
                        if (subTagIcon != null)
                          Icon(subTagIcon, color: Colors.white, size: 10),
                        if (subTagIcon != null) const SizedBox(width: 2),
                        Text(subTag!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 4),
          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 12),
              const Icon(Icons.star, color: Colors.orange, size: 12),
              const Icon(Icons.star, color: Colors.orange, size: 12),
              const Icon(Icons.star, color: Colors.orange, size: 12),
              const Icon(Icons.star, color: Colors.orange, size: 12),
              const SizedBox(width: 4),
              Text("$rating ($reviews+)",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 6),
          // Price
          Row(
            children: [
              Text(price,
                  style: const TextStyle(
                      color: AppTheme.joviRed,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              Text(oldPrice,
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.joviRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(discount,
                    style: const TextStyle(
                        color: AppTheme.joviRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (greenTruck) ...[
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.local_shipping, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text("Entrega en 24h",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
          if (isBestPrice) ...[
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.check_circle, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text("Mejor Precio",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
          if (extraTag != null) ...[
            const SizedBox(height: 4),
            Text(extraTag!,
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isRedButton ? AppTheme.joviRed : Colors.white,
                side: isRedButton
                    ? null
                    : const BorderSide(color: AppTheme.joviRed),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(buttonText,
                  style: TextStyle(
                      color: isRedButton ? Colors.white : AppTheme.joviRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;

  const _RecentItem(
      {required this.title, required this.price, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
                image: NetworkImage(imageUrl), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(price,
            style: const TextStyle(
              color: AppTheme.joviRed,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            )),
      ],
    );
  }
}
