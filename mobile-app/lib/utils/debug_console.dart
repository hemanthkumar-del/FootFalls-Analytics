import 'dart:isolate';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogColor { green, yellow, red, blue, white }

class DebugLog {
  final DateTime timestamp;
  final String isolate;
  final String file;
  final String function;
  final String pipelineId;
  final String message;
  final LogColor color;

  DebugLog({
    required this.timestamp,
    required this.isolate,
    required this.file,
    required this.function,
    this.pipelineId = '',
    required this.message,
    this.color = LogColor.white,
  });

  String get formattedTimestamp => DateFormat('HH:mm:ss.SSS').format(timestamp);

  String toExportString() {
    return '[$formattedTimestamp][$isolate][$file][$function] ${pipelineId.isNotEmpty ? "$pipelineId " : ""}$message';
  }
}

class DebugConsole {
  static final DebugConsole _instance = DebugConsole._internal();
  factory DebugConsole() => _instance;
  DebugConsole._internal();

  // Observable log list
  final ValueNotifier<List<DebugLog>> logsNotifier = ValueNotifier<List<DebugLog>>([]);

  // Observable live stats
  final ValueNotifier<Map<String, dynamic>> statsNotifier = ValueNotifier<Map<String, dynamic>>({
    'statusBanner': 'WAITING FOR CAMERA',
    'cameraInitialized': false,
    'cameraPreviewActive': false,
    'streamCalled': false,
    'callbackEntered': false,
    'framesReceived': 0,
    'framesProcessed': 0,
    'fps': 0.0,
    'inferenceTime': 0,
    'detectionCount': 0,
    'isProcessing': false,
    'lastException': 'None',
    'resolutionPreset': 'Unknown',
    'imageWidth': 0,
    'imageHeight': 0,
    'imageFormat': 'Unknown',
    'tensorInput': 'Unknown',
    'tensorOutput': 'Unknown',
  });

  static void addLog({
    required String file,
    required String function,
    String pipelineId = '',
    required String message,
    LogColor color = LogColor.white,
  }) {
    final now = DateTime.now();
    final isolateName = Isolate.current.debugName ?? 'main';

    final log = DebugLog(
      timestamp: now,
      isolate: isolateName,
      file: file,
      function: function,
      pipelineId: pipelineId,
      message: message,
      color: color,
    );

    debugPrint(log.toExportString());

    final currentLogs = List<DebugLog>.from(_instance.logsNotifier.value);
    currentLogs.add(log);
    
    if (currentLogs.length > 200) {
      currentLogs.removeRange(0, currentLogs.length - 200);
    }
    
    _instance.logsNotifier.value = currentLogs;
  }

  static void updateStat(String key, dynamic value) {
    final currentStats = Map<String, dynamic>.from(_instance.statsNotifier.value);
    currentStats[key] = value;
    _instance.statsNotifier.value = currentStats;
  }

  static void updateBanner(String bannerText) {
    updateStat('statusBanner', bannerText);
  }

  static void incrementStat(String key) {
    final currentStats = Map<String, dynamic>.from(_instance.statsNotifier.value);
    if (currentStats[key] is int) {
      currentStats[key] = (currentStats[key] as int) + 1;
      _instance.statsNotifier.value = currentStats;
    }
  }

  static void clearLogs() {
    _instance.logsNotifier.value = [];
    updateStat('lastException', 'None');
    updateBanner('WAITING FOR CAMERA');
  }

  static Future<void> copyLogs() async {
    final logsString = _instance.logsNotifier.value.map((l) => l.toExportString()).join('\n');
    await Clipboard.setData(ClipboardData(text: logsString));
  }

  static Future<String?> exportLogs() async {
    try {
      final logsString = _instance.logsNotifier.value.map((l) => l.toExportString()).join('\n');
      final directory = await getExternalStorageDirectory(); // Android only
      if (directory != null) {
        final file = File('${directory.path}/pipeline_debug_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
        await file.writeAsString(logsString);
        return file.path;
      }
      return null;
    } catch (e) {
      addLog(
        file: 'debug_console.dart',
        function: 'exportLogs',
        message: 'Failed to export logs: $e',
        color: LogColor.red,
      );
      return null;
    }
  }
}
