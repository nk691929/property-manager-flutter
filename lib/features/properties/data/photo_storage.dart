const propertyPhotosBucket = 'property-photos';
const propertyPhotosTable = 'property_photos';
const propertyPhotoColumns = 'id, storage_path, position';

/// Properties with their photos in a single request (PostgREST embedding).
const propertySelect = '*, $propertyPhotosTable($propertyPhotoColumns)';
