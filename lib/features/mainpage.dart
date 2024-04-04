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
  PlatformFile? pickedFile;// Dosya seçme işlemi
  UploadTask? uploadTask;// Dosya yükleme işlemi
  VideoPlayerController? _videoPlayerController; // Videoyu oynatma işlemi

  @override
  void dispose() {// Videoyu kapatma işlemi
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> selectFile() async {// Dosya seçme işlemi 
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,// Dosya seçme işlemi için dosya türünü belirleme
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4'],// Dosya seçme işlemi için dosya uzantılarını belirleme
    );

    if (result == null || result.files.isEmpty) return; // Dosya seçilmediyse, dosya seçme işlemi yapma

    setState(() {
      pickedFile = result.files.first;// Dosya seçme işlemi 
    });

    if (pickedFile!.extension == 'mp4') {// Eğer dosya bir video ise videoyu yükleme işlemi yapma
      _videoPlayerController = VideoPlayerController.file(File(pickedFile!.path!))
        ..initialize().then((_) {// Videoyu yükleme işlemi
          setState(() {// Videoyu oynatma işlemi
            _videoPlayerController!.play();// Videoyu oynatma 
          });
        });
    }
  }

  Future<void> uploadFile() async {// Dosya yükleme işlemi
    if (pickedFile == null) return;// Dosya seçilmediyse, dosya yükleme işlemi yapma

    final path = 'files/${pickedFile!.name}';// Dosya yükleme işlemi için dosya yolu belirleme
    final file = File(pickedFile!.path!);// Dosya yükleme işlemi için dosya oluşturma

    final ref = FirebaseStorage.instance.ref().child(path);// Dosya yükleme işlemi için referans oluşturma
    setState(() {
      uploadTask = ref.putFile(file);// Dosya yükleme işlemi başlatma
    });
    final snapshot = await uploadTask!.whenComplete(() => null);// Dosya yükleme işlemi tamamlandığında snapshot al
    final urlDownload = await snapshot.ref.getDownloadURL();// Dosya yükleme işlemi tamamlandığında dosyanın indirme bağlantısını al
    print('Download-Link: $urlDownload');// Dosyanın indirme bağlantısını yazdır

    setState(() {
      // İlerleme çubuğunu kaldırma
      uploadTask = null;
      // Dosya seçimini kaldırma
      pickedFile = null;
    });

    // Uyarı mesajını gösterme ve ilerleme çubuğunu kaldırma
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        // Uyarı mesajını gösterme
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
          // Eğer dosya seçilmişse, dosyayı gösterme
          if (pickedFile != null) 
          
            Expanded(
              child: Container(
                color: Colors.blue[100], // Dosya seçildiğinde arka plan rengini belirleme
                child: Center(

                  // Seçilen dosyanın tipine göre, dosyayı gösterme
                  child: pickedFile!.extension == 'mp4'

                  // Eğer dosya bir video ise, videoyu oynat
                      ? _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                      //burda aspect ratio belirliyoruz, videoyu o şekilde gösteriyoruz
                          ? AspectRatio(
                              aspectRatio: _videoPlayerController!.value.aspectRatio,
                              child: VideoPlayer(_videoPlayerController!),
                            )
                          : Container()
                      : Image.file(
                        // Eğer dosya bir resim ise, resmi göster
                          File(pickedFile!.path!),
                          //resmi tam ekran yapmak için
                          fit: BoxFit.cover,
                          //resmi genişletmek için
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
    // Yükleme işlemi sırasında ilerleme çubuğunu gösterme
        stream: uploadTask?.snapshotEvents,
        // Yükleme işlemi sırasında ilerleme çubuğunu güncelleme
        builder: (context, snapshot) {
          // Eğer yükleme işlemi tamamlanmışsa, ilerleme çubuğunu kaldır
          if (snapshot.hasData) {
            final data = snapshot.data!;
            // İlerleme çubuğunu güncelleme
            double progress = data.bytesTransferred / data.totalBytes;
            // İlerleme çubuğunu gösterme
            return SizedBox(
              
              height: 50,
              // İlerleme çubuğunu oluşturma
              child: Stack(children: [
                // İlerleme çubuğunu oluşturma
                LinearProgressIndicator(
                  // İlerleme çubuğunun değerini güncelleme
                  value: progress,
                  // İlerleme çubuğunun arka plan rengini belirleme
                  backgroundColor: Colors.grey,
                  // İlerleme çubuğunun rengini belirleme
                  color: Colors.green,
                ),
                // İlerleme çubuğunun değerini gösterme
                Center(
                  child: Text(
                    // İlerleme çubuğunun değerini yüzde olarak gösterme
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
// Anasayfaya geri dönme
Future<void> navigateToHomePage(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const HomePage()),
  );
}
