import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save personal profile
  Future<void> savePersonalProfile({
    required List<String> interests,
    required String bio,
    List<String>? photoUrls,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    await _db.collection('users').doc(uid).update({
      'personalProfile': {
        'interests': interests,
        'bio': bio,
        'photoUrls': photoUrls ?? [],
      },
      'profileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Save job profile
  Future<void> saveJobProfile({
    required String jobTitle,
    required String company,
    required String location,
    required String startDate,
    required String endDate,
    required String description,
    required String school,
    required String degree,
    required String fieldOfStudy,
    required String graduationDate,
    required String skills,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    await _db.collection('users').doc(uid).update({
      'jobProfile': {
        'experience': {
          'jobTitle': jobTitle,
          'company': company,
          'location': location,
          'startDate': startDate,
          'endDate': endDate,
          'description': description,
        },
        'education': {
          'school': school,
          'degree': degree,
          'fieldOfStudy': fieldOfStudy,
          'graduationDate': graduationDate,
        },
        'skills': skills,
      },
      'profileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new post
  Future<String> createPost({
    required String content,
    String? imageUrl,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    // Get user data
    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data();

    final postData = {
      'userId': uid,
      'userName': userData?['name'] ?? 'Anonymous',
      'profilePicture': userData?['profilePicture'],
      'content': content,
      'imageUrl': imageUrl,
      'likes': 0,
      'likedBy': [],
      'comments': 0,
      'shares': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add video fields if video is included
    if (videoUrl != null) {
      postData['videoUrl'] = videoUrl;
      postData['thumbnailUrl'] = thumbnailUrl;
      postData['duration'] = duration;
    }

    final postRef = await _db.collection('posts').add(postData);

    return postRef.id;
  }

  // Get all posts (stream for real-time updates)
  Stream<QuerySnapshot> getPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Like/unlike a post
  Future<void> toggleLike(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final postRef = _db.collection('posts').doc(postId);
    final post = await postRef.get();
    final likedBy = List<String>.from(post.data()?['likedBy'] ?? []);

    if (likedBy.contains(uid)) {
      // Unlike - remove from likedBy array
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      // Like - add to likedBy array
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // Add a comment to a post (comments stored in subcollection posts/{postId}/comments)
  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data();

    final commentRef = _db.collection('posts').doc(postId).collection('comments').doc();
    await commentRef.set({
      'commentId': commentRef.id,
      'userId': uid,
      'userName': userData?['name'] ?? 'Anonymous',
      'profilePicture': userData?['profilePicture'],
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // increment comment counter on post doc
    await _db.collection('posts').doc(postId).update({'comments': FieldValue.increment(1)});
  }

  // Stream comments for a post
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    await _db.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
    await _db.collection('posts').doc(postId).update({'comments': FieldValue.increment(-1)});
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final postRef = _db.collection('posts').doc(postId);
    final postDoc = await postRef.get();
    final postData = postDoc.data();

    // Only allow delete if current user is the author
    if (postData?['userId'] != uid) {
      throw Exception('Permission denied');
    }

    // Delete comments subcollection documents (batch)
    final comments = await postRef.collection('comments').get();
    final batch = _db.batch();
    for (final doc in comments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(postRef);
    await batch.commit();
  }

  // Get user profile
  Future<DocumentSnapshot> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // Update profile picture
  Future<void> updateProfilePicture(String base64Image) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    // Update user's profile doc
    await _db.collection('users').doc(uid).update({
      'profilePicture': base64Image,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Propagate profile picture to existing posts and comments authored by the user.
    // Use batched writes in chunks to respect Firestore limits (500 operations per batch).
    try {
      // Fetch all posts authored by this user
      final postsQuery = await _db.collection('posts').where('userId', isEqualTo: uid).get();

      final List<WriteBatch> batches = [];
      WriteBatch currentBatch = _db.batch();
      int pending = 0;

      void commitBatchIfNeeded() {
        if (pending >= 450) {
          batches.add(currentBatch);
          currentBatch = _db.batch();
          pending = 0;
        }
      }

      for (final postDoc in postsQuery.docs) {
        // Update the post's profilePicture field
        currentBatch.update(postDoc.reference, {'profilePicture': base64Image});
        pending++;
        commitBatchIfNeeded();

        // Update any comments in this post authored by the user
        final commentsQuery = await postDoc.reference.collection('comments').where('userId', isEqualTo: uid).get();
        for (final commentDoc in commentsQuery.docs) {
          currentBatch.update(commentDoc.reference, {'profilePicture': base64Image});
          pending++;
          commitBatchIfNeeded();
        }
      }

      // Add the final batch if it has writes
      if (pending > 0) batches.add(currentBatch);

      // Commit all batches sequentially
      for (final b in batches) {
        await b.commit();
      }
    } catch (e) {
      // Non-fatal: log and continue. Propagation can be retried later via cloud function or admin script.
      // In an app environment, consider surfacing a retry option to the user.
      // For now, swallow and rethrow only if necessary
      // ignore: avoid_print
      print('⚠️ Error propagating profile picture to posts/comments: $e');
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // Public helper to get current UID
  String? getCurrentUid() {
    return _auth.currentUser?.uid;
  }

  // Follow a user
  Future<void> followUser(String targetUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');
    if (uid == targetUid) throw Exception('Cannot follow yourself');

    final batch = _db.batch();

    // Add targetUid to current user's following array
    batch.update(_db.collection('users').doc(uid), {
      'following': FieldValue.arrayUnion([targetUid]),
      'followingCount': FieldValue.increment(1),
    });

    // Add uid to target user's followers array
    batch.update(_db.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayUnion([uid]),
      'followerCount': FieldValue.increment(1),
    });

    await batch.commit();

    // Update connection count for both users
    await _updateConnectionCount(uid);
    await _updateConnectionCount(targetUid);
  }

  // Unfollow a user
  Future<void> unfollowUser(String targetUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final batch = _db.batch();

    // Remove targetUid from current user's following array
    batch.update(_db.collection('users').doc(uid), {
      'following': FieldValue.arrayRemove([targetUid]),
      'followingCount': FieldValue.increment(-1),
    });

    // Remove uid from target user's followers array
    batch.update(_db.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayRemove([uid]),
      'followerCount': FieldValue.increment(-1),
    });

    await batch.commit();

    // Update connection count for both users
    await _updateConnectionCount(uid);
    await _updateConnectionCount(targetUid);
  }

  // Check if current user is following target user
  Future<bool> isFollowing(String targetUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _db.collection('users').doc(uid).get();
    final following = List<String>.from(doc.data()?['following'] ?? []);
    return following.contains(targetUid);
  }

  // Update connection count (mutual follows)
  Future<void> _updateConnectionCount(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return;

    final followers = Set<String>.from(data['followers'] ?? []);
    final following = Set<String>.from(data['following'] ?? []);
    final connections = followers.intersection(following);

    await _db.collection('users').doc(userId).update({
      'connectionCount': connections.length,
    });
  }

  // Initialize stats fields for existing user (migration helper)
  Future<void> initializeUserStats(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return;

    final updates = <String, dynamic>{};
    
    if (!data.containsKey('followers')) updates['followers'] = [];
    if (!data.containsKey('following')) updates['following'] = [];
    if (!data.containsKey('followerCount')) updates['followerCount'] = 0;
    if (!data.containsKey('followingCount')) updates['followingCount'] = 0;
    if (!data.containsKey('connectionCount')) updates['connectionCount'] = 0;

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(userId).update(updates);
    }
  }
}
