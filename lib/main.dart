import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Generator App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QRGeneratorPage(),
    );
  }
}

class QRGeneratorPage extends StatefulWidget {
  const QRGeneratorPage({super.key});

  @override
  _QRGeneratorPageState createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey globalKey = GlobalKey(); // Key for RepaintBoundary
  String qrData = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Tool ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tool Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Concatenar ID y nombre en un formato JSON
                  qrData =
                      '{"id": "${idController.text}", "name": "${nameController.text}"}';
                });
              },
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 20),
            qrData.isNotEmpty
                ? RepaintBoundary(
                    key: globalKey,
                    child: Column(
                      children: <Widget>[
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          gapless: false,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (cxt, err) {
                            return const Center(
                              child: Text(
                                'Uh oh! Something went wrong...',
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          nameController.text,
                          style:
                              const TextStyle(fontSize: 20, color: Colors.blue),
                        ),
                      ],
                    ),
                  )
                : Container(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: qrData.isNotEmpty ? _saveQRToGallery : null,
              child: const Text('Save to Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQRToGallery() async {
    try {
      // Obtén la imagen desde el widget.
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List bytes = byteData.buffer.asUint8List();

        // Usa gal para guardar la imagen en la galería desde bytes.
        final album = 'QR Codes';
        await Gal.putImageBytes(bytes, album: album);

        // Muestra un mensaje de éxito al usuario.
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Code saved to gallery!')));
      }
    } catch (e) {
      print('Error saving QR Code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save QR Code')));
    }
  }
}
