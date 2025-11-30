import 'package:carhive/ads/checkout.dart';
import 'package:flutter/material.dart';

class BookVisitScreen extends StatefulWidget {
  const BookVisitScreen({super.key});

  @override
  State<BookVisitScreen> createState() => _BookVisitScreenState();
}

class _BookVisitScreenState extends State<BookVisitScreen> {
  String? selectedArea;
  final List<String> areas = ['DHA', 'Gulberg', 'Johar Town', 'Model Town'];
  final List<String> availableDates = ['Aug 6', 'Aug 7', 'Aug 8', 'Aug 9'];
  final Map<String, int> seatAvailability = {
    'Aug 6': 2,
    'Aug 7': 4,
    'Aug 8': 1,
    'Aug 9': 3,
  };

  String? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Visit"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📍 Step Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepCircle("1", "Info", completed: true),
                Container(width: 40, height: 2, color: Colors.blue),
                _buildStepCircle("2", "Visit", active: true),
                Container(width: 40, height: 2, color: Colors.grey),
                _buildStepCircle("3", "Checkout"),
              ],
            ),
            const SizedBox(height: 30),

            /// 🏙️ Area Selection
            const Text("Select Area",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              value: selectedArea,
              items: areas
                  .map((area) => DropdownMenuItem(
                        value: area,
                        child: Text(area),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedArea = value;
                  selectedDate = null; // Reset date on new area selection
                });
              },
            ),

            /// 📅 Date Selection + Seat Availability
            if (selectedArea != null) ...[
              const SizedBox(height: 30),
              const Text("Available Dates",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: availableDates.map((date) {
                  final isSelected = date == selectedDate;
                  return ChoiceChip(
                    label: Text("$date (${seatAvailability[date]} seats)"),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 50),

            /// ✅ Continue Button
            Center(
              child: ElevatedButton(
                onPressed: selectedDate != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CheckoutScreen()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedDate != null ? Colors.blue : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text("Continue to Checkout",
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step Circle Widget
  Widget _buildStepCircle(String number, String label,
      {bool active = false, bool completed = false}) {
    Color color;
    if (completed) {
      color = Colors.green;
    } else if (active) {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Text(number, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
