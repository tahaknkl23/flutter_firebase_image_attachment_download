import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_download/features/homepage.dart';
import 'package:video_player/video_player.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  PlatformFile? pickedFile;
  UploadTask? uploadTask;
  VideoPlayerController? _videoPlayerController;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      pickedFile = result.files.first;
    });

    if (pickedFile!.extension == 'mp4') {
      _videoPlayerController = VideoPlayerController.file(File(pickedFile!.path!))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  Future<void> uploadFile() async {
    if (pickedFile == null) return;

    final path = 'files/${pickedFile!.name}';
    final file = File(pickedFile!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    setState(() {
      uploadTask = ref.putFile(file);
    });

    final snapshot = await uploadTask!.whenComplete(() => null);
    final urlDownload = await snapshot.ref.getDownloadURL();
    print('Download-Link: $urlDownload');

    setState(() {
      uploadTask = null;
      pickedFile = null;
    });

    // Uyarı mesajını gösterme ve ilerleme çubuğunu kaldırma
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dosya başariyla yüklendi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select File')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (pickedFile != null)
            Expanded(
              child: Container(
                color: Colors.blue[100],
                child: Center(
                  child: pickedFile!.extension == 'mp4'
                      ? _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoPlayerController!.value.aspectRatio,
                              child: VideoPlayer(_videoPlayerController!),
                            )
                          : Container()
                      : Image.file(
                          File(pickedFile!.path!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: selectFile,
            child: const Text('Firebase Dosya Yüklemek İçin Seç'),
          ),
          ElevatedButton(
            onPressed: uploadFile,
            child: const Text('Firebase Storage Yükleme İşlemi Başlat'),
          ),
          ElevatedButton(
            onPressed: () => selectFile().then((_) => navigateToHomePage(context)),
            child: const Text('Dosya Seç ve Anasayfaya Git'),
          ),
          const SizedBox(height: 32),
          buildProgress(),
        ]),
      ),
    );
  }

  Widget buildProgress() => StreamBuilder<TaskSnapshot>(
        stream: uploadTask?.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            double progress = data.bytesTransferred / data.totalBytes;
            return SizedBox(
              height: 50,
              child: Stack(children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey,
                  color: Colors.green,
                ),
                Center(
                  child: Text(
                    '${(progress * 100).roundToDouble()} %',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ]),
            );
          } else {
            return const SizedBox(
              height: 50,
            );
          }
        },
      );
}

Future<void> navigateToHomePage(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const HomePage()),
  );
}
