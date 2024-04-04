import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<ListResult> futureFiles;
  Map<int, double> downloadProgress = {};
  @override
  void initState() {
    super.initState();
    futureFiles = FirebaseStorage.instance.ref("/files").listAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Files')),
      body: FutureBuilder<ListResult>(
        future: futureFiles,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final files = snapshot.data!.items;
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                double? progress = downloadProgress[index];
                return ListTile(
                    title: Text(file.name),
                    subtitle: progress != null ? LinearProgressIndicator(value: progress, backgroundColor: Colors.black26) : null,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.download,
                        color: Colors.black,
                      ),
                      onPressed: () => downloadFile(index, file),
                    ));
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<void> downloadFile(int index, Reference ref) async {
    final url = await ref.getDownloadURL();
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/${ref.name}';
    await Dio().download(url, path, onReceiveProgress: (received, total) {
      double progress = received / total;

      //bu kısımda setState kullanmamızın sebebi, indirme işlemi sırasında progress değerinin değişmesi
      setState(() {
        downloadProgress[index] = progress;
      });
    });

    if (url.contains('mp4')) {
      await GallerySaver.saveVideo(path, toDcim: true);
    } else if (url.contains('png')) {
      await GallerySaver.saveImage(path, toDcim: true);
    } else if (url.contains('jpg')) {
      await GallerySaver.saveImage(path, toDcim: true);
    }

    // Indirme tamamlandığında uyarı gösterme
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dosya Başarıyla İndirildi: ${ref.name}'),
      ),
    );

    // Anasayfaya geri dönme
    Navigator.pop(context);
  }
}
