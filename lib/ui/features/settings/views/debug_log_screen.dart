import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/services/log_service.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final LogService _logService = LogService();
  final _dateFormat = DateFormat('HH:mm:ss.SSS');

  @override
  void initState() {
    super.initState();
    _logService.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    _logService.removeListener(_onLogsChanged);
    super.dispose();
  }

  void _onLogsChanged() {
    setState(() {});
  }

  Future<void> _copyLogs() async {
    final logs = _logService.logs;
    final buffer = StringBuffer();
    for (var log in logs) {
      buffer.writeln('[${_dateFormat.format(log.timestamp)}] [${log.level}] ${log.message}');
      if (log.error != null) {
        buffer.writeln(log.error);
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = _logService.logs.reversed.toList(); // Newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _logService.clear(),
            tooltip: 'Clear logs',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copy all',
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Text(
                'No logs available.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final log = logs[index];
                final color = log.level == 'ERROR'
                    ? theme.colorScheme.error
                    : log.level == 'WARN'
                        ? Colors.orange
                        : theme.colorScheme.onSurface;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _dateFormat.format(log.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.level,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        height: 1.5,
                      ),
                    ),
                    if (log.error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
