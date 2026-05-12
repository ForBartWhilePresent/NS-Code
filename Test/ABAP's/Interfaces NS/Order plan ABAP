*&---------------------------------------------------------------------*
*& Report ZSVG_SEND_ORDERPLAN
*&---------------------------------------------------------------------*
*& This interface includes sending the purchase orders and
*& the purchase requests from S4-Hana to SVG via CPI.
*& The data is sent as a single JSON file
*&---------------------------------------------------------------------*
REPORT zsvg_send_orderplan.

INCLUDE zsvg_send_ordpln. " Data declaration and selection screen:

*&---------------------------------------------------------------------*
*& Include zsvg_send_ordpln
*&---------------------------------------------------------------------*

TABLES: ekko, ekpo, eban.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS: so_pot  FOR ekko-bsart, " PO type
                  so_pod  FOR ekko-bedat, " PO Date
                  so_stlo FOR ekpo-lgort. " Storage location

  PARAMETERS: p_poo  TYPE ekko-ekorg, " PO org.
              p_gre  TYPE xfeld DEFAULT 'X', " Goods Receipt Expected
              p_icd  TYPE xfeld, " Complete delivery
              p_irt  TYPE xfeld, " Return
              p_pidc TYPE eloek. " Deletion code

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  SELECT-OPTIONS: so_prt   FOR eban-bsart, " PR type
                  so_prd   FOR ekko-bedat, " PR date
                  so_stlo2 FOR ekpo-lgort. " Storage location

  PARAMETERS: p_pro   TYPE ekko-ekorg, " PO org
              p_prge  TYPE xfeld DEFAULT 'X', " Goods Receipt Expected
              p_prst  TYPE eban-statu DEFAULT 'N', " Processing status
              p_prdel TYPE eloek, " Deletion code
              p_prcsd TYPE xfeld. " Closed code

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(31) TEXT-004 FOR FIELD r_api.
  PARAMETERS r_api RADIOBUTTON GROUP rad DEFAULT 'X' USER-COMMAND sel.
  SELECTION-SCREEN COMMENT 47(15) TEXT-005 FOR FIELD r_file.
  PARAMETERS r_file RADIOBUTTON GROUP rad.
SELECTION-SCREEN END OF LINE.

  PARAMETERS: p_dest   TYPE string LOWER CASE, " Destination via variant: 'SCO_APIM_SVG' of 'SCO_CPI_SVG'
              p_pstfix TYPE string LOWER CASE, " Postfix via variant: '/SCO-SVG-Orderplan/api/1.0/entity/order-plan.ws' of '/http/sco/svg'
              p_file   TYPE char100 LOWER CASE MODIF ID f1. " via variant
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-006.
  PARAMETERS cb_test TYPE abap_bool AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b4.

CONSTANTS true      TYPE char1  VALUE 'X'.
CONSTANTS sup_plant TYPE char4  VALUE 'L100'.
CONSTANTS zorderp   TYPE string VALUE 'ZSVG_ORDERPLAN'.

TYPES: BEGIN OF ty_orderplan_atb,

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
         PWSCustom3            TYPE string,

       END OF ty_orderplan_atb.

TYPES tt_orderplan_atb TYPE TABLE OF ty_orderplan_atb WITH KEY hostorderid.

DATA orderplan_atb TYPE tt_orderplan_atb.
DATA result        TYPE zcl_s4_to_svg=>ty_convert_result.
DATA errors        TYPE STANDARD TABLE OF zcl_s4_to_svg=>ty_error.
DATA quantity      TYPE ekpo-menge.
DATA days          TYPE i.
DATA host_vendor   TYPE lifnr.
DATA order_date    TYPE dats.
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
  SELECT FROM zc_order_plan AS zc

    FIELDS zc~PurchaseOrder,
           zc~PurchaseOrderItem,
           zc~PurchaseOrderScheduleLine,
           zc~SchedLineStscDeliveryDate,
           zc~ScheduleLineOrderQuantity,
           zc~STOLatestPossibleGRDate,
           zc~ScheduleLineIssuedQuantity,
           zc~RoughGoodsReceiptQty,
           zc~PurchaseOrderQuantityUnit,
           zc~ScheduleLineDeliveryDate,
           zc~\_ItemApi-RequirementTracking,
           zc~\_ItemApi-Plant,
           zc~\_ItemApi-Material,
           zc~\_ItemApi-PurchaseOrderItemCategory,
           zc~\_ItemApi-GoodsReceiptDurationInDays,
           zc~\_Po-PurchaseOrderType,
           zc~\_Po-Supplier,
           zc~\_Po-SupplyingPlant,
           zc~\_Po-PurchaseOrderDate,
           zc~\_Po-PurchaseOrderSubtype,
           zc~\_Pd-LastChangeDateTime,
           zc~\_Var-value1,
           zc~\_Var-value2,
           zc~\_Prod-BaseUnit,
           zc~\_Status-text

    WHERE ( zc~ScheduleLineOrderQuantity - zc~RoughGoodsReceiptQty )  > 0 " only
      AND zc~POType IN @so_pot
      AND zc~\_Po-PurchaseOrderDate IN @so_pod
      AND zc~\_ItemApi-StorageLocation IN @so_stlo
      AND ( zc~\_Po-PurchasingOrganization = @p_pro OR @p_pro IS INITIAL )
      AND zc~\_ItemApi-GoodsReceiptIsExpected = @p_gre
      AND zc~\_ItemApi-IsCompletelyDelivered  = @p_icd
      AND ( @p_irt IS INITIAL OR ( @p_irt IS NOT INITIAL AND zc~\_ItemApi-IsReturnsItem <> @p_irt ) )
      AND zc~\_ItemApi-PurchasingDocumentDeletionCode = @p_pidc
      AND zc~\_Prod-zz1_os_xelusrelevant_prd          = @true
      AND zc~\_Var-param1 = zc~POType
      AND zc~\_Var-param2 = zc~PurchaseOrderItemCategory
      AND (    ( zc~SupPlant  = @sup_plant AND zc~\_Var-param3  = @sup_plant )
            OR ( zc~SupPlant <> @sup_plant AND zc~\_Var-param3 IS INITIAL ) )

  INTO TABLE @DATA(op_data).

  " Selection of ATB data based on user input to collect data from various CDS-views

  SELECT FROM zi_pur_req_order_plan AS pri

    FIELDS pri~RequirementTracking,
           pri~Plant,
           pri~Material,
           pri~Supplier,
           pri~FixedSupplier,
           pri~SupplyingPlant,
           pri~PurchaseRequisition,
           pri~PurchaseRequisitionItem,
           pri~LastChangeDateTime,
           pri~PurchaseRequisitionReleaseDate,
           pri~DeliveryDate,
           pri~RequestedQuantity,
           pri~CreationDate,
           pri~MaterialGoodsReceiptDuration,
           pri~PurchasingDocumentSubtype,
           pri~\_Var-value1,
           pri~\_Var-value2,
           pri~\_Status-text

    WHERE pri~PurchaseRequisitionType         IN @so_prt
      AND pri~CreationDate                    IN @so_prd
      AND pri~StorageLocation                 IN @so_stlo2
      AND pri~\_Prod-zz1_os_xelusrelevant_prd  = @true
      AND ( pri~PurchasingOrganization = @p_pro OR @p_pro IS INITIAL )
      AND pri~GoodsReceiptIsExpected = @p_prge
      AND pri~ProcessingStatus       = @p_prst
      AND pri~IsDeleted              = @p_prdel
      AND pri~IsClosed               = @p_prcsd
      AND pri~\_Var-param1           = pri~PurchaseRequisitionType
      AND pri~\_Var-param2           = pri~PurchasingDocumentItemCategory
      AND (    ( pri~SupplyingPlant  = @sup_plant AND pri~\_Var-param3  = @sup_plant )
            OR ( pri~SupplyingPlant <> @sup_plant AND pri~\_Var-param3 IS INITIAL ) )

  INTO TABLE @DATA(atb_data).

  " When no data is found for both selections, end query
  IF op_data IS INITIAL AND atb_data IS INITIAL.
    WRITE / TEXT-007.
    RETURN.
  ENDIF.

  " -----------------------------------------------------------------------
  " Build-up output table
  " -----------------------------------------------------------------------

  DATA(svg_klasse) = NEW zcl_s4_to_svg( ). " Initiate class to use applicable methods

  " Build-up first part with Order Plan data

  IF op_data IS NOT INITIAL.
    LOOP AT op_data ASSIGNING FIELD-SYMBOL(<orderplan>).

      CLEAR: result,
             order_date,
             days.

      " Convert quantities to BaseUnit if needed (when not equal to PO quantity unit and issued quantity greater than 0)
      " Using FM: 'MD_CONVERT_MATERIAL_UNIT', log error in table errors (for testing purposes)
      " When error occurs, quantity is set to zero.

      IF <orderplan>-PurchaseOrderQuantityUnit <> <orderplan>-BaseUnit AND <orderplan>-ScheduleLineOrderQuantity > 0.

        " Plan Quantity
        quantity = <orderplan>-ScheduleLineOrderQuantity.

        result = svg_klasse->convert_material( material = <orderplan>-Material
                                               pounit   = <orderplan>-PurchaseOrderQuantityUnit
                                               baseunit = <orderplan>-BaseUnit
                                               quantity = quantity
                                               po_item  = <orderplan>-PurchaseOrderItem ).

        <orderplan>-ScheduleLineOrderQuantity = result-converted_quantity.

        " Shipped Quantity
        quantity = <orderplan>-ScheduleLineIssuedQuantity.

        result = svg_klasse->convert_material( material = <orderplan>-Material
                                               pounit   = <orderplan>-PurchaseOrderQuantityUnit
                                               baseunit = <orderplan>-BaseUnit
                                               quantity = quantity
                                               po_item  = <orderplan>-PurchaseOrderItem ).

        <orderplan>-ScheduleLineIssuedQuantity = result-converted_quantity.

        " Received Quantity
        quantity = <orderplan>-RoughGoodsReceiptQty.

        result = svg_klasse->convert_material( material = <orderplan>-Material
                                               pounit   = <orderplan>-PurchaseOrderQuantityUnit
                                               baseunit = <orderplan>-BaseUnit
                                               quantity = quantity
                                               po_item  = <orderplan>-PurchaseOrderItem ).

        <orderplan>-RoughGoodsReceiptQty = result-converted_quantity.
        APPEND result-error TO errors. " Error table for testing for missing conversions

      ENDIF.

      " Check on PO sub-type = T, change host vendor if necessary
      IF <orderplan>-PurchaseOrderSubtype = 'T'.
        host_vendor = <orderplan>-SupplyingPlant.
      ELSE.
        host_vendor = <orderplan>-Supplier.
      ENDIF.

      " Extract last change date (format: YYYYMMDD).
      DATA(string) = CONV string( <orderplan>-LastChangeDateTime ).
      order_date = string+0(8).

      " If necessary move date to first available work day (function: 'BKK_GET_NEXT_WORKDAY')
      IF <orderplan>-STOLatestPossibleGRDate IS NOT INITIAL.

        <orderplan>-STOLatestPossibleGRDate = svg_klasse->get_work_day( <orderplan>-STOLatestPossibleGRDate ).

      ELSE.

        " If STOLATESTPOSSIBLEGRDATE not available, use function 'FKK_ADD_WORKINGDAY'
        days = <orderplan>-GoodsReceiptDurationInDays.
        <orderplan>-STOLatestPossibleGRDate = svg_klasse->add_work_day( date = <orderplan>-ScheduleLineDeliveryDate
                                                                        days = days ).

      ENDIF.

      " Fill line of output table with selected data
      APPEND VALUE #(
          HostOrderID           = |{ <orderplan>-RequirementTracking }/{ <orderplan>-PurchaseOrderItem }/{ <orderplan>-PurchaseOrderScheduleLine }| " concatenate fields using symbol '/'
          HostLocID             = <orderplan>-Plant
          HostPartID            = <orderplan>-Material
          HostVendorLocID       = <orderplan>-supplier
          HostReplSourceLocID   = <orderplan>-supplyingplant
          OrderStatus           = 'O'
          HostPurchaseOrderID   = <orderplan>-PurchaseOrder
          OrderTypeID           = <orderplan>-Value1
          OrderStatusLastUpdate = order_date
          PlanOrderDate         = <orderplan>-ScheduleLineDeliveryDate
          PlanRcvDate           = <orderplan>-STOLatestPossibleGRDate
          PlanQuantity          = <orderplan>-ScheduleLineOrderQuantity
          ActualOrderDate       = <orderplan>-PurchaseOrderDate
          ShippedQuantity       = <orderplan>-ScheduleLineIssuedQuantity
          ReceivedQuantity      = <orderplan>-RoughGoodsReceiptQty
          PWSCustom2            = <orderplan>-Text
          PWSCustom3            = <orderplan>-Value2 )

             TO orderplan_atb.
    ENDLOOP.
  ENDIF.

  " Then append the above created table with the ATB data

  IF atb_data IS NOT INITIAL.
    LOOP AT atb_data ASSIGNING FIELD-SYMBOL(<atb>).

      CLEAR: order_date,
             host_vendor.

      " If necessary add work day(s) to supplied delivery date (function: 'FKK_ADD_WORKINGDAY')
      days = <atb>-MaterialGoodsReceiptDuration.
      IF <atb>-DeliveryDate IS NOT INITIAL.

        <atb>-DeliveryDate = svg_klasse->add_work_day( date = <atb>-DeliveryDate
                                                       days = days ).

      ENDIF.

      " Extract last change date (format: YYYYMMDD).
      DATA(string_atb) = CONV string( <atb>-LastChangeDateTime ).
      order_date = string_atb+0(8).

      " Check if supplier exists otherwise use Fixed Supplier
      IF <atb>-Supplier IS NOT INITIAL.
        host_vendor = <atb>-Supplier.
      ELSE.
        host_vendor = <atb>-FixedSupplier.
      ENDIF.

      " Fill line of output table with selected data
      APPEND VALUE #( HostOrderID           = |{ <atb>-RequirementTracking }/{ <atb>-PurchaseRequisitionItem }|
                      HostLocID             = <atb>-Plant
                      HostPartID            = <atb>-Material
                      HostVendorLocID       = host_vendor
                      HostReplSourceLocID   = <atb>-SupplyingPlant
                      OrderStatus           = 'O'
                      HostPurchaseOrderID   = <atb>-PurchaseRequisition
                      OrderTypeID           = <atb>-Value1
                      OrderStatusLastUpdate = order_date
                      PlanOrderDate         = <atb>-PurchaseRequisitionReleaseDate
                      PlanRcvDate           = <atb>-DeliveryDate
                      PlanQuantity          = <atb>-RequestedQuantity
                      ActualOrderDate       = <atb>-CreationDate
                      PWSCustom2            = <atb>-Text
                      PWSCustom3            = <atb>-Value2 )

             TO orderplan_atb.
    ENDLOOP.
  ENDIF.

  " -----------------------------------------------------------------------
  " Sent out table with all data as JSON or CSV
  " -----------------------------------------------------------------------

  IF cb_test <> abap_true. " Excluded for testing

    IF r_api = abap_true.
      " Sent out orderplan_atb table
      CALL FUNCTION 'ZSVG_SEND_FILE_JSON'
        EXPORTING
          iv_destination  = p_dest
          iv_path_postfix = p_pstfix
          it_table        = orderplan_atb.
    ENDIF.

    IF r_file = abap_true.

      " Sent out orderplan_atb table
      CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
        EXPORTING
          iv_destination  = p_dest
          iv_path_postfix = p_pstfix
          iv_filename     = p_file
          it_table        = orderplan_atb.

    ENDIF.

  ENDIF.

  " -----------------------------------------------------------------------
  " Create ALV (test modus only)
  " -----------------------------------------------------------------------
  IF orderplan_atb IS NOT INITIAL AND cb_test = abap_true.

    svg_klasse->display_alv( table = REF #( orderplan_atb )
                             title = 'Orderplan selection' ).

  ELSE.
    RETURN.
  ENDIF.