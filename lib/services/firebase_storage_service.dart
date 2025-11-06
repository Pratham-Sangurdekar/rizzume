import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseStorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get Firebase Storage instance with proper error handling
  FirebaseStorage get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (e) {
      print('❌ Error accessing Firebase Storage: $e');
      rethrow;
    }
  }

  /// Upload image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadPostImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'post_${user.uid}_$timestamp.jpg';
      
      // Create reference to storage location with default bucket
      final storageRef = _storage.ref('posts/${user.uid}/$fileName');
      
      print('📤 Uploading image to: posts/${user.uid}/$fileName');
      
      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': timestamp.toString(),
        },
      );

      // Upload file with progress tracking
      final uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('📊 Upload progress: ${progress.toStringAsFixed(2)}%');
        },
        onError: (error) {
          print('❌ Upload stream error: $error');
        },
      );

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {
        print('✅ Upload task completed');
      });
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Firebase Storage Error: ${e.code} - ${e.message}');
      print('   Plugin: ${e.plugin}');
      print('   Stack trace: ${e.stackTrace}');
      
      // Provide user-friendly error messages
      if (e.code == 'storage/unauthorized') {
        throw Exception('Permission denied. Please enable Firebase Storage and configure security rules.');
      } else if (e.code == 'storage/canceled') {
        throw Exception('Upload was canceled.');
      } else if (e.code == 'storage/unknown' || e.message?.contains('404') == true) {
        throw Exception(
          'Firebase Storage not configured. Please:\n'
          '1. Go to Firebase Console\n'
          '2. Enable Storage in your project\n'
          '3. Set up security rules'
        );
      } else if (e.code == 'storage/object-not-found' || e.code == 'storage/bucket-not-found') {
        throw Exception(
          'Storage bucket not found. Please enable Firebase Storage in Firebase Console.'
        );
      } else if (e.code == 'storage/project-not-found') {
        throw Exception('Firebase project not found.');
      } else if (e.code == 'storage/quota-exceeded') {
        throw Exception('Storage quota exceeded.');
      } else if (e.code == 'storage/unauthenticated') {
        throw Exception('You must be logged in to upload images.');
      } else if (e.code == 'storage/retry-limit-exceeded') {
        throw Exception('Upload failed after multiple retries. Please check your internet connection.');
      } else {
        throw Exception('Upload failed: ${e.message ?? e.code}');
      }
    } catch (e) {
      print('❌ Unexpected error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload user profile picture
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final fileName = 'profile_${user.uid}.jpg';
      final storageRef = _storage.ref().child('profiles/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Image deleted successfully');
    } catch (e) {
      print('❌ Error deleting image: $e');
      // Don't throw error for delete failures
    }
  }
}
