import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../clear_quote_sdk.dart';
import 'initialize_screen.dart';

String? _optionalTrim(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  String? _dealerCode;

  final _userName = TextEditingController();
  final _dealer = TextEditingController();
  final _dealerIdentifier = TextEditingController();
  final _clientUniqueId = TextEditingController();
  final _organisationId = TextEditingController();

  final _customerName = TextEditingController();
  final _customerEmail = TextEditingController();
  final _dialCode = TextEditingController();
  final _phoneNumber = TextEditingController();

  final _regNumber = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _bodyStyle = TextEditingController();
  final _fuelType = TextEditingController();
  final _variant = TextEditingController();

  final _inspectionType = TextEditingController();
  final _fleetImageType = TextEditingController();

  bool _isOffline = false;
  StreamSubscription<InspectionCompletionStatus>? _completionSubscription;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    _loadDealerCode();
    _completionSubscription = ClearQuoteSDK.addInspectionCompletionListener((status) {
      _showAlert(
        'Inspection Status',
        [
          'identifier: ${status.identifier}',
          'message: ${status.message}',
          'code: ${status.code}',
          'isOffline: ${status.isOffline}',
          'serverQuoteId: ${status.serverQuoteId ?? '—'}',
          'serverInspectionId: ${status.serverInspectionId ?? '—'}',
        ].join('\n'),
      );
    });
  }

  Future<void> _loadDealerCode() async {
    try {
      final code = await ClearQuoteSDK.getDealerCode();
      if (mounted) {
        setState(() => _dealerCode = code);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _dealerCode = null);
      }
    }
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    for (final controller in [
      _userName,
      _dealer,
      _dealerIdentifier,
      _clientUniqueId,
      _organisationId,
      _customerName,
      _customerEmail,
      _dialCode,
      _phoneNumber,
      _regNumber,
      _make,
      _model,
      _bodyStyle,
      _fuelType,
      _variant,
      _inspectionType,
      _fleetImageType,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  ClientAttrs _buildClientAttrs() => {
        'userName': _optionalTrim(_userName.text),
        'dealer': _optionalTrim(_dealer.text),
        'dealerIdentifier': _optionalTrim(_dealerIdentifier.text),
        'client_unique_id': _optionalTrim(_clientUniqueId.text),
        'organisationId': _optionalTrim(_organisationId.text),
      };

  InputDetails _buildInputDetails() => {
        'customerDetails': {
          'name': _optionalTrim(_customerName.text),
          'email': _optionalTrim(_customerEmail.text),
          'dialCode': _optionalTrim(_dialCode.text),
          'phoneNumber': _optionalTrim(_phoneNumber.text),
        },
        'vehicleDetails': {
          'regNumber': _optionalTrim(_regNumber.text),
          'make': _optionalTrim(_make.text),
          'model': _optionalTrim(_model.text),
          'bodyStyle': _optionalTrim(_bodyStyle.text),
          'fuelType': _optionalTrim(_fuelType.text),
          'variant': _optionalTrim(_variant.text),
        },
        'quoteData': {
          'inspectionType': _optionalTrim(_inspectionType.text),
          'fleetImageType': _optionalTrim(_fleetImageType.text),
        },
      };

  Future<void> _onStartInspection(bool skipInputPage) async {
    try {
      final result = await ClearQuoteSDK.startInspection(
        clientAttrs: _buildClientAttrs(),
        inputDetails: _buildInputDetails(),
        userFlowParams: {
          'isOffline': _isOffline,
          'skipInputPage': skipInputPage,
        },
      );
      if (result.started) return;
      _showAlert(
        'Start Inspection Result',
        'started: ${result.started} \nmessage: ${result.message} \ncode: ${result.code}',
      );
    } on PlatformException catch (e) {
      _showAlert('Error', e.message ?? 'Start failed');
    } catch (e) {
      _showAlert('Error', e.toString());
    }
  }

  Future<void> _onLogout() async {
    await ClearQuoteSDK.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const InitializeScreen(),
      ),
    );
  }

  Future<void> _onManualOfflineSync() async {
    await ClearQuoteSDK.manualOfflineSync();
  }

  void _showAlert(String title, String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Start Inspection',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    children: [
                      const TextSpan(text: 'Dealer Code: '),
                      TextSpan(
                        text: _dealerCode ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const _SectionTitle('Client Attrs'),
              _Field(
                label: 'User Name (Optional)',
                controller: _userName,
                placeholder: 'userName',
              ),
              _Field(
                label: 'Dealer (Optional)',
                controller: _dealer,
                placeholder: 'dealer',
              ),
              _Field(
                label: 'Dealer Identifier (Optional)',
                controller: _dealerIdentifier,
                placeholder: 'dealerIdentifier',
              ),
              _Field(
                label: 'Client Unique ID (Optional)',
                controller: _clientUniqueId,
                placeholder: 'client_unique_id',
              ),
              _Field(
                label: 'Organisation ID (Optional)',
                controller: _organisationId,
                placeholder: 'organisationId',
              ),
              const _SectionTitle('Customer Details'),
              _Field(
                label: 'Customer Name (Optional)',
                controller: _customerName,
                placeholder: 'name',
                textCapitalization: TextCapitalization.words,
              ),
              _Field(
                label: 'Customer Email (Optional)',
                controller: _customerEmail,
                placeholder: 'email',
                keyboardType: TextInputType.emailAddress,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 35,
                      child: _Field(
                        label: 'Dial Code',
                        controller: _dialCode,
                        placeholder: 'dialCode',
                        keyboardType: TextInputType.phone,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 65,
                      child: _Field(
                        label: 'Phone Number (Optional)',
                        controller: _phoneNumber,
                        placeholder: 'phoneNumber',
                        keyboardType: TextInputType.phone,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionTitle('Vehicle Details (If Skipping Input in SDK)'),
              _Field(
                label: 'Registration Number',
                controller: _regNumber,
                placeholder: 'regNumber',
                textCapitalization: TextCapitalization.characters,
              ),
              _Field(label: 'Make', controller: _make, placeholder: 'make'),
              _Field(label: 'Model', controller: _model, placeholder: 'model'),
              _Field(
                label: 'Body Style',
                controller: _bodyStyle,
                placeholder: 'bodyStyle',
              ),
              _Field(
                label: 'Fuel Type',
                controller: _fuelType,
                placeholder: 'fuelType',
              ),
              _Field(
                label: 'Variant',
                controller: _variant,
                placeholder: 'variant',
              ),
              const _SectionTitle('Quote Data (If Skipping Input in SDK)'),
              _Field(
                label: 'Inspection Type',
                controller: _inspectionType,
                placeholder: 'inspectionType',
              ),
              _Field(
                label: 'Fleet Image Type',
                controller: _fleetImageType,
                placeholder: 'fleetImageType',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'Offline Mode',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _isOffline,
                      onChanged: (value) => setState(() => _isOffline = value),
                    ),
                  ],
                ),
              ),
              _StartButton(
                title: 'Start Inspection',
                onPressed: () => _onStartInspection(false),
              ),
              _StartButton(
                title: 'Start Inspection (Skip Input)',
                onPressed: () => _onStartInspection(true),
              ),
              _StartButton(
                title: 'Manual Offline Sync',
                onPressed: () => _onManualOfflineSync(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextButton(
                  onPressed: _onLogout,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.compact = false,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 0.0 : 16.0;
    return Padding(
      padding: EdgeInsets.only(left: horizontal, right: horizontal, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: placeholder,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
