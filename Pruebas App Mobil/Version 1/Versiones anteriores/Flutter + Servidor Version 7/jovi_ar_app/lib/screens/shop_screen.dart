import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart'; // Para JoviTheme
import 'package:url_launcher/url_launcher.dart';

class JoviShopScreen extends StatefulWidget {
  const JoviShopScreen({super.key});

  final List<Map<String, dynamic>> products = const [
    {
      "name": "Plastilina Jovi 10 Colores",
      "price": "3.50€",
      "image": "https://www.jovi.es/uploads/productos/ref_70/70.jpg",
      "description": "La plastilina vegetal que no se seca nunca. Muy moldeable."
    },
    {
      "name": "Caja 12 Rotuladores",
      "price": "4.20€",
      "image": "https://www.jovi.es/uploads/productos/ref_1612/1612.jpg",
      "description": "Rotuladores de larga duración con punta resistente."
    },
    {
      "name": "Acuarelas 24 Pastillas",
      "price": "6.80€",
      "image": "https://www.jovi.es/uploads/productos/ref_800_24/800_24.jpg",
      "description": "Colores vivos e intensos. Incluye pincel."
    },
    {
      "name": "Témpera Escolar 500ml",
      "price": "5.50€",
      "image": "https://www.jovi.es/uploads/productos/ref_500/500_vermet.jpg",
      "description": "Témpera líquida lista para usar. Gran cobertura."
    },
    {
      "name": "Ceras Blandas 12 Uds",
      "price": "2.90€",
      "image": "https://www.jovi.es/uploads/productos/ref_980/980.jpg",
      "description": "Ceras suaves que no manchan. Ideales para iniciar."
    },
    {
      "name": "Pasta para Modelar Air Dry",
      "price": "4.00€",
      "image": "https://www.jovi.es/uploads/productos/ref_86/86.jpg",
      "description": "Arcilla blanca que seca al aire. No necesita horno."
    }
  ];

  @override
  State<JoviShopScreen> createState() => _JoviShopScreenState();
}

class _JoviShopScreenState extends State<JoviShopScreen> {
  // ... (products list)
  int cartCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoviTheme.gray,
      appBar: AppBar(
        title: const Text("Tienda Oficial Jovi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: JoviTheme.blue,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(LucideIcons.shoppingCart)),
              if (cartCount > 0)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$cartCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Banner promocional
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: JoviTheme.yellow,
            child: Row(
              children: [
                const Icon(LucideIcons.shoppingBag, size: 30, color: JoviTheme.blue),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "¡Consigue los mejores productos para tus creaciones!",
                    style: JoviTheme.fontBaloo.copyWith(fontSize: 16, color: JoviTheme.blue),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Padding extra bottom para el FAB
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Image.network(
                            product['image'],
                            fit: BoxFit.contain, 
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(LucideIcons.image, size: 40, color: Colors.grey)
                            ),
                          ),
                        ),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              product['price'],
                              style: const TextStyle(
                                color: JoviTheme.blue, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 16
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: double.infinity,
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                   setState(() => cartCount++);
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       content: Text("Añadido ${product['name']}"),
                                       duration: const Duration(milliseconds: 500),
                                     )
                                   );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: JoviTheme.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text("Añadir", style: TextStyle(fontSize: 12)),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: cartCount > 0 
        ? FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                  title: const Text("¡Compra Realizada!"),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Icon(LucideIcons.checkCircle, color: Colors.green, size: 50),
                       SizedBox(height: 10),
                       Text("Gracias por tu compra. Tus productos Jovi llegarán pronto.")
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () {
                       setState(() => cartCount = 0);
                       Navigator.pop(ctx);
                    }, child: const Text("Genial"))
                  ],
                )
              );
            },
            backgroundColor: JoviTheme.blue,
            icon: const Icon(LucideIcons.creditCard, color: Colors.white),
            label: Text("Finalizar Compra ($cartCount)", style: const TextStyle(color: Colors.white)),
          )
        : null,
    );
  }
}
