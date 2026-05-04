import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/support_chat_model.dart';
import '../models/support_quick_reply_model.dart';
import '../services/support_chat_service.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final SupportChatService _service = SupportChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  bool _startingNew = false;
  bool _escalatingToHuman = false;
  SupportQuickTopic? _selectedTopic;
  SupportQuickQuestion? _selectedQuestion;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.sendUserMessage(text);
      _controller.clear();
      _scrollToBottom(animated: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _selectTopic(SupportQuickTopic topic) {
    setState(() {
      _selectedTopic = topic;
      _selectedQuestion = null;
    });
    _scrollToBottom(animated: true);
  }

  void _selectQuestion(SupportQuickQuestion question) {
    setState(() => _selectedQuestion = question);
    _scrollToBottom(animated: true);
  }

  void _backToTopics() {
    setState(() {
      _selectedTopic = null;
      _selectedQuestion = null;
    });
    _scrollToBottom(animated: false);
  }

  Future<void> _talkToHuman() async {
    if (_escalatingToHuman) return;
    setState(() => _escalatingToHuman = true);
    try {
      await _service.sendUserMessage(
        _humanEscalationMessage(_selectedTopic, _selectedQuestion),
      );
      _scrollToBottom(animated: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _escalatingToHuman = false);
    }
  }

  String _humanEscalationMessage(
    SupportQuickTopic? topic,
    SupportQuickQuestion? question,
  ) {
    if (question != null) {
      return 'I need help with ${topic?.title ?? 'support'}: ${question.question}';
    }
    if (topic != null) return 'I need help with ${topic.title}.';
    return 'I want to talk to a human support agent.';
  }

  void _openQuickHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _QuickHelpSheet(
        service: _service,
        onTalkToHuman: (topic, question) async {
          await _service.sendUserMessage(_humanEscalationMessage(topic, question));
          _scrollToBottom(animated: true);
        },
      ),
    );
  }

  Future<void> _startNewChat() async {
    if (_startingNew) return;
    setState(() => _startingNew = true);
    try {
      await _service.startNewChat();
      _scrollToBottom(animated: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _startingNew = false);
    }
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CarHive Support')),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, 'loginscreen'),
            icon: const Icon(Icons.login),
            label: const Text('Log in to chat'),
          ),
        ),
      );
    }

    return StreamBuilder<SupportOnlineStatus>(
      stream: _service.supportStatusStream(),
      builder: (context, statusSnapshot) {
        final onlineStatus = statusSnapshot.hasError
            ? const SupportOnlineStatus(online: false, lastSeen: null)
            : statusSnapshot.data ??
                const SupportOnlineStatus(online: false, lastSeen: null);

        return StreamBuilder<SupportChat?>(
          stream: _service.currentUserChatStream(),
          builder: (context, chatSnapshot) {
            if (chatSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('CarHive Support')),
                body: _SupportErrorState(
                  message:
                      'We could not connect to support chat. Please check your connection and try again.',
                  onRetry: () => setState(() {}),
                ),
              );
            }

            final chat = chatSnapshot.data;
            final isResolved = chat?.isResolved ?? false;
            if (chat != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _service.markReadByUser();
              });
            }

            return Scaffold(
              appBar: AppBar(
                titleSpacing: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CarHive Support'),
                    Text(
                      chat?.ticketNumber.isNotEmpty == true
                          ? '#${chat!.ticketNumber}'
                          : 'Live chat',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: _openQuickHelpSheet,
                    tooltip: 'Quick help',
                    icon: const Icon(Icons.quickreply_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _OnlineBadge(status: onlineStatus),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (isResolved)
                    _ResolvedBanner(
                      onStartNew: _startNewChat,
                      loading: _startingNew,
                    ),
                  Expanded(
                    child: chat == null
                        ? _PreChatHelpFlow(
                            service: _service,
                            scrollController: _scrollController,
                            selectedTopic: _selectedTopic,
                            selectedQuestion: _selectedQuestion,
                            escalatingToHuman: _escalatingToHuman,
                            onSelectTopic: _selectTopic,
                            onSelectQuestion: _selectQuestion,
                            onBackToTopics: _backToTopics,
                            onTalkToHuman: _talkToHuman,
                          )
                        : StreamBuilder<List<SupportMessage>>(
                            stream: _service.messagesStream(user.uid),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return _SupportErrorState(
                                  message:
                                      'Messages could not load. Please reopen the chat.',
                                  onRetry: () => setState(() {}),
                                );
                              }

                              final messages = snapshot.data ?? const [];
                              final displayWelcome = messages.isEmpty;
                              _scrollToBottom(animated: false);

                              return ListView.builder(
                                controller: _scrollController,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(14, 16, 14, 18),
                                itemCount:
                                    messages.length + (displayWelcome ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (displayWelcome && index == 0) {
                                    return const _SupportBubble(
                                      text: SupportChatService.welcomeMessage,
                                      isUser: false,
                                      timestamp: null,
                                      isRead: true,
                                      showAvatar: true,
                                    );
                                  }
                                  final message = messages[
                                      index - (displayWelcome ? 1 : 0)];
                                  final isUser = message.senderType ==
                                      SupportSenderType.user;
                                  final previousIndex =
                                      index - (displayWelcome ? 2 : 1);
                                  final previous = previousIndex >= 0
                                      ? messages[previousIndex]
                                      : null;
                                  final showAvatar = !isUser &&
                                      (previous == null ||
                                          previous.senderType !=
                                              message.senderType);
                                  return _SupportBubble(
                                    text: message.text,
                                    isUser: isUser,
                                    timestamp: message.timestamp,
                                    isRead: message.isRead,
                                    showAvatar: showAvatar,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  _InputBar(
                    controller: _controller,
                    enabled: !isResolved,
                    sending: _sending,
                    onSend: _send,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PreChatHelpFlow extends StatelessWidget {
  const _PreChatHelpFlow({
    required this.service,
    required this.scrollController,
    required this.selectedTopic,
    required this.selectedQuestion,
    required this.escalatingToHuman,
    required this.onSelectTopic,
    required this.onSelectQuestion,
    required this.onBackToTopics,
    required this.onTalkToHuman,
  });

  final SupportChatService service;
  final ScrollController scrollController;
  final SupportQuickTopic? selectedTopic;
  final SupportQuickQuestion? selectedQuestion;
  final bool escalatingToHuman;
  final ValueChanged<SupportQuickTopic> onSelectTopic;
  final ValueChanged<SupportQuickQuestion> onSelectQuestion;
  final VoidCallback onBackToTopics;
  final VoidCallback onTalkToHuman;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      children: [
        const _SupportBubble(
          text: 'Hi! What do you need help with?',
          isUser: false,
          timestamp: null,
          isRead: true,
          showAvatar: true,
        ),
        if (selectedTopic == null)
          StreamBuilder<List<SupportQuickTopic>>(
            stream: service.quickTopicsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _QuickReplyError(onTalkToHuman: onTalkToHuman);
              }

              final topics = snapshot.data ?? const [];
              if (topics.isEmpty) {
                return _QuickReplyEmpty(onTalkToHuman: onTalkToHuman);
              }

              return _QuickReplyCard(
                title: 'Choose a topic',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: topics
                      .map(
                        (topic) => _QuickReplyButton(
                          label: topic.title,
                          leadingText: topic.icon,
                          onTap: () => onSelectTopic(topic),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          )
        else ...[
          _SupportBubble(
            text: selectedTopic!.title,
            isUser: true,
            timestamp: null,
            isRead: true,
            showAvatar: false,
          ),
          if (selectedQuestion == null)
            StreamBuilder<List<SupportQuickQuestion>>(
              stream: service.quickQuestionsStream(selectedTopic!.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _QuickReplyError(onTalkToHuman: onTalkToHuman);
                }

                final questions = snapshot.data ?? const [];
                if (questions.isEmpty) {
                  return _QuickReplyCard(
                    title: 'No quick answers in this topic yet',
                    child: _HumanEscalationActions(
                      escalatingToHuman: escalatingToHuman,
                      onTalkToHuman: onTalkToHuman,
                      onBackToTopics: onBackToTopics,
                    ),
                  );
                }

                return _QuickReplyCard(
                  title: 'What happened?',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final question in questions) ...[
                        _QuestionButton(
                          label: question.question,
                          onTap: () => onSelectQuestion(question),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextButton.icon(
                        onPressed: onBackToTopics,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back to topics'),
                      ),
                    ],
                  ),
                );
              },
            )
          else ...[
            _SupportBubble(
              text: selectedQuestion!.question,
              isUser: true,
              timestamp: null,
              isRead: true,
              showAvatar: false,
            ),
            _SupportBubble(
              text: selectedQuestion!.answer,
              isUser: false,
              timestamp: null,
              isRead: true,
              showAvatar: true,
            ),
            _QuickReplyCard(
              title: 'Need more help?',
              child: _HumanEscalationActions(
                escalatingToHuman: escalatingToHuman,
                onTalkToHuman: onTalkToHuman,
                onBackToTopics: onBackToTopics,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _QuickHelpBanner extends StatelessWidget {
  const _QuickHelpBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.quickreply_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quick Help: browse instant answers before waiting for support.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickHelpSheet extends StatefulWidget {
  const _QuickHelpSheet({
    required this.service,
    required this.onTalkToHuman,
  });

  final SupportChatService service;
  final Future<void> Function(
    SupportQuickTopic? topic,
    SupportQuickQuestion? question,
  ) onTalkToHuman;

  @override
  State<_QuickHelpSheet> createState() => _QuickHelpSheetState();
}

class _QuickHelpSheetState extends State<_QuickHelpSheet> {
  SupportQuickTopic? _topic;
  SupportQuickQuestion? _question;
  bool _sending = false;

  Future<void> _talkToHuman() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await widget.onTalkToHuman(_topic, _question);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.42,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.quickreply_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quick Help',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _SupportBubble(
                text: 'Hi! What do you need help with?',
                isUser: false,
                timestamp: null,
                isRead: true,
                showAvatar: true,
              ),
              if (_topic == null)
                StreamBuilder<List<SupportQuickTopic>>(
                  stream: widget.service.quickTopicsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _QuickReplyError(onTalkToHuman: _talkToHuman);
                    }

                    final topics = snapshot.data ?? const [];
                    if (topics.isEmpty) {
                      return _QuickReplyEmpty(onTalkToHuman: _talkToHuman);
                    }

                    return _QuickReplyCard(
                      title: 'Choose a topic',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: topics
                            .map(
                              (topic) => _QuickReplyButton(
                                label: topic.title,
                                leadingText: topic.icon,
                                onTap: () {
                                  setState(() {
                                    _topic = topic;
                                    _question = null;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                )
              else ...[
                _SupportBubble(
                  text: _topic!.title,
                  isUser: true,
                  timestamp: null,
                  isRead: true,
                  showAvatar: false,
                ),
                if (_question == null)
                  StreamBuilder<List<SupportQuickQuestion>>(
                    stream: widget.service.quickQuestionsStream(_topic!.id),
                    builder: (context, snapshot) {
                      final questions = snapshot.data ?? const [];
                      if (snapshot.hasError || questions.isEmpty) {
                        return _QuickReplyCard(
                          title: 'No quick answer found',
                          child: _HumanEscalationActions(
                            escalatingToHuman: _sending,
                            onTalkToHuman: _talkToHuman,
                            onBackToTopics: () => setState(() => _topic = null),
                          ),
                        );
                      }

                      return _QuickReplyCard(
                        title: 'What happened?',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final question in questions) ...[
                              _QuestionButton(
                                label: question.question,
                                onTap: () => setState(() => _question = question),
                              ),
                              const SizedBox(height: 8),
                            ],
                            TextButton.icon(
                              onPressed: () => setState(() => _topic = null),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back to topics'),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else ...[
                  _SupportBubble(
                    text: _question!.question,
                    isUser: true,
                    timestamp: null,
                    isRead: true,
                    showAvatar: false,
                  ),
                  _SupportBubble(
                    text: _question!.answer,
                    isUser: false,
                    timestamp: null,
                    isRead: true,
                    showAvatar: true,
                  ),
                  _QuickReplyCard(
                    title: 'Need more help?',
                    child: _HumanEscalationActions(
                      escalatingToHuman: _sending,
                      onTalkToHuman: _talkToHuman,
                      onBackToTopics: () {
                        setState(() {
                          _topic = null;
                          _question = null;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QuickReplyCard extends StatelessWidget {
  const _QuickReplyCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 42, bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _QuickReplyButton extends StatelessWidget {
  const _QuickReplyButton({
    required this.label,
    required this.leadingText,
    required this.onTap,
  });

  final String label;
  final String leadingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.46 : 0.72,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingText.isNotEmpty) ...[
                Text(leadingText, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
              ] else ...[
                Icon(
                  Icons.support_agent_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionButton extends StatelessWidget {
  const _QuestionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(Icons.chevron_right_rounded, color: scheme.primary),
        ],
      ),
    );
  }
}

class _HumanEscalationActions extends StatelessWidget {
  const _HumanEscalationActions({
    required this.escalatingToHuman,
    required this.onTalkToHuman,
    required this.onBackToTopics,
  });

  final bool escalatingToHuman;
  final VoidCallback onTalkToHuman;
  final VoidCallback onBackToTopics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: escalatingToHuman ? null : onTalkToHuman,
          icon: escalatingToHuman
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.support_agent_rounded),
          label: const Text('Talk to a human'),
        ),
        OutlinedButton.icon(
          onPressed: onBackToTopics,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Choose another topic'),
        ),
      ],
    );
  }
}

class _QuickReplyEmpty extends StatelessWidget {
  const _QuickReplyEmpty({required this.onTalkToHuman});

  final VoidCallback onTalkToHuman;

  @override
  Widget build(BuildContext context) {
    return _QuickReplyCard(
      title: 'Quick help is being set up',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can still start a live support ticket now.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onTalkToHuman,
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Talk to a human'),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyError extends StatelessWidget {
  const _QuickReplyError({required this.onTalkToHuman});

  final VoidCallback onTalkToHuman;

  @override
  Widget build(BuildContext context) {
    return _QuickReplyCard(
      title: 'Quick help could not load',
      child: FilledButton.icon(
        onPressed: onTalkToHuman,
        icon: const Icon(Icons.support_agent_rounded),
        label: const Text('Talk to a human'),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.status});

  final SupportOnlineStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.online ? const Color(0xFF22C55E) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.online ? 'Online' : 'Away',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SupportErrorState extends StatelessWidget {
  const _SupportErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: scheme.primary,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedBanner extends StatelessWidget {
  const _ResolvedBanner({
    required this.onStartNew,
    required this.loading,
  });

  final VoidCallback onStartNew;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF22C55E).withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This chat has been resolved. Start a new chat if you have another question.',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: loading ? null : onStartNew,
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start New Chat'),
          ),
        ],
      ),
    );
  }
}

class _SupportBubble extends StatelessWidget {
  const _SupportBubble({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isRead,
    required this.showAvatar,
  });

  final String text;
  final bool isUser;
  final DateTime? timestamp;
  final bool isRead;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bubbleColor = isUser ? scheme.primary : theme.cardColor;
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            showAvatar ? const _SupportAvatar() : const SizedBox(width: 34),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.45),
                          ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(color: textColor, height: 1.35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _metaText(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _metaText() {
    final time =
        timestamp == null ? 'Support' : DateFormat('h:mm a').format(timestamp!);
    if (!isUser) return time;
    return '$time  ${isRead ? 'Seen' : 'Delivered'}';
  }
}

class _SupportAvatar extends StatelessWidget {
  const _SupportAvatar();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: 17,
      backgroundColor: primary,
      child: const Text(
        'C',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => enabled ? onSend() : null,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Type your message...'
                      : 'This chat has been resolved',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.5 : 0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: enabled ? scheme.primary : scheme.outline,
              child: IconButton(
                onPressed: enabled && !sending ? onSend : null,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
