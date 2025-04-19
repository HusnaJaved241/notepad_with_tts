import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:notepad_with_tts/custom_button.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _textFieldFocusNode = FocusNode();
  final TextEditingController _notesController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final String _fileName = "notes.txt";
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      setState(() => _permissionGranted = true);
      return;
    }

    final status = await Permission.manageExternalStorage.request();
    setState(() => _permissionGranted = status.isGranted);

    if (!status.isGranted) {
      _showSnackBar("Storage permission denied!");
    }
  }

  Future<void> _saveNoteToFile() async {
    if (_notesController.text.isEmpty) {
      _showSnackBar("Note cannot be empty!");
      return;
    }

    if (!_permissionGranted) {
      _showSnackBar("Please grant storage permission first");
      return;
    }

    try {
      final directory = Directory("/storage/emulated/0/Downloads/MyNotes");
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File("${directory.path}/$_fileName");
      await file.writeAsString(_notesController.text);

      _notesController.clear();
      _showSnackBar("Note saved to: ${file.path}");
    } catch (e) {
      _showSnackBar("Failed to save note: $e");
    }
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => _textFieldFocusNode.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Speaking Notepad",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 33),
                ),
              ),
              Stack(
                children: [
                  SizedBox(
                    height: screenHeight * 0.45,
                    width: screenWidth * 0.85,
                    child: TextFormField(
                      controller: _notesController,
                      focusNode: _textFieldFocusNode,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      shape: const CircleBorder(),
                      onPressed: () => _flutterTts.speak(_notesController.text),
                      child: const Icon(Icons.mic_sharp),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    right: 20,
                    child: FloatingActionButton(
                      shape: const CircleBorder(),
                      onPressed: () => _flutterTts.stop(),
                      child: const Icon(Icons.stop_circle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomElevatedButton(
                    onPressed: _saveNoteToFile,
                    text: "Save",
                  ),
                  CustomElevatedButton(
                    onPressed: _notesController.clear,
                    text: "Clear",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
