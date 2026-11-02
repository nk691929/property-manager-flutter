import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/logging/app_logger.dart';
import 'package:property_manager/features/properties/data/datasources/property_photos_data_source.dart';
import 'package:property_manager/features/properties/data/photo_storage.dart';
import 'package:property_manager/features/properties/data/property_json.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final class SupabasePropertyPhotosDataSource
    implements PropertyPhotosDataSource {
  const new(this._client, this._logger);

  final SupabaseClient _client;
  final AppLogger _logger;

  StorageFileApi get _bucket => _client.storage.from(propertyPhotosBucket);

  PropertyPhoto _parse(Map<String, dynamic> row) =>
      photoFromJson(row, _bucket.getPublicUrl);

  @override
  Future<PropertyPhoto> add(
    String propertyId,
    PhotoUpload upload, {
    required int position,
  }) => supabaseGuard(() async {
    final path = '$propertyId/${const Uuid().v4()}.${upload.extension}';
    await _bucket.uploadBinary(
      path,
      upload.bytes,
      // The path is unique and never overwritten, so the file is immutable.
      fileOptions: FileOptions(
        contentType: upload.contentType,
        cacheControl: '31536000',
      ),
    );
    try {
      final row = await _client
          .from(propertyPhotosTable)
          .insert({
            'property_id': propertyId,
            'storage_path': path,
            'position': position,
          })
          .select(propertyPhotoColumns)
          .single();
      return _parse(row);
    } on Object {
      // Compensating action: a file without a row is unreachable garbage.
      await _removeFile(path);
      rethrow;
    }
  });

  @override
  Future<void> remove(PropertyPhoto photo) => supabaseGuard(() async {
    // Row first, then file: a failure leaves an invisible orphan file,
    // never a row pointing at a missing image.
    final rows = await _client
        .from(propertyPhotosTable)
        .delete()
        .eq('id', photo.id)
        .select('id');
    if (rows.isEmpty) throw const NotFoundFailure();
    await _removeFile(photo.path);
  });

  @override
  Future<PropertyPhoto> setPosition(String photoId, int position) =>
      supabaseGuard(() async {
        final row = await _client
            .from(propertyPhotosTable)
            .update({'position': position})
            .eq('id', photoId)
            .select(propertyPhotoColumns)
            .single();
        return _parse(row);
      });

  Future<void> _removeFile(String path) async {
    try {
      await _bucket.remove([path]);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Orphaned photo file $path',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
