import 'package:carhive/ads/Bookcarvisit.dart';
import 'package:flutter/material.dart';

class CombinedInfoScreen extends StatefulWidget {
  const CombinedInfoScreen({super.key});

  @override
  _CombinedInfoScreenState createState() => _CombinedInfoScreenState();
}

class _CombinedInfoScreenState extends State<CombinedInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? name, phone, city, carModel, carYear, registeredCity;
  bool isLocal = false;
  bool isImported = false;
  bool _carModelFocused = false;
  final TextEditingController _carModelController = TextEditingController();

  final List<String> pakistaniCities = [
    'Punjab',
    'Sindh',
    'Islamabad',
    'KPK',
    'Balochistan',
    'Unregistered'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell It Myself'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: "Basic Information",
                children: [
                  _buildSquareTextField('Name', onSaved: (val) => name = val),
                  _buildSquareTextField('Phone Number',
                      keyboardType: TextInputType.phone,
                      onSaved: (val) => phone = val),
                  _buildSquareTextField('City', onSaved: (val) => city = val),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: "Car Information",
                children: [
                  Focus(
                    onFocusChange: (hasFocus) {
                      setState(() => _carModelFocused = hasFocus);
                    },
                    child: TextFormField(
                      controller: _carModelController,
                      decoration: InputDecoration(
                        labelText: 'Car Model',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _carModelFocused ? Colors.blue : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onSaved: (val) => carModel = val,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSquareTextField('Model Year',
                      keyboardType: TextInputType.number,
                      onSaved: (val) => carYear = val),
                  const SizedBox(height: 12),
                  const Text("Car Assembly",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  CheckboxListTile(
                    title: const Text("Local"),
                    value: isLocal,
                    activeColor: Colors.blue,
                    onChanged: (val) => setState(() => isLocal = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text("Imported"),
                    value: isImported,
                    activeColor: Colors.blue,
                    onChanged: (val) =>
                        setState(() => isImported = val ?? false),
                  ),
                  const SizedBox(height: 10),
                  const Text("Registered",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<String>(
                    value: registeredCity,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: pakistaniCities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => registeredCity = val),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BookVisitScreen()),
                      );
                    }
                  },
                  child: const Text("Next", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _step("1", true, "Basic & Car", highlight: true),
        _stepLine(),
        _step("2", false, "Book Visit"),
        _stepLine(),
        _step("3", false, "Checkout"),
      ],
    );
  }

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

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSquareTextField(String label,
      {TextInputType keyboardType = TextInputType.text,
      FormFieldSetter<String>? onSaved}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        keyboardType: keyboardType,
        onSaved: onSaved,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
