import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_you_macos/demo.dart';

void main() {
  runApp(const WallpaperThemedApp());
}

class WallpaperThemedApp extends StatefulWidget {
  const WallpaperThemedApp({super.key});

  @override
  State<WallpaperThemedApp> createState() => _WallpaperThemedAppState();
}

class _WallpaperThemedAppState extends State<WallpaperThemedApp> {
  static const _wallpaperStream = EventChannel('wallpaper/imageStream');

  StreamSubscription? _subscription;
  ImageProvider? _wallpaperImage;

  @override
  void initState() {
    super.initState();

    _subscription = _wallpaperStream.receiveBroadcastStream().listen((
      dynamic data,
    ) {
      if (data is Uint8List) {
        setState(() {
          _wallpaperImage = MemoryImage(data);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ColorScheme>(
      future: _wallpaperImage != null
          ? ColorScheme.fromImageProvider(
              provider: _wallpaperImage!,
              brightness: Brightness.light,
            )
          : Future.value(ColorScheme.fromSeed(seedColor: Colors.black)),
      builder: (context, snapshot) {
        final scheme = snapshot.data;

        return MaterialApp(
          theme: scheme != null
              ? ThemeData(colorScheme: scheme, useMaterial3: true)
              : ThemeData(useMaterial3: true),
          home: const DemoPage(),
        );
      },
    );
  }
}
