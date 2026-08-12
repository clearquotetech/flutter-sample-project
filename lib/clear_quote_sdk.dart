import 'dart:async';

import 'package:flutter/services.dart';

import 'types/clear_quote_types.dart';

export 'types/clear_quote_types.dart';

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

  static Future<String> getSDKVersion() async {
    final result = await _methodChannel.invokeMethod<String>(ClearQuoteMethod.sdkVersion.name);
    return result ?? '';
  }
}
