import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Mis Pedidos y Puntos",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {})
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Points Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: AppTheme.arteRed,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x66FF0000),
                      blurRadius: 20,
                      offset: Offset(0, 10))
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Balance actual",
                            style:
                                TextStyle(color: Colors.white, fontSize: 14)),
                        SizedBox(height: 4),
                        Text("1,250 Puntos ARte",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.qr_code,
                          color: Colors.white, size: 28),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                // Barcode Placeholder
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text("barcode",
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 24,
                              letterSpacing: 5)),
                      const SizedBox(height: 8),
                      Text("JV-AR-1250-88392",
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Vence: 12 Dic 2024",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    Text("Ver recompensas",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Current Order
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pedido #JV-9921",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FDF0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("EN TRÁNSITO",
                    style: TextStyle(
                        color: Color(0xFF1CB955),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Order Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                // Stepper Mockup
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StepIcon(
                          icon: Icons.check,
                          isActive: true,
                          label: "Confirmado"),
                      _StepLine(isActive: true),
                      _StepIcon(
                          icon: Icons.local_shipping,
                          isActive: true,
                          label: "Enviado"),
                      _StepLine(isActive: false),
                      _StepIcon(
                          icon: Icons.location_on,
                          isActive: false,
                          label: "Reparto"),
                      _StepLine(isActive: false),
                      _StepIcon(
                          icon: Icons.check_circle_outline,
                          isActive: false,
                          label: "Entregado"),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: const Icon(Icons.inventory_2_outlined,
                              color: Colors.grey),
                        ),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: AppTheme.arteRed,
                                shape: BoxShape.circle),
                            child: const Text("2",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
                          const Text("Pack Explorador AR + Merch ARte",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Llega hoy antes de las 20:00",
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text("Ayuda",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // AR Feature Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("NUEVA FUNCIÓN",
                          style: TextStyle(
                              color: AppTheme.arteRed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      const Text("Visualiza tus productos en AR",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Comprueba cómo queda el Merch antes de recibirlo",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.view_in_ar, color: Colors.grey, size: 40)
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Previous Orders
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pedidos anteriores",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Ver todo",
                  style: TextStyle(
                      color: AppTheme.arteRed, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          const _OrderHistoryItem(
              title: "ARte Cap & Stickers",
              date: "Entregado el 15 de Sept",
              price: "24,90€"),
          const SizedBox(height: 12),
          const _OrderHistoryItem(
              title: "Camiseta 'Explorer' White",
              date: "Entregado el 2 de Sept",
              price: "19,00€"),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String label;

  const _StepIcon(
      {required this.icon, required this.isActive, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.arteRed : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: isActive ? Colors.white : Colors.grey.shade400, size: 16),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.black : Colors.grey.shade400,
                fontWeight: FontWeight.bold))
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
        color: isActive ? AppTheme.arteRed : Colors.grey.shade200,
      ),
    );
  }
}

class _OrderHistoryItem extends StatelessWidget {
  final String title;
  final String date;
  final String price;

  const _OrderHistoryItem(
      {required this.title, required this.date, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8)),
            child: const Center(
                child: Text("80x80",
                    style: TextStyle(fontSize: 10, color: Colors.grey))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(date,
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ],
          )
        ],
      ),
    );
  }
}
