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
