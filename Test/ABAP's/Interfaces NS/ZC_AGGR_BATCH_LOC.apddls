@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Aggregated batch values based on Product'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_AGGR_BATCH_STLOC
  as select from I_StockQuantityCurrentValue_2( P_DisplayCurrency: 'EUR' ) as sq
    inner join   I_Batch                                                   as ba on  ba.Plant    = sq.Plant
                                                                                 and ba.Material = sq.Product
                                                                                 and ba.Batch    = sq.Batch

{
  key sq.Product,
  key sq.Plant,
      min( ba.ShelfLifeExpirationDate ) as ShelfLife

}
where
  (
       sq.StorageLocation                    = 'S020'
    or sq.StorageLocation                    = 'S100'
  )
  and  ba.ShelfLifeExpirationDate            is not initial
  and  ba.BatchIsMarkedForDeletion           = ' '
  and  sq._Product.MinimalShelfLife          > 0
  and  sq.MatlWrhsStkQtyInMatlBaseUnit       > 0
  and  sq._Product.IsBatchManagementRequired = 'X'


group by
  sq.Product,
  sq.Plant
