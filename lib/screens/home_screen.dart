import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userDisplayName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Provider.of<AuthState>(context, listen: false).user;
    if (user != null) {
      try {
        final response = await supabase.Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', user.id)
            .single();

        if (!mounted) return;
        setState(() {
          _userDisplayName = response['name'];
          _loading = false;
        });
      } catch (e) {
        print("Error loading user profile: $e");
        if (!mounted) return;
        setState(() {
          _userDisplayName = null;
          _loading = false;
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthState>(context).user;
    
    // Determine what to display
    String displayText = 'User';
    if (_loading) {
      displayText = 'Loading...';
    } else if (_userDisplayName != null && _userDisplayName!.isNotEmpty) {
      displayText = _userDisplayName!;
    } else if (user?.email != null) {
      displayText = user!.email!;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $displayText!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Thank you for using RideWealth Assistant to manage your ride-share business. Whether this is a side-hustle or a full-time job, we are here to help.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 16),
                    InstructionItem(
                      icon: Icons.directions_car,
                      text:
                          'To get started, click on the Mileage icon and enter the date, start and end mileage.',
                    ),
                    InstructionItem(
                      icon: Icons.shopping_cart,
                      text:
                          'To track your expenses, click on the Expense icon and enter the date, expenditure amount and other details.',
                    ),
                    InstructionItem(
                      icon: Icons.attach_money,
                      text:
                          'To track your income, click on the Income icon and enter the income date, income source, and income amount.',
                    ),
                    InstructionItem(
                      icon: Icons.calculate,
                      text:
                          'To see your total profit (income - expenditures) and estimated tax payment, click on the Taxes and Income icon.',
                    ),
                    InstructionItem(
                      icon: Icons.person,
                      text:
                          'To see and change your account info or to submit feedback, click on the User icon.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 70, bottom: 16),
      width: double.infinity,
      color: AppThemes.primaryColor,
      child: Text(
        'RideWealth Assistant',
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}

class InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  InstructionItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppThemes.primaryColor),
          SizedBox(width: 8),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
