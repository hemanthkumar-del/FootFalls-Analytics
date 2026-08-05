import 'package:flutter/material.dart';
import 'package:footfalls_app/utils/debug_console.dart';

class DeveloperDebugPanel extends StatefulWidget {
  const DeveloperDebugPanel({super.key});

  @override
  State<DeveloperDebugPanel> createState() => _DeveloperDebugPanelState();
}

class _DeveloperDebugPanelState extends State<DeveloperDebugPanel> {
  bool _isExpanded = false;

  Color _getColorForLog(LogColor color) {
    switch (color) {
      case LogColor.green: return Colors.greenAccent;
      case LogColor.yellow: return Colors.yellowAccent;
      case LogColor.red: return Colors.redAccent;
      case LogColor.blue: return Colors.lightBlueAccent;
      case LogColor.white: return Colors.white70;
    }
  }

  Widget _buildBanner(String status) {
    Color bannerColor = Colors.grey;
    if (status.contains('WAITING')) bannerColor = Colors.orange;
    if (status.contains('ERROR') || status.contains('STOPPED') || status.contains('DENIED')) bannerColor = Colors.red;
    if (status.contains('RECEIVED') || status.contains('STARTED')) bannerColor = Colors.green;
    if (status.contains('YOLO') || status.contains('OVERLAY')) bannerColor = Colors.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: bannerColor,
      alignment: Alignment.center,
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.5))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Developer Debug Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Icon(_isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.white),
                    ],
                  ),
                ),
              ),
              
              if (_isExpanded)
                ValueListenableBuilder<Map<String, dynamic>>(
                  valueListenable: DebugConsole().statsNotifier,
                  builder: (context, stats, _) {
                    return Column(
                      children: [
                        _buildBanner(stats['statusBanner']),
                        
                        // Live Stats Grid
                        Container(
                          height: 150,
                          padding: const EdgeInsets.all(8),
                          child: SingleChildScrollView(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatRow('Cam Init', stats['cameraInitialized']),
                                      _buildStatRow('Preview Active', stats['cameraPreviewActive']),
                                      _buildStatRow('Stream Called', stats['streamCalled']),
                                      _buildStatRow('Callback Entered', stats['callbackEntered']),
                                      _buildStatRow('Frames Rx', stats['framesReceived']),
                                      _buildStatRow('Frames Px', stats['framesProcessed']),
                                      _buildStatRow('Processing Flag', stats['isProcessing']),
                                      _buildStatRow('FPS', stats['fps']),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatRow('Inference ms', stats['inferenceTime']),
                                      _buildStatRow('Detections', stats['detectionCount']),
                                      _buildStatRow('Format', stats['imageFormat']),
                                      _buildStatRow('Width', stats['imageWidth']),
                                      _buildStatRow('Height', stats['imageHeight']),
                                      _buildStatRow('Resolution', stats['resolutionPreset']),
                                      _buildStatRow('Input Shape', stats['tensorInput']),
                                      _buildStatRow('Output Shape', stats['tensorOutput']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        if (stats['lastException'] != 'None')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            color: Colors.red.withValues(alpha: 0.3),
                            child: Text('Last Err: ${stats['lastException']}', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                          ),
                      ],
                    );
                  }
                ),

              if (_isExpanded)
                ValueListenableBuilder<List<DebugLog>>(
                  valueListenable: DebugConsole().logsNotifier,
                  builder: (context, logs, _) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[logs.length - 1 - index]; // Show newest first
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '[${log.formattedTimestamp}] [${log.isolate}] [${log.file}] [${log.function}]',
                                  style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace'),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log.pipelineId.isNotEmpty)
                                      Text('${log.pipelineId} ', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                    Expanded(
                                      child: Text(
                                        log.message,
                                        style: TextStyle(color: _getColorForLog(log.color), fontSize: 10, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                
              if (_isExpanded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => DebugConsole.copyLogs(), 
                      icon: const Icon(Icons.copy, size: 16), 
                      label: const Text('Copy')
                    ),
                    TextButton.icon(
                      onPressed: () => DebugConsole.clearLogs(), 
                      icon: const Icon(Icons.clear, size: 16), 
                      label: const Text('Clear')
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final path = await DebugConsole.exportLogs();
                        if (mounted && path != null) {
                          messenger.showSnackBar(SnackBar(content: Text('Exported to: $path')));
                        }
                      }, 
                      icon: const Icon(Icons.save, size: 16), 
                      label: const Text('Export')
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
