import 'dart:async';

import 'package:flutter/services.dart';

typedef ClientAttrs = Map<String, String?>;
typedef InputDetails = Map<String, dynamic>;
typedef UserFlowParams = Map<String, dynamic>;

enum ClearQuoteMethod {
  initSDK,
  startInspection,
  logout,
  getDealerCode,
  isSDKInitialized,
  manualOfflineSync,
}

final class ClearQuoteSDK {
  ClearQuoteSDK._();

  static const _methodChannel = MethodChannel('com.clearquote/sdk');
  static const _eventChannel = EventChannel('com.clearquote/sdk/events');

  static Future<Map<String, dynamic>> initSDK(String key) async {
    final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
      ClearQuoteMethod.initSDK.name,
      {'key': key},
    );
    return Map<String, dynamic>.from(result ?? const {});
  }

  static Future<StartInspectionResult> startInspection({
    ClientAttrs? clientAttrs,
    InputDetails? inputDetails,
    UserFlowParams? userFlowParams,
  }) async {
    final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
      ClearQuoteMethod.startInspection.name,
      {
        'clientAttrs': clientAttrs,
        'inputDetails': inputDetails,
        'userFlowParams': userFlowParams,
      },
    );
    return StartInspectionResult.fromMap(result ?? const {});
  }

  static Future<void> logout() {
    return _methodChannel.invokeMethod<void>(ClearQuoteMethod.logout.name);
  }

  static Future<String?> getDealerCode() {
    return _methodChannel.invokeMethod<String>(
      ClearQuoteMethod.getDealerCode.name,
    );
  }

  static Future<bool> isSDKInitialized() async {
    final result = await _methodChannel.invokeMethod<bool>(
      ClearQuoteMethod.isSDKInitialized.name,
    );
    return result ?? false;
  }

  static StreamSubscription<InspectionCompletionStatus>
      addInspectionCompletionListener(
    void Function(InspectionCompletionStatus status) listener,
  ) {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return InspectionCompletionStatus.fromMap(
          Map<Object?, Object?>.from(event),
        );
      }
      return const InspectionCompletionStatus(
        identifier: '',
        message: '',
        code: 0,
        isOffline: false,
      );
    }).listen(listener);
  }

  static Future<void> manualOfflineSync() {
    return _methodChannel.invokeMethod<void>(ClearQuoteMethod.manualOfflineSync.name);
  }
}

class StartInspectionResult {
  const StartInspectionResult({
    required this.started,
    required this.message,
    required this.code,
  });

  factory StartInspectionResult.fromMap(Map<Object?, Object?> map) {
    return StartInspectionResult(
      started: map['started'] as bool? ?? false,
      message: map['message'] as String? ?? '',
      code: (map['code'] as num?)?.toInt() ?? 0,
    );
  }

  final bool started;
  final String message;
  final int code;
}

class InspectionCompletionStatus {
  const InspectionCompletionStatus({
    required this.identifier,
    required this.message,
    required this.code,
    required this.isOffline,
    this.serverQuoteId,
    this.serverInspectionId,
  });

  factory InspectionCompletionStatus.fromMap(Map<Object?, Object?> map) {
    return InspectionCompletionStatus(
      identifier: map['identifier'] as String? ?? '',
      message: map['message'] as String? ?? '',
      code: (map['code'] as num?)?.toInt() ?? 0,
      isOffline: map['isOffline'] as bool? ?? false,
      serverQuoteId: map['serverQuoteId'] as String?,
      serverInspectionId: map['serverInspectionId'] as String?,
    );
  }

  final String identifier;
  final String message;
  final int code;
  final bool isOffline;
  final String? serverQuoteId;
  final String? serverInspectionId;
}
