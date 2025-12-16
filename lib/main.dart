import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:filesystem_picker/filesystem_picker.dart';

void main() {
  runApp(Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MusicPlayerScreen());
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<File> _audioFiles = [];
  late AudioPlayer _audioPlayer; // 1. Audio Player Instance

  @override
  void initState() {
    super.initState();
    permsAndStructure();
    _controller = AnimationController(vsync: this);
    _audioPlayer = AudioPlayer(); // 2. Initialize Player
  }

  Future<void> permsAndStructure() async {
    var status = await Permission.audio.request();
    if (status.isDenied) {
      debugPrint("Audio permission denied, opening app settings.");
      openAppSettings();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose(); // 2. Dispose Player
    super.dispose();
  }

  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.deepPurpleAccent,
            title: const Text('MusicM: Music Library'),
            toolbarHeight: kToolbarHeight * 2,
          ),

          drawer: Drawer(),
          body: ListView.builder(
            padding: const EdgeInsets.only(top: 80),
            itemCount: _audioFiles.length,
            itemBuilder: (context, index) {
              final file = _audioFiles[index];
              final fileName = file.path.split('/').last;

              // 3. Add onTap Handler
              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(fileName),
                onTap: () async {
                  // 4. Play Logic
                  debugPrint("Playing ${file.path}");
                  try {
                    await _audioPlayer.setFilePath(file.path);
                    _audioPlayer.play();
                  } catch (e) {
                    debugPrint("Error playing audio: $e");
                  }
                },
              );
            },
          ),
        ),
        Positioned(
          top: 100.0,
          left: 16.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              debugPrint("Song button pressed");

              String? path = await FilesystemPicker.open(
                title: 'Select a folder',
                context: context,
                rootDirectory: Directory('/storage/emulated/0/Music'),
                fsType: FilesystemType.folder,
                pickText: 'Select this folder',
              );

              if (path != null) {
                debugPrint("Selected directory: $path");

                final directory = Directory(path);
                List<File> foundFiles = [];

                await for (var entity in directory.list()) {
                  if (entity is File) {
                    if (entity.path.endsWith('.mp3') ||
                        entity.path.endsWith('.m4a') ||
                        entity.path.endsWith('.wav')) {
                      foundFiles.add(entity);
                    }
                  }
                }
                setState(() {
                  _audioFiles = foundFiles;
                });

                debugPrint("Found ${_audioFiles.length} audio files:");
              } else {
                debugPrint("No directory selected.");
              }
            },
            child: const Text('Songs'),
          ),
        ),
      ],
    );
  }
}
