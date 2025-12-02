import 'package:carhive/ads/checkout.dart';
import 'package:flutter/material.dart';

class BookVisitScreen extends StatefulWidget {
  final String carModel;
  final String carYear;
  final String engine;
  final String registeredCity;
  final String assembly;

  const BookVisitScreen({
    super.key,
    required this.carModel,
    required this.carYear,
    required this.engine,
    required this.registeredCity,
    required this.assembly,
  });

  @override
  State<BookVisitScreen> createState() => _BookVisitScreenState();
}

class _BookVisitScreenState extends State<BookVisitScreen> {
  String? selectedCity;
  String? selectedArea;
  final Map<String, List<String>> cityAreas = {
    'Lahore': ['DHA', 'Gulberg', 'Johar Town', 'Model Town', 'Bahria Town'],
    'Karachi': ['Clifton', 'DHA', 'Gulshan', 'North Nazimabad', 'Saddar'],
    'Islamabad': ['F-6', 'F-7', 'F-8', 'G-6', 'Blue Area'],
    'Rawalpindi': ['Bahria Town', 'Saddar', 'Satellite Town', 'Chaklala'],
  };
  final List<String> availableDates = ['Aug 6', 'Aug 7', 'Aug 8', 'Aug 9'];
  final Map<String, int> seatAvailability = {
    'Aug 6': 2,
    'Aug 7': 4,
    'Aug 8': 1,
    'Aug 9': 3,
  };

  String? selectedDate;
  String? selectedSlot;
  final Map<String, List<String>> timeSlotsByDate = {
    'Aug 6': ['09:30 AM', '11:00 AM', '01:00 PM', '03:00 PM'],
    'Aug 7': ['10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM'],
    'Aug 8': ['09:00 AM', '11:30 AM', '01:30 PM', '03:30 PM'],
    'Aug 9': ['10:30 AM', '12:30 PM', '02:30 PM', '04:30 PM'],
  };

  String _weekdayFor(String label) {
    final parts = label.split(' ');
    if (parts.length != 2) return '';
    final monthAbbr = parts[0];
    final day = int.tryParse(parts[1]) ?? 1;
    final months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final month = months[monthAbbr];
    if (month == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, month, day);
    const fullWeekNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return fullWeekNames[dt.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Visit"),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
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
                Container(width: 40, height: 2, color: const Color(0xFFFF6B35)),
                _buildStepCircle("2", "Visit", active: true),
                Container(width: 40, height: 2, color: Colors.grey),
                _buildStepCircle("3", "Checkout"),
              ],
            ),
            const SizedBox(height: 30),

            /// 🗺️ Visit Details Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available, color: Color(0xFFf48c25)),
                      const SizedBox(width: 8),
                      Text(
                        "Visit Details",
                        style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Select City",
                      style:
                          TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.location_city, color: isDark ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                      focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide:
                              BorderSide(color: Color(0xFFf48c25), width: 2)),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E1E1E) : null,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    value: selectedCity,
                    items: cityAreas.keys
                        .map((city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                        selectedArea = null;
                        selectedDate = null;
                      });
                    },
                  ),
                  if (selectedCity != null) ...[
                    const SizedBox(height: 16),
                    Text("Select Area",
                        style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.place_outlined, color: isDark ? Colors.white70 : Colors.black54),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(14)),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            borderSide:
                                BorderSide(color: Color(0xFFf48c25), width: 2)),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : null,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      value: selectedArea,
                      items: (cityAreas[selectedCity] ?? [])
                          .map((area) => DropdownMenuItem(
                                value: area,
                                child: Text(area),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedArea = value;
                          selectedDate = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            /// 📅 Date Selection + Seat Availability
            if (selectedArea != null) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Color(0xFFf48c25)),
                        const SizedBox(width: 8),
                        Text(
                          "Available Dates",
                          style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: () {
                        List<Widget> rows = [];
                        for (int i = 0; i < availableDates.length; i += 2) {
                          final isLastAndOdd = i == availableDates.length - 1;
                          if (isLastAndOdd) {
                            // Last item occupies full row
                            rows.add(
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child:
                                    _buildDateTile(availableDates[i], flex: 1),
                              ),
                            );
                          } else {
                            rows.add(
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child:
                                            _buildDateTile(availableDates[i])),
                                    const SizedBox(width: 10),
                                    if (i + 1 < availableDates.length)
                                      Expanded(
                                          child: _buildDateTile(
                                              availableDates[i + 1])),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                        return rows;
                      }(),
                    ),
                    if (selectedDate != null) ..[
                      const SizedBox(height: 14),
                      Text("Available Time Slots",
                          style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 8),
                      Column(
                        children: () {
                          final seats = seatAvailability[selectedDate] ?? 0;
                          final allSlots = timeSlotsByDate[selectedDate] ??
                              ['10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM'];
                          // Show exactly as many slots as seats available
                          final slots = allSlots.take(seats).toList();
                          List<Widget> rows = [];
                          for (int i = 0; i < slots.length; i += 2) {
                            final isLastAndOdd = i == slots.length - 1;
                            if (isLastAndOdd) {
                              rows.add(
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildSlotTile(slots[i], flex: 1),
                                ),
                              );
                            } else {
                              rows.add(
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(child: _buildSlotTile(slots[i])),
                                      const SizedBox(width: 10),
                                      if (i + 1 < slots.length)
                                        Expanded(
                                            child:
                                                _buildSlotTile(slots[i + 1])),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }
                          return rows;
                        }(),
                      ),
                    ],
                  ],
                ),
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
                              builder: (context) => CheckoutScreen(
                                    carModel: widget.carModel,
                                    carYear: widget.carYear,
                                    engine: widget.engine,
                                    registeredCity: widget.registeredCity,
                                    assembly: widget.assembly,
                                  )),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedDate != null
                      ? const Color(0xFFf48c25)
                      : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Continue to Checkout",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
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
    final Color brand = const Color(0xFFf48c25);
    final Color color = completed || active ? brand : Colors.grey;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Text(number, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// Date Tile Widget
  Widget _buildDateTile(String date, {int flex = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = date == selectedDate;
    final seats = seatAvailability[date] ?? 0;
    final bool disabled = seats == 0;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = date;
              selectedSlot = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isSelected ? const Color(0xFFf48c25) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? const Color(0xFFf48c25) : (isDark ? Colors.white12 : Colors.black12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Weekday pill - full width at top
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : (isDark ? Colors.white12 : Colors.black12)),
                  ),
                  child: Text(
                    _weekdayFor(date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Date and Seat badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Date with checkmark
                    Row(
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                        if (isSelected) const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    // Seat badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : (isDark ? Colors.white12 : Colors.black12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_seat,
                              size: 16,
                              color:
                                  isSelected ? Colors.white : Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            "$seats",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Time Slot Tile Widget
  Widget _buildSlotTile(String slot, {int flex = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelectedSlot = selectedSlot == slot;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSlot = slot;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelectedSlot ? const Color(0xFFf48c25) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelectedSlot ? const Color(0xFFf48c25) : (isDark ? Colors.white12 : Colors.black12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time,
                size: 16,
                color: isSelectedSlot ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Text(slot,
                style: TextStyle(
                    color: isSelectedSlot ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
