import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Coding Playground Screen
/// API: POST /api/v1/playground/run  { language, code }
///          → response: { output, error, executionTime }
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final _codeCtrl = TextEditingController(text: _defaultCode('python'));
  String _selectedLanguage = 'python';
  String _output = '';
  String? _error;
  bool _running = false;
  int? _execTime;

  static const Map<String, String> _languages = {
    'python'    : 'Python 3',
    'javascript': 'JavaScript',
    'java'      : 'Java',
    'cpp'       : 'C++',
    'c'         : 'C',
  };

  static String _defaultCode(String lang) {
    switch (lang) {
      case 'python':
        return '# Write your Python code here\nprint("Hello, SkillForge!")';
      case 'javascript':
        return '// Write your JavaScript code here\nconsole.log("Hello, SkillForge!");';
      case 'java':
        return 'public class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello, SkillForge!");\n    }\n}';
      case 'cpp':
        return '#include <iostream>\nusing namespace std;\nint main() {\n    cout << "Hello, SkillForge!" << endl;\n    return 0;\n}';
      default:
        return '// Start coding here';
    }
  }

  Future<void> _run() async {
    setState(() { _running = true; _output = ''; _error = null; _execTime = null; });
    try {
      final resp = await ApiClient.post(AppConstants.playgroundRunUrl, {
        'language': _selectedLanguage,
        'code'    : _codeCtrl.text,
      });
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body)['data'];
        setState(() {
          _output   = body?['output']?.toString() ?? '';
          _error    = body?['error']?.toString();
          _execTime = body?['executionTimeMs'] as int?;
          _running  = false;
        });
      } else {
        setState(() {
          _error   = 'Server error. Please try again.';
          _running = false;
        });
      }
    } catch (_) {
      setState(() { _error = 'You are offline.'; _running = false; });
    }
  }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // Dark editor background
      appBar: AppBar(
        backgroundColor: const Color(0xFF181825),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Coding Playground',
            style: TextStyle(color: Colors.white)),
        actions: [
          // Language selector
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.sp8),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: const Color(0xFF181825),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedLanguage = v;
                  _codeCtrl.text = _defaultCode(v);
                });
              },
              items: _languages.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              )).toList(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Code Editor
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF1E1E2E),
              child: TextField(
                controller: _codeCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Color(0xFFCDD6F4),
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(AppTheme.sp16),
                  border: InputBorder.none,
                  hintText: '// Write your code here...',
                  hintStyle: TextStyle(color: Color(0xFF585B70), fontFamily: 'monospace'),
                  filled: true,
                  fillColor: Color(0xFF1E1E2E),
                ),
              ),
            ),
          ),

          // Run button bar
          Container(
            color: const Color(0xFF181825),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp16, vertical: AppTheme.sp8),
            child: Row(children: [
              Text(_selectedLanguage.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF89B4FA),
                      fontFamily: 'monospace', fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_execTime != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.sp16),
                  child: Text('${_execTime}ms',
                      style: const TextStyle(color: Color(0xFF6C7086), fontSize: 12)),
                ),
              ElevatedButton.icon(
                onPressed: _running ? null : _run,
                icon: _running
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(_running ? 'Running...' : 'Run Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ]),
          ),

          // Output Panel
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF11111B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp16, vertical: AppTheme.sp8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFF313244))),
                    ),
                    child: Row(children: [
                      const Icon(Icons.terminal_rounded,
                          color: Color(0xFF89B4FA), size: 16),
                      const SizedBox(width: AppTheme.sp8),
                      const Text('Output',
                          style: TextStyle(color: Color(0xFFCDD6F4),
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      if (_output.isNotEmpty || _error != null)
                        GestureDetector(
                          onTap: () => setState(() { _output = ''; _error = null; }),
                          child: const Text('Clear',
                              style: TextStyle(color: Color(0xFF6C7086), fontSize: 12)),
                        ),
                    ]),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.sp16),
                      child: SelectableText(
                        _error != null
                            ? '❌ Error:\n$_error'
                            : _output.isNotEmpty
                                ? _output
                                : 'Run your code to see output here...',
                        style: TextStyle(
                          color: _error != null
                              ? const Color(0xFFF38BA8)
                              : const Color(0xFFA6E3A1),
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
