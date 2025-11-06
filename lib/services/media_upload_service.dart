import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_compress/video_compress.dart';

class MediaUploadService {
  // Cloudinary config - Replace with your actual credentials
  static const String cloudName = 'dfakkp96h'; // Replace this
  static const String uploadPreset = 'rizzumepreset'; // Replace this

  /// Generate thumbnail from video
  Future<File?> generateThumbnail(String videoPath) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 50,
        position: 0,
      );
      return thumbnailFile;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Compress video to reduce size
  Future<File?> compressVideo(String inputPath) async {
    try {
      final info = await VideoCompress.compressVideo(
        inputPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      
      if (info == null || info.path == null) return null;
      return File(info.path!);
    } catch (e) {
      print('Error compressing video: $e');
      return null;
    }
  }

  /// Upload file to Cloudinary
  Future<Map<String, dynamic>> uploadToCloudinary(
    File file, {
    required String folder,
    bool isVideo = false,
  }) async {
    final resourceType = isVideo ? 'video' : 'image';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;

    if (isVideo) {
      request.fields['resource_type'] = 'video';
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusCode} ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Upload video with thumbnail
  Future<Map<String, String>> uploadVideoWithThumbnail(File videoFile) async {
    try {
      // 1. Get video duration first (in seconds)
      final durationSeconds = await getVideoDuration(videoFile.path);
      
      // 2. Compress video
      print('Compressing video...');
      final compressed = await compressVideo(videoFile.path);
      final toUpload = compressed ?? videoFile;

      // 3. Generate thumbnail
      print('Generating thumbnail...');
      final thumbFile = await generateThumbnail(toUpload.path);

      // 4. Upload video
      print('Uploading video...');
      final videoResponse = await uploadToCloudinary(
        toUpload,
        folder: 'rizzume/videos',
        isVideo: true,
      );

      // 5. Upload thumbnail if generated
      String? thumbnailUrl;
      if (thumbFile != null) {
        print('Uploading thumbnail...');
        final thumbResponse = await uploadToCloudinary(
          thumbFile,
          folder: 'rizzume/video_thumbs',
          isVideo: false,
        );
        thumbnailUrl = thumbResponse['secure_url'] as String?;
      }

      return {
        'videoUrl': videoResponse['secure_url'] as String,
        'thumbnailUrl': thumbnailUrl ?? '',
        'duration': durationSeconds.toString(),
      };
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  /// Get video duration in seconds
  Future<int> getVideoDuration(String videoPath) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoPath);
      // duration is in milliseconds, convert to seconds
      final durationMs = info.duration?.toInt() ?? 0;
      return (durationMs / 1000).round();
    } catch (e) {
      print('Error getting video duration: $e');
      return 0;
    }
  }

  /// Cancel compression
  void cancelCompression() {
    VideoCompress.cancelCompression();
  }

  /// Delete cached files
  Future<void> deleteAllCache() async {
    await VideoCompress.deleteAllCache();
  }
}
