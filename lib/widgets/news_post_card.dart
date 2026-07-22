// Big, Instagram-post-style news card used in the Home feed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data.dart';
import '../theme.dart';

class NewsPostCard extends StatefulWidget {
  final NewsItem item;

  const NewsPostCard({super.key, required this.item});

  @override
  State<NewsPostCard> createState() => _NewsPostCardState();
}

class _NewsPostCardState extends State<NewsPostCard> {
  bool _liked = false;
  final int _likeCount = 0;
  final int _commentCount = 0;
  final TextEditingController _commentCtl = TextEditingController();
  final List<String> _comments = [];

  void _toggleLike() {
    setState(() => _liked = !_liked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_liked ? 'Liked' : 'Like removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addComment() {
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
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Comments (${_comments.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (_comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No comments yet. Be the first!'),
              ),
            ..._comments.map((c) => ListTile(
                  leading: const Icon(Icons.comment_outlined),
                  title: Text(c),
                  dense: true,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtl,
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
                  onPressed: () {
                    final text = _commentCtl.text.trim();
                    if (text.isNotEmpty) {
                      setState(() => _comments.add(text));
                      _commentCtl.clear();
                      Navigator.of(ctx).pop();
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

  void _share() {
    final text = '${widget.item.title}\n${widget.item.link ?? ''}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    // Best-effort: copy to clipboard (no extra deps).
    // ignore: deprecated_member_use
    Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final desc = widget.item.description ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: sport avatar + source + time
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brandBlue.withValues(alpha: 0.15),
                  child: Text(
                    widget.item.sportEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.source,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.item.timeAgo.isNotEmpty)
                        Text(
                          widget.item.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.item.tag,
                    style: const TextStyle(
                      color: AppColors.brandBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Big image header
          if (widget.item.image != null && widget.item.image!.isNotEmpty)
            Image.network(
              widget.item.image!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, prog) =>
                  prog == null ? child : Container(height: 200, color: Colors.grey.shade800),
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.brandBlue.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 40, color: Colors.white54),
                ),
              ),
            ),

          // Title + description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                _stat(
                  _liked ? Icons.favorite : Icons.favorite_outline,
                  _liked ? 'Liked' : 'Like',
                  isDark,
                  onTap: _toggleLike,
                  active: _liked,
                ),
                const SizedBox(width: 18),
                _stat(
                  Icons.chat_bubble_outline,
                  'Comment',
                  isDark,
                  onTap: _addComment,
                ),
                const SizedBox(width: 18),
                _stat(
                  Icons.share_outlined,
                  'Share',
                  isDark,
                  onTap: _share,
                ),
                const Spacer(),
                if (widget.item.link != null && widget.item.link!.isNotEmpty)
                  TextButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Read'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandBlue,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, bool isDark,
      {VoidCallback? onTap, bool active = false}) {
    final color = active
        ? AppColors.brandBlue
        : (isDark ? Colors.white70 : Colors.grey.shade700);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
