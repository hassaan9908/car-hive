import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/support_chat_model.dart';
import '../../models/support_quick_reply_model.dart';
import '../../services/support_chat_service.dart';
import 'admin_theme.dart';

class AdminSupportChatsPage extends StatefulWidget {
  const AdminSupportChatsPage({super.key});

  @override
  State<AdminSupportChatsPage> createState() => _AdminSupportChatsPageState();
}

class _AdminSupportChatsPageState extends State<AdminSupportChatsPage> {
  final SupportChatService _service = SupportChatService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _messagesController = ScrollController();

  String _query = '';
  String _filter = 'all';
  String? _selectedUserId;
  bool _sending = false;
  bool _resolving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _replyController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  Future<void> _sendReply(SupportChat chat) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sending || chat.isResolved) return;

    setState(() => _sending = true);
    try {
      await _service.sendAdminMessage(userId: chat.userId, text: text);
      _replyController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send reply: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resolve(SupportChat chat) async {
    if (_resolving || chat.isResolved) return;
    setState(() => _resolving = true);
    try {
      await _service.markResolved(chat);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resolve chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _selectChat(SupportChat chat) {
    setState(() => _selectedUserId = chat.userId);
    _service.markReadByAdmin(chat.userId);
    _scrollToBottom();
  }

  void _openQuickReplyManager() {
    showDialog<void>(
      context: context,
      builder: (context) => _QuickReplyManagerDialog(service: _service),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesController.hasClients) return;
      _messagesController.animateTo(
        _messagesController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final border = AdminThemeTokens.pageBorder(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<SupportChat>>(
        stream: _service.allChatsStream(),
        builder: (context, snapshot) {
          final chats = _filtered(snapshot.data ?? const []);
          final selected = _selectedUserId == null
              ? (chats.isNotEmpty ? chats.first : null)
              : chats
                  .where((chat) => chat.userId == _selectedUserId)
                  .cast<SupportChat?>()
                  .firstOrNull;

          if (_selectedUserId == null && selected != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _selectChat(selected);
            });
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 980;
              final list = _ChatListPanel(
                chats: chats,
                selectedUserId: selected?.userId,
                queryController: _searchController,
                query: _query,
                filter: _filter,
                onQueryChanged: (value) => setState(() => _query = value),
                onFilterChanged: (value) => setState(() => _filter = value),
                onSelect: _selectChat,
                onManageQuickReplies: _openQuickReplyManager,
              );
              final detail = selected == null
                  ? const _NoChatSelected()
                  : _ChatDetailPanel(
                      chat: selected,
                      service: _service,
                      controller: _replyController,
                      messagesController: _messagesController,
                      sending: _sending,
                      resolving: _resolving,
                      onSend: () => _sendReply(selected),
                      onResolve: () => _resolve(selected),
                      onMessagesBuilt: _scrollToBottom,
                    );

              if (narrow) {
                return Column(
                  children: [
                    SizedBox(height: 360, child: list),
                    Divider(height: 1, color: border),
                    Expanded(child: detail),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(width: 380, child: list),
                  VerticalDivider(width: 1, color: border),
                  Expanded(child: detail),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<SupportChat> _filtered(List<SupportChat> chats) {
    final query = _query.trim().toLowerCase();
    return chats.where((chat) {
      final matchesFilter = _filter == 'all' ||
          (_filter == 'open' && chat.status == SupportChatStatus.open) ||
          (_filter == 'resolved' && chat.status == SupportChatStatus.resolved);
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final ticket = chat.ticketNumber.toLowerCase();
      final name = chat.userProfile.name.toLowerCase();
      return ticket.contains(query) || name.contains(query);
    }).toList();
  }
}

class _ChatListPanel extends StatelessWidget {
  const _ChatListPanel({
    required this.chats,
    required this.selectedUserId,
    required this.queryController,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSelect,
    required this.onManageQuickReplies,
  });

  final List<SupportChat> chats;
  final String? selectedUserId;
  final TextEditingController queryController;
  final String query;
  final String filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<SupportChat> onSelect;
  final VoidCallback onManageQuickReplies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Support Chats',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onManageQuickReplies,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Quick Replies'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Live tickets and instant answer setup',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: queryController,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search name or ticket...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            queryController.clear();
                            onQueryChanged('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _FilterChipButton(
                    label: 'All',
                    value: 'all',
                    selectedValue: filter,
                    onChanged: onFilterChanged,
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: 'Open',
                    value: 'open',
                    selectedValue: filter,
                    onChanged: onFilterChanged,
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: 'Resolved',
                    value: 'resolved',
                    selectedValue: filter,
                    onChanged: onFilterChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: chats.isEmpty
              ? _EmptyChatsState(color: scheme.primary)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _ChatListTile(
                      chat: chat,
                      selected: chat.userId == selectedUserId,
                      onTap: () => onSelect(chat),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _QuickReplyManagerDialog extends StatefulWidget {
  const _QuickReplyManagerDialog({required this.service});

  final SupportChatService service;

  @override
  State<_QuickReplyManagerDialog> createState() =>
      _QuickReplyManagerDialogState();
}

class _QuickReplyManagerDialogState extends State<_QuickReplyManagerDialog> {
  bool _busy = false;

  Future<void> _saveTopic([SupportQuickTopic? topic]) async {
    final result = await showDialog<_TopicFormData>(
      context: context,
      builder: (context) => _TopicFormDialog(topic: topic),
    );
    if (result == null) return;

    await _runAdminAction(() async {
      if (topic == null) {
        await widget.service.createQuickTopic(
          title: result.title,
          icon: result.icon,
          sortOrder: result.sortOrder,
          isActive: result.isActive,
        );
      } else {
        await widget.service.updateQuickTopic(
          topicId: topic.id,
          title: result.title,
          icon: result.icon,
          sortOrder: result.sortOrder,
          isActive: result.isActive,
        );
      }
    });
  }

  Future<void> _deleteTopic(SupportQuickTopic topic) async {
    final confirmed = await _confirm(
      title: 'Delete topic?',
      message: 'This will remove "${topic.title}" and all questions under it.',
    );
    if (!confirmed) return;
    await _runAdminAction(() => widget.service.deleteQuickTopic(topic.id));
  }

  Future<void> _saveQuestion(
    SupportQuickTopic topic, [
    SupportQuickQuestion? question,
  ]) async {
    final result = await showDialog<_QuestionFormData>(
      context: context,
      builder: (context) => _QuestionFormDialog(question: question),
    );
    if (result == null) return;

    await _runAdminAction(() async {
      if (question == null) {
        await widget.service.createQuickQuestion(
          topicId: topic.id,
          question: result.question,
          answer: result.answer,
          sortOrder: result.sortOrder,
          isActive: result.isActive,
        );
      } else {
        await widget.service.updateQuickQuestion(
          topicId: topic.id,
          questionId: question.id,
          question: result.question,
          answer: result.answer,
          sortOrder: result.sortOrder,
          isActive: result.isActive,
        );
      }
    });
  }

  Future<void> _deleteQuestion(SupportQuickQuestion question) async {
    final confirmed = await _confirm(
      title: 'Delete question?',
      message: 'This quick answer will no longer appear in the user app.',
    );
    if (!confirmed) return;
    await _runAdminAction(
      () => widget.service.deleteQuickQuestion(
        topicId: question.topicId,
        questionId: question.id,
      ),
    );
  }

  Future<void> _seedStarterReplies() async {
    await _runAdminAction(widget.service.seedStarterQuickReplies);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runAdminAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save quick reply: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.82;

    return Dialog(
      insetPadding: const EdgeInsets.all(22),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 980, maxHeight: height),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.quickreply_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Replies',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Manage the instant help topics shown before live chat starts.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _saveTopic(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Topic'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: StreamBuilder<List<SupportQuickTopic>>(
                stream: widget.service.quickTopicsStream(activeOnly: false),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Quick replies could not load.'),
                    );
                  }

                  final topics = snapshot.data ?? const [];
                  if (topics.isEmpty) {
                    return _QuickReplyAdminEmpty(
                      onAdd: () => _saveTopic(),
                      onSeed: _seedStarterReplies,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: topics.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return _QuickTopicTile(
                        topic: topic,
                        service: widget.service,
                        onEditTopic: () => _saveTopic(topic),
                        onDeleteTopic: () => _deleteTopic(topic),
                        onAddQuestion: () => _saveQuestion(topic),
                        onEditQuestion: (question) =>
                            _saveQuestion(topic, question),
                        onDeleteQuestion: _deleteQuestion,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTopicTile extends StatelessWidget {
  const _QuickTopicTile({
    required this.topic,
    required this.service,
    required this.onEditTopic,
    required this.onDeleteTopic,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
  });

  final SupportQuickTopic topic;
  final SupportChatService service;
  final VoidCallback onEditTopic;
  final VoidCallback onDeleteTopic;
  final VoidCallback onAddQuestion;
  final ValueChanged<SupportQuickQuestion> onEditQuestion;
  final ValueChanged<SupportQuickQuestion> onDeleteQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: topic.icon.isEmpty
              ? Icon(Icons.support_agent_rounded, color: scheme.primary)
              : Text(topic.icon, style: const TextStyle(fontSize: 17)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                topic.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!topic.isActive)
              const _StatusChip(label: 'Inactive', color: Colors.grey),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Edit topic',
              onPressed: onEditTopic,
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'Delete topic',
              onPressed: onDeleteTopic,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        subtitle: Text(
          'Order ${topic.sortOrder}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAddQuestion,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Question'),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<SupportQuickQuestion>>(
            stream: service.quickQuestionsStream(topic.id, activeOnly: false),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Questions could not load.'),
                );
              }

              final questions = snapshot.data ?? const [];
              if (questions.isEmpty) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No questions yet.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                );
              }

              return Column(
                children: questions
                    .map(
                      (question) => _QuickQuestionTile(
                        question: question,
                        onEdit: () => onEditQuestion(question),
                        onDelete: () => onDeleteQuestion(question),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickQuestionTile extends StatelessWidget {
  const _QuickQuestionTile({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final SupportQuickQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.35 : 0.62,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        question.question,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!question.isActive)
                      const _StatusChip(label: 'Inactive', color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  question.answer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Order ${question.sortOrder}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit question',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Delete question',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyAdminEmpty extends StatelessWidget {
  const _QuickReplyAdminEmpty({
    required this.onAdd,
    required this.onSeed,
  });

  final VoidCallback onAdd;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quickreply_outlined, size: 58, color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              'No quick replies yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add topics and answers users can try before opening a live ticket.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Topic'),
                ),
                OutlinedButton.icon(
                  onPressed: onSeed,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Add Starter Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicFormDialog extends StatefulWidget {
  const _TopicFormDialog({this.topic});

  final SupportQuickTopic? topic;

  @override
  State<_TopicFormDialog> createState() => _TopicFormDialogState();
}

class _TopicFormDialogState extends State<_TopicFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _iconController;
  late final TextEditingController _sortController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final topic = widget.topic;
    _titleController = TextEditingController(text: topic?.title ?? '');
    _iconController = TextEditingController(text: topic?.icon ?? '');
    _sortController = TextEditingController(
      text: (topic?.sortOrder ?? 0).toString(),
    );
    _isActive = topic?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _iconController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      _TopicFormData(
        title: title,
        icon: _iconController.text.trim(),
        sortOrder: int.tryParse(_sortController.text.trim()) ?? 0,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.topic == null ? 'Add Topic' : 'Edit Topic'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Topic title'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: 'Icon or emoji',
                hintText: 'Example: car, payment, help',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort order'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: const Text('Active in user app'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({this.question});

  final SupportQuickQuestion? question;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _sortController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _questionController = TextEditingController(text: question?.question ?? '');
    _answerController = TextEditingController(text: question?.answer ?? '');
    _sortController = TextEditingController(
      text: (question?.sortOrder ?? 0).toString(),
    );
    _isActive = question?.isActive ?? true;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();
    if (question.isEmpty || answer.isEmpty) return;
    Navigator.pop(
      context,
      _QuestionFormData(
        question: question,
        answer: answer,
        sortOrder: int.tryParse(_sortController.text.trim()) ?? 0,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(labelText: 'Auto answer'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort order'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: const Text('Active in user app'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TopicFormData {
  const _TopicFormData({
    required this.title,
    required this.icon,
    required this.sortOrder,
    required this.isActive,
  });

  final String title;
  final String icon;
  final int sortOrder;
  final bool isActive;
}

class _QuestionFormData {
  const _QuestionFormData({
    required this.question,
    required this.answer,
    required this.sortOrder,
    required this.isActive,
  });

  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value == selectedValue;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.chat,
    required this.selected,
    required this.onTap,
  });

  final SupportChat chat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = chat.status == SupportChatStatus.open
        ? scheme.primary
        : const Color(0xFF22C55E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              _ProfileAvatar(profile: chat.userProfile),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.userProfile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          _relativeTime(chat.lastMessageTime),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${chat.ticketNumber}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessage.isEmpty
                          ? (chat.subject.isEmpty
                              ? 'Waiting for first message'
                              : chat.subject)
                          : chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(
                          label: supportStatusLabel(chat.status),
                          color: statusColor,
                        ),
                        const Spacer(),
                        if (chat.unreadByAdmin > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            height: 22,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${chat.unreadByAdmin}',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatDetailPanel extends StatelessWidget {
  const _ChatDetailPanel({
    required this.chat,
    required this.service,
    required this.controller,
    required this.messagesController,
    required this.sending,
    required this.resolving,
    required this.onSend,
    required this.onResolve,
    required this.onMessagesBuilt,
  });

  final SupportChat chat;
  final SupportChatService service;
  final TextEditingController controller;
  final ScrollController messagesController;
  final bool sending;
  final bool resolving;
  final VoidCallback onSend;
  final VoidCallback onResolve;
  final VoidCallback onMessagesBuilt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Row(
            children: [
              _ProfileAvatar(profile: chat.userProfile, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.userProfile.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${chat.ticketNumber}  •  ${chat.userProfile.email.isEmpty ? 'No email' : chat.userProfile.email}'
                      '${chat.userProfile.joinedAt == null ? '' : '  •  Joined ${DateFormat('MMM d, yyyy').format(chat.userProfile.joinedAt!)}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!chat.isResolved)
                FilledButton.icon(
                  onPressed: resolving ? null : onResolve,
                  icon: resolving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Resolved'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                  ),
                )
              else
                const _StatusChip(
                  label: 'Resolved',
                  color: Color(0xFF22C55E),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<SupportMessage>>(
            stream: service.messagesStream(chat.userId),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? const [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                service.markReadByAdmin(chat.userId);
                onMessagesBuilt();
              });

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: messagesController,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _AdminMessageBubble(message: message);
                },
              );
            },
          ),
        ),
        _AdminReplyBar(
          controller: controller,
          enabled: !chat.isResolved,
          sending: sending,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _AdminMessageBubble extends StatelessWidget {
  const _AdminMessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAdmin = message.senderType == SupportSenderType.admin;
    final bubbleColor = isAdmin ? scheme.primary : theme.cardColor;
    final textColor = isAdmin ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isAdmin ? 18 : 5),
                      bottomRight: Radius.circular(isAdmin ? 5 : 18),
                    ),
                    border: isAdmin
                        ? null
                        : Border.all(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.45),
                          ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, height: 1.35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(message.timestamp),
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
}

class _AdminReplyBar extends StatelessWidget {
  const _AdminReplyBar({
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
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
              onSubmitted: (_) => enabled ? onSend() : null,
              decoration: InputDecoration(
                hintText: enabled ? 'Write a reply...' : 'Ticket resolved',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: enabled && !sending ? onSend : null,
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    this.radius = 20,
  });

  final SupportUserProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial =
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
      backgroundImage:
          profile.avatar.isNotEmpty ? NetworkImage(profile.avatar) : null,
      child: profile.avatar.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _NoChatSelected extends StatelessWidget {
  const _NoChatSelected();

  @override
  Widget build(BuildContext context) {
    return _EmptyChatsState(color: Theme.of(context).colorScheme.primary);
  }
}

class _EmptyChatsState extends StatelessWidget {
  const _EmptyChatsState({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_outlined, size: 60, color: color),
            const SizedBox(height: 14),
            Text(
              'No active chats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'New support conversations will appear here in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('MMM d').format(value);
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
