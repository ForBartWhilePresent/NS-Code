@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material Plant incl. Min Order Qty'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZC_MaterialPlant
  as select from marc as m

  association of one to one  mara as a
    on m.matnr = a.matnr

  association of one to many eord as _SourceOfSupply
    on  $projection.Material     = _SourceOfSupply.matnr
    and $projection.Plant        = 'L100'
    and _SourceOfSupply.vdatu <= $session.system_date
    and _SourceOfSupply.bdatu >= $session.system_date

  association of one to many eord as _SourceOfSupply_0
    on  $projection.Material     = _SourceOfSupply_0.matnr
    and $projection.Plant        = 'L100'
    and _SourceOfSupply_0.vdatu <= $session.system_date
    and _SourceOfSupply_0.bdatu >= $session.system_date
    and _SourceOfSupply_0.eortp  = '0'
    and _SourceOfSupply_0.febel  = 'X'

  association of one to many eord as _SourceOfSupply_3
    on  $projection.Material     = _SourceOfSupply_3.matnr
    and $projection.Plant        = 'L100'
    and _SourceOfSupply_3.vdatu <= $session.system_date
    and _SourceOfSupply_3.bdatu >= $session.system_date
    and _SourceOfSupply_3.eortp  = '3'

{
  key m.matnr  as Material,
  key m.werks  as Plant,

      a.meins,

      @Semantics.quantity.unitOfMeasure: 'meins'
      m.bstmi,

      @Semantics.quantity.unitOfMeasure: 'meins'
      m.bstfe,

      m.dispo,
      m.schgt,
      m.ekgrp,
      m.mmsta,

      _SourceOfSupply,
      // lifnr for eortp = '0'
      _SourceOfSupply_0.lifnr as HostProcureNewPriVendLocID,
      // lifnr for eortp = '3'
      _SourceOfSupply_3.lifnr as HostRepairPriVendLocID

}
