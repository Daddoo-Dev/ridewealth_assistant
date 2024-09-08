import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthState>(context).user;
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
                      'Welcome, ${user?.displayName ?? user?.email ?? 'User'}!',
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
            ?.copyWith(color: Colors.white),
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
