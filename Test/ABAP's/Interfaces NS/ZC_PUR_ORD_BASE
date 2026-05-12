@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base view for Purchase Orders'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_PUR_ORD_BASE as select from I_PurOrdScheduleLineAPI01 as sl

association of one to one I_PurchaseOrderItemAPI01 as _ItemApi
    on _ItemApi.PurchaseOrder     = sl.PurchaseOrder
   and _ItemApi.PurchaseOrderItem = sl.PurchaseOrderItem

association of one to one I_PurchaseOrderItem as _Item
    on _Item.PurchaseOrder     = sl.PurchaseOrder
   and _Item.PurchaseOrderItem = sl.PurchaseOrderItem

{
    key sl.PurchaseOrder,
    key sl.PurchaseOrderItem,
    key sl.PurchaseOrderScheduleLine,
    sl.PerformancePeriodStartDate,
    sl.PerformancePeriodEndDate,
    sl.DelivDateCategory,
    sl.ScheduleLineDeliveryDate,
    sl.SchedLineStscDeliveryDate,
    sl.ScheduleLineDeliveryTime,
    @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
    sl.ScheduleLineOrderQuantity,
    @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
    sl.RoughGoodsReceiptQty,
    sl.PurchaseOrderQuantityUnit,
    sl.PurchaseRequisition,
    sl.PurchaseRequisitionItem,
    sl.SourceOfCreation,
    @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
    sl.PrevDelivQtyOfScheduleLine,
    sl.NoOfRemindersOfScheduleLine,
    sl.ScheduleLineIsFixed,
    @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
    sl.ScheduleLineCommittedQuantity,
    sl.Reservation,
    sl.ProductAvailabilityDate,
    sl.MaterialStagingTime,
    sl.TransportationPlanningDate,
    sl.TransportationPlanningTime,
    sl.LoadingDate,
    sl.LoadingTime,
    sl.GoodsIssueDate,
    sl.GoodsIssueTime,
    sl.STOLatestPossibleGRDate,
    sl.STOLatestPossibleGRTime,
    @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
    sl.StockTransferDeliveredQuantity,
    @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
    sl.ScheduleLineIssuedQuantity,
    sl.Batch,
    _ItemApi.PurchaseOrderItemCategory,
    _ItemApi.Material,

    /* Associations */
    sl._PurchaseOrder ,
    _ItemApi,
    _Item

}
