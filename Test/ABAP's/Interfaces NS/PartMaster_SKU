*&---------------------------------------------------------------------*
*& Report zsvg_send_partmaster_sku_cds
*&---------------------------------------------------------------------*
*& This interface includes sending SAP article and master data,
*& Xelus/Servigistics (SVG) relevant from S4-Hana to SVG via CPI.
*& Xelus was the predecessor of SVG.
*& The data is sent using 2 seperate CSV files/tables.
*&---------------------------------------------------------------------*
REPORT zsvg_send_partmaster_sku_cds.

INCLUDE zsvg_send_pmsku_data. " Data declaration and selection screen:

*&---------------------------------------------------------------------*
*& Include zsvg_send_pmsku_data
*&---------------------------------------------------------------------*

TABLES mara.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS mat_chk RADIOBUTTON GROUP rad1.
  SELECT-OPTIONS so_matnr FOR mara-matnr.
  PARAMETERS cp_chk RADIOBUTTON GROUP rad1 DEFAULT 'X'.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(33) TEXT-002 FOR FIELD p_frdate.
    PARAMETERS p_frdate TYPE sy-datum OBLIGATORY.
    SELECTION-SCREEN COMMENT 48(10) TEXT-003 FOR FIELD p_frtime.
    PARAMETERS p_frtime TYPE syst_uzeit OBLIGATORY.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(33) TEXT-004 FOR FIELD p_todate.
    PARAMETERS p_todate TYPE sy-datum OBLIGATORY DEFAULT sy-datum.

    SELECTION-SCREEN COMMENT 48(10) TEXT-003 FOR FIELD p_totime.
    PARAMETERS p_totime TYPE syst_uzeit OBLIGATORY.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-005.
  PARAMETERS: p_dest   TYPE string LOWER CASE , " Destination via variant: 'SCO_CPI_SVG'
              p_pstfix TYPE string LOWER CASE , " Postfix via variant: '/http/sco/svg'
              p_postm  TYPE char100 LOWER CASE, " Via variant
              p_sku    TYPE char100 LOWER CASE. " Via variant

SELECTION-SCREEN END OF BLOCK b2.


SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-006.
  PARAMETERS: cb_test TYPE abap_bool AS CHECKBOX DEFAULT 'X',
              cb_part TYPE abap_bool RADIOBUTTON GROUP rad2 DEFAULT 'X',
              cb_sku  TYPE abap_bool RADIOBUTTON GROUP rad2.

SELECTION-SCREEN END OF BLOCK b3.

CONSTANTS zserv_pu  TYPE char30 VALUE 'ZSVG_PARTMASTER_SKU_CDS'.
CONSTANTS zserv_sku TYPE string VALUE 'Z_OS_TYPE_VESTIGING'.
CONSTANTS tvcname   TYPE char30 VALUE 'Z_SCO_SVG_PARTMASTER_LAST_RUN'.
CONSTANTS MesType1  TYPE char30 VALUE 'ZMATMAS_OS'.
CONSTANTS MesType2  TYPE char30 VALUE 'SRCLST'.
CONSTANTS spras     TYPE spras  VALUE 'N'.
CONSTANTS bwkey     TYPE bwkey  VALUE 'L100'.
CONSTANTS bwtar_s   TYPE char1  VALUE 'S'.
CONSTANTS bwtar_v   TYPE char1  VALUE 'V'.
CONSTANTS true      TYPE char1  VALUE 'X'.
CONSTANTS yes       TYPE char1  VALUE 'Y'.
CONSTANTS no        TYPE char1  VALUE 'N'.
CONSTANTS delimit   TYPE char1  VALUE '|'.
CONSTANTS replace   TYPE char1  VALUE '^'.

TYPES tt_partmaster TYPE TABLE OF zsvg_partmaster WITH KEY HostPartID.
TYPES tt_sku        TYPE TABLE OF zsvg_sku WITH KEY HostPartID hostlocid.

DATA partmaster  TYPE tt_partmaster. " result table PartMaster
DATA sku         TYPE tt_sku.        " result table SKU
DATA PartRepair  TYPE char1.
DATA PartActive  TYPE char1.
DATA IsPartKit   TYPE char1.
DATA PartCustom4 TYPE char3.
DATA PartCustom5 TYPE char1.
DATA PartCustom6 TYPE char1.
DATA HostDefault TYPE matnr.
DATA combined    TYPE TABLE OF zsvg_sku.
DATA tdline      TYPE char255.
DATA(svg_class) = NEW zcl_s4_to_svg( ). " Class for SVG methods

INITIALIZATION. " Inititate value for last change date and time
  SELECT SINGLE low FROM tvarvc INTO @DATA(last_change) WHERE name = @tvcname.
  p_frdate = last_change+0(8).
  p_frtime = last_change+8(8).
  p_totime = sy-timlo - 60.   " Correction 1 minute (60 sec.)

" -----------------------------------------------------------------------
" Start data selection
" -----------------------------------------------------------------------

START-OF-SELECTION.
  " -----------------------------------------------------------------------
  " Create where_clause based on variables (concerning: ZSVG_PARTMASTER_SKU)
  " Output will look something like:
  " ( PRODUCTTYPE EQ 'Z005' OR PRODUCTTYPE EQ 'Z013' ) AND ( EXTERNALPRODUCTGROUP EQ 'FICTIEF' OR etc....
  " -----------------------------------------------------------------------

  TRY.
      DATA(where_clause) = svg_class->create_where_clause( name = zserv_pu " ZSVG_PARTMASTER_SKU_CDS
                                                           ref  = zserv_pu ).
    CATCH cx_sy_itab_line_not_found.
      MESSAGE |Error: key { zserv_pu } not found| TYPE 'E'.
  ENDTRY.

  IF cp_chk = abap_true. " Selection based on change pointer input

    " -----------------------------------------------------------------------
    " Collect product selection based on Change Pointer input
    " -----------------------------------------------------------------------

    " Compare last_change data with user input, change if needed
    IF last_change+0(8) <> p_frdate.
      CONCATENATE p_frdate p_frtime INTO last_change.
    ENDIF.

    " Use last_change data to collect selection from bdcp2 table based on changepointers ZMATMAS_OS and SRCLST
    SELECT DISTINCT substring( cdobjid, 1, 40 ) AS product
      FROM bdcp2
      WHERE acttime >= @last_change
        AND ( mestype = @mestype1 OR mestype = @mestype2 )
      INTO TABLE @DATA(selection).

    IF selection IS NOT INITIAL. " When no data found, end program with message

      " -----------------------------------------------------------------------
      " Use the created where_clause and above selected product values from bdcp2 table
      " to collect data from various DB tables. Select based only on Dutch language if needed
      " -----------------------------------------------------------------------

      SELECT
        FROM ZC_PartMaster_SKU_data AS pro
               INNER JOIN
                 @selection AS sel ON sel~product = pro~Product  " Changepointer input as selection criteria

        FIELDS pro~Product,
               pro~ProductType,
               pro~ExternalProductGroup,
               pro~CrossPlantStatus,
               pro~ProductHierarchy,
               pro~zz1_os_kritisch_stil_prd,
               pro~zz1_ink_inspgrp_prd,
               pro~MinimalShelfLife,
               pro~BaseUnit,
               pro~\_Desc-ProductDescription,
               pro~StandPrice_S,
               pro~StandPrice_V,
               pro~\_Matplant-bstmi,
               pro~\_Matplant-bstfe,
               pro~\_Matplant-dispo,
               pro~\_Matplant-schgt,
               pro~\_Matplant-ekgrp,
               pro~\_Matplant-mmsta,
               pro~\_Matplant\_SourceOfSupply-werks         AS Plant,
               pro~\_Prodh-ProdhName,
               pro~\_BaseUnitOfMeasure-UnitOfMeasureISOCode
        WHERE (where_clause)
        AND zz1_os_xelusrelevant_prd = @true " Xelus/SVG relevant
        AND pro~\_Matplant-Plant = @bwkey

        ORDER BY pro~product
        INTO TABLE @DATA(i_product_data).

      DELETE ADJACENT DUPLICATES FROM i_product_data COMPARING Product.

    ENDIF.

  ELSEIF mat_chk = abap_true. " Selection based on product input

    " -----------------------------------------------------------------------
    " Collect product selection based on user input or select all
    " Use where_clause as created before based on MATKL and MTART
    " -----------------------------------------------------------------------

    SELECT FROM ZC_PartMaster_SKU_data AS pro

      FIELDS pro~Product,
             pro~ProductType,
             pro~ExternalProductGroup,
             pro~CrossPlantStatus,
             pro~ProductHierarchy,
             pro~zz1_os_kritisch_stil_prd,
             pro~zz1_ink_inspgrp_prd,
             pro~MinimalShelfLife,
             pro~BaseUnit,
             pro~\_Desc-ProductDescription,
             pro~StandPrice_S,
             pro~StandPrice_V,
             pro~\_Matplant-bstmi,
             pro~\_Matplant-bstfe,
             pro~\_Matplant-dispo,
             pro~\_Matplant-schgt,
             pro~\_Matplant-ekgrp,
             pro~\_Matplant-mmsta,
             pro~\_Matplant\_SourceOfSupply-werks         AS Plant,
             pro~\_Prodh-ProdhName,
             pro~\_BaseUnitOfMeasure-UnitOfMeasureISOCode
      WHERE pro~product IN @so_matnr
        AND (where_clause)
        AND zz1_os_xelusrelevant_prd = @true " Xelus/SVG relevant

      ORDER BY pro~Product
      INTO TABLE @DATA(i_product_data2).

    DELETE ADJACENT DUPLICATES FROM i_product_data2 COMPARING Product.

  ENDIF.

  IF cp_chk = abap_true.
    DATA(result) = i_product_data. " Result data based on Change Pointer input
  ELSE.
    result = i_product_data2.      " Result data based on product input
  ENDIF.

  IF result IS INITIAL. " Error no data found
    WRITE / TEXT-007.
    RETURN.
  ENDIF.

  " -----------------------------------------------------------------------
  " Build-up output tables
  " -----------------------------------------------------------------------

  IF result IS NOT INITIAL.

    " If data is found start with creating the Partmaster table based on result internal table and additional logic for some fields.
    " The SKU table will be created later based on the result table and additional selection.

    LOOP AT result ASSIGNING FIELD-SYMBOL(<partmaster>). " Loop over all lines of partmaster selection data

      CLEAR: partrepair,
             partactive,
             ispartkit,
             partcustom4,
             partcustom5,
             partcustom6,
             hostdefault,
             tdline.

      " When the '|' delimiter is used in the PartName, replace with '^'
      IF <partmaster>-ProductDescription CS delimit.
        <partmaster>-ProductDescription = svg_class->change_delimiter( text      = |{ <partmaster>-ProductDescription }|
                                                                       delimiter = delimit " '|'
                                                                       replace   = replace ). " '^'
      ENDIF.

      " Create a concatenated field for all results of tdline, max length is char255.
      " Via method read_text_product, using FM: Read_Text.
      " Optional: use the replace element for any instance of already used delimiter in found text.
      tdline = svg_class->read_text_matnr( matnr     = <partmaster>-product
                                           id        = 'GRUN'
                                           language  = 'N'
                                           object    = 'MATERIAL'
                                           delimiter = delimit  " '|'
                                           replace   = replace ). " Optional, '|' delimiters will be replaced with '^'

      " Assign RepairCost only when greater than 0 (Cost Price minus Dirty Price)
      IF <partmaster>-StandPrice_V > 0.
        <partmaster>-StandPrice_V = <partmaster>-StandPrice_S - <partmaster>-StandPrice_V.
      ENDIF.

      " Assign PartRepairable based on value of extwg, type: 'Y' or 'N'
      IF <partmaster>-ExternalProductGroup = 'OS WISSELDEEL' OR <partmaster>-ExternalProductGroup = 'OS HOOFDDEEL'.
        partrepair = yes.
      ELSE.
        partrepair = no.
      ENDIF.

      " Assign PartActive based values of i_product~mtart and ~mstae, type: 'Y' or 'N'
      IF     <partmaster>-ProductType = 'Z005'
         AND ( <partmaster>-CrossPlantStatus = 'O3' OR <partmaster>-CrossPlantStatus = 'O4' OR <partmaster>-CrossPlantStatus = 'O5' ).
        partactive = yes.
      ELSE.
        partactive = no.
      ENDIF.

      " Assign IsPartKit based on values of extwg and eord~werks, type: 'Y' or 'N'
      IF <partmaster>-ExternalProductGroup = 'OS KIT' AND <partmaster>-Plant IS INITIAL.
        ispartkit = yes.
      ELSE.
        ispartkit = no.
      ENDIF.

      " Assign PartCustom4 based on value of i_product~mtart and i_product~schgt, type: 'Y' or 'N'
      IF <partmaster>-ProductType = 'Z008' OR <partmaster>-ProductType = 'Z013'.
        partcustom4 = 'O2B'.
      ELSEIF <partmaster>-schgt = true.
        partcustom4 = 'OKG'.
      ENDIF.

      " Assign PartCustom5 based on value of i_product~producthierarchy, type: 'Y' or 'N'
      IF <partmaster>-ProductHierarchy = '0000120.23'.
        partcustom5 = yes.
      ELSE.
        partcustom5 = no.
      ENDIF.

      " Assign PartCustom6 based on value of zz1_os_kritisch_stil_prd, type: 'Y' or 'N'
      IF <partmaster>-zz1_os_kritisch_stil_prd = 'JA'.
        partcustom6 = yes.
      ELSE.
        partcustom6 = no.
      ENDIF.

      " Assign HostDefaultKittingID for OS KIT based on product
      IF <partmaster>-ExternalProductGroup = 'OS KIT'.
        hostdefault = <partmaster>-product.
      ENDIF.

      " Assign values to table line partmaster
      APPEND VALUE #( HostPartID           = <partmaster>-product
                      PartNumber           = <partmaster>-product
                      PartName             = <partmaster>-productdescription
                      HostPartTypeID       = <partmaster>-ProductType
                      PartDescription      = tdline
                      Price                = <partmaster>-StandPrice_S
                      RepairCost           = <partmaster>-StandPrice_V
                      PartRepairable       = partrepair
                      PartActive           = partactive
                      PartProcurable       = no
                      MinOQ                = <partmaster>-bstmi
                      LotSize              = <partmaster>-bstfe
                      HostPlannerCodeID    = <partmaster>-dispo
                      IsPartKit            = ispartkit
                      PartCustom1          = <partmaster>-ExternalProductGroup
                      PartCustom2          = <partmaster>-ProdhName
                      PartCustom3          = <partmaster>-CrossPlantStatus
                      PartCustom4          = partcustom4
                      PartCustom5          = partcustom5
                      PartCustom6          = partcustom6
                      PartCustom7          = <partmaster>-MinimalShelfLife
                      PartCustom8          = <partmaster>-ekgrp
                      uom                  = <partmaster>-UnitOfMeasureISOCode
                      HostDefaultKittingID = hostdefault
                      HostReplLocHierID    = <partmaster>-zz1_ink_inspgrp_prd )
             TO partmaster.

    ENDLOOP.

    " End of PartMaster table

    " -----------------------------------------------------------------------
    " Start with selecting additional input for SKU table
    " -----------------------------------------------------------------------

    " Selection of values maintained in the zzns_variabelen table (concerning: ZSVG_OS_TYPE_VESTIGING)
    SELECT DISTINCT low FROM zzns_variabelen
      INTO TABLE @DATA(vartab_sku)
      WHERE name = @zserv_sku " Z_OS_TYPE_VESTIGING
        AND ref  = @zserv_sku.

    " Create a table line for every combination of product and location(vestiging) based on result and vartab_sku tables
    combined = VALUE #( FOR <result> IN result
                        FOR <vartab> IN vartab_sku
                        ( hostpartid = <result>-product hostlocid = <vartab>-low ) ).

    " Based on above selection (combination product/werks), fetch additional data from MARC and EORD (supplier/source list) using custom view
    SELECT
      FROM ZC_MaterialPlant AS plant
             INNER JOIN
               @combined AS c ON c~hostpartid = plant~Material AND c~hostlocid = plant~Plant

      FIELDS plant~Material,
             plant~Plant,
             plant~mmsta,
             plant~HostProcureNewPriVendLocID,
             plant~HostRepairPriVendLocID

      INTO TABLE @DATA(skus). " Additional data for creating SKU output table

    SORT skus BY Material Plant. " Sort by material and plant
    DELETE ADJACENT DUPLICATES FROM skus COMPARING Material Plant. " Remove duplicates for possible multiple entries in EORD.

    " Based on above skus table, start with creating the SKU table
    LOOP AT skus ASSIGNING FIELD-SYMBOL(<skus>).
      READ TABLE result ASSIGNING FIELD-SYMBOL(<results>) WITH KEY product = <skus>-Material.

      IF sy-subrc <> 0. " When product is not in the SKU table, skip line
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO sku ASSIGNING FIELD-SYMBOL(<combine>). " Add line to output table

      " Assign values based on above DB selections
      <combine>-hostpartid = <results>-product.
      <combine>-hostlocid  = <skus>-Plant.

      " Assign ProcAllowed based on values of i_product~mtart, ~mstae and marc~mmsta, type: 'Y' or 'N'
      IF <results>-ProductType = 'Z005' AND ( <results>-CrossPlantStatus = 'O3' OR <results>-CrossPlantStatus = 'O4' ) AND <skus>-mmsta = 'OF'.
        <combine>-procallowed = yes.
      ELSE.
        <combine>-procallowed = no.
      ENDIF.

      <combine>-repaallowed                = no.            " Default value 'N'
      <combine>-hostprocurenewprivendlocid = <skus>-HostProcureNewPriVendLocID.
      <combine>-hostrepairprivendlocid     = <skus>-HostRepairPriVendLocID.

      " Assign values based on marc~mmsta, type: 'Y' or 'N'
      IF <skus>-mmsta = 'OF'.
        <combine>-skuactive = yes.
      ELSE.
        <combine>-skuactive = no.
      ENDIF.
    ENDLOOP.
  ENDIF.

  " -----------------------------------------------------------------------
  " Sent out tables and modify last change (date/time) in tvarvc table
  " -----------------------------------------------------------------------

  IF cb_test <> abap_true. " Not used in test modus

    " Sent out partmaster table as CSV
    CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
      EXPORTING iv_destination  = p_dest
                iv_path_postfix = p_pstfix
                iv_filename     = p_postm
                it_table        = partmaster.

    " Sent out sku's table as CSV
    CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
      EXPORTING iv_destination  = p_dest
                iv_path_postfix = p_pstfix
                iv_filename     = p_sku
                it_table        = sku.

    DATA tvarvc TYPE tvarvc.

    tvarvc-name = tvcname.
    tvarvc-type = 'P'.
    tvarvc-sign = 'I'.
    tvarvc-opti = 'EQ'.
    CONCATENATE p_todate p_totime INTO tvarvc-low.
    MODIFY tvarvc FROM tvarvc.

    IF sy-subrc = 0. " When successful, send out message
      WRITE / TEXT-008.
    ENDIF.

  ENDIF.

  " -----------------------------------------------------------------------
  " Create ALV (only for test modus)
  " -----------------------------------------------------------------------
  IF partmaster IS NOT INITIAL AND cb_test = abap_true. " Only when data is available, and test modus

    IF cb_part = abap_true. " Partmaster table
      svg_class->display_alv( table = REF #( partmaster )
                              title = 'PartMaster Output' ). " Sent table and optional title
    ELSE. " SKU table
      svg_class->display_alv( table = REF #( sku )
                              title = 'SKU Output' ).
    ENDIF.

  ELSE.
    RETURN.
  ENDIF.