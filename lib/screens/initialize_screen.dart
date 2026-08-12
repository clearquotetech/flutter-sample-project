import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../clear_quote_sdk.dart';
import 'inspection_screen.dart';

class InitializeScreen extends StatefulWidget {
  const InitializeScreen({super.key});

  @override
  State<InitializeScreen> createState() => _InitializeScreenState();
}

class _InitializeScreenState extends State<InitializeScreen> {
  final _sdkKeyController = TextEditingController();
  bool _isInitializing = false;
  String _sdkVersion = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    _loadSDKVersion();
  }

  Future<void> _loadSDKVersion() async {
    try {
      final version = await ClearQuoteSDK.getSDKVersion();
      if (!mounted) return;
      setState(() => _sdkVersion = version);
    } catch (_) {
      // Leave version empty if unavailable.
    }
  }

  @override
  void dispose() {
    _sdkKeyController.dispose();
    super.dispose();
  }

  Future<void> _initializeSDK() async {
    final sdkKey = _sdkKeyController.text.trim();
    if (sdkKey.isEmpty) {
      _showAlert('Error', 'Please enter SDK Key');
      return;
    }

    setState(() => _isInitializing = true);
    try {
      final result = await ClearQuoteSDK.initSDK(sdkKey);
      final code = result['code'];
      if (code == 200) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const InspectionScreen(),
          ),
        );
      } else {
        _showAlert(
          'SDK Init Result',
          const JsonEncoder.withIndent('  ').convert(result),
        );
      }
    } on PlatformException catch (e) {
      _showAlert('Init Failed', e.message ?? 'Unknown error');
    } catch (e) {
      _showAlert('Init Failed', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    Text(
                      'ClearQuoteSDK',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Flutter Demo App',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'ClearQuote SDK Key',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _sdkKeyController,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            hintText: 'Enter SDK Key',
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
                      ),
                      const SizedBox(height: 16),
                      Padding(
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
                          onPressed: _isInitializing ? null : _initializeSDK,
                          child: Text(
                            _isInitializing ? 'Initializing…' : 'Initialize SDK',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _sdkVersion.isEmpty
                      ? 'SDK Version - …'
                      : 'SDK Version - $_sdkVersion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Color(0xFF666666),
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
