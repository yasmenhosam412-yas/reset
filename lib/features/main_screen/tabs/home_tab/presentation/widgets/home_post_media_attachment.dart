import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/post_media_url.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_fullscreen_post_media.dart';
import 'package:video_player/video_player.dart';

/// Renders a feed attachment from [post_image] URL: image or inline video.
class HomePostMediaAttachment extends StatefulWidget {
  const HomePostMediaAttachment({
    super.key,
    required this.url,
    required this.scheme,
  });

  final String url;
  final ColorScheme scheme;

  @override
  State<HomePostMediaAttachment> createState() =>
      _HomePostMediaAttachmentState();
}

class _HomePostMediaAttachmentState extends State<HomePostMediaAttachment> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    if (postMediaUrlLooksLikeVideo(widget.url)) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      await c.setLooping(false);
      c.addListener(_onVideoControllerTick);
      if (!mounted) {
        c.removeListener(_onVideoControllerTick);
        await c.dispose();
        return;
      }
      setState(() {
        _video = c;
        _videoReady = true;
      });
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideoControllerTick);
    _video?.dispose();
    super.dispose();
  }

  void _onVideoControllerTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = postMediaUrlLooksLikeVideo(widget.url);
    if (isVideo && !_videoFailed) {
      if (!_videoReady || _video == null) {
        return AspectRatio(
          aspectRatio: 16 / 12,
          child: Container(
            color: widget.scheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: widget.scheme.primary,
              ),
            ),
          ),
        );
      }
      final controller = _video!;
      final ar = controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : (16 / 12);
      return AspectRatio(
        aspectRatio: ar,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    });
                  },
                  child: Center(
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: const [
                        Shadow(blurRadius: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    }
                    openFullscreenPostVideo(context, widget.url);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (isVideo && _videoFailed) {
      return AspectRatio(
        aspectRatio: 16 / 12,
        child: Container(
          color: widget.scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.videocam_off_outlined,
            color: widget.scheme.outline,
            size: 40,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openFullscreenPostImage(context, widget.url),
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.url,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) => Container(
                  color: widget.scheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: widget.scheme.outline,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Icon(
                  Icons.zoom_in_map_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.75),
                  shadows: const [Shadow(blurRadius: 8, color: Colors.black45)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
