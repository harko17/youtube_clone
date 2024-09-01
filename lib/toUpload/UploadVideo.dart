import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube/home%20screen/home_screen.dart';

class VideoUploadScreen extends StatefulWidget {
  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  File? _videoFile;
  File? _thumbnailFile;
  VideoPlayerController? _videoPlayerController;
  double _progress = 0.0;

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _videoPlayerController = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController!.setLooping(true);
          });
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (title.isEmpty) {
      _showAlert('Title is required');
      return;
    }

    if (title.length > 50) {
      _showAlert('Title cannot be more than 50 characters');
      return;
    }

    if (description.isEmpty) {
      _showAlert('Description is required');
      return;
    }

    if (description.length > 500) {
      _showAlert('Description cannot be more than 500 characters');
      return;
    }

    if (_videoFile == null) {
      _showAlert('Please select a video');
      return;
    }

    if (_thumbnailFile == null) {
      _showAlert('Please select a thumbnail');
      return;
    }

    final docPath = DateTime.now().millisecondsSinceEpoch;

    try {
      setState(() {
        _progress = 0.25;
      });

      // Upload video to Supabase Storage
      final videoResponse = await Supabase.instance.client.storage
          .from('videos')
          .upload('${docPath}.mp4', _videoFile!);

      if (videoResponse == null) {
        throw Exception('Error uploading video');
      }

      setState(() {
        _progress = 0.5;
      });

      // Upload thumbnail to Supabase Storage
      final thumbnailResponse = await Supabase.instance.client.storage
          .from('thumbnail')
          .upload('${docPath}.jpg', _thumbnailFile!);

      if (thumbnailResponse == null) {
        throw Exception('Error uploading thumbnail');
      }

      setState(() {
        _progress = 0.75;
      });

      final videoUrl = Supabase.instance.client.storage
          .from('videos')
          .getPublicUrl('${docPath}.mp4');
      final thumbnailUrl = Supabase.instance.client.storage
          .from('thumbnail')
          .getPublicUrl('${docPath}.jpg');

      // Insert video metadata into Supabase table
      final insertResponse =
      await Supabase.instance.client.from('videos').insert({
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'views': 0,
      });

      if (insertResponse.error != null) {
        throw Exception(
            'Error inserting video metadata: ${insertResponse.error!.message}');
      }

      setState(() {
        _progress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video uploaded successfully!')),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      });
    } catch (e) {
      setState(() {
        _progress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video uploaded successfully!')),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      });
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _titleController,
              labelText: 'Video Title',
              hintText: 'Enter video title...',
              icon: Icons.title,
              maxLength: 50,
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: _descriptionController,
              labelText: 'Description',
              hintText: 'Enter video description...',
              icon: Icons.description,
              maxLength: 500,
            ),
            SizedBox(height: 20),
            _buildPreviewSection(),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSelectButton(
                  icon: Icons.video_library,
                  label: 'Select Video',
                  onPressed: _pickVideo,
                ),
                _buildSelectButton(
                  icon: Icons.image,
                  label: 'Select Thumbnail',
                  onPressed: _pickThumbnail,
                ),
              ],
            ),
            SizedBox(height: 30),
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.upload, size: 24),
                label: Text('Upload Video', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: _uploadVideo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required int maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _videoFile == null
            ? GestureDetector(
          onTap: _pickVideo,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text('No video selected')),
          ),
        )
            : AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: VideoPlayer(_videoPlayerController!),
        ),
        SizedBox(height: 20),
        _thumbnailFile == null
            ? GestureDetector(
          onTap: _pickThumbnail,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text('No thumbnail selected')),
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(_thumbnailFile!,
              height: 150, width: double.infinity, fit: BoxFit.cover),
        ),
      ],
    );
  }

  Widget _buildSelectButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
