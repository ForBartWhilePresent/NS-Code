*&---------------------------------------------------------------------*
*& Report zsvg_send_orderplan_partial
*&---------------------------------------------------------------------*
*& This interface includes sending only the changed purchase orders and
*& the purchase requests from S4-Hana to SVG via CPI.
*& The data is sent as a single JSON file
*&---------------------------------------------------------------------*
REPORT zsvg_send_orderplan_partial.

INCLUDE zsvg_send_ordpln_partial_data. " Data declaration and selection screen

*&---------------------------------------------------------------------*
*& Include zsvg_send_ordpln_partial_data
*&---------------------------------------------------------------------*

TABLES: ekko, ekpo, cdpos.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-002 FOR FIELD p_frdate.
    PARAMETERS p_frdate TYPE sy-datum OBLIGATORY DEFAULT sy-datum.
    SELECTION-SCREEN COMMENT 47(10) TEXT-003 FOR FIELD p_frtime.
    PARAMETERS p_frtime TYPE syst_uzeit OBLIGATORY DEFAULT sy-timlo.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-004 FOR FIELD p_todate.
    PARAMETERS p_todate TYPE sy-datum OBLIGATORY.
    SELECTION-SCREEN COMMENT 47(10) TEXT-003 FOR FIELD p_totime.
    PARAMETERS p_totime TYPE syst_uzeit DEFAULT '235959' OBLIGATORY.
  SELECTION-SCREEN END OF LINE.

  SELECT-OPTIONS: so_po   FOR ekko-ebeln, " Purchase Order
                  so_pot  FOR ekko-bsart, " PO type
                  so_chng FOR cdpos-chngind, " Change type
                  so_db   FOR cdpos-tabname, " DB table
                  so_dbf  FOR cdpos-fname, " DB table field
                  so_stl  FOR ekpo-lgort. " Storage Location

  PARAMETERS: p_poo    TYPE ekko-ekorg DEFAULT '5900', " PO Organization.
              p_chgdoc TYPE cdhdr-changenr, " Change Doc.
              p_proces TYPE banst DEFAULT 'N', " Processing Status
              p_val    TYPE ekbe-bwtar, " Inventory Valuation Type
              p_irt    TYPE xfeld. " Is Return

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-005.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(31) TEXT-006 FOR FIELD r_api.
  PARAMETERS r_api RADIOBUTTON GROUP rad DEFAULT 'X' USER-COMMAND sel.
  SELECTION-SCREEN COMMENT 47(15) TEXT-007 FOR FIELD r_file.
  PARAMETERS r_file RADIOBUTTON GROUP rad.
SELECTION-SCREEN END OF LINE.

  PARAMETERS: : p_dest   TYPE string LOWER CASE, " Destination via variant: 'SCO_APIM_SVG'
                p_pstfix TYPE string LOWER CASE, " Postfix via variant: '/SCO-SVG-Orderplan/api/1.0/entity/order-plan.ws'
                p_file   TYPE char100  LOWER CASE MODIF ID f1. " via variant

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-008.
  PARAMETERS cb_test TYPE abap_bool AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b3.

CONSTANTS sup_plant TYPE char4  VALUE 'L100'.
CONSTANTS zorderp   TYPE string VALUE 'ZSVG_ORDERPLAN'.

TYPES: BEGIN OF ty_orderplan_part,

         HostOrderID           TYPE string,
         HostLocID             TYPE ewerk,
         HostPartID            TYPE matnr,
         HostVendorLocID       TYPE lifnr,
         HostReplSourceLocID   TYPE reswk,
         OrderStatus           TYPE iaom_status,
         HostPurchaseOrderID   TYPE ebeln,
         OrderTypeID           TYPE bstyp,
         OrderStatusLastUpdate TYPE dats,
         PlanOrderDate         TYPE eindt,
         PlanRcvDate           TYPE eldat,
         PlanQuantity          TYPE etmen,
         ActualOrderDate       TYPE bedat,
         ShippedQuantity       TYPE wamng,
         ReceivedQuantity      TYPE weemg,
         PWSCustom2            TYPE val_text,
         PWSCustom3            TYPE zcustom,

       END OF ty_orderplan_part,
       tt_orderplan_part TYPE TABLE OF ty_orderplan_part WITH KEY hostorderid.

DATA orderplan_part TYPE tt_orderplan_part.
DATA(svg_class) = NEW zcl_s4_to_svg( ). " Initiate class to use applicable method(s)
DATA result       TYPE zcl_s4_to_svg=>ty_convert_result.
DATA errors       TYPE STANDARD TABLE OF zcl_s4_to_svg=>ty_error.
DATA quantity     TYPE ekpo-menge.
DATA days         TYPE i.
DATA host_vendor  TYPE lifnr.
DATA order_date   TYPE dats.
DATA order_status TYPE char1.
DATA ls_screen     TYPE screen.

"----------------------------------------------------------------------
"  Dynamic UI:
"----------------------------------------------------------------------

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN INTO ls_screen.

    " Check which option is active
    IF ls_screen-name = 'P_DEST' OR ls_screen-name = 'P_PSTFIX'.
      ls_screen-active = 1.
      ls_screen-input  = 1.
      MODIFY SCREEN FROM ls_screen.
      CONTINUE.
    ENDIF.

    " P_FILE + label → MODIF ID F1
    IF ls_screen-group1 = 'F1'.

      IF r_file = abap_true.
        ls_screen-active = 1.
        ls_screen-input  = 1.
      ELSE.
        ls_screen-active = 0.
        ls_screen-input  = 0.
      ENDIF.

      MODIFY SCREEN FROM ls_screen.
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

  " 2) Validate at Execute (F8)

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
" Start data selection
" -----------------------------------------------------------------------

START-OF-SELECTION.
  " Selection of Purchase Orders based on user input to collect data from I_PurchaseOrderChangeDocument (Updates and Cancellation)

  SELECT FROM I_PurchaseOrderChangeDocument AS po

    FIELDS po~PurchaseOrder,
           CAST( substring( po~\_PurOrdChangeDocumentItem-ChangeDocTableKey, 14, 5 ) AS NUMC ) AS PurchaseOrderItem

    WHERE po~PurchaseOrderType      IN @so_pot
      AND po~PurchasingOrganization  = @p_poo
      AND po~PurchaseOrder          IN @so_po
      AND ( po~\_PurOrdChangeDocumentItem-ChangeDocument = @p_chgdoc OR @p_chgdoc IS INITIAL )
      AND po~\_PurOrdChangeDocumentItem-ChangeDocument               = po~ChangeDocument
      AND po~CreationDate >= @p_frdate
      AND po~CreationDate <= @p_todate
      AND po~CreationTime >= @p_frtime
      AND po~CreationTime <= @p_totime
      AND po~\_PurOrdChangeDocumentItem-DatabaseTable               IN @so_db
      AND po~\_PurOrdChangeDocumentItem-ChangeDocDatabaseTableField IN @so_dbf
      AND po~\_PurOrdChangeDocumentItem-ChangeDocItemChangeType     IN @so_chng

    INTO TABLE @DATA(sel_upd_cnc).

  SORT sel_upd_cnc BY PurchaseOrder
                      PurchaseOrderItem.

  " Remove duplicates, and empty items
  DELETE sel_upd_cnc WHERE PurchaseOrderItem = ' '.
  DELETE ADJACENT DUPLICATES FROM sel_upd_cnc COMPARING PurchaseOrder PurchaseOrderItem.

  " Selection Purchase Orders data based on user input to collect data from custom CDS view (new lines)

  SELECT FROM ZC_Order_plan AS zc

    FIELDS zc~PurchaseOrder,
           zc~PurchaseOrderItem

    WHERE zc~\_PurchaseOrder-PurchaseOrderType IN @so_pot
      AND zc~\_Item-StorageLocation            IN @so_stl
      AND ( zc~\_PurchaseOrder-PurchasingOrganization = @p_poo OR @p_poo IS INITIAL )
      AND zc~\_Prod-ZZ1_OS_XelusRelevant_PRD = @abap_true
      AND zc~\_Var-param1                    = zc~POType
      AND zc~\_Var-param2                    = zc~PurchaseOrderItemCategory
      AND (    ( zc~SupPlant  = @sup_plant AND zc~\_Var-param3  = @sup_plant )
            OR ( zc~SupPlant <> @sup_plant AND zc~\_Var-param3 IS INITIAL ) )
      AND zc~\_Item-CreationDate >= @p_frdate
      AND zc~\_Item-CreationDate <= @p_todate
      AND zc~\_Item-CreationTime >= @p_frtime
      AND zc~\_Item-CreationTime <= @p_totime

    INTO TABLE @DATA(sel_new).

  SORT sel_new BY PurchaseOrder
                  PurchaseOrderItem.
  DELETE ADJACENT DUPLICATES FROM sel_new COMPARING PurchaseOrder PurchaseOrderItem.

  " Selection Purchase Orders data based on user input to collect data from custom CDS view (delivered  lines)
  SELECT FROM ZC_HIST_Unique AS zch

    FIELDS zch~PurchaseOrder,
           zch~PurchaseOrderItem,
           zch~MaxDate,
           zch~MaxTime

    WHERE zch~MaxDate >= @p_frdate
      AND zch~MaxDate <= @p_todate
      AND zch~MaxTime >= @p_frtime
      AND zch~MaxTime <= @p_totime
      AND zch~InventoryValuationType         = @p_val
      AND zch~PurchasingHistoryDocumentType  = 1

    INTO TABLE @DATA(sel_del).

  SORT sel_del BY PurchaseOrder
                  PurchaseOrderItem.
  DELETE ADJACENT DUPLICATES FROM sel_del COMPARING PurchaseOrder PurchaseOrderItem.

  APPEND LINES OF sel_del TO sel_new.
  APPEND LINES OF sel_upd_cnc TO sel_new.
  DATA(total) = sel_new.

  SORT total BY PurchaseOrder
                PurchaseOrderItem.
  DELETE ADJACENT DUPLICATES FROM total COMPARING PurchaseOrder PurchaseOrderItem.

  " Selection of additional fields for affected PO's (based on above selections)
  SELECT
    FROM @total AS ttl
           INNER JOIN
             ZC_Order_plan AS zc ON ttl~PurchaseOrder = zc~PurchaseOrder AND ttl~PurchaseOrderItem = zc~PurchaseOrderItem
               LEFT JOIN
                 ZC_HIST_Unique AS zch ON ttl~PurchaseOrder = zch~PurchaseOrder AND ttl~PurchaseOrderItem = zch~PurchaseOrderItem

    FIELDS zc~PurchaseOrder,
           zc~PurchaseOrderItem,
           zc~PurchaseOrderScheduleLine,
           zc~SchedLineStscDeliveryDate,
           zc~ScheduleLineOrderQuantity,
           zc~STOLatestPossibleGRDate,
           zc~ScheduleLineIssuedQuantity,
           zc~RoughGoodsReceiptQty,
           ( zc~ScheduleLineOrderQuantity - zc~RoughGoodsReceiptQty ) AS Sum,
           zc~PurchaseOrderQuantityUnit,
           zc~ScheduleLineDeliveryDate,
           zc~\_ItemApi-RequirementTracking,
           zc~\_ItemApi-Plant,
           zc~Material,
           zc~PurchaseOrderItemCategory,
           zc~\_ItemApi-GoodsReceiptDurationInDays,
           zc~\_PurchaseOrder-PurchaseOrderType,
           zc~\_PurchaseOrder-Supplier,
           zc~SupPlant,
           zc~\_PurchaseOrder-PurchaseOrderDate,
           zc~\_PurchaseOrder-PurchaseOrderSubtype,
           zc~\_Pd-LastChangeDateTime,
           zc~\_Prod-BaseUnit,
           zc~\_Status-text,
           zc~Status,
           zch~IsCompletelyDelivered                                  AS orderdelivered,
           zc~\_ItemApi-IsCompletelyDelivered                         AS itemdelivered,
           zc~\_ItemApi-PurchasingDocumentDeletionCode,
           zc~\_Var-value1,
           zc~\_Var-value2

    WHERE zc~\_PurchaseOrder-PurchaseOrderType IN @so_pot
      AND zc~\_Item-StorageLocation            IN @so_stl
      AND ( zc~\_PurchaseOrder-PurchasingOrganization = @p_poo OR @p_poo IS INITIAL )
      AND zc~\_Prod-ZZ1_OS_XelusRelevant_PRD = @abap_true
      AND zc~\_Var-param1                    = zc~POType
      AND zc~\_Var-param2                    = zc~PurchaseOrderItemCategory
      AND (    ( zc~SupPlant  = @sup_plant AND zc~\_Var-param3  = @sup_plant )
            OR ( zc~SupPlant <> @sup_plant AND zc~\_Var-param3 IS INITIAL ) )
      AND (    @p_irt IS INITIAL OR ( @p_irt IS NOT INITIAL AND zc~\_ItemApi-IsReturnsItem <> @p_irt ) )

    INTO TABLE @DATA(sel_po).

  SORT sel_po BY PurchaseOrder
                 PurchaseOrderItem
                 PurchaseOrderScheduleLine
                 orderdelivered DESCENDING.
  DELETE ADJACENT DUPLICATES FROM sel_po COMPARING PurchaseOrder PurchaseOrderItem PurchaseOrderScheduleLine.

  "----------------------------------------------------------------------------------
  " Selection of ATB data based on user input to collect data from custom CDS-views(s)
  "----------------------------------------------------------------------------------

  SELECT FROM I_PurchaseReqnChgDoc WITH
    PRIVILEGED ACCESS AS doc        " CDS view has restricted access

    FIELDS ChangeDocObject,
           ChangeDocument,
           CreationDate,
           CreationTime

    WHERE doc~CreationDate >= @p_frdate
      AND doc~CreationDate <= @p_todate
      AND doc~CreationTime >= @p_frtime
      AND doc~CreationTime <= @p_totime

    INTO TABLE @DATA(atb_new).

  SELECT FROM I_PurchaseReqnChgDocItmAPI01 WITH
    PRIVILEGED ACCESS AS itm        " CDS view has restricted access
    INNER JOIN @atb_new AS chng ON  chng~ChangeDocObject = itm~ChangeDocObject
                                AND chng~ChangeDocument  = itm~ChangeDocument

    FIELDS CAST( substring( itm~ChangeDocTableKey , 4, 10 ) AS CHAR ) AS po,
           CAST( substring( itm~ChangeDocTableKey , 14, 5 ) AS NUMC ) AS item,
           chng~CreationDate

    WHERE DatabaseTable = 'EBAN' " Only use EBAN lines
      AND (    ChangeDocDatabaseTableField = 'KEY'
            OR ChangeDocDatabaseTableField = 'WERKS'
            OR ChangeDocDatabaseTableField = 'MENGE'
            OR ChangeDocDatabaseTableField = 'LOEKZ'
            OR ChangeDocDatabaseTableField = 'EBAKZ' )

    INTO TABLE @DATA(atb_change_data).

  SORT atb_change_data BY po
                          item.

  " Only save one line per PO
  DELETE ADJACENT DUPLICATES FROM atb_change_data COMPARING po item.

  SELECT
    FROM @atb_change_data AS chng
           LEFT JOIN
             zi_pur_req_order_plan AS pro ON  pro~PurchaseRequisition     = chng~po
                                          AND pro~PurchaseRequisitionItem = chng~item

    FIELDS pro~RequirementTracking,
           pro~Plant,
           pro~Material,
           pro~Supplier,
           pro~FixedSupplier,
           pro~SupplyingPlant,
           pro~PurchaseRequisition,
           pro~PurchaseRequisitionItem,
           pro~LastChangeDateTime,
           pro~PurchaseRequisitionReleaseDate,
           pro~DeliveryDate,
           pro~RequestedQuantity,
           pro~MaterialGoodsReceiptDuration,
           pro~PurchasingDocumentSubtype,
           pro~\_Var-value1,
           pro~\_Var-value2,
           pro~\_Status-text,
           pro~IsDeleted,
           pro~IsClosed,
           chng~CreationDate

    WHERE pro~\_Prod-zz1_os_xelusrelevant_prd  = @abap_true
      AND pro~PurchaseRequisitionType         IN @so_pot
      AND ( pro~PurchasingOrganization = @p_poo OR @p_poo IS INITIAL )
      AND pro~StorageLocation  IN @so_stl
      AND pro~ProcessingStatus  = @p_proces
      AND pro~\_Var-param1      = pro~PurchaseRequisitionType
      AND pro~\_Var-param2      = pro~PurchasingDocumentItemCategory
      AND (    ( pro~SupplyingPlant  = @sup_plant AND pro~\_Var-param3  = @sup_plant )
            OR ( pro~SupplyingPlant <> @sup_plant AND pro~\_Var-param3 IS INITIAL ) )

    INTO TABLE @DATA(atb_data).

  " When no data is found for both selections, end query
  IF sel_po IS INITIAL AND atb_data IS INITIAL.
    WRITE / TEXT-009.
    RETURN.
  ENDIF.

  " -----------------------------------------------------------------------
  " Build-up output table
  " -----------------------------------------------------------------------

  " Build-up first part with Order Plan data

  IF sel_po IS NOT INITIAL.

    LOOP AT sel_po ASSIGNING FIELD-SYMBOL(<orderplan_part>).

      CLEAR: result,
             order_date,
             order_status,
             days.

      " Check and change Order Status
      IF     <orderplan_part>-orderdelivered                 IS INITIAL AND <orderplan_part>-itemdelivered IS INITIAL
         AND <orderplan_part>-purchasingdocumentdeletioncode IS INITIAL.
        order_status = 'O'. " Open
      ELSEIF     <orderplan_part>-orderdelivered  = abap_true AND <orderplan_part>-sum > 0
             AND <orderplan_part>-itemdelivered  IS INITIAL   AND <orderplan_part>-purchasingdocumentdeletioncode IS INITIAL.
        order_status = 'O'. " Open
      ELSEIF     <orderplan_part>-orderdelivered IS INITIAL
             AND ( <orderplan_part>-itemdelivered = abap_true OR <orderplan_part>-purchasingdocumentdeletioncode IS NOT INITIAL ).
        order_status = 'C'. " Closed
        <orderplan_part>-ScheduleLineOrderQuantity = <orderplan_part>-RoughGoodsReceiptQty.
      ELSEIF <orderplan_part>-orderdelivered = abap_true AND <orderplan_part>-sum = 0.
        order_status = 'C'. " Closed
      ELSEIF     <orderplan_part>-orderdelivered = abap_true AND <orderplan_part>-sum > 0
             AND ( <orderplan_part>-itemdelivered = abap_true OR <orderplan_part>-purchasingdocumentdeletioncode IS NOT INITIAL ).
        order_status = 'C'. " Closed
      ENDIF.

      " Convert quantities to BaseUnit if needed (when not equal to PO quantity unit and issued quantity greater than 0)
      " Using FM: 'MD_CONVERT_MATERIAL_UNIT', log error in table errors (for testing purposes)
      " When error occurs, quantity is set to zero.

      IF <orderplan_part>-PurchaseOrderQuantityUnit <> <orderplan_part>-BaseUnit AND <orderplan_part>-ScheduleLineOrderQuantity > 0.

        " Plan Quantity
        quantity = <orderplan_part>-ScheduleLineOrderQuantity.

        result = svg_class->convert_material( material = <orderplan_part>-Material
                                              pounit   = <orderplan_part>-PurchaseOrderQuantityUnit
                                              baseunit = <orderplan_part>-BaseUnit
                                              quantity = quantity
                                              po_item  = <orderplan_part>-PurchaseOrderItem ).

        <orderplan_part>-ScheduleLineOrderQuantity = result-converted_quantity.

        " Shipped Quantity
        quantity = <orderplan_part>-ScheduleLineIssuedQuantity.

        result = svg_class->convert_material( material = <orderplan_part>-Material
                                              pounit   = <orderplan_part>-PurchaseOrderQuantityUnit
                                              baseunit = <orderplan_part>-BaseUnit
                                              quantity = quantity
                                              po_item  = <orderplan_part>-PurchaseOrderItem ).

        <orderplan_part>-ScheduleLineIssuedQuantity = result-converted_quantity.

        " Received Quantity
        quantity = <orderplan_part>-RoughGoodsReceiptQty.

        result = svg_class->convert_material( material = <orderplan_part>-Material
                                              pounit   = <orderplan_part>-PurchaseOrderQuantityUnit
                                              baseunit = <orderplan_part>-BaseUnit
                                              quantity = quantity
                                              po_item  = <orderplan_part>-PurchaseOrderItem ).

        <orderplan_part>-RoughGoodsReceiptQty = result-converted_quantity.
        APPEND result-error TO errors. " Error table for testing for missing conversions

      ENDIF.

      " Extract last change date (format: YYYYMMDD).
      DATA(string) = CONV string( <orderplan_part>-LastChangeDateTime ).
      order_date = string+0(8).

      " If necessary move date to first available work day (function: 'BKK_GET_NEXT_WORKDAY')
      IF <orderplan_part>-STOLatestPossibleGRDate IS NOT INITIAL.

        <orderplan_part>-STOLatestPossibleGRDate = svg_class->get_work_day( <orderplan_part>-STOLatestPossibleGRDate ).

      ELSE.

        " If STOLATESTPOSSIBLEGRDATE not available, use function 'FKK_ADD_WORKINGDAY'
        days = <orderplan_part>-GoodsReceiptDurationInDays.
        <orderplan_part>-STOLatestPossibleGRDate = svg_class->add_work_day(
                                                       date = <orderplan_part>-ScheduleLineDeliveryDate
                                                       days = days ).

      ENDIF.

      " Fill line of output table with selected data
      APPEND VALUE #(
          HostOrderID           = |{ <orderplan_part>-RequirementTracking }/{ <orderplan_part>-PurchaseOrderItem }/{ <orderplan_part>-PurchaseOrderScheduleLine }| " concatenate fields using symbol '/'
          HostLocID             = <orderplan_part>-Plant
          HostPartID            = <orderplan_part>-Material
          HostVendorLocID       = <orderplan_part>-supplier
          HostReplSourceLocID   = <orderplan_part>-SupPlant
          OrderStatus           = order_status
          HostPurchaseOrderID   = <orderplan_part>-PurchaseOrder
          OrderTypeID           = <orderplan_part>-Value1
          OrderStatusLastUpdate = order_date
          PlanOrderDate         = <orderplan_part>-ScheduleLineDeliveryDate
          PlanRcvDate           = <orderplan_part>-STOLatestPossibleGRDate
          PlanQuantity          = <orderplan_part>-ScheduleLineOrderQuantity
          ActualOrderDate       = <orderplan_part>-PurchaseOrderDate
          ShippedQuantity       = <orderplan_part>-ScheduleLineIssuedQuantity
          ReceivedQuantity      = <orderplan_part>-RoughGoodsReceiptQty
          PWSCustom2            = <orderplan_part>-Text
          PWSCustom3            = <orderplan_part>-Value2 )

             TO orderplan_part.
    ENDLOOP.
  ENDIF.

  " Append the above created table with the ATB data

  IF atb_data IS NOT INITIAL.
    LOOP AT atb_data ASSIGNING FIELD-SYMBOL(<atb>).

      CLEAR: order_status,
             order_date,
             host_vendor.

      " Check if supplier exists otherwise use Fixed Supplier
      IF <atb>-Supplier IS NOT INITIAL.
        host_vendor = <atb>-Supplier.
      ELSE.
        host_vendor = <atb>-FixedSupplier.
      ENDIF.

      " Check for cancellations
      IF <atb>-IsClosed = 'X' OR <atb>-IsDeleted = 'X'.
        order_status = 'C'. " Cancelled
        <atb>-RequestedQuantity = 0.
      ELSEIF <atb>-IsClosed IS INITIAL AND <atb>-IsDeleted IS INITIAL.
        order_status = 'O'.
      ENDIF.

      " If necessary add work day(s) to supplied delivery date (function: 'FKK_ADD_WORKINGDAY')
      days = <atb>-MaterialGoodsReceiptDuration.
      IF <atb>-DeliveryDate IS NOT INITIAL.

        <atb>-DeliveryDate = svg_class->add_work_day( date = <atb>-DeliveryDate
                                                      days = days ).

      ENDIF.

      " Extract last change date (format: YYYYMMDD).
      DATA(string_atb) = CONV string( <atb>-LastChangeDateTime ).
      order_date = string_atb+0(8).

      " Fill line of output table with selected data
      APPEND VALUE #( HostOrderID           = |{ <atb>-RequirementTracking }/{ <atb>-PurchaseRequisitionItem }|
                      HostLocID             = <atb>-Plant
                      HostPartID            = <atb>-Material
                      HostVendorLocID       = host_vendor
                      HostReplSourceLocID   = <atb>-SupplyingPlant
                      OrderStatus           = order_status
                      HostPurchaseOrderID   = <atb>-PurchaseRequisition
                      OrderTypeID           = <atb>-Value1
                      OrderStatusLastUpdate = order_date
                      PlanOrderDate         = <atb>-PurchaseRequisitionReleaseDate
                      PlanRcvDate           = <atb>-DeliveryDate
                      PlanQuantity          = <atb>-RequestedQuantity
                      ActualOrderDate       = <atb>-CreationDate
                      PWSCustom2            = <atb>-Text
                      PWSCustom3            = <atb>-Value2 )

             TO orderplan_part.
    ENDLOOP.
  ENDIF.

  " -----------------------------------------------------------------------
  " Sent out table with all data as JSO or CSV
  " -----------------------------------------------------------------------

  IF cb_test <> abap_true. " Excluded for testing

    IF r_api = abap_true.
      " Sent out orderplan_part table as JSON file
      CALL FUNCTION 'ZSVG_SEND_FILE_JSON'
        EXPORTING iv_destination  = p_dest
                  iv_path_postfix = p_pstfix
                  it_table        = orderplan_part.
    ENDIF.

    IF r_file = abap_true.

      " Sent out orderplan_part table as CSV file
      CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
        EXPORTING iv_destination  = p_dest
                  iv_path_postfix = p_pstfix
                  iv_filename     = p_file
                  it_table        = orderplan_part.

    ENDIF.

  ENDIF.

  " -----------------------------------------------------------------------
  " Create ALV (test modus only)
  " -----------------------------------------------------------------------
  IF orderplan_part IS NOT INITIAL AND cb_test = abap_true.

    svg_class->display_alv( table = REF #( orderplan_part )
                            title = 'Orderplan Partial Selection' ).

  ELSE.
    RETURN.
  ENDIF.