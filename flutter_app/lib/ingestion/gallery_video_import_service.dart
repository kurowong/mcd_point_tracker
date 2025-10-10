import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'adaptive_frame_extractor.dart';
import 'perceptual_hash.dart';
import 'raw_media_metadata.dart';

class GalleryVideoImportService {
  GalleryVideoImportService({
    required AdaptiveFrameExtractor frameExtractor,
    required PerceptualHash hasher,
  })  : _frameExtractor = frameExtractor,
        _hasher = hasher;

  final AdaptiveFrameExtractor _frameExtractor;
  final PerceptualHash _hasher;

  Future<List<RawMediaMetadata>> fetchMetadata() async {
    final permissionGranted = await _ensurePermissions();
    if (!permissionGranted) {
      return <RawMediaMetadata>[];
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    final entries = <RawMediaMetadata>[];
    for (final path in paths) {
      final assets = await path.getAssetListRange(start: 0, end: path.assetCount);
      for (final asset in assets) {
        if (asset.type != AssetType.video) {
          continue;
        }
        final frames = await _collectFrames(asset);
        if (frames.isEmpty) {
          continue;
        }
        final representativeHash = _hasher.hash(frames.first);
        entries.add(
          RawMediaMetadata(
            id: asset.id,
            type: RawMediaType.video,
            sourcePath: asset.relativePath ?? path.name,
            capturedAt: asset.createDateTime,
            perceptualHash: representativeHash,
            displayName: asset.title,
            duration: asset.videoDuration,
            frameSampleCount: frames.length,
            extras: <String, dynamic>{
              'width': asset.width,
              'height': asset.height,
            },
          ),
        );
      }
    }
    return entries;
  }

  Future<List<Uint8List>> _collectFrames(AssetEntity asset) async {
    final thumb = await asset.thumbnailDataWithSize(const ThumbnailSize(512, 512));
    if (thumb == null) {
      return <Uint8List>[];
    }
    // The adaptive frame extractor skips an initial warm-up segment based on the
    // configured frame rate. When we only have a single thumbnail frame
    // available, feeding it through the extractor would always yield an empty
    // result. Since the thumbnail is already representative, bypass the
    // extractor and return it directly.
    return <Uint8List>[thumb];
  }

  Future<bool> _ensurePermissions() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      return true;
    }
    final videosStatus = await Permission.videos.request();
    if (videosStatus.isGranted) {
      return true;
    }
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }
}
