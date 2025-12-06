import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediaJournalApp());
}

class MediaJournalApp extends StatelessWidget {
  const MediaJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaJournal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

enum PageMode { notes, camera, video }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageMode _mode = PageMode.notes;

  // ---------------- NOTES (File I/O) ----------------
  final TextEditingController _notesController = TextEditingController();
  String _loadedText = '';

  List<String> get _lines => _loadedText.isEmpty
      ? const []
      : _loadedText.split('\n').where((e) => e.trim().isNotEmpty).toList();

  Future<File> _notesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'notes.txt'));
  }

  Future<void> _saveNotes() async {
    final file = await _notesFile();
    await file.writeAsString(_notesController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan tersimpan ke notes.txt')),
    );
  }

  Future<void> _loadNotes() async {
    try {
      final file = await _notesFile();
      if (await file.exists()) {
        final text = await file.readAsString();
        setState(() => _loadedText = text);
      } else {
        setState(() => _loadedText = '');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat catatan: $e')),
      );
    }
  }

  // ---------------- CAMERA (Image Picker + AnimatedSwitcher) ----------------
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;

  Future<void> _pickFromGallery() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _pickedImage = File(x.path));
  }

  Future<void> _pickFromCamera() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.camera);
    if (x != null) setState(() => _pickedImage = File(x.path));
  }

  // ---------------- VIDEO (Video Player) ----------------
  late final VideoPlayerController _videoController;
  Future<void>? _videoInit;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    );
    _videoInit = _videoController.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForMode(_mode)),
        actions: [
          PopupMenuButton<PageMode>(
            onSelected: (m) => setState(() => _mode = m),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: PageMode.notes, child: Text('Catatan')),
              PopupMenuItem(value: PageMode.camera, child: Text('Kamera')),
              PopupMenuItem(value: PageMode.video, child: Text('Video')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  String _titleForMode(PageMode mode) {
    switch (mode) {
      case PageMode.notes:
        return 'Catatan & File I/O';
      case PageMode.camera:
        return 'Kamera (Picker) & AnimatedSwitcher';
      case PageMode.video:
        return 'Media Player (Video)';
    }
  }

  Widget _buildBody() {
    switch (_mode) {
      case PageMode.notes:
        return _notesView();
      case PageMode.camera:
        return _cameraView();
      case PageMode.video:
        return _videoView();
    }
  }

  // ---------------- NOTES VIEW ----------------
  Widget _notesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Tulis catatan di sini',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _saveNotes,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _loadNotes,
              icon: const Icon(Icons.download),
              label: const Text('Muat'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Daftar Catatan (ListView.builder):',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _lines.isEmpty
              ? const Center(child: Text('Belum ada catatan tersimpan.'))
              : ListView.builder(
                  itemCount: _lines.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(Icons.note),
                    title: Text(_lines[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // ---------------- CAMERA VIEW ----------------
  Widget _cameraView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _pickedImage == null
                  ? const Text(
                      'Belum ada gambar.\nAmbil dari kamera atau pilih dari galeri.',
                      key: ValueKey('empty'),
                      textAlign: TextAlign.center,
                    )
                  : Image.file(
                      _pickedImage!,
                      key: ValueKey('image'),
                      width: 260,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFromCamera,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Kamera'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeri'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- VIDEO VIEW ----------------
  Widget _videoView() {
    return Column(
      children: [
        FutureBuilder(
          future: _videoInit,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              );
            }
            return AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                if (_videoController.value.isPlaying) {
                  _videoController.pause();
                } else {
                  _videoController.play();
                }
                setState(() {});
              },
              icon: Icon(
                _videoController.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              label: Text(
                _videoController.value.isPlaying ? 'Pause' : 'Play',
              ),
            ),
          ],
        ),
      ],
    );
  }
}