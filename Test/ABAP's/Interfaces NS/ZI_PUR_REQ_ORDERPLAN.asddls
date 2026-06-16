@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'View for Purchase requisition doc detail'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PUR_REQ_ORDER_PLAN as select from I_PurchaseRequisitionItemAPI01

  association of one to one I_Product                   as _Prod
    on $projection.Material = _Prod.Product

  association of one to one ZC_MEPROCSTATE              as _Status
    on $projection.PurReqnReleaseStatus = _Status.value
    and _Status.language   = 'N'

  association of one to one zzns_variabelen             as _Var
    on  _Var.name = 'ZSVG_ORDERPLAN'
    and _Var.ref  = 'ZSVG_ORDERPLAN'

{
    key PurchaseRequisition,
    key PurchaseRequisitionItem,
    PurchaseReqnItemUniqueID,
    PurchasingDocument,
    PurchasingDocumentItem,
    PurReqnReleaseStatus,
    PurchaseRequisitionType,
    PurchasingDocumentSubtype,
    PurchasingDocumentItemCategory,
    PurchaseRequisitionItemText,
    AccountAssignmentCategory,
    Material,
    MaterialGroup,
    PurchasingDocumentCategory,
    @Semantics.quantity.unitOfMeasure: 'BaseUnit'
    RequestedQuantity,
    BaseUnit,@Semantics.amount.currencyCode: 'PurReqnItemCurrency'
    PurchaseRequisitionPrice,
    @Semantics.quantity.unitOfMeasure: 'BaseUnit'
    PurReqnPriceQuantity,
    MaterialGoodsReceiptDuration,
    ReleaseCode,
    PurchaseRequisitionReleaseDate,
    PurchasingOrganization,
    PurchasingGroup,
    Plant,
    SourceOfSupplyIsAssigned,
    SupplyingPlant,
    @Semantics.quantity.unitOfMeasure: 'BaseUnit'
    OrderedQuantity,
    @Semantics.amount.currencyCode: 'PurReqnItemCurrency'
    PurReqnLimitConsumptionAmt,
    DeliveryDate,
    CreationDate,
    ProcessingStatus,
    PurchasingInfoRecord,
    Supplier,
    IsDeleted,
    FixedSupplier,
    RequisitionerName,
    CreatedByUser,
    PurReqCreationDate,
    DeliveryAddressID,
    ManualDeliveryAddressID,
    PurReqnItemCurrency,
    MaterialPlannedDeliveryDurn,
    DelivDateCategory,
    MultipleAcctAssgmtDistribution,
    StorageLocation,
    PurReqnSSPRequestor,
    PurReqnSSPAuthor,
    PurchaseContract,
    PurReqnSourceOfSupplyType,
    PurchaseContractItem,
    ConsumptionPosting,
    PurReqnOrigin,
    PurReqnSSPCatalog,
    PurReqnSSPCatalogItem,
    PurReqnSSPCrossCatalogItem,
    IsPurReqnBlocked,
    ItemDeliveryAddressID,
    Language,
    IsClosed,
    Reservation,
    ReleaseIsNotCompleted,
    ServicePerformer,
    ProductType,
    PurchaseRequisitionStatus,
    ReleaseStrategy,
    PerformancePeriodStartDate,
    PerformancePeriodEndDate,
    CompanyCode,
    SupplierMaterialNumber,
    Batch,
    MaterialRevisionLevel,
    MaterialRevisionLevel_2,
    MinRemainingShelfLife,
    @Semantics.amount.currencyCode: 'PurReqnItemCurrency'
    ItemNetAmount,
    GoodsReceiptIsExpected,
    InvoiceIsExpected,
    GoodsReceiptIsNonValuated,
    RequirementTracking,
    MRPArea,
    MRPController,
    TaxCode,
    PurchaseRequisitionIsFixed,
    AddressID,
    LastChangeDateTime,
    PurContractForOverallLimit,
    PurContractItemForOverallLimit,
    ProcurementHubSourceSystem,
    ExtPurgOrgForPurg,
    ExtCompanyCodeForPurg,
    ExtPlantForPurg,
    ExtInfoRecordForPurg,
    ExtContractItemForPurg,
    ExtContractForPurg,
    ExtDesiredSupplierForPurg,
    ExtFixedSupplierForPurg,
    ExtMaterialForPurg,
    IsOutline,
    PurchasingParentItem,
    PurgConfigurableItemNumber,
    PurgExternalSortNumber,
    ZZ1_PurchaseContractIt_PRI,
    ZZ1_SendAttachment_PRI,
    ZZ1_SupOrderID_PRI,
    ZZ1_PurchaseContract_PRI,
    /* Associations */
    _PurchaseRequisition,
    _PurReqnAcctAssgmt,
    _Prod,
    _Status,
    _Var
}
