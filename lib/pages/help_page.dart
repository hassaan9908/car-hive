import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: const _HelpContent(),
    );
  }
}

class _HelpContent extends StatelessWidget {
  const _HelpContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to CarHive', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'CarHive helps you buy, sell and explore cars with trust. This guide explains all major features so you can get the most out of the app.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _sectionHeader(context, 'Getting Started'),
            _bulletList([
              'Create an account or log in via the Profile tab.',
              'Complete your profile: name, username, phone, city. Verified phone improves trust.',
              'Set your theme (light/dark) from device or app settings if available.'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Browsing Cars'),
            _bulletList([
              'Homepage shows curated and recent ads (Cool Rides section in development).',
              'Use search and filters (city, price, brand) to narrow results.',
              'Tap a car to open the detailed page with photos, specs, seller info and actions.'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Posting an Ad'),
            _bulletList([
              'Go to Upload tab to start creating a listing.',
              'Add clear title, description and accurate specifications (year, mileage, condition).',
              'Upload high quality photos. Images are stored using Cloudinary for fast global delivery.',
              'Set a fair price: research similar models using search first.',
              'Review and publish. Your ad appears immediately; can be edited later in My Ads.'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Managing Your Ads'),
            _bulletList([
              'Open My Ads to view, edit or remove listings.',
              'Keep details up to date (price / availability) to maintain trust.',
              'Replace blurry images with clearer ones; first photo is the primary thumbnail.'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Contacting Sellers'),
            _bulletList([
              'On a car detail page you can Call or Message the seller.',
              'Use Call for quick negotiation; use Message for sharing details & leaving a written trace.',
              'Be polite and verify information (registration, documents) before payment.'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Trust & Reviews'),
            _bulletList([
              'Trust level badges appear near usernames, based on activity & positive interactions.',
              'Leaving honest reviews helps build a safer marketplace.',
              'Suspicious behavior can be reported (feature under expansion).'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Profile & Security'),
            _bulletList([
              'Edit Profile lets you update personal details in real time.',
              'Phone number changes require OTP verification for security.',
              'Profile photo uploads use Cloudinary; avoid personal documents in images.'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Images & Media'),
            _bulletList([
              'Use natural daylight; shoot from multiple angles (front, rear, side, interior, engine).',
              'Avoid heavy watermarks; keep file size reasonable for faster loading.',
              'First selected image should be the most appealing angle.'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Search Tips'),
            _bulletList([
              'Combine filters (city + brand + price range) for precision.',
              'If results are empty, broaden criteria (increase max price or remove mileage filter).',
              'Save interesting listings by bookmarking (feature roadmap).'
            ]),
            const SizedBox(height: 20),
            _sectionHeader(context, 'FAQ'),
            _qa('Why can\'t I see my uploaded ad immediately?',
                'It may take a few seconds to propagate. Pull-to-refresh or revisit My Ads. Ensure network connectivity.'),
            _qa('How do I reset my password?',
                'Use the Log in screen forgot password option (if enabled) or contact support.'),
            _qa('What makes a trusted seller?',
                'Consistent accurate listings, responsive communication, and positive review history.'),
            _qa('Is in-app payment supported?',
                'Currently transactions are arranged directly between buyer and seller. In-app escrow is on the roadmap.'),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Best Practices'),
            _bulletList([
              'Never share one-time codes or full personal documents publicly.',
              'Meet in safe public locations and verify original documents before paying.',
              'Use official transfer processes for ownership changes.'
            ]),
            const SizedBox(height: 24),
            _sectionHeader(context, 'Need More Help?'),
            Text(
              'If you encounter issues: update the app to latest version, check your connection, then contact support (support@carhive.example). Include screenshots and your device model.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'CarHive © ${DateTime.now().year}',
                style: textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _bulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 8),
                  child: Icon(Icons.circle, size: 8, color: Colors.blueAccent),
                ),
                Expanded(
                  child: Text(item),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _qa(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(answer),
        ],
      ),
    );
  }
}
