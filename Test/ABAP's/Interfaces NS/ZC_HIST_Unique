@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Select one line date/time from POHist'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZC_HIST_Unique as select from I_PurchaseOrderHistoryAPI01
{
    key PurchaseOrder,
    key PurchaseOrderItem,
    AccountingDocumentCreationDate as MaxDate,
    PostingDate,
    max(PurgHistDocumentCreationTime) as MaxTime,
    PurchasingHistoryDocumentType,
    PurchasingHistoryCategory,
    IsCompletelyDelivered,
    InventoryValuationType

}
    where PurchasingHistoryDocumentType = '1' or PurchasingHistoryDocumentType = '6'

    group by PurchaseOrder, PurchaseOrderItem, AccountingDocumentCreationDate, PostingDate ,PurchasingHistoryDocumentType,
             PurchasingHistoryCategory, IsCompletelyDelivered, InventoryValuationType
