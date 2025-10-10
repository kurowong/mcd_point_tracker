import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'perceptual_hash.dart';
import 'raw_media_metadata.dart';

class ScreenshotImportService {
  ScreenshotImportService({required PerceptualHash hasher}) : _hasher = hasher;

  final PerceptualHash _hasher;

  Future<List<RawMediaMetadata>> fetchMetadata() async {
    final permissionGranted = await _ensurePermissions();
    if (!permissionGranted) {
      return <RawMediaMetadata>[];
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    final metadata = <RawMediaMetadata>[];
    for (final path in paths) {
      final assets = await path.getAssetListRange(start: 0, end: path.assetCount);
      for (final asset in assets) {
        if (asset.type != AssetType.image) {
          continue;
        }
        final bytes = await asset.originBytes;
        if (bytes == null) {
          continue;
        }
        final hash = _hasher.hash(bytes);
        metadata.add(
          RawMediaMetadata(
            id: asset.id,
            type: RawMediaType.screenshot,
            sourcePath: asset.relativePath ?? path.name,
            capturedAt: asset.createDateTime,
            perceptualHash: hash,
            displayName: asset.title,
            frameSampleCount: 1,
            extras: <String, dynamic>{
              'width': asset.width,
              'height': asset.height,
            },
          ),
        );
      }
    }
    return metadata;
  }

  Future<bool> _ensurePermissions() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      return true;
    }
    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted) {
      return true;
    }
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }
}
