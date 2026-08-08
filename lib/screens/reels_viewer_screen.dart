// Full-screen, Instagram-style reels viewer.
// Swipe vertically between reels; videos auto-play, tap to pause/resume.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme.dart';
import '../services/reels_service.dart';
import '../services/social_service.dart';

class ReelsViewerScreen extends StatefulWidget {
  final List<ReelItem> reels;
  final int initialIndex;

  const ReelsViewerScreen({
    super.key,
    required this.reels,
    this.initialIndex = 0,
  });

  @override
  State<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends State<ReelsViewerScreen> {
  late PageController _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.reels.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _ReelPage(
                  key: ValueKey(widget.reels[index].code),
                  reel: widget.reels[index],
                  isActive: index == _current,
                  isDark: isDark,
                );
              },
            ),
            // Close button
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Text(
                '${_current + 1}/${widget.reels.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  final ReelItem reel;
  final bool isActive;
  final bool isDark;

  const _ReelPage({
    super.key,
    required this.reel,
    required this.isActive,
    required this.isDark,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  VideoPlayerController? _controller;
  bool _showPlayIcon = false;
  bool _videoError = false;
  bool _liked = false;
  int _likeCount = 0;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.reel.likeCount;
    _commentCount = widget.reel.commentCount;
    if (widget.reel.isVideo && widget.reel.videoUrl != null) {
      _initVideo(widget.reel.videoUrl!);
    }
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await SocialService.getReelStats(widget.reel.code);
    if (stats != null && mounted) {
      setState(() {
        _likeCount = (stats['likes'] as int?) ?? _likeCount;
        _commentCount = (stats['comments'] as List?)?.length ?? _commentCount;
      });
    }
  }

  void _showCommentSheet(BuildContext context) {
    final ctl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Comments ($_commentCount)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Be the first to comment!'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctl,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.brandBlue),
                  onPressed: () async {
                    final text = ctl.text.trim();
                    if (text.isNotEmpty) {
                      await SocialService.commentOnReel(widget.reel.code, text, 'Fan');
                      if (mounted) {
                        setState(() => _commentCount += 1);
                        _loadStats();
                      }
                      ctl.clear();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _initVideo(String url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        if (widget.isActive) _controller!.setLooping(true);
        if (widget.isActive) _controller!.play();
      }).catchError((e) {
        if (mounted) setState(() => _videoError = true);
      });
  }

  @override
  void didUpdateWidget(covariant _ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null) return;
    if (widget.isActive && !_controller!.value.isPlaying) {
      _controller!.play();
    } else if (!widget.isActive && _controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showPlayIcon = true;
      } else {
        _controller!.play();
        _showPlayIcon = false;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final hasVideo = reel.isVideo && _controller != null && _controller!.value.isInitialized;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media layer
          if (hasVideo)
            Center(child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ))
          else if (reel.imageUrl != null && reel.imageUrl!.isNotEmpty)
            Image.network(
              reel.imageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          else
            _placeholder(),

          if (_videoError)
            _placeholder(text: 'Video unavailable'),

          // Tap-to-pause indicator
          if (_showPlayIcon)
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
            ),

          // Gradient + caption overlay (Instagram style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 80, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${reel.username ?? 'sports'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (reel.caption.isNotEmpty)
                    Text(
                      reel.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),

          // Right action rail
          Positioned(
            right: 12,
            bottom: 28,
            child: Column(
              children: [
                _action(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  _formatCount(_likeCount),
                  onTap: () async {
                    setState(() => _liked = !_liked);
                    if (_liked) {
                      final c = await SocialService.likeReel(reel.code);
                      if (mounted) setState(() => _likeCount = c);
                    } else {
                      final c = await SocialService.unlikeReel(reel.code);
                      if (mounted) setState(() => _likeCount = c);
                    }
                  },
                  active: _liked,
                ),
                const SizedBox(height: 18),
                _action(
                  Icons.comment_outlined,
                  _formatCount(_commentCount),
                  onTap: () => _showCommentSheet(context),
                ),
                const SizedBox(height: 18),
                _action(
                  Icons.remove_red_eye_outlined,
                  _formatCount(reel.viewCount),
                ),
                const SizedBox(height: 18),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved'),
                      duration: Duration(seconds: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
                  onPressed: () async {
                    final text = reel.link.isNotEmpty
                        ? '${reel.caption}\n${reel.link}'
                        : reel.caption;
                    Clipboard.setData(ClipboardData(text: text));
                    await SocialService.shareReel(reel.code);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label,
      {VoidCallback? onTap, bool active = false}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: active ? Colors.redAccent : Colors.white, size: 28),
          onPressed: onTap ?? () {},
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _placeholder({String text = 'No preview'}) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports, color: Colors.white38, size: 56),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
