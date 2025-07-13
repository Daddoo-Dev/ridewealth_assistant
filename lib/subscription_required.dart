// lib/subscription_required.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'apple_iap_service.dart';
import 'google_iap_service.dart';
import 'main.dart' show AuthState;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SubscriptionRequiredScreen extends StatefulWidget {
  final dynamic iapService;

  const SubscriptionRequiredScreen({
    super.key,
    required this.iapService,
  });

  @override
  State<SubscriptionRequiredScreen> createState() => _SubscriptionRequiredScreenState();
}
class _SubscriptionRequiredScreenState extends State<SubscriptionRequiredScreen> {
  bool _loading = false;
  String? _error;
  List<ProductDetails> _products = [];
  late final dynamic _iapService;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _iapService = Platform.isIOS ?
        widget.iapService as AppleIAPService :
        widget.iapService as GoogleIAPService;
      _loadProducts();
    } else {
      _error = 'In-app purchases are not supported on web.';
    }
  }

  Future<void> _loadProducts() async {
    if (kIsWeb) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await _iapService.loadProducts();
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (kIsWeb) return;
    setState(() => _loading = true);
    try {
      await _iapService.restorePurchases();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _subscribe(ProductDetails product) async {
    if (kIsWeb) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iapService.purchaseProduct(product);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _logout(BuildContext context) {
    Provider.of<AuthState>(context, listen: false).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _loading ? null : _restorePurchases,
            tooltip: 'Restore Purchases',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ..._buildSubscriptionCards(),
            const SizedBox(height: 24),
            const Text(
              'Subscription automatically renews. Cancel anytime.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubscriptionCards() {
    return _products.map((product) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                product.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 16),
              Text(
                product.price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : () => _subscribe(product),
                child: const Text('Subscribe Now'),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}