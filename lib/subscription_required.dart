import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'main.dart' show AuthState;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'revenuecat_manager.dart';

class SubscriptionRequiredScreen extends StatefulWidget {
  final VoidCallback? onSubscriptionMaybeChanged;

  const SubscriptionRequiredScreen({
    super.key,
    this.onSubscriptionMaybeChanged,
  });

  @override
  State<SubscriptionRequiredScreen> createState() =>
      _SubscriptionRequiredScreenState();
}

class _SubscriptionRequiredScreenState extends State<SubscriptionRequiredScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadPackages();
    }
  }

  Future<void> _loadPackages() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final offering = await RevenueCatManager.getOfferings();
      if (!mounted) return;

      final packages = offering?['availablePackages'];
      setState(() {
        _packages = packages is List
            ? packages.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        _loading = false;
        if (_packages.isEmpty) {
          _error = 'No subscription plans are available right now.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (!mounted || kIsWeb) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final restored = await RevenueCatManager.restorePurchases();
      if (!mounted) return;

      if (restored) {
        widget.onSubscriptionMaybeChanged?.call();
      } else {
        setState(() {
          _error = 'No active subscription found to restore.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _subscribe(Map<String, dynamic> package) async {
    if (!mounted || kIsWeb) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final active = await RevenueCatManager.purchaseSubscription(package);
      if (!mounted) return;

      if (active) {
        widget.onSubscriptionMaybeChanged?.call();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        setState(() {
          _error = e.message ?? e.toString();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _logout(BuildContext context) {
    Provider.of<AuthState>(context, listen: false).signOut();
  }

  bool _packageHasFreeTrial(Map<String, dynamic> package) {
    return package['hasFreeTrial'] == true;
  }

  String _packagePrice(Map<String, dynamic> package) {
    final product = package['product'];
    if (product is Map<String, dynamic>) {
      return product['priceString'] as String? ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final hasTrialOffer = _packages.any(_packageHasFreeTrial);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Subscription'),
        actions: [
          if (!kIsWeb)
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
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'A subscription is required to continue. Please sign in on our mobile app to subscribe.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPackages,
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
                          Text(
                            hasTrialOffer
                                ? 'Start your 30-day free trial'
                                : 'Choose a plan and subscribe',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasTrialOffer
                                ? 'Try the full app free for 30 days. Billing starts after the trial unless you cancel.'
                                : 'Your subscription unlocks full access to the app.',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ..._buildSubscriptionCards(),
                          const SizedBox(height: 24),
                          const Text(
                            'Subscription automatically renews. Cancel anytime in your device account settings.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _buildSubscriptionCards() {
    return _packages.map((package) {
      final hasTrial = _packageHasFreeTrial(package);
      final title = package['title'] as String? ?? 'Annual Subscription';
      final description =
          package['description'] as String? ?? 'Full access to the app';

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (hasTrial) ...[
                const Text(
                  '30-day free trial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Then ${_packagePrice(package)} / year',
                  style: const TextStyle(color: Colors.grey),
                ),
              ] else
                Text(
                  _packagePrice(package),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : () => _subscribe(package),
                child: Text(hasTrial ? 'Start Free Trial' : 'Subscribe'),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
