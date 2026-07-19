import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String lessonTitle;
  const VideoPlayerScreen(
      {super.key, required this.videoUrl, required this.lessonTitle});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primary,
          handleColor: AppTheme.primary,
          backgroundColor: AppTheme.bgSection,
          bufferedColor: AppTheme.primaryLight,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: Text(widget.lessonTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _error
                ? Container(
                    color: AppTheme.bgSection,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: AppTheme.error, size: 48),
                          SizedBox(height: AppTheme.sp8),
                          Text('Failed to load video.',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                : !_initialized
                    ? Container(
                        color: AppTheme.bgSection,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary),
                        ),
                      )
                    : Chewie(controller: _chewieController!),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.sp24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.lessonTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.sp8),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: AppTheme.sp16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp8, vertical: AppTheme.sp4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusButton),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_camera_back_outlined,
                            color: AppTheme.primary, size: 16),
                        SizedBox(width: 6),
                        Text('Video Lesson',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                      'Have questions? Ask the AI Tutor for help with this lesson.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
