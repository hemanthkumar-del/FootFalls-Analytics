import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetectionConfig {
  final bool isConfigMode;
  final Offset lineStart;
  final Offset lineEnd;
  final Rect roi;

  const DetectionConfig({
    this.isConfigMode = false,
    this.lineStart = const Offset(0.2, 0.5),
    this.lineEnd = const Offset(0.8, 0.5),
    this.roi = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
  });

  DetectionConfig copyWith({
    bool? isConfigMode,
    Offset? lineStart,
    Offset? lineEnd,
    Rect? roi,
  }) {
    return DetectionConfig(
      isConfigMode: isConfigMode ?? this.isConfigMode,
      lineStart: lineStart ?? this.lineStart,
      lineEnd: lineEnd ?? this.lineEnd,
      roi: roi ?? this.roi,
    );
  }
}

final detectionConfigProvider = StateNotifierProvider<DetectionConfigNotifier, DetectionConfig>((ref) {
  return DetectionConfigNotifier();
});

class DetectionConfigNotifier extends StateNotifier<DetectionConfig> {
  DetectionConfigNotifier() : super(const DetectionConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    final lsX = prefs.getDouble('lineStartX');
    final lsY = prefs.getDouble('lineStartY');
    final leX = prefs.getDouble('lineEndX');
    final leY = prefs.getDouble('lineEndY');
    
    final rL = prefs.getDouble('roiLeft');
    final rT = prefs.getDouble('roiTop');
    final rR = prefs.getDouble('roiRight');
    final rB = prefs.getDouble('roiBottom');
    
    Offset? loadedStart;
    Offset? loadedEnd;
    Rect? loadedRoi;
    
    if (lsX != null && lsY != null) loadedStart = Offset(lsX, lsY);
    if (leX != null && leY != null) loadedEnd = Offset(leX, leY);
    if (rL != null && rT != null && rR != null && rB != null) {
      loadedRoi = Rect.fromLTRB(rL, rT, rR, rB);
    }
    
    state = state.copyWith(
      lineStart: loadedStart,
      lineEnd: loadedEnd,
      roi: loadedRoi,
    );
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lineStartX', state.lineStart.dx);
    await prefs.setDouble('lineStartY', state.lineStart.dy);
    await prefs.setDouble('lineEndX', state.lineEnd.dx);
    await prefs.setDouble('lineEndY', state.lineEnd.dy);
    
    await prefs.setDouble('roiLeft', state.roi.left);
    await prefs.setDouble('roiTop', state.roi.top);
    await prefs.setDouble('roiRight', state.roi.right);
    await prefs.setDouble('roiBottom', state.roi.bottom);
  }

  void toggleConfigMode() {
    state = state.copyWith(isConfigMode: !state.isConfigMode);
  }

  void updateLine(Offset start, Offset end) {
    state = state.copyWith(lineStart: start, lineEnd: end);
    _saveConfig();
  }

  void updateRoi(Rect newRoi) {
    state = state.copyWith(roi: newRoi);
    _saveConfig();
  }
}
