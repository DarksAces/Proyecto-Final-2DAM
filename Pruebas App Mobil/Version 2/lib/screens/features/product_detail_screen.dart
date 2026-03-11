import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? productData;
  const ProductDetailScreen({super.key, this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImage = 0;
  int _quantity = 1;

  final List<Color> _bgColors = [
    const Color(0xFF4B8B8B), // Close to the teal in the image
    const Color(0xFFE57373),
    const Color(0xFF64B5F6),
    const Color(0xFFFFB74D),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detalle del Producto",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 350,
                        child: PageView.builder(
                          onPageChanged: (index) {
                            setState(() {
                              _currentImage = index;
                            });
                          },
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return Container(
                              color: _bgColors[index],
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Product Image from dynamic data
                                  Center(
                                    child: widget.productData?['imageUrl'] !=
                                            null
                                        ? Image.network(
                                            widget.productData!['imageUrl'],
                                            fit: BoxFit.contain,
                                            height: 250,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(Icons.palette,
                                                        size: 150,
                                                        color: Colors.white
                                                            .withAlpha(100)),
                                          )
                                        : Icon(
                                            Icons.palette,
                                            size: 150,
                                            color: Colors.white.withAlpha(100),
                                          ),
                                  ),
                                  // AR Compatible Badge
                                  Positioned(
                                    top: 20,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.view_in_ar_rounded,
                                              color: AppTheme.joviRed,
                                              size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            "COMPATIBLE AR",
                                            style: TextStyle(
                                              color: AppTheme.joviRed,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Carousel Indicators
                      Positioned(
                        bottom: 20,
                        child: Row(
                          children: List.generate(4, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImage == index
                                    ? Colors.white
                                    : Colors.white.withAlpha(100),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.productData?['category']
                                      ?.toString()
                                      .toUpperCase() ??
                                  "MANUALIDADES AR",
                              style: const TextStyle(
                                color: AppTheme.joviRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.joviRed.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.productData?['price'] ?? "18.50€",
                                style: const TextStyle(
                                  color: AppTheme.joviRed,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          widget.productData?['title'] ??
                              "Plastilina Jovi – Set Creativo AR",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Rating
                        Row(
                          children: [
                            ...List.generate(
                                5,
                                (index) => const Icon(Icons.star_rounded,
                                    color: AppTheme.joviYellow, size: 20)),
                            const SizedBox(width: 8),
                            const Text(
                              "4.8",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "(124 reseñas)",
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Benefits Section
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, // Rounded icon
                                color: AppTheme.joviBlue,
                                size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Beneficios Creativos",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.productData?['description'] ??
                              "Descubre una nueva dimensión del arte. Nuestra plastilina vegetal no solo es perfecta para modelar, sino que ahora cobra vida. Escanea tus creaciones con la app Jovi AR y observa cómo tus personajes interactúan con el entorno.",
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.5,
                              fontSize: 14),
                        ),

                        const SizedBox(height: 30),

                        // Includes Section
                        const Text(
                          "¿Qué incluye el set?",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: const [
                            _IncludeItem(
                                icon: Icons.palette,
                                title: "COLORES",
                                subtitle: "12 Pastillas",
                                color: AppTheme.joviRed),
                            _IncludeItem(
                                icon: Icons.build,
                                title: "HERRAMIENTAS",
                                subtitle: "3 Estecas",
                                color: AppTheme.joviYellow),
                            _IncludeItem(
                                icon: Icons.qr_code_scanner,
                                title: "ACCESO",
                                subtitle: "Código AR",
                                color: AppTheme.joviBlue),
                            _IncludeItem(
                                icon: Icons.grass,
                                title: "ECO",
                                subtitle: "100% Vegetal",
                                color: Colors.green),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Reviews Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Opiniones",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                "Ver todas",
                                style: TextStyle(color: AppTheme.joviRed),
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "4.8",
                              style: TextStyle(
                                  fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: _RatingBar(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Related Products
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Productos relacionados",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.grey.shade400),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: const [
                        _RelatedProductCard(
                            image: Icons.brush,
                            title: "Set Pinceles Pro",
                            price: "8.25€",
                            color: Colors.orange),
                        _RelatedProductCard(
                            image: Icons.water_drop,
                            title: "Plastilina Flúor",
                            price: "12.40€",
                            color: Colors.blue),
                        _RelatedProductCard(
                            image: Icons.backpack,
                            title: "Bolsa Escolar",
                            price: "15.00€",
                            color: Colors.purple),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom padding for fixed bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20), // Darker shadow
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 20), // Increased padding
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      "$_quantity",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Añadido al carrito")),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartScreen()),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined,
                      color: Colors.white),
                  label: const Text(
                    "Añadir al Carrito",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.joviRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncludeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _IncludeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBar(5, 0.7),
        const SizedBox(height: 4),
        _buildBar(4, 0.2),
      ],
    );
  }

  Widget _buildBar(int stars, double percentage) {
    return Row(
      children: [
        Text("$stars",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 4),
        Icon(Icons.star_rounded, size: 12, color: Colors.grey.shade300),
        const SizedBox(width: 8),
        Container(
          height: 4,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.joviRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text("${(percentage * 100).toInt()}%",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ],
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  final IconData image;
  final String title;
  final String price;
  final Color color;

  const _RelatedProductCard({
    required this.image,
    required this.title,
    required this.price,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Icon(image, size: 40, color: color),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(price,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.joviRed,
                            fontSize: 14)),
                    Icon(Icons.add_circle,
                        color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
