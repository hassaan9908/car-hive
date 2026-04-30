import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/support_chat_model.dart';
import '../services/support_chat_service.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchController = TextEditingController();
  final SupportChatService _supportService = SupportChatService();
  String _query = '';

  late final List<_HelpTopic> _topics = _buildTopics();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredTopics = _topics.where((topic) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;

      final haystack = <String>[
        topic.title,
        topic.subtitle,
        ...topic.items,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Help Topics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _query.isEmpty
                    ? 'Browse the main areas of CarHive and open any topic for step-by-step guidance.'
                    : '${filteredTopics.length} topic${filteredTopics.length == 1 ? '' : 's'} found for "${_query.trim()}".',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (filteredTopics.isEmpty)
                _EmptyResults(
                  query: _query.trim(),
                  onReset: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTopics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 88,
                      ),
                      itemBuilder: (context, index) {
                        final topic = filteredTopics[index];
                        return _HelpTopicCard(
                          topic: topic,
                          onTap: () => _openTopic(topic),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 22),
              _SupportCard(
                statusStream: _supportService.supportStatusStream(),
                onEmailTap: _emailSupport,
                onLiveChatTap: _openLiveChat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _emailSupport() async {
    final uri = Uri.parse('mailto:hfa5pro@gmail.com');

    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No mail app found. Please email us at hfa5pro@gmail.com',
          ),
        ),
      );
    }
  }

  void _openLiveChat() {
    Navigator.pushNamed(context, '/support-chat');
  }

  void _openTopic(_HelpTopic topic) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _HelpTopicDetailPage(topic: topic);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  List<_HelpTopic> _buildTopics() {
    return const [
      _HelpTopic(
        title: 'Getting Started',
        subtitle: 'Set up your account and get comfortable with the app.',
        icon: Icons.rocket_launch_outlined,
        items: [
          'Create an account or log in from the Profile tab to unlock selling, saving ads, visits, and investment features.',
          'Complete your profile with your name, username, phone number, and city so other users can recognize and trust you more easily.',
          'Use your phone or app theme settings to switch between light and dark mode for the experience that suits you best.',
        ],
      ),
      _HelpTopic(
        title: 'Browsing Cars',
        subtitle:
            'Search listings, apply filters, and compare vehicles faster.',
        icon: Icons.directions_car_outlined,
        items: [
          'Use the Home screen search and filters to narrow listings by city, price, brand, and other preferences.',
          'Open any car card to view photos, specs, seller details, and the actions available for that listing.',
          'If your results feel too limited, relax one or two filters and browse broader results before refining again.',
        ],
      ),
      _HelpTopic(
        title: 'Posting an Ad',
        subtitle:
            'Create a stronger listing with accurate details and good photos.',
        icon: Icons.post_add_outlined,
        items: [
          'Start from the Upload tab and fill in the car title, description, year, mileage, fuel type, and condition carefully.',
          'Upload clear, well-lit images from multiple angles so buyers can understand the car quickly.',
          'Set a realistic asking price by checking similar listings inside CarHive before you publish.',
        ],
      ),
      _HelpTopic(
        title: 'Managing Your Ads',
        subtitle: 'Keep your listings current and easy for buyers to trust.',
        icon: Icons.dashboard_customize_outlined,
        items: [
          'Open My Ads to review, edit, remove, or update the status of your active listings.',
          'Update price and availability as soon as things change so buyers do not waste time on outdated information.',
          'Replace weak cover photos with stronger ones because the first image is what most people judge first.',
        ],
      ),
      _HelpTopic(
        title: 'Contacting Sellers',
        subtitle: 'Reach out clearly and verify details before you commit.',
        icon: Icons.support_agent_outlined,
        items: [
          'Use Call when you want a quick conversation or Message when you want a written trail of the discussion.',
          'Ask for registration details, documents, maintenance history, and any important issues before agreeing on a deal.',
          'Meet in safe public places and confirm the car matches the listing before making payments.',
        ],
      ),
      _HelpTopic(
        title: 'Trust & Reviews',
        subtitle:
            'Use ratings, reviews, and activity signals to judge credibility.',
        icon: Icons.verified_user_outlined,
        items: [
          'Trust indicators and user activity can help you understand how established a seller is on the platform.',
          'Leave honest reviews after your experience so other buyers and sellers can make better decisions.',
          'If something looks suspicious, pause the deal and verify more details before moving forward.',
        ],
      ),
      _HelpTopic(
        title: 'Profile & Security',
        subtitle:
            'Protect your account and keep your personal details current.',
        icon: Icons.lock_outline,
        items: [
          'Use Edit Profile to keep your name, username, contact number, and city up to date.',
          'Treat OTPs, passwords, and private documents carefully and never share them in public chats or listings.',
          'If you have trouble signing in or resetting your account, use the login recovery flow or contact support.',
        ],
      ),
      _HelpTopic(
        title: 'Mutual Investment',
        subtitle:
            'Understand shared vehicle investments and your ownership records.',
        icon: Icons.pie_chart_outline,
        items: [
          'Browse investment opportunities carefully and review the target amount, total share pool, and current progress before investing.',
          'When you invest in the same opportunity again, CarHive adds the new amount to your existing holding instead of creating duplicate entries in My Investments.',
          'You can also explore share marketplace listings to review available percentages, asking prices, and any premium attached to a seller listing.',
        ],
      ),
      _HelpTopic(
        title: 'CarHive Assisted',
        subtitle: 'Book visits, complete checkout, and manage reschedules.',
        icon: Icons.event_available_outlined,
        items: [
          'Choose your city, area, available date, and time slot from the visit schedule provided by the admin team.',
          'After checkout, your booking is saved under My Visits where you can track booked and completed appointments.',
          'If your plans change, use Request Reschedule from My Visits and wait for the admin team to review the new preferred date and slot.',
        ],
      ),
    ];
  }
}

class _HelpTopicDetailPage extends StatelessWidget {
  const _HelpTopicDetailPage({required this.topic});

  final _HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(topic.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    topic.icon,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'What You Need To Know',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(topic.items.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HelpDetailItem(
                index: index + 1,
                text: topic.items[index],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search for help...',
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}

class _HelpTopicCard extends StatelessWidget {
  const _HelpTopicCard({
    required this.topic,
    required this.onTap,
  });

  final _HelpTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    topic.icon,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        topic.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topic.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpDetailItem extends StatelessWidget {
  const _HelpDetailItem({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.statusStream,
    required this.onEmailTap,
    required this.onLiveChatTap,
  });

  final Stream<SupportOnlineStatus> statusStream;
  final Future<void> Function() onEmailTap;
  final VoidCallback onLiveChatTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.support_agent,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Still need help?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Can\'t find what you\'re looking for?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<SupportOnlineStatus>(
            stream: statusStream,
            builder: (context, snapshot) {
              final status = snapshot.data ??
                  const SupportOnlineStatus(online: false, lastSeen: null);
              final dotColor =
                  status.online ? const Color(0xFF22C55E) : Colors.grey;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.45 : 0.70),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.online
                            ? 'Support is online now'
                            : 'Typically replies within a few hours',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEmailTap,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email Support'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLiveChatTap,
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Live Chat',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.query,
    required this.onReset,
  });

  final String query;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 40,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No help topics found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword for "$query" or reset the search to see every category.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onReset,
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
}

class _HelpTopic {
  const _HelpTopic({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> items;
}
