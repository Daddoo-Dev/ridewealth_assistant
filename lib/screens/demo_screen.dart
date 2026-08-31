import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class DemoScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const DemoScreen({super.key, required this.onComplete});

  static const String _prefKey = 'rwa_seen_demo';

  static Future<bool> hasSeenDemo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  // Controllers for interactive fields
  final _startMileageController = TextEditingController();
  final _expenseDescController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _incomeDescController = TextEditingController();
  final _incomeAmountController = TextEditingController();
  final _endMileageController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _startMileageController.dispose();
    _expenseDescController.dispose();
    _expenseAmountController.dispose();
    _incomeDescController.dispose();
    _incomeAmountController.dispose();
    _endMileageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _complete() async {
    await DemoScreen.markSeen();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppThemes.accentColor : AppThemes.primaryColor;

    return Scaffold(
      appBar: AppThemes.buildAppBar(context, 'RideWealth Assistant'),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: primary.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                'Try it out — enter the sample data below',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildStartMileagePage(context),
                  _buildExpensePage(context),
                  _buildIncomePage(context),
                  _buildEndMileagePage(context),
                  _buildTaxPage(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? primary : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    key: const Key('demo_skip_button'),
                    onPressed: _complete,
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    key: const Key('demo_next_button'),
                    onPressed: _next,
                    child: Text(
                      _currentPage == _totalPages - 1
                          ? 'Sign Up Free'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartMileagePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            context,
            'Starting your shift',
            'Enter your odometer reading before you head out.',
            Icons.directions_car,
          ),
          const SizedBox(height: 20),
          _instructionCard(context, [
            _instruction('Start Mileage', '25432',
                'Type your current odometer reading'),
          ]),
          const SizedBox(height: 16),
          TextField(
            key: const Key('demo_start_mileage_field'),
            controller: _startMileageController,
            decoration: AppThemes.getInputDecoration(context)
                .copyWith(labelText: 'Start Mileage', hintText: 'e.g. 25432'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: AppThemes.elevatedButtonStyle,
            child: const Text('Save Start Mileage'),
          ),
          const SizedBox(height: 12),
          Text(
            'Date: ${DateTime.now().toString().substring(0, 10)}',
            style: AppThemes.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            context,
            'Log an expense',
            'Stopped for fuel? Log it right away.',
            Icons.shopping_cart,
          ),
          const SizedBox(height: 20),
          _instructionCard(context, [
            _instruction('Category', 'Car and truck expenses',
                'Select this from the dropdown'),
            _instruction('Description', 'Conoco', 'Type the vendor name'),
            _instruction('Amount', '63.46', 'Type the dollar amount'),
          ]),
          const SizedBox(height: 16),
          IgnorePointer(
            child: DropdownButtonFormField<String>(
              value: 'Car and truck expenses',
              decoration: AppThemes.getInputDecoration(context)
                  .copyWith(labelText: 'Category'),
              items: const [
                DropdownMenuItem(
                  value: 'Car and truck expenses',
                  child: Text('Car and truck expenses'),
                ),
              ],
              onChanged: null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('demo_expense_desc_field'),
            controller: _expenseDescController,
            decoration: AppThemes.getInputDecoration(context)
                .copyWith(labelText: 'Description', hintText: 'e.g. Conoco'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('demo_expense_amount_field'),
            controller: _expenseAmountController,
            decoration: AppThemes.getInputDecoration(context).copyWith(
              labelText: 'Amount',
              hintText: 'e.g. 63.46',
              prefixText: '\$ ',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: AppThemes.elevatedButtonStyle,
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            context,
            'Track your income',
            'Finished a batch of deliveries? Record your earnings.',
            Icons.attach_money,
          ),
          const SizedBox(height: 20),
          _instructionCard(context, [
            _instruction('Source', 'Delivery income',
                'Select this from the dropdown'),
            _instruction('Description', 'DoorDash', 'Type the platform name'),
            _instruction('Amount', '195.27', 'Type what you earned'),
          ]),
          const SizedBox(height: 16),
          IgnorePointer(
            child: DropdownButtonFormField<String>(
              value: 'Delivery income',
              decoration: AppThemes.getInputDecoration(context)
                  .copyWith(labelText: 'Source'),
              items: const [
                DropdownMenuItem(
                  value: 'Delivery income',
                  child: Text('Delivery income'),
                ),
              ],
              onChanged: null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('demo_income_desc_field'),
            controller: _incomeDescController,
            decoration: AppThemes.getInputDecoration(context).copyWith(
                labelText: 'Description', hintText: 'e.g. DoorDash'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('demo_income_amount_field'),
            controller: _incomeAmountController,
            decoration: AppThemes.getInputDecoration(context).copyWith(
              labelText: 'Amount',
              hintText: 'e.g. 195.27',
              prefixText: '\$ ',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: AppThemes.elevatedButtonStyle,
            child: const Text('Add Income'),
          ),
        ],
      ),
    );
  }

  Widget _buildEndMileagePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            context,
            'Ending your shift',
            'Log your final odometer reading to record your miles.',
            Icons.flag,
          ),
          const SizedBox(height: 20),
          _instructionCard(context, [
            _instruction('Start Mileage', '25432',
                'Same number from the start of your shift'),
            _instruction('End Mileage', '25525',
                'Your odometer reading now — that\'s 93 miles!'),
          ]),
          const SizedBox(height: 16),
          IgnorePointer(
            child: TextField(
              controller: TextEditingController(text: '25432'),
              decoration: AppThemes.getInputDecoration(context)
                  .copyWith(labelText: 'Start Mileage'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('demo_end_mileage_field'),
            controller: _endMileageController,
            decoration: AppThemes.getInputDecoration(context)
                .copyWith(labelText: 'End Mileage', hintText: 'e.g. 25525'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: AppThemes.elevatedButtonStyle,
            child: const Text('Submit Mileage'),
          ),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift complete!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '93 miles driven today',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxPage(BuildContext context) {
    const double income = 195.27;
    const double expenses = 63.46;
    const double mileageDeduction = 65.10; // 93 * 0.70
    const double fedRate = 0.15;
    const double stateRate = 0.05;

    const double conservativeBase = income;
    const double moderateBase = income - expenses;
    const double aggressiveBase = income - expenses - mileageDeduction;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppThemes.accentColor : AppThemes.primaryColor;
    final quarter = ((DateTime.now().month - 1) ~/ 3) + 1;
    final year = DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            context,
            'Your tax estimate',
            'Based on what you just entered — Q$quarter $year',
            Icons.calculate,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryTile(context, 'Income', '\$195.27', Colors.green),
              const SizedBox(width: 8),
              _summaryTile(context, 'Expense', '\$63.46', Colors.red),
              const SizedBox(width: 8),
              _summaryTile(context, 'Miles', '93', primary),
            ],
          ),
          const SizedBox(height: 16),
          _taxCard(
            context,
            label: 'Conservative',
            formula: 'No deductions',
            base: conservativeBase,
            federal: conservativeBase * fedRate,
            state: conservativeBase * stateRate,
          ),
          const SizedBox(height: 8),
          _taxCard(
            context,
            label: 'Moderate',
            formula: 'Income \u2212 Expenses',
            base: moderateBase,
            federal: moderateBase * fedRate,
            state: moderateBase * stateRate,
          ),
          const SizedBox(height: 8),
          _taxCard(
            context,
            label: 'Aggressive',
            formula: 'Income \u2212 Expenses \u2212 93 mi \u00d7 \$0.70',
            base: aggressiveBase,
            federal: aggressiveBase * fedRate,
            state: aggressiveBase * stateRate,
            highlight: true,
            primary: primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Sign up free to start tracking your real numbers.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: primary,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _stepHeader(
      BuildContext context, String title, String subtitle, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppThemes.accentColor : AppThemes.primaryColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Creates a row of {field, value, hint} to show above the inputs.
  Map<String, String> _instruction(
          String field, String value, String hint) =>
      {'field': field, 'value': value, 'hint': hint};

  Widget _instructionCard(
      BuildContext context, List<Map<String, String>> instructions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppThemes.accentColor : AppThemes.primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 14, color: primary),
              const SizedBox(width: 6),
              Text(
                'Try entering this:',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...instructions.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 8,
                      child: Text('•',
                          style: TextStyle(color: primary, fontSize: 13)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                          ),
                          children: [
                            TextSpan(
                              text: i['field']!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ': '),
                            TextSpan(
                              text: i['value']!,
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '  — ${i['hint']!}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _summaryTile(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color)),
            Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taxCard(
    BuildContext context, {
    required String label,
    required String formula,
    required double base,
    required double federal,
    required double state,
    bool highlight = false,
    Color? primary,
  }) {
    return Card(
      elevation: highlight ? 3 : 1,
      shape: highlight
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: primary!, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (highlight && primary != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Best'),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: primary.withOpacity(0.15),
                    labelStyle: TextStyle(color: primary, fontSize: 11),
                  ),
                ],
              ],
            ),
            Text(formula, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Taxable base:',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('\$${base.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Federal (15%):',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('\$${federal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('State (5%):',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('\$${state.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
