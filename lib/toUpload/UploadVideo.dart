import 'dart:io';

import 'package:cupertino_icons/cupertino_icons.dart';
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
  bool vU=false,tU=false,dU=false;
  Future<void> _uploadVideo() async {
    if (_videoFile == null || _thumbnailFile == null) return;

    final title = _titleController.text;
    final description = _descriptionController.text;
    final docPath=DateTime.now().millisecondsSinceEpoch;

    // Upload video to Supabase Storage
    final videoResponse = await Supabase.instance.client.storage
        .from('videos')
        .upload('${docPath}.mp4', _videoFile!).whenComplete(() {
          setState(() {
            vU=true;
          });
    });

    if (videoResponse == null) {
      print('Error uploading video: ${videoResponse.toString()}');
      return;
    }

    // Upload thumbnail to Supabase Storage
    final thumbnailResponse = await Supabase.instance.client.storage
        .from('thumbnail')
        .upload('${docPath}.jpg', _thumbnailFile!).whenComplete((){
          setState(() {
            tU=true;
          });
    });

    if (thumbnailResponse == null) {
      print('Error uploading thumbnail: ${thumbnailResponse.toString()}');
      return;
    }

    final videoUrl = Supabase.instance.client.storage.from('videos').getPublicUrl('${docPath}.mp4');
    String tt=videoUrl;

    final thumbnailUrl = Supabase.instance.client.storage.from('thumbnail').getPublicUrl('${docPath}.jpg');

    // Insert video metadata into Supabase table
    final insertResponse = await Supabase.instance.client
        .from('videos')
        .insert({
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'views': 0,
    }).whenComplete(() {
      dU=true;
    });

    if (insertResponse.error != null) {
      print('Error inserting video metadata: ${insertResponse.error!.message}');
      return;
    }



    print('Video uploaded successfully!');

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16.0),
              _videoFile == null
                  ? Text('No video selected.')
                  : _videoPlayerController!.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              )
                  : CircularProgressIndicator(),
              SizedBox(height: 16.0),
              _thumbnailFile == null
                  ? Text('No thumbnail selected.')
                  : Image.file(_thumbnailFile!),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _pickVideo,
                child: Text('Select Video'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _pickThumbnail,
                child: Text('Select Thumbnail'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: (){
                  _uploadVideo;
                  if(vU && tU && dU)
                 {
                   setState(() {
                     {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Video uploaded successfully!')),
                       );
                     }
                   });
                 }
                },
                child: Text('Upload Video'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}