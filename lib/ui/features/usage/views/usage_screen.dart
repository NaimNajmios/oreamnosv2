import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../data/services/usage_service.dart';
import '../../../../domain/models/usage_log.dart';
import '../../../core/widgets/app_button.dart';
import 'widgets/usage_chart.dart';

class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageService = context.watch<UsageService>();
    final logs = usageService.logs;

    int totalTokens = 0;
    int successCount = 0;
    int totalLatency = 0;

    for (var log in logs) {
      totalTokens += log.estimatedTokens;
      if (log.isSuccess) successCount++;
      totalLatency += log.latencyMs;
    }

    final successRate = logs.isEmpty ? 0.0 : (successCount / logs.length) * 100;
    final avgLatency = logs.isEmpty ? 0 : totalLatency ~/ logs.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmClear(context, usageService),
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No usage data yet.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCards(context, totalTokens, successRate, avgLatency),
                const SizedBox(height: 24),
                Text(
                  'Token Usage History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                UsageChart(logs: logs),
                const SizedBox(height: 24),
                Text(
                  'Recent Requests',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...logs.map((log) => _buildLogTile(context, log)),
              ],
            ),
    );
  }

  Widget _buildStatCards(BuildContext context, int tokens, double success, int latency) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Tokens', value: '$tokens')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Success', value: '${success.toStringAsFixed(0)}%')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Avg Time', value: '${latency}ms')),
      ],
    );
  }

  Widget _buildLogTile(BuildContext context, UsageLog log) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('MMM d, HH:mm').format(log.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          Icon(
            log.isSuccess ? Icons.check_circle : Icons.error,
            color: log.isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.providerId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${log.estimatedTokens} tokens'),
              Text(
                '${log.latencyMs}ms',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, UsageService service) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will delete all usage statistics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          AppButton(
            label: 'CLEAR',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      service.clearLogs();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
