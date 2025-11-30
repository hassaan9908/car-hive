import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminViewAllAdsPage extends StatefulWidget {
  const AdminViewAllAdsPage({super.key});

  @override
  State<AdminViewAllAdsPage> createState() => _AdminViewAllAdsPageState();
}

class _AdminViewAllAdsPageState extends State<AdminViewAllAdsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  bool _isDeleting = false;
  bool _selectionMode = false;
  final Set<String> _selectedAdIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _selectionMode ? '${_selectedAdIds.length} selected' : 'All Ads'),
        actions: [
          if (!_selectionMode) ...[
            IconButton(
              tooltip: 'Select Multiple',
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _selectionMode = true),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _statusFilter = value),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'all', child: Text('All')),
                PopupMenuItem(value: 'active', child: Text('Active')),
                PopupMenuItem(value: 'pending', child: Text('Pending')),
                PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                PopupMenuItem(value: 'removed', child: Text('Removed')),
              ],
              icon: const Icon(Icons.filter_list),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Cancel Selection',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedAdIds.clear();
              }),
            ),
            if (_statusFilter != 'removed')
              IconButton(
                tooltip: 'Soft Remove Selected',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _selectedAdIds.isEmpty ? null : _softRemoveSelected,
              ),
            if (_statusFilter == 'removed')
              IconButton(
                tooltip: 'Restore Selected',
                icon: const Icon(Icons.restore),
                onPressed: _selectedAdIds.isEmpty ? null : _restoreSelected,
              ),
            IconButton(
              tooltip: 'Delete Permanently',
              icon: const Icon(Icons.delete_forever),
              onPressed: _selectedAdIds.isEmpty ? null : _deleteSelected,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ads by title, city or price',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ads')
                  .orderBy('createdAt', descending: true)
                  .limit(500)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No ads found'));
                }

                final filtered = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final city =
                      (data['location'] ?? '').toString().toLowerCase();
                  final price = (data['price']?.toString() ?? '').toLowerCase();
                  final status =
                      (data['status'] ?? 'active').toString().toLowerCase();
                  if (_statusFilter != 'all' && status != _statusFilter)
                    return false;
                  if (_searchQuery.isEmpty) return true;
                  return title.contains(_searchQuery) ||
                      city.contains(_searchQuery) ||
                      price.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No ads match filters'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = _safeString(data['title']) ?? 'Untitled';
                    final price = _safeString(data['price']) ?? '0';
                    final location = _safeString(data['location']) ?? 'Unknown';
                    final year = _safeString(data['year']) ?? '—';
                    final mileage =
                        _safeString(data['mileage'] ?? data['kmsDriven']) ??
                            '—';
                    final fuel = _safeString(data['fuel']) ?? '';
                    final status =
                        (_safeString(data['status']) ?? 'active').toLowerCase();
                    final imageUrls = _extractImageUrls(
                        data['imageUrls'] ?? data['images'] ?? data['photos']);
                    final firstImage =
                        imageUrls.isNotEmpty ? imageUrls.first : null;

                    final statusColor = _statusColor(status);

                    final selected = _selectedAdIds.contains(doc.id);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (selected) {
                                _selectedAdIds.remove(doc.id);
                              } else {
                                _selectedAdIds.add(doc.id);
                              }
                            });
                          } else {
                            _showAdDetails(data, doc.id);
                          }
                        },
                        onLongPress: () {
                          if (!_selectionMode) {
                            setState(() {
                              _selectionMode = true;
                              _selectedAdIds.add(doc.id);
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectionMode)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 8, top: 4),
                                  child: Checkbox(
                                    value: selected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedAdIds.add(doc.id);
                                        } else {
                                          _selectedAdIds.remove(doc.id);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: firstImage != null
                                    ? Image.network(
                                        firstImage,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _imagePlaceholder(),
                                      )
                                    : _imagePlaceholder(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        _statusChip(
                                            status.toUpperCase(), statusColor),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Price: $price  •  City: $location',
                                        style: const TextStyle(fontSize: 13)),
                                    Text(
                                        'Year: $year  •  $mileage km${fuel.isNotEmpty ? '  •  $fuel' : ''}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    if (data['description'] != null &&
                                        data['description']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          data['description'].toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_selectionMode)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'view') {
                                      _showAdDetails(data, doc.id);
                                    } else if (value == 'delete') {
                                      _confirmDeleteAd(doc.id, title);
                                    } else if (value == 'remove') {
                                      _softRemoveSelected(singleId: doc.id);
                                    } else if (value == 'restore') {
                                      _restoreSelected(singleId: doc.id);
                                    }
                                  },
                                  itemBuilder: (context) {
                                    final statusLower = status.toLowerCase();
                                    return [
                                      const PopupMenuItem(
                                          value: 'view',
                                          child: Text('View Details')),
                                      if (statusLower != 'removed')
                                        const PopupMenuItem(
                                            value: 'remove',
                                            child: Text('Soft Remove')),
                                      if (statusLower == 'removed')
                                        const PopupMenuItem(
                                            value: 'restore',
                                            child: Text('Restore')),
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Permanently')),
                                    ];
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAdDetails(Map<String, dynamic> data, String adId) async {
    Map<String, dynamic>? seller;
    final userId = _safeString(data['userId']);
    if (userId != null && userId.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        seller = snap.data();
      } catch (_) {}
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final imageUrls = _extractImageUrls(
            data['imageUrls'] ?? data['images'] ?? data['photos']);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_car,
                          size: 36, color: Colors.blueGrey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_safeString(data['title']) ?? 'Untitled',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          Text('Price: ${_safeString(data['price']) ?? '0'}'),
                          Text(
                              'Status: ${(_safeString(data['status']) ?? 'active').toUpperCase()}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (imageUrls.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrls[index],
                          width: 150,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 150,
                            height: 110,
                            color: Colors.blueGrey.shade50,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _infoRow('Ad ID', adId),
                _infoRow('Location', _safeString(data['location']) ?? 'N/A'),
                _infoRow('Year', _safeString(data['year']) ?? 'N/A'),
                _infoRow('Mileage',
                    _safeString(data['mileage'] ?? data['kmsDriven']) ?? 'N/A'),
                _infoRow('Fuel', _safeString(data['fuel']) ?? 'N/A'),
                _infoRow('Brand', _safeString(data['carBrand']) ?? 'N/A'),
                _infoRow('Color', _safeString(data['bodyColor']) ?? 'N/A'),
                _infoRow('Registered In',
                    _safeString(data['registeredIn']) ?? 'N/A'),
                _infoRow(
                    'Seller Name',
                    seller?['fullName']?.toString() ??
                        _safeString(data['name']) ??
                        'N/A'),
                _infoRow(
                    'Seller Phone',
                    seller?['phoneNumber']?.toString() ??
                        _safeString(data['phone']) ??
                        'N/A'),
                _infoRow('User ID', userId ?? 'N/A'),
                if (data['description'] != null &&
                    data['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(data['description'].toString()),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: _isDeleting
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _confirmDeleteAd(
                                    adId, _safeString(data['title']) ?? 'Ad');
                              },
                        icon: const Icon(Icons.delete),
                        label: _isDeleting
                            ? const Text('Deleting...')
                            : const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAd(String adId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: Text(
            'Are you sure you want to delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance.collection('ads').doc(adId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ad "$title" deleted'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedAdIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Selected Ads'),
        content: Text(
            'Permanently delete ${_selectedAdIds.length} ads? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          )
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isDeleting = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedAdIds) {
        batch.delete(FirebaseFirestore.instance.collection('ads').doc(id));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Deleted ${_selectedAdIds.length} ads'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _selectionMode = false;
          _selectedAdIds.clear();
        });
      }
    }
  }

  Future<void> _softRemoveSelected({String? singleId}) async {
    final ids = singleId != null ? {singleId} : _selectedAdIds;
    if (ids.isEmpty) return;
    setState(() => _isDeleting = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in ids) {
        final ref = FirebaseFirestore.instance.collection('ads').doc(id);
        batch.update(ref, {
          'previousStatus': FieldValue.delete(), // clear any existing
        });
      }
      await batch.commit();
      // Need to read each and set previousStatus then removed to preserve old status
      for (final id in ids) {
        final ref = FirebaseFirestore.instance.collection('ads').doc(id);
        final snap = await ref.get();
        final currentStatus = (snap.data()?['status'] ?? 'active').toString();
        await ref.update({
          'previousStatus': currentStatus,
          'status': 'removed',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Soft removed ${ids.length} ads'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Soft remove failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          if (singleId == null) {
            _selectionMode = false;
            _selectedAdIds.clear();
          }
        });
      }
    }
  }

  Future<void> _restoreSelected({String? singleId}) async {
    final ids = singleId != null ? {singleId} : _selectedAdIds;
    if (ids.isEmpty) return;
    setState(() => _isDeleting = true);
    try {
      for (final id in ids) {
        final ref = FirebaseFirestore.instance.collection('ads').doc(id);
        final snap = await ref.get();
        final prev = snap.data()?['previousStatus']?.toString();
        await ref.update({
          'status': prev == null || prev.isEmpty ? 'active' : prev,
          'previousStatus': FieldValue.delete(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Restored ${ids.length} ads'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          if (singleId == null) {
            _selectionMode = false;
            _selectedAdIds.clear();
          }
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'removed':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      ),
    );
  }

  static String? _safeString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num) return v.toString();
    if (v is Map) {
      final inner = v['value'] ?? v['name'] ?? v['title'];
      if (inner is String) return inner;
    }
    return v.toString();
  }

  static List<String> _extractImageUrls(dynamic raw) {
    if (raw == null) return [];
    final out = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item == null) continue;
        if (item is String) {
          out.add(item);
        } else if (item is Map) {
          final url = item['secure_url'] ?? item['url'] ?? item['path'];
          if (url is String && url.isNotEmpty) out.add(url);
        }
      }
    } else if (raw is String) {
      out.add(raw);
    }
    return out;
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.directions_car, color: Colors.blueGrey, size: 32),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
