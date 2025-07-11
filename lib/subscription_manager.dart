import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'revenuecat_manager.dart';

class SubscriptionManager extends StatefulWidget {
  @override
  SubscriptionManagerState createState() => SubscriptionManagerState();
}

class SubscriptionManagerState extends State<SubscriptionManager> {
  final supabase = Supabase.instance.client;
  
  bool isLoading = false;
  bool isSubscribed = false;
  Map<String, dynamic>? subscriptionDetails;
  Map<String, dynamic>? offerings;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      final supabaseUser = supabase.auth.currentUser;
      
      if (supabaseUser == null) {
        setState(() {
          isLoading = false;
          isSubscribed = false;
        });
        return;
      }

      // Check subscription status from Supabase
      final supabaseSubscription = await _checkSupabaseSubscription(supabaseUser.id);
      
      // Also check RevenueCat
      final revenueCatSubscription = await RevenueCatManager.isSubscribed();
      
      // Get subscription details
      final customerInfo = await RevenueCatManager.getCustomerInfo();
      
      // Get available offerings
      final availableOfferings = await RevenueCatManager.getOfferings();

      setState(() {
        isSubscribed = supabaseSubscription || revenueCatSubscription;
        subscriptionDetails = customerInfo;
        offerings = availableOfferings;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading subscription status: $e');
      setState(() {
        isLoading = false;
        isSubscribed = false;
      });
    }
  }

  Future<bool> _checkSupabaseSubscription(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select('subscription_end_date, is_subscribed')
          .eq('id', userId)
          .single();
      
      // response is never null after .single(), so remove the null check
      final isSubscribed = response['is_subscribed'] as bool? ?? false;
      final subscriptionEndDate = response['subscription_end_date'] as String?;
      
      if (!isSubscribed || subscriptionEndDate == null) return false;
      
      final endDate = DateTime.parse(subscriptionEndDate);
      return endDate.isAfter(DateTime.now());
    } catch (e) {
      print('Error checking Supabase subscription: $e');
      return false;
    }
  }

  Future<void> _purchaseSubscription(Map<String, dynamic> package) async {
    try {
      setState(() {
        isLoading = true;
      });

      await RevenueCatManager.purchasePackage(package['identifier']);
      
      // Update subscription status in Supabase
      await _updateSubscriptionStatus();
      
      // Reload subscription status
      await _loadSubscriptionStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription purchased successfully!')),
        );
      }
    } catch (e) {
      print('Error purchasing subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to purchase subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSubscriptionStatus() async {
    final supabaseUser = supabase.auth.currentUser;
    
    if (supabaseUser == null) return;
    
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));
    
    await supabase.from('users').update({
      'subscription_start_date': now.toIso8601String(),
      'subscription_end_date': endDate.toIso8601String(),
      'is_subscribed': true,
      'subscription_type': 'premium',
      'last_updated': now.toIso8601String(),
    }).eq('id', supabaseUser.id);
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() {
        isLoading = true;
      });

      await RevenueCatManager.restorePurchases();
      
      // Update subscription status
      await _updateSubscriptionStatus();
      
      // Reload subscription status
      await _loadSubscriptionStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchases restored successfully!')),
        );
      }
    } catch (e) {
      print('Error restoring purchases: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      setState(() {
        isLoading = true;
      });

      await RevenueCatManager.cancelSubscription();
      
      // Update subscription status
      final supabaseUser = supabase.auth.currentUser;
      
      if (supabaseUser != null) {
        await supabase.from('users').update({
          'is_subscribed': false,
          'subscription_type': 'cancelled',
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('id', supabaseUser.id);
      }
      
      // Reload subscription status
      await _loadSubscriptionStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription cancelled successfully!')),
        );
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSubscriptionStatus,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubscriptionStatusCard(),
                  SizedBox(height: 16),
                  if (!isSubscribed) _buildPurchaseOptions(),
                  if (isSubscribed) _buildSubscriptionDetails(),
                  SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isSubscribed ? Icons.check_circle : Icons.cancel,
                  color: isSubscribed ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  isSubscribed ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSubscribed ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOptions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...offerings?.entries.map((entry) => Card(
              child: ListTile(
                title: Text(entry.value['title'] ?? 'Premium Plan'),
                subtitle: Text(entry.value['description'] ?? 'Full access to all features'),
                trailing: ElevatedButton(
                  onPressed: () => _purchaseSubscription(entry.value),
                  child: Text('Subscribe'),
                ),
              ),
            )).toList() ?? [],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (subscriptionDetails != null) ...[
              Text('Plan: ${subscriptionDetails!['plan'] ?? 'Premium'}'),
              Text('Status: ${subscriptionDetails!['status'] ?? 'Active'}'),
              if (subscriptionDetails!['expiryDate'] != null)
                Text('Expires: ${subscriptionDetails!['expiryDate']}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _restorePurchases,
                    child: Text('Restore Purchases'),
                  ),
                ),
                SizedBox(width: 16),
                if (isSubscribed)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelSubscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('Cancel Subscription'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}