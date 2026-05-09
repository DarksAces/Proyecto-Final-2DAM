import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const CustomLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
          backgroundColor:
              (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
        ),
      ),
    );
  }
}

class BrandedLoadingScreen extends StatelessWidget {
  const BrandedLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const CustomLoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
