import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'home_screen.dart';
import 'mileage_screen.dart';
import 'income_screen.dart';
import 'expenses_screen.dart';
import 'tax_estimates.dart';
import 'user_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MileageScreen(),
    IncomeScreen(),
    ExpensesScreen(),
    EstimatedTaxScreen(),
    UserScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RideWealth Assistant'),
        backgroundColor: AppThemes.primaryColor,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car),
            label: 'Mileage',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Income',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate),
            label: 'Taxes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'User',
          ),
        ],
      ),
    );
  }
}
