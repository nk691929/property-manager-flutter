import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/rules/property_validators.dart';
import 'package:property_manager/l10n/app_localizations.dart';

extension ListingTypeLabel on ListingType {
  String label(AppLocalizations l10n) => switch (this) {
    ListingType.rent => l10n.listingRent,
    ListingType.sale => l10n.listingSale,
  };
}

extension PropertyTypeLabel on PropertyType {
  String label(AppLocalizations l10n) => switch (this) {
    PropertyType.house => l10n.typeHouse,
    PropertyType.apartment => l10n.typeApartment,
    PropertyType.room => l10n.typeRoom,
    PropertyType.commercial => l10n.typeCommercial,
    PropertyType.plot => l10n.typePlot,
  };
}

extension AreaUnitLabel on AreaUnit {
  String label(AppLocalizations l10n) => switch (this) {
    AreaUnit.sqft => l10n.unitSqft,
    AreaUnit.sqm => l10n.unitSqm,
    AreaUnit.marla => l10n.unitMarla,
    AreaUnit.kanal => l10n.unitKanal,
  };
}

extension PropertyStatusLabel on PropertyStatus {
  String label(AppLocalizations l10n) => switch (this) {
    PropertyStatus.draft => l10n.statusDraft,
    PropertyStatus.pendingReview => l10n.statusPendingReview,
    PropertyStatus.published => l10n.statusPublished,
    PropertyStatus.rejected => l10n.statusRejected,
    PropertyStatus.archived => l10n.statusArchived,
  };
}

extension PropertySortLabel on PropertySort {
  String label(AppLocalizations l10n) => switch (this) {
    PropertySort.newest => l10n.sortNewest,
    PropertySort.priceAsc => l10n.sortPriceAsc,
    PropertySort.priceDesc => l10n.sortPriceDesc,
  };
}

extension PropertyFieldErrorMessage on PropertyFieldError {
  String localized(AppLocalizations l10n) => switch (this) {
    PropertyFieldError.empty => l10n.fieldEmpty,
    PropertyFieldError.titleLength => l10n.propTitleLength,
    PropertyFieldError.descriptionTooLong => l10n.propDescriptionTooLong,
    PropertyFieldError.cityLength => l10n.propCityLength,
    PropertyFieldError.addressTooLong => l10n.propAddressTooLong,
    PropertyFieldError.priceInvalid => l10n.propPriceInvalid,
    PropertyFieldError.countInvalid => l10n.propCountInvalid,
    PropertyFieldError.areaInvalid => l10n.propAreaInvalid,
    PropertyFieldError.areaIncomplete => l10n.propAreaIncomplete,
  };
}

/// Button text for a status move, e.g. draft -> pendingReview = "Submit".
String statusActionLabel({
  required PropertyStatus from,
  required PropertyStatus to,
  required AppLocalizations l10n,
}) => switch ((from, to)) {
  (PropertyStatus.rejected, PropertyStatus.pendingReview) =>
    l10n.actionResubmit,
  (_, PropertyStatus.pendingReview) => l10n.actionSubmitForReview,
  (PropertyStatus.pendingReview, PropertyStatus.published) =>
    l10n.actionApprove,
  (_, PropertyStatus.published) => l10n.actionPublish,
  (_, PropertyStatus.rejected) => l10n.actionReject,
  (PropertyStatus.pendingReview, PropertyStatus.draft) => l10n.actionWithdraw,
  (PropertyStatus.published, PropertyStatus.draft) => l10n.actionUnpublish,
  (_, PropertyStatus.draft) => l10n.actionRestore,
  (_, PropertyStatus.archived) => l10n.actionArchive,
};
