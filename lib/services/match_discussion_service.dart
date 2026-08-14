// Persistent, Firestore-backed match discussion board.
//
// Unlike the ephemeral WS Live Chat (a real-time ticker), this persists a
// threaded history per match so fans can keep discussing before/during/after
// a game. Collection layout (free-tier safe):
//
//   match_discussions/{matchId}/posts/{postId}
//       { text, uid, userName, userPhoto, likes: [uid], replies: [ {...} ], createdAt }
//
// Reads are public; writes require auth. Rules live in firestore.rules.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchDiscussionReply {
  final String uid;
  final String? userName;
  final String? userPhoto;
  final String text;
  final DateTime? createdAt;

  const MatchDiscussionReply({
    required this.uid,
    this.userName,
    this.userPhoto,
    required this.text,
    this.createdAt,
  });

  factory MatchDiscussionReply.fromMap(Map<String, dynamic> m) {
    return MatchDiscussionReply(
      uid: (m['uid'] ?? '').toString(),
      userName: m['userName']?.toString(),
      userPhoto: m['userPhoto']?.toString(),
      text: (m['text'] ?? '').toString(),
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'text': text,
        'createdAt': Timestamp.now(),
      };
}

class MatchDiscussion {
  final String id;
  final String text;
  final String uid;
  final String? userName;
  final String? userPhoto;
  final DateTime? createdAt;
  final List<String> likes;
  final List<MatchDiscussionReply> replies;

  const MatchDiscussion({
    required this.id,
    required this.text,
    required this.uid,
    this.userName,
    this.userPhoto,
    this.createdAt,
    this.likes = const [],
    this.replies = const [],
  });

  bool get likedByMe {
    final u = FirebaseAuth.instance.currentUser;
    return u != null && likes.contains(u.uid);
  }

  factory MatchDiscussion.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? const {};
    return MatchDiscussion(
      id: doc.id,
      text: (d['text'] ?? '').toString(),
      uid: (d['uid'] ?? '').toString(),
      userName: d['userName']?.toString(),
      userPhoto: d['userPhoto']?.toString(),
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
      likes: List<String>.from((d['likes'] as List?) ?? const []),
      replies: ((d['replies'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => MatchDiscussionReply.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class MatchDiscussionService {
  static CollectionReference<Map<String, dynamic>> _posts(String matchId) =>
      FirebaseFirestore.instance
          .collection('match_discussions')
          .doc(matchId)
          .collection('posts');

  static Stream<List<MatchDiscussion>> stream(String matchId) {
    return _posts(matchId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(MatchDiscussion.fromDoc).toList());
  }

  static User? get _user => FirebaseAuth.instance.currentUser;

  static Future<void> addPost(String matchId, String text) async {
    final u = _user;
    final t = text.trim();
    if (u == null || t.isEmpty) return;
    await _posts(matchId).add({
      'text': t,
      'uid': u.uid,
      'userName': u.displayName ?? u.email ?? 'Fan',
      'userPhoto': u.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': <String>[],
      'replies': <dynamic>[],
    });
  }

  static Future<void> toggleLike(
      String matchId, MatchDiscussion post) async {
    final u = _user;
    if (u == null) return;
    final ref = _posts(matchId).doc(post.id);
    if (post.likedByMe) {
      await ref.update({'likes': FieldValue.arrayRemove([u.uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([u.uid])});
    }
  }

  static Future<void> addReply(
      String matchId, String postId, String text) async {
    final u = _user;
    final t = text.trim();
    if (u == null || t.isEmpty) return;
    final reply = MatchDiscussionReply(
      uid: u.uid,
      userName: u.displayName ?? u.email ?? 'Fan',
      userPhoto: u.photoURL,
      text: t,
    ).toMap();
    await _posts(matchId).doc(postId).update({
      'replies': FieldValue.arrayUnion([reply]),
    });
  }
}
