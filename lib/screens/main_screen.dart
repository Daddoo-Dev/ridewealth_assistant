import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'mileage_screen.dart';
import 'income_screen.dart';
import 'expenses_screen.dart';
import 'tax_estimates.dart';
import 'user_screen.dart';
import '../revenuecat_manager.dart';
import '../theme/app_themes.dart';

class MainScreen extends StatefulWidget {
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _trialStatus;

  final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MileageScreen(),
    IncomeScreen(),
    ExpensesScreen(),
    EstimatedTaxScreen(),
    UserScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadTrialStatus();
  }

  Future<void> _loadTrialStatus() async {
    final trialStatus = await RevenueCatManager.getTrialStatus();
    setState(() {
      _trialStatus = trialStatus;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppThemes.buildAppBar(context, 'RideWealth Assistant'),
      body: Column(
        children: [
          // Trial status banner
          if (_trialStatus != null && _trialStatus!['isInTrial'] == true)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange.shade900.withOpacity(0.3)
                  : Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.orange.shade300
                        : Colors.orange.shade800,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free Trial: ${_trialStatus!['daysRemaining']} days remaining',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.shade300
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
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
