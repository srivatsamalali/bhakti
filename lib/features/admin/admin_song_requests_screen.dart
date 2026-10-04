import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song_request_model.dart';
import '../../services/firebase/song_request_service.dart';
import 'admin_add_edit_song_screen.dart';

class AdminSongRequestsScreen extends StatefulWidget {
  const AdminSongRequestsScreen({super.key});

  @override
  State<AdminSongRequestsScreen> createState() => _AdminSongRequestsScreenState();
}

class _AdminSongRequestsScreenState extends State<AdminSongRequestsScreen> {
  String _filter = 'all'; // all, pending, in_progress, fulfilled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SongRequestService>().loadRequests();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled':
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'in_progress':
      case 'in_review':
        return const Color(0xFFE65100);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'pending':
      default:
        return const Color(0xFF1565C0);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled':
      case 'approved':
        return 'Fulfilled ✅';
      case 'in_progress':
      case 'in_review':
        return 'In Progress ⏳';
      case 'rejected':
        return 'Declined ❌';
      case 'pending':
      default:
        return 'Pending 📩';
    }
  }

  Future<void> _handleDelete(BuildContext context, SongRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Song Request?'),
        content: Text('Are you sure you want to delete the request for "${request.songTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<SongRequestService>().deleteRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request removed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestService = context.watch<SongRequestService>();
    final allRequests = requestService.requests;

    final totalCount = allRequests.length;
    final pendingCount = allRequests.where((r) => r.status == 'pending').length;
    final inProgressCount = allRequests.where((r) => r.status == 'in_progress' || r.status == 'in_review').length;
    final fulfilledCount = allRequests.where((r) => r.status == 'fulfilled' || r.status == 'approved').length;

    var displayed = allRequests;
    if (_filter == 'pending') {
      displayed = allRequests.where((r) => r.status == 'pending').toList();
    } else if (_filter == 'in_progress') {
      displayed = allRequests.where((r) => r.status == 'in_progress' || r.status == 'in_review').toList();
    } else if (_filter == 'fulfilled') {
      displayed = allRequests.where((r) => r.status == 'fulfilled' || r.status == 'approved').toList();
    }

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('Devotee Song Requests 📜'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Requests',
            onPressed: () => requestService.loadRequests(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => requestService.loadRequests(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Statistics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Requests',
                        '$totalCount',
                        Icons.queue_music_rounded,
                        AppColors.maroonPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        'Pending',
                        '$pendingCount',
                        Icons.mark_email_unread_rounded,
                        const Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'In Progress',
                        '$inProgressCount',
                        Icons.hourglass_top_rounded,
                        const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        'Fulfilled / Added',
                        '$fulfilledCount',
                        Icons.check_circle_rounded,
                        const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('All ($totalCount)'),
                        selected: _filter == 'all',
                        onSelected: (_) => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Pending ($pendingCount)'),
                        selected: _filter == 'pending',
                        onSelected: (_) => setState(() => _filter = 'pending'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('In Progress ($inProgressCount)'),
                        selected: _filter == 'in_progress',
                        onSelected: (_) => setState(() => _filter = 'in_progress'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Fulfilled ($fulfilledCount)'),
                        selected: _filter == 'fulfilled',
                        onSelected: (_) => setState(() => _filter = 'fulfilled'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (requestService.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.maroonPrimary),
                    ),
                  )
                else if (displayed.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEADBCE)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_email_read_rounded, size: 48, color: Color(0xFFC7B198)),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'all'
                              ? 'No devotee song requests submitted yet.'
                              : 'No requests matching "$_filter" status.',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...displayed.map((request) => _buildRequestCard(context, request)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF75655B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, SongRequestModel request) {
    final statusColor = _getStatusColor(request.status);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(request.requestedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Status Chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.songTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E1A11),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (request.deity.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFB74D)),
                              ),
                              child: Text(
                                '🛕 ${request.deity}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFB39DDB)),
                            ),
                            child: Text(
                              '🗣️ ${request.language.toUpperCase()}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF512DA8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: request.status,
                  tooltip: 'Update Status',
                  onSelected: (newStatus) {
                    context.read<SongRequestService>().updateStatus(request.id, newStatus);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status updated to "${_getStatusLabel(newStatus)}"')),
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'pending', child: Text('📩 Pending')),
                    PopupMenuItem(value: 'in_progress', child: Text('⏳ In Progress')),
                    PopupMenuItem(value: 'fulfilled', child: Text('✅ Fulfilled / Added')),
                    PopupMenuItem(value: 'rejected', child: Text('❌ Declined')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getStatusLabel(request.status),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down_rounded, size: 18, color: statusColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (request.singerOrComposer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_pin_rounded, size: 15, color: Color(0xFF8D6E63)),
                  const SizedBox(width: 6),
                  Text(
                    'Singer/Composer: ${request.singerOrComposer}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF5D4037), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            if (request.referenceUrl.isNotEmpty) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: request.referenceUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reference URL copied to clipboard! 📋')),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Color(0xFF1976D2)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.referenceUrl,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2), decoration: TextDecoration.underline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Copy 📋', style: TextStyle(fontSize: 11, color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],

            if (request.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF0E5D8)),
                ),
                child: Text(
                  'Notes: ${request.notes}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B584C), fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),

            // Bottom action row: Date + Delete + Fulfill / Add Song Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Delete Request',
                      onPressed: () => _handleDelete(context, request),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.library_add_rounded, size: 16),
                      label: const Text('Add to Catalog', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroonPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const AdminAddEditSongScreen(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          await context.read<SongRequestService>().updateStatus(request.id, 'fulfilled');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
