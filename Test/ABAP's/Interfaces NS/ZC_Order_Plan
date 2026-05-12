@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'View for PO changed documents'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZC_ORDER_PLAN
  as select from ZC_PUR_ORD_BASE

  association of one to one  I_PurchasingDocument as _Pd
    on $projection.PurchaseOrder = _Pd.PurchasingDocument

  association of one to one  I_PurchaseOrderAPI01 as _Po
    on $projection.PurchaseOrder = _Po.PurchaseOrder

  association of one to one  I_Product            as _Prod
    on $projection.Material = _Prod.Product

  association of one to many ZC_MEPROCSTATE       as _Status
    on  $projection.Status = _Status.value
    and _Status.language   = 'N'

  association of one to one  zzns_variabelen      as _Var
    on  _Var.name = 'ZSVG_ORDERPLAN'
    and _Var.ref  = 'ZSVG_ORDERPLAN'

  association of one to one  ZC_PUR_ORD_HIST_SUM  as _HistSum
    on  $projection.PurchaseOrder     = _HistSum.PurchaseOrder
    and $projection.PurchaseOrderItem = _HistSum.PurchaseOrderItem

  association of one to many I_PurchaseOrderHistoryAPI01  as _Hist
    on  $projection.PurchaseOrder     = _Hist.PurchaseOrder
    and $projection.PurchaseOrderItem = _Hist.PurchaseOrderItem

{
  key ZC_PUR_ORD_BASE.PurchaseOrder,
  key ZC_PUR_ORD_BASE.PurchaseOrderItem,
  key ZC_PUR_ORD_BASE.PurchaseOrderScheduleLine,

      ZC_PUR_ORD_BASE.PerformancePeriodStartDate,
      ZC_PUR_ORD_BASE.PerformancePeriodEndDate,
      ZC_PUR_ORD_BASE.DelivDateCategory,
      ZC_PUR_ORD_BASE.ScheduleLineDeliveryDate,
      ZC_PUR_ORD_BASE.SchedLineStscDeliveryDate,
      ZC_PUR_ORD_BASE.ScheduleLineDeliveryTime,

      @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
      ZC_PUR_ORD_BASE.ScheduleLineOrderQuantity,

      @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
      ZC_PUR_ORD_BASE.RoughGoodsReceiptQty,

      ZC_PUR_ORD_BASE.PurchaseOrderQuantityUnit,
      ZC_PUR_ORD_BASE.PurchaseRequisition,
      ZC_PUR_ORD_BASE.PurchaseRequisitionItem,
      ZC_PUR_ORD_BASE.SourceOfCreation,

      @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
      ZC_PUR_ORD_BASE.PrevDelivQtyOfScheduleLine,

      ZC_PUR_ORD_BASE.NoOfRemindersOfScheduleLine,
      ZC_PUR_ORD_BASE.ScheduleLineIsFixed,

      @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
      ZC_PUR_ORD_BASE.ScheduleLineCommittedQuantity,

      ZC_PUR_ORD_BASE.Reservation,
      ZC_PUR_ORD_BASE.ProductAvailabilityDate,
      ZC_PUR_ORD_BASE.MaterialStagingTime,
      ZC_PUR_ORD_BASE.TransportationPlanningDate,
      ZC_PUR_ORD_BASE.TransportationPlanningTime,
      ZC_PUR_ORD_BASE.LoadingDate,
      ZC_PUR_ORD_BASE.LoadingTime,
      ZC_PUR_ORD_BASE.GoodsIssueDate,
      ZC_PUR_ORD_BASE.GoodsIssueTime,
      ZC_PUR_ORD_BASE.STOLatestPossibleGRDate,
      ZC_PUR_ORD_BASE.STOLatestPossibleGRTime,

      @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
      ZC_PUR_ORD_BASE.StockTransferDeliveredQuantity,

      @Semantics.quantity.unitOfMeasure: 'PurchaseOrderQuantityUnit'
      ZC_PUR_ORD_BASE.ScheduleLineIssuedQuantity,

      ZC_PUR_ORD_BASE.Batch,
      ZC_PUR_ORD_BASE.Material,
      ZC_PUR_ORD_BASE.PurchaseOrderItemCategory,
      ZC_PUR_ORD_BASE._PurchaseOrder.PurchasingProcessingStatus        as Status,
      ZC_PUR_ORD_BASE._PurchaseOrder.SupplyingPlant                    as SupPlant,
      ZC_PUR_ORD_BASE._PurchaseOrder.PurchaseOrderType                 as POType,

      coalesce(_HistSum[GoodsMovementType = '101'].QuantitySum, 0)   // Subtract the values of 102 from 101 values
        - coalesce(_HistSum[GoodsMovementType = '102'].QuantitySum, 0) as TotalQuantityInBaseUnit,

      /* Associations */
      ZC_PUR_ORD_BASE._PurchaseOrder,
      ZC_PUR_ORD_BASE._ItemApi,
      ZC_PUR_ORD_BASE._Item,

      _Pd,
      _Prod,
      _Status,
      _Var,
      _Hist,
      _Po
}
