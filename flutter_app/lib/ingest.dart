import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'phash.dart';

class VideoFrame {
  final File file;
  final int timestamp; // milliseconds
  final String hash;

  VideoFrame(this.file, this.timestamp, this.hash);
}

class IngestService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickScreenshotFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return null;
    return File(x.path);
  }

  Future<File?> pickVideoFromFiles() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    final path = result?.files.single.path;
    return path != null ? File(path) : null;
  }

  Future<List<VideoFrame>> extractFramesFromVideo(
    File videoFile, {
    Function(String)? onProgress,
  }) async {
    final frames = <VideoFrame>[];
    final deduplicator = FrameDeduplicator();

    // Get video duration (simplified - in real implementation you'd use ffmpeg)
    // For now, we'll extract frames at intervals
    const initialFps = 2; // Start at 2 fps
    const maxFps = 5; // Maximum 5 fps
    const intervalMs = 1000 ~/ initialFps; // 500ms intervals

    final tempDir = await getTemporaryDirectory();

    try {
      // Extract frames at regular intervals
      for (int timeMs = 0; timeMs < 300000; timeMs += intervalMs) {
        // Max 5 minutes
        onProgress?.call('Extracting frame at ${timeMs ~/ 1000}s...');

        final thumbnailBytes = await VideoThumbnail.thumbnailData(
          video: videoFile.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 75,
        );

        if (thumbnailBytes == null) {
          // Likely reached end of video
          break;
        }

        // Check for duplicates using perceptual hash
        if (!deduplicator.isDuplicate(thumbnailBytes, timeMs)) {
          // Save unique frame
          final frameFile = File(
            path.join(
              tempDir.path,
              'frame_${timeMs}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );

          await frameFile.writeAsBytes(thumbnailBytes);

          final hash = computePerceptualHash(thumbnailBytes);
          frames.add(VideoFrame(frameFile, timeMs, hash));

          onProgress?.call(
            'Extracted ${frames.length} unique frames '
            '(${deduplicator.uniqueFrameCount}/${deduplicator.totalFrameCount} unique)',
          );
        }

        // Adaptive frame rate: if we're getting too many duplicates,
        // we can increase the interval
        if (deduplicator.totalFrameCount > 10) {
          final uniqueRatio =
              deduplicator.uniqueFrameCount / deduplicator.totalFrameCount;
          if (uniqueRatio < 0.3) {
            // Too many duplicates, slow down
            break;
          }
        }
      }

      onProgress?.call('Completed: ${frames.length} unique frames extracted');
      return frames;
    } catch (e) {
      onProgress?.call('Error extracting frames: $e');
      rethrow;
    }
  }

  Future<void> cleanupFrames(List<VideoFrame> frames) async {
    for (final frame in frames) {
      try {
        if (await frame.file.exists()) {
          await frame.file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
}
