import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'discovery_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Mi Cesta",
          style: TextStyle(
              fontWeight: FontWeight.w900, color: Colors.black, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.shopping_bag, // Filled icon as per image
                      color: Colors.black,
                      size: 28)),
              Positioned(
                right: 12,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppTheme.auraRed, shape: BoxShape.circle),
                  child: const Text("3",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _CartItem(
                    title: "Gaudí Hidden AR Experience",
                    subtitle: "Ubicación: Barcelona",
                    price: "12,99 €",
                    quantity: 1,
                    isDigital: true,
                    image: Icons.temple_buddhist),
                const SizedBox(height: 16),
                const _CartItem(
                    title: "Aura AR Explorer Cap",
                    subtitle: "Talla: M | Color: Rojo",
                    price: "30,00 €",
                    unitPrice: "15,00 € ud.",
                    quantity: 2,
                    isDigital: false,
                    image: Icons
                        .beach_access), // Using beach_access as cap placeholder
                const SizedBox(height: 16),
                const _CartItem(
                    title: "Digital Map Pack: Hidden Gems",
                    subtitle: "Entrega inmediata digital",
                    price: "5,50 €",
                    quantity: 1,
                    isDigital: true,
                    image: Icons.public),
                const SizedBox(height: 20),

                // Promo Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8), // Light red/pink
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.auraRed.withAlpha(50))),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: AppTheme.auraRed, shape: BoxShape.circle),
                        child: const Icon(Icons.star,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "¡Añade 1 experiencia más y obtén un 15% de descuento!",
                          style: TextStyle(
                              color: AppTheme.auraRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Order Summary
                const Text("Resumen de Pedido",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Column(
                    children: [
                      _SummaryRow(label: "Subtotal", amount: "48,49 €"),
                      SizedBox(height: 12),
                      _SummaryRow(
                          label: "Envío (Físico)", amount: "3,99 €"),
                      SizedBox(height: 12),
                      _SummaryRow(label: "Impuestos", amount: "1,20 €"),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                          Text("53,68 €",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.auraRed)),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // SSL Secure
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text("PAGO SEGURO SSL ENCRIPTADO",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 16),

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DiscoveryScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.auraRed,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: AppTheme.auraRed.withAlpha(100),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Finalizar Compra",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white)
                        ],
                      )),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;

  const _SummaryRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        Text(amount,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CartItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final int quantity;
  final bool isDigital;
  final IconData image;
  final String? unitPrice;

  const _CartItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.isDigital,
    required this.image,
    this.unitPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Thumbnail
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(image, size: 40, color: Colors.grey.shade400),
              ),
              if (isDigital)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppTheme.auraRed,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomRight: Radius.circular(8)),
                    ),
                    child: const Text("DIGITAL",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 12),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const _QtyBtn(icon: Icons.remove),
                          SizedBox(
                              width: 20,
                              child: Center(
                                  child: Text("$quantity",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)))),
                          const _QtyBtn(icon: Icons.add, isRed: true),
                        ],
                      ),
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(price,
                            style: const TextStyle(
                                color: AppTheme.auraRed,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        if (unitPrice != null)
                          Text(unitPrice!,
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 10)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool isRed;

  const _QtyBtn({required this.icon, this.isRed = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon,
            size: 16, // Slightly larger
            color: isRed ? AppTheme.auraRed : Colors.grey.shade600),
      ),
    );
  }
}
