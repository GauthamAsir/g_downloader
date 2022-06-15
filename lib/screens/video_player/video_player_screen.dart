import 'dart:io';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File file;

  const VideoPlayerScreen({Key? key, required this.file}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  FlickManager? flickManager;

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.file(widget.file),
    );
    setState(() {});
  }

  @override
  void dispose() {
    if (flickManager != null) {
      flickManager!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: flickManager == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : FlickVideoPlayer(flickManager: flickManager!,),
      ),
    );
  }
}
