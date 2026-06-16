@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'View for Partmaster and SKU details'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZC_PartMaster_SKU_data
  as select from I_Product as _Prod

  association of one to one I_ProductValuation as _Val
    on $projection.Product = _Val.Product
    and _Val.ValuationArea = 'L100'
    and _Val.InventoryValuationProcedure = 'S'

  association of one to one I_ProductDescription_2 as _Desc
    on $projection.Product = _Desc.Product
    and _Desc.Language = 'N'

  association of one to one ZC_MaterialPlant   as _Matplant
    on  $projection.Product = _Matplant.Material
    and _Matplant.Plant = 'L100'

  association of one to one ZT_MM_PRODH        as _Prodh
    on  $projection.ProductHierarchy = _Prodh.Prodh
    and _Prodh.Language              = 'N'

 association of one to one I_UnitOfMeasure as _UOM on $projection.BaseUnit = _UOM.UnitOfMeasure

{
  key Product,

      ProductExternalID,
      ProductOID,
      ProductType,
      CreationDate,
      CreationTime,
      CreationDateTime,
      CreatedByUser,
      LastChangeDate,
      LastChangedByUser,
      IsMarkedForDeletion,
      CrossPlantStatus,
      CrossPlantStatusValidityDate,
      ProductOldID,

      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      GrossWeight,

      PurchaseOrderQuantityUnit,
      SourceOfSupply,
      WeightUnit,
      CountryOfOrigin,
      CompetitorID,
      ProductGroup,
      BaseUnit,
      ItemCategoryGroup,

      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      NetWeight,

      ProductHierarchy,
      Division,
      VarblPurOrdUnitIsActive,
      VolumeUnit,

      @Semantics.quantity.unitOfMeasure: 'VolumeUnit'
      MaterialVolume,

      SalesStatus,
      TransportationGroup,
      SalesStatusValidityDate,
      AuthorizationGroup,
      ANPCode,
      ProductCategory,
      Brand,
      ProcurementRule,
      ValidityStartDate,
      LowLevelCode,
      ProdNoInGenProdInPrepackProd,
      SerialIdentifierAssgmtProfile,
      SizeOrDimensionText,
      IndustryStandardName,
      ProductStandardID,
      InternationalArticleNumberCat,
      ProductIsConfigurable,
      IsBatchManagementRequired,
      HasEmptiesBOM,
      ExternalProductGroup,
      CrossPlantConfigurableProduct,
      SerialNoExplicitnessLevel,
      ProductManufacturerNumber,
      ManufacturerNumber,
      ManufacturerPartProfile,
      QltyMgmtInProcmtIsActive,
      IsApprovedBatchRecordReqd,
      HandlingIndicator,
      WarehouseProductGroup,
      WarehouseStorageCondition,
      StandardHandlingUnitType,
      SerialNumberProfile,
      AdjustmentProfile,
      PreferredUnitOfMeasure,
      IsPilferable,
      IsRelevantForHzdsSubstances,

      @Semantics.quantity.unitOfMeasure: 'TimeUnitForQuarantinePeriod'
      QuarantinePeriod,

      TimeUnitForQuarantinePeriod,
      QualityInspectionGroup,
      HandlingUnitType,
      HasVariableTareWeight,

      @Semantics.quantity.unitOfMeasure: 'UnitForMaxPackagingDimensions'
      MaximumPackagingLength,

      @Semantics.quantity.unitOfMeasure: 'UnitForMaxPackagingDimensions'
      MaximumPackagingWidth,

      @Semantics.quantity.unitOfMeasure: 'UnitForMaxPackagingDimensions'
      MaximumPackagingHeight,

      MaximumCapacity,
      OvercapacityTolerance,
      UnitForMaxPackagingDimensions,

      @Semantics.quantity.unitOfMeasure: 'ProductMeasurementUnit'
      BaseUnitSpecificProductLength,

      @Semantics.quantity.unitOfMeasure: 'ProductMeasurementUnit'
      BaseUnitSpecificProductWidth,

      @Semantics.quantity.unitOfMeasure: 'ProductMeasurementUnit'
      BaseUnitSpecificProductHeight,

      ProductMeasurementUnit,
      ProductValidStartDate,
      ArticleCategory,
      ContentUnit,

      @Semantics.quantity.unitOfMeasure: 'ContentUnit'
      NetContent,

      ComparisonPriceQuantity,

      @Semantics.quantity.unitOfMeasure: 'ContentUnit'
      GrossContent,

      ProductValidEndDate,
      AssortmentListType,
      HasTextilePartsWthAnimalOrigin,
      ProductSeasonUsageCategory,
      IndustrySector,
      ChangeNumber,
      MaterialRevisionLevel,
      IsActiveEntity,
      LastChangeDateTime,
      LastChangeTime,
      DangerousGoodsIndProfile,
      ProductUUID,
      ProdSupChnMgmtUUID22,
      ProductDocumentChangeNumber,
      ProductDocumentPageCount,
      ProductDocumentPageNumber,
      OwnInventoryManagedProduct,
      DocumentIsCreatedByCAD,
      ProductionOrInspectionMemoTxt,
      ProductionMemoPageFormat,
      GlobalTradeItemNumberVariant,
      ProductIsHighlyViscous,
      TransportIsInBulk,
      ProdAllocDetnProcedure,
      ProdEffctyParamValsAreAssigned,
      ProdIsEnvironmentallyRelevant,
      LaboratoryOrDesignOffice,
      PackagingMaterialGroup,
      ProductIsLocked,
      DiscountInKindEligibility,
      SmartFormName,
      PackingReferenceProduct,
      BasicMaterial,
      ProductDocumentNumber,
      ProductDocumentVersion,
      ProductDocumentType,
      ProductDocumentPageFormat,
      ProductConfiguration,
      SegmentationStrategy,
      SegmentationIsRelevant,
      ProductCompositionIsRelevant,
      IsChemicalComplianceRelevant,
      ManufacturerBookPartNumber,
      LogisticalProductCategory,
      SalesProduct,
      ProdCharc1InternalNumber,
      ProdCharc2InternalNumber,
      ProdCharc3InternalNumber,
      ProductCharacteristic1,
      ProductCharacteristic2,
      ProductCharacteristic3,
      MaintenanceStatus,
      FashionProdInformationField1,
      FashionProdInformationField2,
      FashionProdInformationField3,
      MinimalShelfLife,
      DfsAmmunitionGroupCode,
      DfsRICIdentifier,
      DfsProductSensitivity,
      DfsManufacturerPartLongNumber,
      DfsMatlConditionMgmt,
      DfsReturnDelivery,
      DfsLogisticsLevel,
      DfsNationalItemIdnNumber,
      ZZ1_OS_RestrictedPart_PRD,
      ZZ1_OS_Veilighkritisch_PRD,
      ZZ1_OS_Servicedeel_PRD,
      ZZ1_OS_MaximoRelevant_PRD,
      ZZ1_OS_XelusRelevant_PRD,
      ZZ1_OS_Kritisch_Stil_PRD,
      ZZ1_INK_INSPGRP_PRD,
      _Val.Currency                                                                                             as Currency,

      @Semantics.amount.currencyCode: 'Currency'
      _Val[ ValuationType = 'S' ] .StandardPrice as StandPrice_S,

      @Semantics.amount.currencyCode: 'Currency'

      _Val[ ValuationType = 'V' ] .StandardPrice as StandPrice_V,

      _Matplant.Plant,

      /* Associations */
      _AdjustmentProfile,
      _AdjustmentProfileText,
      _AdjustmentProfileText_2,
      _AdjustmentProfile_2,
      _AssortmentListType,
      _AssortmentListTypeText,
      _BaseUnitOfMeasure,
      _BaseUnitOfMeasureText,
      _BasicMaterial,
      _Brand,
      _BrandText,
      _BR_ANPCode,
      _BR_ANPCodeText,
      _ChemicalComplianceRelevant,
      _ChemicalComplianceRlvtText,
      _ContentUnit,
      _ContentUnitText,
      _CreatedByUser,
      _CreatedByUserContactCard,
      _CrossPlantConfigurableProduct,
      _Division,
      _DivisionText,
      _ESHCharValueAssignment,
      _ESHClassAssignment,
      _ESHDocInfoRecordObjectLink,
      _ESHProductPlant,
      _ESHProductSalesDelivery,
      _ESHPurOrderQuantityUnitText,
      _ESHSourceOfSupply,
      _ESHSupplier,
      _ESHTextObjectPlainLongText,
      _ExternalProductGroup,
      _ExtProdGrpText,
      _FashionProdInfoFld1,
      _FashionProdInfoFld1Text,
      _FashionProdInfoFld2,
      _FashionProdInfoFld2Text,
      _FashionProdInfoFld3,
      _FashionProdInfoFld3Text,
      _HandlingIndicator,
      _HandlingIndicatorText,
      _HandlingUnitType,
      _HandlingUnitTypeText,
      _IntArticleNumberText,
      _InternationalArticleNumberCat,
      _ItemCategoryGroup,
      _ItemCategoryGroupText,
      _LastChangedByUser,
      _LastChangedByUserContactCard,
      _MaterialRevisionLevel,
      _MaterialText,
      _MDProductHierarchyNode,
      _ProductCategory,
      _ProductCategoryText,
      _ProductDescription_2,
      _ProductESPP,
      _ProductGroup,
      _ProductGroupText,
      _ProductGroupText_2,
      _ProductGroup_2,
      _ProductHierarchy,
      _ProductHierarchyText,
      _ProductMeasurementUnit,
      _ProductMeasurementUnitText,
      _ProductProcurement,
      _ProductRetail,
      _ProductSales,
      _ProductSCM,
      _ProductStatus,
      _ProductStatusText,
      _ProductType,
      _ProductTypeName,
      _ProductType_2,
      _ProdUnivHierarchyNode,
      _QualityInspectionGroup,
      _QualityInspectionGroupText,
      _QuantityUnitText,
      _QuantityUnitValueHelp,
      _RetProdCharc1,
      _RetProdCharc1Text,
      _RetProdCharc2,
      _RetProdCharc2Text,
      _RetProdCharc3,
      _RetProdCharc3Text,
      _SerialNumberProfile,
      _SerialNumberProfileText,
      _StandardHandlingUnitType,
      _StandardHandlingUnitTypeText,
      _Text,
      _TimeUnitForQuarantinePeriod,
      _TimeUnitQuarantinePeriodText,
      _UnitForMaxPackaging,
      _UnitForMaxPackagingText,
      _WarehouseProductGroup,
      _WarehouseProductGroupText,
      _WarehouseStorageCondition,
      _WarehouseStorageConditionText,
      _WeightUnitText,
      _WeightUnitValueHelp,
      _ZZ1_INK_INSPGRP_PRD,
      _ZZ1_OS_Kritisch_Stil_PRD,
      _ZZ1_OS_Servicedeel_PRD,
      _ZZ1_OS_Veilighkritisch_PRD,
      _Matplant,
      _Prodh,
      _UOM,
      _Desc
}
