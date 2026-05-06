import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_bottom_nav.dart';
import '../services/investment_vehicle_service.dart';
import '../services/investment_service.dart';
import '../models/investment_vehicle_model.dart';
import '../models/investment_model.dart';
import 'investment_detail_page.dart';
import 'create_investment_page.dart';
import 'share_marketplace_page.dart';
import 'my_investment_detail_page.dart';

class Mutualinvestment extends StatefulWidget {
  const Mutualinvestment({super.key});

  @override
  State<Mutualinvestment> createState() => _MutualinvestmentState();
}

class _MutualinvestmentState extends State<Mutualinvestment>
    with SingleTickerProviderStateMixin {
  static const int _selectedIndex = 3;
  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

  late TabController _tabController;
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Available', 'My Investments', 'Marketplace'];
  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final InvestmentService _investmentService = InvestmentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTermsAccepted());
  }

  Future<void> _checkTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('investment_terms_accepted') ?? false;
    if (!accepted && mounted) {
      _showTermsDialog(isFirstTime: true);
    }
  }

  void _showTermsDialog({bool isFirstTime = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !isFirstTime,
      enableDrag: !isFirstTime,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.gavel,
                        color: Color(0xFFf48c25), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  children: [
                    // Subtitle block
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf48c25).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFf48c25).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mutual Investment – Terms & Conditions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFFf48c25),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pakistan-Wide Compliance + Investment Rules',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          Text(
                            'For: Ownership Transfer + Multi-Investor Vehicles + Provincial Laws',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _tcSection(isDark, '1. Purpose & Acceptance',
                        'By participating in the Mutual Investment Program ("Program") through this App ("Platform"), the Investor acknowledges and agrees to:\n'
                        '• These Terms & Conditions\n'
                        '• Federal Pakistani vehicle laws\n'
                        '• Provincial Excise & Taxation rules of Punjab, Sindh, and Islamabad (ICT)\n'
                        '• Platform\'s investment process and owner-selection mechanism\n\n'
                        'Continued use of the Platform signifies acceptance of updated policies.'),
                    _tcSection(isDark, '2. Mutual Investment Structure',
                        '2.1 Multi-Investor Setup\n'
                        'A vehicle listed by its current owner may be opened for Mutual Investment, allowing 4–6 investors to bid or invest in the vehicle.\n\n'
                        '2.2 Ownership Determination\n'
                        '• Highest investor / highest payer becomes the legal owner (the person whose name will be on the official Registration Book/Smart Card)\n'
                        '• 2nd highest investor becomes the secondary beneficiary, NOT legal owner\n'
                        '• All remaining investors hold financial stakes only, not ownership\n\n'
                        'Important Legal Note (Pakistan Law):\n'
                        'Pakistan allows only one legal owner per vehicle on the official Excise registration. There is no system for joint names on the Registration Book/Smart Card.\n'
                        'Legal ownership = only one name. Financial rights = based on internal agreements between investors.'),
                    _tcSection(isDark, '3. Company\'s Role & Responsibilities',
                        '3.1 Company Manages Entire Transfer Process\n'
                        'The Company is responsible for:\n'
                        '• Handling all legal documents\n'
                        '• Coordinating with Excise & Taxation offices\n'
                        '• Preparing and submitting transfer files\n'
                        '• Ensuring biometric verification is completed\n'
                        '• Scheduling visits to Excise / NADRA e-Sahulat\n'
                        '• Assisting in Punjab ePay digital process\n'
                        '• Ensuring Sindh Form T.O. compliance\n'
                        '• Ensuring ICT MRA requirements are fulfilled\n\n'
                        '3.2 Company is Physically Present\n'
                        'To prevent fraud and ensure safety:\n'
                        '• The Company will be physically present with all parties at Excise offices\n'
                        '• Biometric verification will be conducted face to face\n'
                        '• Pakistan does NOT allow online or remote multi-owner transfers\n'
                        '• Therefore, all ownership changes must be done in person'),
                    _tcSection(isDark, '4. Agreement Between Investors',
                        'Because Pakistan only allows one registered owner, all other investor rights come from:\n'
                        '• A private Mutual Investment Agreement\n'
                        '• Stamped and notarized contract between investors\n'
                        '• Internal guidelines of the Platform\n\n'
                        'This Agreement defines:\n'
                        '• Profit sharing\n'
                        '• Use of vehicle\n'
                        '• Responsibilities of highest and secondary investors\n'
                        '• Exit rules\n'
                        '• Dispute handling\n'
                        '• Buyout options\n\n'
                        'This Agreement is legally binding among the investors, even though Excise recognizes only one owner.'),
                    _tcSection(isDark, '5. Mandatory Legal Compliance (Pakistan-Wide)',
                        '5.1 Biometric Verification\n'
                        'Required by law for:\n'
                        '• Seller\n'
                        '• Buyer (highest investor)\n'
                        '• Hire Purchase Agreement (HPA)/Bank representative (if financed)\n\n'
                        'Biometrics occur at:\n'
                        '• Excise & Taxation Office\n'
                        '• NADRA e-Sahulat Center\n'
                        '• Facial recognition (Punjab digital system)\n\n'
                        '5.2 Required Documents\n'
                        'Applicable nationwide:\n'
                        '• CNIC copies of Buyer & Seller\n'
                        '• Form F or Form T.O.\n'
                        '• Sale Agreement / Affidavit\n'
                        '• Original Registration Book / Smart Card\n'
                        '• Token tax clearance\n'
                        '• NOC from banks if vehicle is leased'),
                    _tcSection(isDark, '6. Provincial Regulations',
                        '6.1 Punjab (ePay Transfer System)\n'
                        '• Registration number check\n'
                        '• Buyer details\n'
                        '• HPA declaration\n'
                        '• PSID challan generation (17-digit)\n'
                        '• Digital status track: BioPending → EV → PA → Delivered\n'
                        '• Online payment of transfer fees\n\n'
                        '6.2 Islamabad (ICT)\n'
                        '• Application to MRA/ETO\n'
                        '• Form F\n'
                        '• CNIC copies\n'
                        '• Attested documents if someone cannot appear\n'
                        '• Proof of residence for out-of-district applicants\n'
                        '• Affidavit that car is not stolen/criminally involved\n'
                        '• Mobile registration via City Islamabad App\n\n'
                        '6.3 Sindh (Form T.O. Based System)\n'
                        '• Stamped Sale Deed\n'
                        '• CNIC copies\n'
                        '• Original file\n'
                        '• Vehicle physical inspection\n'
                        '• RTA/PHA NOC for commercial vehicles\n'
                        '• Internal Excise notes (ETI, AETO, ETO approvals)'),
                    _tcSection(isDark, '7. Nature of Rights of Investors',
                        '7.1 Legal Ownership\n'
                        'Only one name appears on official records: the highest investor.\n\n'
                        '7.2 Secondary Investor\n'
                        'Second highest investor receives:\n'
                        '• Secondary claim\n'
                        '• Economic interest\n'
                        '• Contractual protections\n'
                        'But NOT official Excise-level ownership.\n\n'
                        '7.3 Other Investors\n'
                        'Remaining investors hold:\n'
                        '• Financial/economic stake\n'
                        '• Contractual rights\n'
                        '• Zero Excise-level rights'),
                    _tcSection(isDark, '8. Company Limitations',
                        'The Company does not:\n'
                        '• Change, bypass, or influence government rules\n'
                        '• Provide online ownership transfer (illegal in Pakistan)\n'
                        '• Modify Excise records\n'
                        '• Accept liability for Excise delays\n'
                        '• Take responsibility for incorrect or missing user documents\n'
                        '• Guarantee investor disputes between themselves (covered under agreement)'),
                    _tcSection(isDark, '9. Fraud Prevention & Safety Measures',
                        'To prevent fraud, the Company ensures:\n'
                        '• Face-to-face verification of all parties\n'
                        '• Mandatory CNIC matching\n'
                        '• Physical attendance during biometrics\n'
                        '• Inspection of original vehicle documents\n'
                        '• Excise-level verification before investment\n'
                        '• Seller must bring original vehicle and plates at time of transfer\n\n'
                        'No fund release until:\n'
                        '• Buyer & Seller biometrics match\n'
                        '• Excise confirms case\n'
                        '• Transfer reaches Delivered status (Punjab) or equivalent in region'),
                    _tcSection(isDark, '10. Risks & Liability',
                        'Investors understand risks:\n'
                        '• Delays in Excise offices\n'
                        '• Biometrics not matching\n'
                        '• Problems with vehicle file\n'
                        '• District-to-district NOC issues\n'
                        '• Rejection from Excise due to errors\n'
                        '• Disputes between investors\n\n'
                        'The Platform is not liable for losses due to government decisions or investor misrepresentation.'),
                    _tcSection(isDark, '11. Exit & Resale of Investment',
                        'All exits follow:\n'
                        '• Platform rules\n'
                        '• Mutual Investment Agreement\n'
                        '• Provincial Excise laws\n'
                        '• New biometric + document submission by replacing investor'),
                    _tcSection(isDark, '12. Dispute Resolution',
                        'Disputes are resolved through:\n'
                        '1. Platform internal process\n'
                        '2. Terms of the Mutual Investment Agreement\n'
                        '3. Pakistani law in the relevant jurisdiction'),
                    _tcSection(isDark, '13. Amendments',
                        'The Platform may change these T&Cs at any time. Continued use of the Mutual Investment feature after any update constitutes acceptance of the revised terms.'),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: May 2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (isFirstTime)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/', (route) => false);
                          },
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                                color: Color(0xFFf48c25)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Decline',
                              style:
                                  TextStyle(color: Color(0xFFf48c25))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setBool(
                                'investment_terms_accepted', true);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFf48c25),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Accept & Continue'),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFf48c25),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tcSection(bool isDark, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFFf48c25),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
          context, _navRoutes[0], (route) => false);
    } else {
      Navigator.pushReplacementNamed(context, _navRoutes[index]);
    }
  }

  void _onTopTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _tabController.animateTo(index);
  }

  Widget _buildTopTabs() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: EdgeInsets.only(right: index < _tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => _onTopTabChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        )
                      : null,
                  color: isSelected ? null : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color:
                                theme.colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    // Guest user UI - similar to My Ads
    if (user == null) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mutual Investment',
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
           
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Please login to view investments',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, 'loginscreen');
                    },
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) => _onTabSelected(context, index),
            onFabPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacementNamed(context, _navRoutes[2]);
              }
            },
          ),
        ),
      );
    }

    // Logged in user UI
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mutual Investment',
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.gavel_outlined),
              onPressed: () => _showTermsDialog(),
              tooltip: 'Terms & Conditions',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateInvestmentPage(),
                  ),
                );
                if (result != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Investment opportunity created!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              tooltip: 'Create Investment',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(
              children: [
                
                _buildTopTabs(),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Available Investments Tab
              _buildAvailableInvestmentsTab(),
              // My Investments Tab
                _buildMyInvestmentsTab(user.uid),
              // Marketplace Tab
              _buildMarketplaceTab(),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => _onTabSelected(context, index),
          onFabPressed: () {
            if (_selectedIndex != 2) {
              Navigator.pushReplacementNamed(context, _navRoutes[2]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAvailableInvestmentsTab() {
    return StreamBuilder<List<InvestmentVehicleModel>>(
      stream: _vehicleService.getOpenInvestmentVehicles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading investment opportunities...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final vehicles = snapshot.data ?? [];

        if (vehicles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      size: 64,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Opportunities Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New investment opportunities will appear here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return _buildInvestmentVehicleCard(vehicle);
          },
        );
      },
    );
  }

  Widget _buildMyInvestmentsTab(String userId) {
    return StreamBuilder<List<InvestmentModel>>(
      stream: _investmentService.getUserActiveInvestments(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your investments...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final investments = snapshot.data ?? [];

        if (investments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Investments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start investing in vehicles to see\nyour portfolio here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: investments.length,
          itemBuilder: (context, index) {
            final investment = investments[index];
            return _buildMyInvestmentCard(investment);
          },
        );
      },
    );
  }

  Widget _buildMarketplaceTab() {
    return ShareMarketplacePage();
  }

  Widget _buildInvestmentVehicleCard(InvestmentVehicleModel vehicle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvestmentDetailPage(
                  vehicleInvestmentId: vehicle.id,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Image
                if (vehicle.imageUrls != null && vehicle.imageUrls!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.network(
                        vehicle.imageUrls!.first,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Vehicle Image',
                                  style: TextStyle(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Title
                Text(
                  vehicle.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                // Vehicle Details
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${vehicle.year}',
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 16),
                    Icon(Icons.local_gas_station,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(vehicle.fuel,
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 16),
                    Icon(Icons.speed,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${vehicle.mileage} km',
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 12),
                // Investment Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Investment Goal: ${vehicle.totalInvestmentGoal.toStringAsFixed(0)} PKR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${vehicle.fundingProgress.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: vehicle.fundingProgress / 100,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invested: ${vehicle.currentInvestment.toStringAsFixed(0)} PKR / Remaining: ${vehicle.remainingAmount.toStringAsFixed(0)} PKR',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Minimum Contribution
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.blue.withOpacity(0.2) : Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Minimum: ${vehicle.minimumContribution.toStringAsFixed(0)} PKR',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyInvestmentCard(InvestmentModel investment) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investment',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '#${investment.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(investment.investmentRatio * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount Invested',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${investment.amount.toStringAsFixed(0)} PKR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profit Received',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${investment.totalProfitReceived.toStringAsFixed(0)} PKR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyInvestmentDetailPage(
                        investmentId: investment.id,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
