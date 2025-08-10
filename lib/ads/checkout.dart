import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? selectedMethod = 'Debit/Credit Card';
  bool showDetails = false;
  bool showVoucher = false;

  final List<String> paymentMethods = [
    'Debit/Credit Card',
    'JazzCash Mobile Account',
    'EasyPay Mobile Account',
    'Online Bank Transfer',
    'JazzCash Shop',
  ];

  final Map<String, IconData> methodIcons = {
    'Debit/Credit Card': Icons.credit_card,
    'JazzCash Mobile Account': Icons.mobile_friendly,
    'EasyPay Mobile Account': Icons.payment,
    'Online Bank Transfer': Icons.account_balance,
    'JazzCash Shop': Icons.storefront,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔢 Step Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _step("1", true, "Info"),
                _stepLine(),
                _step("2", true, "Visit"),
                _stepLine(),
                _step("3", true, "Checkout", highlight: true),
              ],
            ),
            const SizedBox(height: 16),

            /// 🔒 Secure Payment Notice
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "All payment methods are encrypted and secure",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            /// 🧾 Checkout Details
            ExpansionTile(
              title: const Text("Checkout details"),
              onExpansionChanged: (val) => setState(() => showDetails = val),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "• Car Model: Honda Civic\n• Year: 2021\n• Engine: 1.8L\n• Registered City: Lahore\n• Assembly: Local",
                    style: TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),

            /// 🎟️ Discount Voucher
            ExpansionTile(
              title: const Text("Have a discount voucher? Add it here"),
              onExpansionChanged: (val) => setState(() => showVoucher = val),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Enter discount code",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 💳 Payment Methods
            ...paymentMethods.map((method) {
              return ListTile(
                leading: Icon(methodIcons[method], size: 24),
                title: Text(method),
                trailing: selectedMethod == method
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    selectedMethod = method;
                  });
                },
              );
            }),

            const SizedBox(height: 30),

            /// 💰 Total and Continue Button
            Column(
              children: [
                const Divider(thickness: 1),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total (incl. VAT):",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "PKR 5,000",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add checkout logic
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child:
                        const Text("Continue", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔘 Step Circle Widget
  Widget _step(String number, bool completed, String label,
      {bool highlight = false}) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: highlight
                ? Colors.orange
                : (completed ? Colors.green : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: highlight
                ? Colors.orange
                : (completed ? Colors.green : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _stepLine() {
    return Container(
      width: 20,
      height: 2,
      color: Colors.grey.shade400,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
