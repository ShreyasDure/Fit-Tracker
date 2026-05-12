import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';

final supportTicketsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await MongoDbService.getSupportTickets();
});

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Theme.of(context).textTheme.bodySmall!.color!),
            onPressed: () => ref.invalidate(supportTicketsProvider),
          ),
        ],
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan, strokeWidth: 2)),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: Theme.of(context).textTheme.bodySmall!.color!, size: 48),
                const SizedBox(height: AppSizes.md),
                Text('Failed to load tickets', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(e.toString().replaceAll('Exception: ', ''), style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12)),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: () => ref.invalidate(supportTicketsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.support_agent_rounded, color: Theme.of(context).textTheme.bodySmall!.color!, size: 48),
                  const SizedBox(height: AppSizes.md),
                  Text('No support requests yet', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('Support requests from users will appear here.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12)),
                ],
              ),
            );
          }
          final pending = tickets.where((t) => (t['status'] ?? 'pending') == 'pending').length;
          return Column(
            children: [
              // Summary bar
              Container(
                margin: EdgeInsets.all(AppSizes.lg),
                padding: EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(color: AppColors.neonOrange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryChip(label: 'Total', value: '${tickets.length}', color: AppColors.neonCyan),
                    _SummaryChip(label: 'Pending', value: '$pending', color: AppColors.neonOrange),
                    _SummaryChip(label: 'Resolved', value: '${tickets.length - pending}', color: AppColors.neonGreen),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, i) {
                    final ticket = tickets[i];
                    final status = ticket['status'] ?? 'pending';
                    final createdAt = ticket['createdAt'] != null
                        ? DateTime.tryParse(ticket['createdAt'].toString())
                        : null;
                    return Container(
                      padding: EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        border: Border.all(color: status == 'pending'
                            ? AppColors.neonOrange.withValues(alpha: 0.2)
                            : AppColors.neonGreen.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.neonPurple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_rounded, color: AppColors.neonPurple, size: 16),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ticket['userId']?.toString() ?? 'Anonymous', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    if (createdAt != null)
                                      Text(_formatTime(createdAt), style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: status == 'pending'
                                      ? AppColors.neonOrange.withValues(alpha: 0.15)
                                      : status == 'inspection'
                                          ? AppColors.neonCyan.withValues(alpha: 0.15)
                                          : AppColors.neonGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'pending' ? AppColors.neonOrange : status == 'inspection' ? AppColors.neonCyan : AppColors.neonGreen,
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Container(
                            padding: EdgeInsets.all(AppSizes.sm),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(ticket['message'] ?? 'No message', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13, height: 1.5)),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await _showContactOptions(context, ticket);
                                  },
                                  icon: const Icon(Icons.message_rounded, size: 14, color: AppColors.neonPurple),
                                  label: Text('Contact', style: const TextStyle(fontSize: 11, color: AppColors.neonPurple)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    side: BorderSide(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              if (status != 'inspection' && status != 'resolved')
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await MongoDbService.updateSupportTicketStatus(ticket['_id'], 'inspection');
                                      ref.invalidate(supportTicketsProvider);
                                    },
                                    icon: const Icon(Icons.search_rounded, size: 14, color: AppColors.neonCyan),
                                    label: Text('Inspect', style: const TextStyle(fontSize: 11, color: AppColors.neonCyan)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                                    ),
                                  ),
                                ),
                              if (status != 'inspection' && status != 'resolved')
                                const SizedBox(width: AppSizes.sm),
                              if (status != 'resolved')
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await MongoDbService.updateSupportTicketStatus(ticket['_id'], 'resolved');
                                      ref.invalidate(supportTicketsProvider);
                                    },
                                    icon: const Icon(Icons.check_rounded, size: 14, color: AppColors.neonGreen),
                                    label: Text('Resolve', style: const TextStyle(fontSize: 11, color: AppColors.neonGreen)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: BorderSide(color: AppColors.neonGreen.withValues(alpha: 0.3)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  Future<void> _showContactOptions(BuildContext context, Map<String, dynamic> ticket) async {
    final rawUser = ticket['userId'];
    final Map<String, dynamic>? userData = rawUser is Map<String, dynamic> ? rawUser : null;
    
    final email = (userData?['email'] ?? '').toString().trim();
    final phoneRaw = (ticket['phone'] ?? '').toString().trim();
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSizes.md),
            Text('Email: ${email.isEmpty ? 'Not provided' : email}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Phone: ${phoneRaw.isEmpty ? 'Not provided' : phoneRaw}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: email.isEmpty
                    ? null
                    : () async {
                        final uri = Uri.parse('mailto:$email');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Contact via Email'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: phoneDigits.isEmpty
                    ? null
                    : () async {
                        final uri = Uri.parse('https://wa.me/$phoneDigits');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Contact via WhatsApp'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.neonGreen.withValues(alpha: 0.35)),
                  foregroundColor: AppColors.neonGreen,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11)),
      ],
    );
  }
}


