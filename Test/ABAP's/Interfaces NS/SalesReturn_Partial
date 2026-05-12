*&---------------------------------------------------------------------*
*& Report zsvg_send_salesreturn_partial
*&---------------------------------------------------------------------*
*& This interface is used for sending the sales return partial data,
*& from S4-Hana to SVG via CPI.
*& The data is sent as a single JSON file (Partial load).
*$ If needed, it can be sent as a CSV file.
*&---------------------------------------------------------------------*
REPORT zsvg_send_salesreturn_partial.

INCLUDE zsvg_send_sls_ret_part. " Data declaration and selection screen:

*&---------------------------------------------------------------------*
*& Include zsvg_send_sls_ret_part
*&---------------------------------------------------------------------*

TABLES: t003o, t156, ekko, t001l.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-002 FOR FIELD p_frdate.
    PARAMETERS p_frdate TYPE sy-datum OBLIGATORY DEFAULT sy-datum.
    SELECTION-SCREEN COMMENT 47(10) TEXT-003 FOR FIELD p_frtime.
    PARAMETERS p_frtime TYPE syst_uzeit OBLIGATORY.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-004 FOR FIELD p_todate.
    PARAMETERS p_todate TYPE sy-datum OBLIGATORY DEFAULT sy-datum.
    SELECTION-SCREEN COMMENT 47(10) TEXT-003 FOR FIELD p_totime.
    PARAMETERS p_totime TYPE syst_uzeit OBLIGATORY DEFAULT '235959'.
  SELECTION-SCREEN END OF LINE.

  SELECT-OPTIONS: so_aufa FOR t003o-auart DEFAULT 'ZMX1', " Maintenance Order Type
                  so_bwrt FOR t156-bwart DEFAULT '531'.   " Goods Movement Type
  PARAMETERS      p_lgrt TYPE t001l-lgort DEFAULT 'V%'.   " Storage Location

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-010.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-002 FOR FIELD p_frdt2.
    PARAMETERS p_frdt2 TYPE sy-datum OBLIGATORY DEFAULT sy-datum.
    SELECTION-SCREEN COMMENT 47(10) TEXT-003 FOR FIELD p_frtm2.
    PARAMETERS p_frtm2 TYPE syst_uzeit OBLIGATORY.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-004 FOR FIELD p_todt2.
    PARAMETERS p_todt2 TYPE sy-datum OBLIGATORY DEFAULT sy-datum.
    SELECTION-SCREEN COMMENT 47(10) TEXT-003 FOR FIELD p_totm2.
    PARAMETERS p_totm2 TYPE syst_uzeit OBLIGATORY DEFAULT '235959'.
  SELECTION-SCREEN END OF LINE.

  SELECT-OPTIONS   so_pot  FOR ekko-bsart DEFAULT 'ZUB1'.  " PO type
  PARAMETERS:      p_lgrt2 TYPE t001l-lgort DEFAULT 'V%',  " Storage Location
                   p_poo   TYPE ekko-ekorg DEFAULT '5900'. " PO Organization

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-005.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-006 FOR FIELD r_api.
    PARAMETERS r_api RADIOBUTTON GROUP rad DEFAULT 'X' USER-COMMAND sel.
    SELECTION-SCREEN COMMENT 47(15) TEXT-007 FOR FIELD r_file.
    PARAMETERS r_file RADIOBUTTON GROUP rad.
  SELECTION-SCREEN END OF LINE.

  PARAMETERS: p_dest   TYPE string LOWER CASE,  " Destination via variant: SCO_APIM_SVG of 'SCO_CPI_SVG'
              p_pstfix TYPE string LOWER CASE,  " Postfix via variant: SCO-SVG-SalesReturn/api/1.0/entity/sales-return.ws of '/http/sco/svg'
              p_file   TYPE char100 LOWER CASE MODIF ID f1. " via variant

SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-008.
  PARAMETERS cb_test TYPE abap_bool AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b4.

TYPES: BEGIN OF Rs_key,
         RsNum TYPE numc10,
         RsPos TYPE numc4,
       END OF Rs_key.

TYPES: BEGIN OF sales_return,
         HostReturnOrderID     TYPE zhostreturnid,
         HostPartID            TYPE matnr,
         HostLocID             TYPE werks_d,
         ReturnedQty           TYPE bdmng,
         RecvGoodQty           TYPE enmng,
         ShipDate              TYPE bdter,
         ExpectedAvailableDate TYPE bdter,
         HostCustomerID        TYPE zz_hostcustomerid,
       END OF sales_return.

DATA screen TYPE screen.
DATA(svg_class) = NEW zcl_s4_to_svg( ). " Initiate class to use applicable methods
DATA result_mo TYPE zcl_s4_to_svg=>ty_convert_result.
DATA errors TYPE STANDARD TABLE OF zcl_s4_to_svg=>ty_error.
DATA found TYPE SORTED TABLE OF Rs_key WITH UNIQUE KEY rsnum rspos.
DATA not_found_del TYPE STANDARD TABLE OF rs_key WITH KEY rsnum.
DATA sales_return TYPE STANDARD TABLE OF sales_return WITH KEY hostreturnorderid.
DATA RetQuan TYPE bdmng.
DATA shipdate type eindt.

"----------------------------------------------------------------------
"  Dynamic UI:
"----------------------------------------------------------------------

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN INTO screen.

    " Check which option is active
    IF screen-name = 'P_DEST' OR screen-name = 'P_PSTFIX'.
      screen-active = 1.
      screen-input  = 1.
      MODIFY SCREEN FROM screen.
      CONTINUE.
    ENDIF.

    " P_FILE + label → MODIF ID F1
    IF screen-group1 = 'F1'.

      IF r_file = abap_true.
        screen-active = 1.
        screen-input  = 1.
      ELSE.
        screen-active = 0.
        screen-input  = 0.
      ENDIF.

      MODIFY SCREEN FROM screen.
    ENDIF.

  ENDLOOP.

  "----------------------------------------------------------------------
  "  Behavior for change between API <-> FILE
  "----------------------------------------------------------------------

AT SELECTION-SCREEN.
  " 1) Change radiobuttons
  IF sy-ucomm = 'SEL'.

    IF r_api = abap_true.
      " Back to API: file-field not relevant
      CLEAR p_file.
    ELSEIF r_file = abap_true.
      " FILE: focus on p_file
      SET CURSOR FIELD 'P_FILE'.
    ENDIF.

    RETURN. " No checks on changepointers
  ENDIF.

  " 2) Validatie at Execute (F8)

  IF sy-ucomm = 'ONLI'.

    " Always check: destination + postfix
    IF p_dest IS INITIAL OR p_pstfix IS INITIAL.
      MESSAGE 'Vul bestemming en postfix in.' TYPE 'E'.
    ENDIF.

    " FILE: p_file also mandatory
    IF r_file = abap_true AND p_file IS INITIAL.
      MESSAGE 'Vul ook de bestandsnaam in (FILE-modus).' TYPE 'E'.
    ENDIF.

  ENDIF.

END-OF-SELECTION.

" -----------------------------------------------------------------------
" Start data selection Maintenance orders
" -----------------------------------------------------------------------

START-OF-SELECTION.
  " Selection for Changes in the RESB table, using change document tables (I_MaintOrdChangeDocumentDEX and I_MaintOrdChgHistory)
  SELECT FROM I_MaintOrdChangeDocumentDEX
    FIELDS CAST( substring( ChangeDocTableKey, 4, 10 ) AS NUMC ) AS RsNum,
           CAST( substring( ChangeDocTableKey, 14, 4 ) AS NUMC ) AS RsPos
    WHERE CreationDate            BETWEEN @p_frdate AND @p_todate
      AND CreationTime            BETWEEN @p_frtime AND @p_totime
      AND DatabaseTable                 = 'RESB'
      AND ChangeDocItemChangeType       = 'I'
    INTO TABLE @DATA(sel_chng).

  SELECT FROM I_MaintOrdChgHistory
    FIELDS CAST( substring( ChangeDocTableKey, 4, 10 ) AS NUMC ) AS RsNum,
           CAST( substring( ChangeDocTableKey, 14, 4 ) AS NUMC ) AS RsPos
    WHERE CreationDate                BETWEEN @p_frdate AND @p_todate
      AND CreationTime                BETWEEN @p_frtime AND @p_totime
      AND DatabaseTable = 'RESB'
      AND ChangeDocDatabaseTableField       = 'BDMNG'
    INTO TABLE @DATA(sel_chng_value).

  SELECT FROM I_GoodsMovementDocumentDEX
    FIELDS Reservation,
           ReservationItem
    WHERE Reservation                   IS NOT INITIAL
      AND CreationDate             BETWEEN @p_frdate AND @p_todate
      AND CreationTime             BETWEEN @p_frtime AND @p_totime
      AND GoodsMovementType             IN @so_bwrt
      AND StockIdfgStorageLocation    LIKE @p_lgrt

    INTO TABLE @DATA(sel_gmd).

  " Combine created tables, and make results unique
  APPEND LINES OF sel_chng TO sel_chng_value.
  APPEND LINES OF sel_gmd TO sel_chng_value.
  SORT sel_chng_value BY rsnum
                         rspos.
  DELETE ADJACENT DUPLICATES FROM sel_chng_value COMPARING rsnum rspos.

  SELECT  " Select additional data for changes
    FROM @sel_chng_value AS sel
           INNER JOIN
             I_MaintOrderComponentDEX AS comp ON comp~Reservation = sel~rsnum AND comp~ReservationItem = sel~rspos
               INNER JOIN
                 I_Product AS prd ON prd~Product = comp~Material

    FIELDS comp~Reservation,
           comp~ReservationItem,
           comp~ReservationType,
           comp~MaintenanceOrder,
           comp~Material,
           comp~Plant,
           comp~RequirementDate,
           comp~RequirementQuantityInBaseUnit,
           comp~QuantityWithdrawnInBaseUnit

    WHERE comp~MaintenanceOrderType      IN @so_aufa
      AND comp~StorageLocation         LIKE @p_lgrt
      AND prd~ZZ1_OS_XelusRelevant_PRD    = @abap_true " Only Xelus relevant

    INTO TABLE @DATA(ttl_chng1).

  " Selection for Changed status
  SELECT FROM I_MaintOrdChgHistory
    FIELDS ChangeDocObject

    WHERE CreationDate                BETWEEN @p_frdate AND  @p_todate
      AND CreationTime                BETWEEN @p_frtime AND  @p_totime
      AND DatabaseTable = 'TJ30'
      AND ChangeDocDatabaseTableField       = 'ESTAT'
      AND ChangeDocNewFieldValue           IN ( 'GGK', 'WGK', 'ANNU', 'SLUI' )

    INTO TABLE @DATA(sel_chng_status).

  SELECT " Select additional data for changes in status
    FROM @sel_chng_status AS sel
           INNER JOIN
             I_MaintOrderComponentDEX AS comp ON comp~MaintenanceOrder = sel~ChangeDocObject
               INNER JOIN
                 I_Product AS prd ON prd~Product = comp~Material

    FIELDS comp~Reservation,
           comp~ReservationItem,
           comp~ReservationType,
           comp~MaintenanceOrder,
           comp~Material,
           comp~Plant,
           comp~RequirementDate,
           comp~RequirementQuantityInBaseUnit,
           comp~QuantityWithdrawnInBaseUnit

    WHERE comp~MaintenanceOrderType      IN @so_aufa
      AND comp~StorageLocation         LIKE @p_lgrt
      AND prd~ZZ1_OS_XelusRelevant_PRD    = @abap_true " Only Xelus relevant

    INTO TABLE @DATA(ttl_chng2).

  " Combine created tables, and make results unique
  APPEND LINES OF ttl_chng1 TO ttl_chng2.
  SORT ttl_chng2 BY Reservation
                    ReservationItem
                    ReservationType.
  DELETE ADJACENT DUPLICATES FROM ttl_chng2 COMPARING Reservation ReservationItem ReservationType.

  " Based on selection, collect missing details from resb table and check status using custom views
  SELECT
    FROM @ttl_chng2 AS ttl
           INNER JOIN
             zc_resb_xelus AS resb ON resb~Rsnum = ttl~Reservation AND resb~Rspos = ttl~ReservationItem
               LEFT JOIN
                 zc_jest_jost_status AS stat ON stat~objnr = concat( 'OR', ttl~MaintenanceOrder ) " Check Object status

    FIELDS resb~Ordernr,
           resb~POMax,
           ttl~Material,
           ttl~Plant,
           ttl~RequirementQuantityInBaseUnit,
           ttl~QuantityWithdrawnInBaseUnit,
           ttl~RequirementDate,
           stat~stat

    WHERE resb~Storage LIKE @p_lgrt

    INTO TABLE @DATA(result).

  " -----------------------------------------------------------------------
  " End first part of data selection, continue for removed lines
  " -----------------------------------------------------------------------

  " Additional selection for Removed lines
  SELECT DISTINCT CAST( substring( ChangeDocTableKey, 4, 10 ) AS NUMC ) AS RsNum,
                  CAST( substring( ChangeDocTableKey, 14, 4 ) AS NUMC ) AS RsPos

    FROM I_MaintOrdChgHistory

    WHERE CreationDate                BETWEEN @p_frdate      AND  @p_todate
      AND CreationTime                BETWEEN @p_frtime      AND @p_totime
      AND DatabaseTable = 'RESB'
      AND ChangeDocDatabaseTableField       = 'XLOEK'
      AND ChangeDocItemChangeType           = 'U'

    INTO TABLE @DATA(sel_del).

  " First check which lines exist in the view
  SELECT
    FROM @sel_del AS sel
           INNER JOIN
             I_MaintOrderComponentDEX AS comp ON comp~Reservation = sel~rsnum AND comp~ReservationItem = sel~rspos

    FIELDS comp~Reservation     AS RsNum,
           comp~ReservationItem AS RsPos

    WHERE comp~MaintenanceOrderType   IN @so_aufa
      AND comp~StorageLocation      LIKE @p_lgrt

    INTO TABLE @found.

  " Remove found lines from the sel_del table
  not_found_del = FILTER #( sel_del EXCEPT IN found WHERE table_line = table_line ).

  " Select additional details from resb table and check on status
  SELECT
    FROM @not_found_del AS not
           INNER JOIN
             zc_resb_xelus AS zc ON zc~Rsnum = not~rsnum AND zc~Rspos = not~rspos
               LEFT JOIN
                 zc_jest_jost_status AS stat ON stat~objnr = concat( 'OR', zc~Ordernr )

    FIELDS zc~Ordernr,
           zc~POMax,
           zc~MatNr   AS Material,
           zc~Plant,
           zc~Datum   AS RequirementDate,
           stat~stat

    WHERE zc~Storage LIKE @p_lgrt

    INTO TABLE @DATA(resb).

  " -----------------------------------------------------------------------
  " Build-up output table for Maintenance Orders
  " -----------------------------------------------------------------------

  IF result IS NOT INITIAL.

    " If data is found start with first step for sales return table
    LOOP AT result ASSIGNING FIELD-SYMBOL(<sales_ret>). " Loop over all lines of sales return selection data
      CLEAR retquan.

      IF <sales_ret>-stat IS NOT INITIAL.
        retquan = 0.
      ELSE.
        retquan = <sales_ret>-RequirementQuantityInBaseUnit - <sales_ret>-QuantityWithdrawnInBaseUnit.
      ENDIF.

      " Assign values to table line sales return
      APPEND VALUE #( HostReturnOrderID     = |{ <sales_ret>-Ordernr }/{ <sales_ret>-POMax }|
                      HostPartID            = <sales_ret>-Material
                      HostLocID             = <sales_ret>-Plant
                      ReturnedQty           = retquan
                      RecvGoodQty           = 0
                      ShipDate              = <sales_ret>-RequirementDate
                      ExpectedAvailableDate = <sales_ret>-RequirementDate
                      HostCustomerID        = 'MAXIMO'  )
             TO sales_return.

    ENDLOOP.
  ENDIF.

  LOOP AT resb ASSIGNING FIELD-SYMBOL(<resb>).
    READ TABLE sales_return WITH KEY hostreturnorderid = |{ <resb>-Ordernr }/{ <resb>-POMax }|
         ASSIGNING FIELD-SYMBOL(<return>).

    IF <return> IS ASSIGNED.
      <return>-returnedqty = 0.
    ELSE.
      APPEND VALUE #( HostReturnOrderID     = |{ <resb>-Ordernr }/{ <resb>-POMax }|
                      HostPartID            = <resb>-Material
                      HostLocID             = <resb>-Plant
                      ReturnedQty           = 0
                      RecvGoodQty           = 0
                      ShipDate              = <resb>-RequirementDate
                      ExpectedAvailableDate = <resb>-RequirementDate
                      HostCustomerID        = 'MAXIMO'  )
             TO sales_return.
    ENDIF.
    UNASSIGN <return>.
  ENDLOOP.

  " -----------------------------------------------------------------------
  " Start data selection Transport orders
  " -----------------------------------------------------------------------

  " Selection of Purchase Orders to collect data from I_PurchaseOrderChangeDocument (Updates and Cancellation)
  SELECT FROM I_PurchaseOrderChangeDocument AS po

    FIELDS po~PurchaseOrder,
           CAST( substring( po~\_PurOrdChangeDocumentItem-ChangeDocTableKey, 14, 5 ) AS NUMC ) AS PurchaseOrderItem,
           po~\_PurOrdChangeDocumentItem-ChangeDocNewFieldValue

    WHERE po~PurchaseOrderType IN @so_pot
      AND ( po~PurchasingOrganization = @p_poo OR @p_poo IS INITIAL )
      AND po~CreationDate BETWEEN @p_frdt2 AND @p_todt2
      AND po~CreationTime BETWEEN @p_frtm2 AND @p_totm2
      AND (        po~\_PurOrdChangeDocumentItem-DatabaseTable                = 'EKPO'  " Check op EKPO velden
               AND po~\_PurOrdChangeDocumentItem-ChangeDocDatabaseTableField IN ( 'ELIKZ', 'LOEKZ', 'MENGE' )
            OR
               (     po~\_PurOrdChangeDocumentItem-DatabaseTable               = 'EKET'  " Check op EKET velden
                 AND po~\_PurOrdChangeDocumentItem-ChangeDocDatabaseTableField = 'EINDT' ) )

    INTO TABLE @DATA(sel_upd_cnc).

  " If needed, remove empty items
  DELETE sel_upd_cnc WHERE PurchaseOrderItem = ' '.

  " Selection Purchase Orders data to collect data from custom CDS view (new lines)
  SELECT FROM ZC_Order_plan AS zc

    FIELDS zc~PurchaseOrder,
           zc~PurchaseOrderItem

    WHERE zc~\_PurchaseOrder-PurchaseOrderType   IN @so_pot
      AND zc~\_Item-StorageLocation            LIKE @p_lgrt2
      AND ( zc~\_PurchaseOrder-PurchasingOrganization = @p_poo OR @p_poo IS INITIAL )
      AND zc~\_Prod-ZZ1_OS_XelusRelevant_PRD       = @abap_true
      AND zc~\_Item-CreationDate             BETWEEN @p_frdt2 AND @p_todt2
      AND zc~\_Item-CreationTime             BETWEEN @p_frtm2 AND @p_totm2
      AND zc~\_Item-IsCompletelyDelivered          = @abap_false

    INTO TABLE @DATA(sel_new_t).

  " Selection Purchase Orders data from custom CDS view (delivered lines, to check if completely delivered or not based on history of the PO)
  SELECT FROM ZC_HIST_Unique

    FIELDS PurchaseOrder,
           PurchaseOrderItem,
           IsCompletelyDelivered AS ChangeDocNewFieldValue,
           MaxDate,
           MaxTime

    WHERE MaxDate BETWEEN @p_frdt2 AND @p_todt2
      AND MaxTime BETWEEN @p_frtm2 AND @p_totm2
      AND InventoryValuationType              = 'V' " Only inventory relevant items
      AND PurchasingHistoryCategory           = 'E' " Purchasing history for PO items
      AND PurchasingHistoryDocumentType       = 1 " Goods receipt for purchase order

    INTO TABLE @DATA(sel_del_t).

  " Combine created tables, and make results unique
  APPEND LINES OF sel_upd_cnc TO sel_del_t.
  APPEND LINES OF sel_new_t TO sel_del_t.
  DATA(total) = sel_del_t.

  SORT total BY PurchaseOrder
                PurchaseOrderItem
                ChangeDocNewFieldValue DESCENDING. " Keep lines with value for this field
  DELETE ADJACENT DUPLICATES FROM total COMPARING PurchaseOrder PurchaseOrderItem.

  " Based on the selection, check the history of the PO's to determine if they are already completely delivered or not, using the ZC_HIST_Unique view
  SELECT FROM ZC_HIST_Unique

    FIELDS PurchaseOrder,
           PurchaseOrderItem,
           MAX( PurchasingHistoryDocumentType ) AS PurchasingHistoryDocumentType,
           MAX( PostingDate )                   AS PostingDate

    WHERE PurchasingHistoryDocumentType       = 6 " Only goods receipt history for purchase order
      AND MaxDate BETWEEN @p_frdt2 AND @p_todt2
      AND MaxTime BETWEEN @p_frtm2 AND @p_totm2

    GROUP BY PurchaseOrder,
             PurchaseOrderItem

    INTO TABLE @DATA(sel_hist).

  " Based on the selection, check the first schedule line delivery date of the PO's using the ZC_Order_plan view (when schedule line is 001, to have a unique line per PO item)
  SELECT
    FROM ZC_Order_plan AS zc
           INNER JOIN
             @total AS ttl ON ttl~PurchaseOrder = zc~PurchaseOrder AND ttl~PurchaseOrderItem = zc~PurchaseOrderItem

    FIELDS zc~PurchaseOrder,
           zc~PurchaseOrderItem,
           zc~ScheduleLineDeliveryDate,
           ttl~ChangeDocNewFieldValue

    WHERE zc~PurchaseOrderScheduleLine = '0001'

    INTO TABLE @DATA(total_date).

  " Selection of additional fields for affected PO's (based on above selections)
  SELECT
    FROM @total_date AS ttl
           INNER JOIN
             ZC_Order_plan AS zc ON ttl~PurchaseOrder = zc~PurchaseOrder AND ttl~PurchaseOrderItem = zc~PurchaseOrderItem

    FIELDS zc~PurchaseOrder,
           zc~PurchaseOrderItem,
           SUM( zc~ScheduleLineOrderQuantity ) - SUM( zc~RoughGoodsReceiptQty ) AS OrderQuantity,
           zc~\_Item-PurchaseOrderItemUniqueID,
           zc~Material,
           zc~\_ItemApi-Plant,
           zc~PurchaseOrderQuantityUnit,
           zc~\_Prod-BaseUnit,
           zc~SupPlant,
           ttl~ChangeDocNewFieldValue,
           ttl~ScheduleLineDeliveryDate

    WHERE zc~\_PurchaseOrder-PurchaseOrderType   IN @so_pot
      AND zc~\_Item-StorageLocation            LIKE @p_lgrt2
      AND ( zc~\_PurchaseOrder-PurchasingOrganization = @p_poo OR @p_poo IS INITIAL )
      AND zc~\_Prod-ZZ1_OS_XelusRelevant_PRD = @abap_true

    GROUP BY zc~PurchaseOrder,
             zc~PurchaseOrderItem,
             zc~\_Item-PurchaseOrderItemUniqueID,
             zc~Material,
             zc~\_ItemApi-Plant,
             zc~PurchaseOrderQuantityUnit,
             zc~\_Prod-BaseUnit,
             zc~SupPlant,
             ttl~ChangeDocNewFieldValue,
             ttl~ScheduleLineDeliveryDate

    INTO TABLE @DATA(sel_po).

  SORT sel_po BY PurchaseOrder
                 PurchaseOrderItem.

  " When no data is found for both selections, end query
  IF result IS INITIAL AND sel_po IS INITIAL.
    WRITE / TEXT-009.
    RETURN.
  ENDIF.

  " -----------------------------------------------------------------------
  " Build-up output table for the Transport Orders
  " -----------------------------------------------------------------------

  IF sel_po IS NOT INITIAL.
    " If data is found, add lines to sales_return table
    LOOP AT sel_po ASSIGNING FIELD-SYMBOL(<sel_po>). " Loop over all lines of Transport order selection data
      READ TABLE sel_hist WITH KEY PurchaseOrder     = <sel_po>-PurchaseOrder
                                   PurchaseOrderItem = <sel_po>-PurchaseOrderItem
           ASSIGNING FIELD-SYMBOL(<hist>). " Check if there is already a goods receipt for this PO line, to determine the ship date for the sales return (Schedule line delivery date or goods receipt posting date)

      CLEAR retquan.

      " When an order is removed or completely delivered, change order quantity to zero.
      IF <sel_po>-ChangeDocNewFieldValue = 'X' OR <sel_po>-ChangeDocNewFieldValue = 'L'.
        <sel_po>-OrderQuantity = 0.
      ENDIF.

      " Convert quantities to BaseUnit if needed (when not equal to PO quantity unit and issued quantity greater than 0)
      " Using FM: 'MD_CONVERT_MATERIAL_UNIT', log error in table errors (for testing purposes)
      " When error occurs, quantity is set to zero.
      IF <sel_po>-PurchaseOrderQuantityUnit <> <sel_po>-BaseUnit AND <sel_po>-OrderQuantity > 0.

        " Change order quantity if needed
        retquan = <sel_po>-OrderQuantity.

        result_mo = svg_class->convert_material( material = <sel_po>-Material
                                                 pounit   = <sel_po>-PurchaseOrderQuantityUnit
                                                 baseunit = <sel_po>-BaseUnit
                                                 quantity = retquan
                                                 po_item  = <sel_po>-PurchaseOrderItem ).

        <sel_po>-OrderQuantity = result_mo-converted_quantity.
        APPEND result_mo-error TO errors. " Error table for testing for missing conversions

      ENDIF.

      " Check if order already has had a goods delivery
      IF <hist> IS NOT ASSIGNED.
        shipdate = <sel_po>-ScheduleLineDeliveryDate.
      ELSE.
        shipdate = <hist>-PostingDate.
      ENDIF.

      " Assign values to table line sales return
      APPEND VALUE #( HostReturnOrderID     = <sel_po>-purchaseorderitemuniqueid
                      HostPartID            = <sel_po>-Material
                      HostLocID             = <sel_po>-Plant
                      ReturnedQty           = <sel_po>-OrderQuantity
                      RecvGoodQty           = 0
                      ShipDate              = shipdate
                      ExpectedAvailableDate = <sel_po>-ScheduleLineDeliveryDate
                      HostCustomerID        = <sel_po>-SupPlant  )
             TO sales_return.

      UNASSIGN <hist>.

    ENDLOOP.
  ENDIF.

  " -----------------------------------------------------------------------
  " Sent out table with selected data as JSON or CSV
  " -----------------------------------------------------------------------

  IF cb_test <> abap_true. " Excluded for testing

    IF r_api = abap_true.

      " Sent out orderplan_atb table
      CALL FUNCTION 'ZSVG_SEND_FILE_JSON'
        EXPORTING iv_destination  = p_dest
                  iv_path_postfix = p_pstfix
                  it_table        = sales_return.
    ENDIF.

    IF r_file = abap_true.

      " Sent out orderplan_atb table
      CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
        EXPORTING iv_destination  = p_dest
                  iv_path_postfix = p_pstfix
                  iv_filename     = p_file
                  it_table        = sales_return.

    ENDIF.

  ENDIF.

  " -----------------------------------------------------------------------
  " Create ALV (test modus only)
  " -----------------------------------------------------------------------
  IF sales_return IS NOT INITIAL AND cb_test = abap_true.

    svg_class->display_alv( table = REF #( sales_return )
                            title = 'Sales return partial selection' ).

  ELSE.
    RETURN.
  ENDIF.