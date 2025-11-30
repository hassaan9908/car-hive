import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final String carModel;
  final String carYear;
  final String engine;
  final String registeredCity;
  final String assembly;

  const CheckoutScreen({
    super.key,
    required this.carModel,
    required this.carYear,
    required this.engine,
    required this.registeredCity,
    required this.assembly,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? selectedMethod = 'Debit/Credit Card';
  bool showDetails = false;
  bool showVoucher = false;
  final TextEditingController _voucherController = TextEditingController();
  bool voucherApplied = false;
  int total = 5000; // displayed total
  int discount = 500; // sample discount shown when applied

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
    final Color brand = const Color(0xFFFF6B35);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.transparent,
      ),
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

            /// 🧾 Checkout Details (Card)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => showDetails = !showDetails),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car,
                              color: Color(0xFFFF6B35)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text("Checkout details",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          Icon(
                              showDetails
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  if (showDetails) const Divider(height: 1),
                  if (showDetails)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: [
                          _DetailRow(
                              label: 'Car Model', value: widget.carModel),
                          _DetailRow(label: 'Year', value: widget.carYear),
                          _DetailRow(label: 'Engine', value: widget.engine),
                          _DetailRow(
                              label: 'Registered City',
                              value: widget.registeredCity),
                          _DetailRow(label: 'Assembly', value: widget.assembly),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            /// 🎟️ Discount Voucher
            /// 🎟️ Discount Voucher (Card like details)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => showVoucher = !showVoucher),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard,
                              color: Color(0xFFFF6B35)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text("Have a discount voucher? Add it here",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          Icon(
                              showVoucher
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  if (showVoucher) const Divider(height: 1),
                  if (showVoucher)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _voucherController,
                              enabled: !voucherApplied,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: "Enter discount code",
                                prefixIcon: const Icon(Icons.card_giftcard),
                                border: const OutlineInputBorder(),
                                suffixIcon: voucherApplied
                                    ? const Icon(Icons.check_circle,
                                        color: Color(0xFFFF6B35))
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!voucherApplied)
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_voucherController.text
                                      .trim()
                                      .isNotEmpty) {
                                    setState(() {
                                      voucherApplied = true;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brand,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                child: const Text("Apply"),
                              ),
                            )
                          else
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  voucherApplied = false;
                                  _voucherController.clear();
                                });
                              },
                              child: const Text("Remove"),
                            ),
                        ],
                      ),
                    ),
                  if (showVoucher && voucherApplied)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: brand.withOpacity(0.1),
                            border: Border.all(color: brand),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.local_offer,
                                  color: Color(0xFFFF6B35), size: 16),
                              SizedBox(width: 6),
                              Text("Voucher applied",
                                  style: TextStyle(color: Color(0xFFFF6B35))),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 💳 Payment Methods
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select Payment Method",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: paymentMethods.map((method) {
                final bool isSelected = selectedMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedMethod = method;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? brand.withOpacity(0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected ? brand : Colors.black12,
                            width: isSelected ? 2 : 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(methodIcons[method],
                              size: 24,
                              color: isSelected ? brand : Colors.black54),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(method,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600))),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Color(0xFFFF6B35)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            /// 💰 Total and Continue Button
            Column(
              children: [
                const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal:", style: TextStyle(fontSize: 16)),
                    Text(
                      "PKR ${total.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                if (voucherApplied) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Discount:", style: TextStyle(fontSize: 16)),
                      Text(
                        "- PKR ${discount.toStringAsFixed(0)}",
                        style: TextStyle(
                            fontSize: 16,
                            color: brand,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total (incl. VAT):",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        if (voucherApplied)
                          Text(
                            "PKR ${total.toStringAsFixed(0)}",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          "PKR ${(voucherApplied ? (total - discount) : total).toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
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
                      backgroundColor: brand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Continue",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
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
                ? const Color(0xFFFF6B35)
                : (completed ? const Color(0xFFFF6B35) : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
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
                ? const Color(0xFFFF6B35)
                : (completed ? const Color(0xFFFF6B35) : Colors.grey),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
