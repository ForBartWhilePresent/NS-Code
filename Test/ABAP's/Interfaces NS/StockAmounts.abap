*&---------------------------------------------------------------------*
*& Report zsvg_send_stockamounts
*&---------------------------------------------------------------------*
*& This interface includes sending the stock amounts,
*& from S4-Hana to SVG via CPI.
*& The data is sent as a single JSON file (Full load or Partial load)
*&---------------------------------------------------------------------*
REPORT zsvg_send_stockamounts.

INCLUDE zsvg_send_stocka_data.:

*&---------------------------------------------------------------------*
*& Include zsvg_send_stocka_data
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Include          ZSVG_SEND_PMSKU_DATA_SEL
*&---------------------------------------------------------------------*

TABLES mara.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS full_chk RADIOBUTTON GROUP rad1 DEFAULT 'X'.
  SELECT-OPTIONS so_matnr FOR mara-matnr.
  PARAMETERS part_chk RADIOBUTTON GROUP rad1.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-002 FOR FIELD p_frdate.
    PARAMETERS p_frdate TYPE sy-datum DEFAULT sy-datum.
    SELECTION-SCREEN COMMENT 47(10) TEXT-003 FOR FIELD p_todate.
    PARAMETERS p_todate TYPE sy-datum DEFAULT sy-datum.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-006.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(31) TEXT-004 FOR FIELD r_api.
  PARAMETERS r_api RADIOBUTTON GROUP rad DEFAULT 'X' USER-COMMAND sel.
  SELECTION-SCREEN COMMENT 47(15) TEXT-005 FOR FIELD r_file.
  PARAMETERS r_file RADIOBUTTON GROUP rad.
SELECTION-SCREEN END OF LINE.

  PARAMETERS: p_dest   TYPE string LOWER CASE,  " Destination via variant: SCO_APIM_SVG of 'SCO_CPI_SVG'
              p_pstfix TYPE string LOWER CASE,  " Postfix via variant: SCO-SVG-StockAmount/api/1.0/entity/stock-amount.ws of '/http/sco/svg'
              p_file TYPE char100 LOWER CASE MODIF ID f1. " via variant

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-007.
  PARAMETERS cb_test TYPE abap_bool AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b3.

CONSTANTS zserv_type TYPE string VALUE 'Z_OS_TYPE_VESTIGING'.
CONSTANTS zstck      TYPE char30 VALUE 'ZSVG_STOCKAMOUNTS'.
CONSTANTS zstck_auto TYPE string VALUE 'Z_OS_SERVICEAUTO'.

TYPES tt_stock TYPE TABLE OF zsvg_stockamounts WITH KEY hostpartid hostlocid.

DATA stockamounts TYPE tt_stock. " result table
DATA(svg_class) = NEW zcl_s4_to_svg( ). " Initiate class to use applicable methods
DATA ShelfLife TYPE sy-datum.
DATA ls_screen TYPE screen.

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
" Start data selection
" -----------------------------------------------------------------------

START-OF-SELECTION.
  " -----------------------------------------------------------------------
  " Create where_clause based on variables from zzns_variabelen table (ZSVG_STOCKAMOUNTS)
  " Output will look something like:
  " ( ProductType EQ 'Z005' OR ProductType EQ 'Z013' ) AND ( ProductGroup EQ 'FICTIEF' OR etc....
  " -----------------------------------------------------------------------
  TRY.
      DATA(where_clause) = svg_class->create_where_clause( name = zstck
                                                           ref  = zstck ).
    CATCH cx_sy_itab_line_not_found.
      MESSAGE |Error: key { zstck } not found| TYPE 'E'.
  ENDTRY.

  " Selection of values maintained in the zzns_variabelen table for Plant and Service Cars. (concerning: Z_OS_SERVICEAUTO / Z_OS_TYPE_VESTIGING)
  SELECT FROM zzns_variabelen
    FIELDS substring( low, 1, 4 ) AS Plant, " Values saved in zzns_var as A020-SAA5
           substring( low, 6, 4 ) AS Car

    WHERE ( name = @zstck_auto OR name = @zserv_type )
      AND ( ref  = @zstck_auto OR ref  = @zserv_type )

    INTO TABLE @DATA(plants).

  " Remove / clean-up duplicates from Plant/Car combination
  DATA(car) = plants.
  DELETE plants WHERE car IS NOT INITIAL.
  SORT plants BY plant.
  DELETE ADJACENT DUPLICATES FROM plants COMPARING plant.
  DELETE car WHERE car IS INITIAL.

  " --------------------------------------------------------------------------------------------
  " Use the created where_clause to collect data from various DB tables using (custom) CDS views
  " --------------------------------------------------------------------------------------------

  IF full_chk = abap_true. " Full load
    SELECT
      FROM zc_stockamounts_extwg( P_DisplayCurrency = 'EUR' ) AS stock
             INNER JOIN
               @plants AS pc ON pc~plant = stock~Plant
                 LEFT JOIN
                   zc_aggr_batch_stloc AS ba ON ba~Plant = pc~plant AND ba~Product = stock~Product

      FIELDS stock~Product                                                                       AS HostPartID,
             stock~Plant                                                                         AS HostlocID,

             SUM( CASE
                WHEN stock~StorageLocation IN ( 'S010', 'S020', 'S100', 'S820', 'S830', 'SJIS' )
                THEN MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END              )                                                                  AS OnHandNew,
             SUM( CASE
                WHEN stock~StorageLocation    IN ( 'V200', 'V810', 'V825' )
                THEN MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS OnHandBad,

             SUM( CASE
                WHEN stock~StorageLocation    IN ( 'S020', 'S100' )
                THEN MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom1,
             SUM( CASE
                WHEN stock~StorageLocation = 'S200'
                THEN MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom2,
             SUM( CASE
                WHEN stock~StorageLocation    IN ( 'S820', 'S830' )
                THEN MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom3,
             SUM( CASE
                WHEN stock~StorageLocation = 'S010'
                THEN MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom4,
             SUM( CASE
                WHEN stock~StorageLocation = 'SJIS'
                THEN MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom5,
             0                                                                                   AS AmountCustom6,
             ba~ShelfLife                                                                        AS AmountCustom7

      WHERE (where_clause)
        AND stock~Product IN @so_matnr
        AND stock~\_Product-ZZ1_OS_XelusRelevant_PRD = @abap_true
        AND InventoryStockType IN ( '01', '02', '07' )
        AND ValuationAreaType   = '1'
        AND stock~StorageLocation    IS NOT INITIAL

      GROUP BY stock~Product,
               stock~Plant,
               ba~ShelfLife

      ORDER BY stock~Product
      INTO TABLE @stockamounts.

    " Selection specific for plants with service car
    SELECT
      FROM zc_stockamounts_extwg( P_DisplayCurrency = 'EUR' ) AS stock
             INNER JOIN
               @car AS car ON car~plant = stock~Plant AND car~car = stock~StorageLocation

      FIELDS stock~Product                           AS HostPartID,
             stock~Plant                             AS HostlocID,
             SUM( MatlWrhsStkQtyInMatlBaseUnit )     AS AmountCustom6

      WHERE (where_clause)
        AND stock~Product IN @so_matnr
        AND stock~\_Product-ZZ1_OS_XelusRelevant_PRD = @abap_true
        AND InventoryStockType IN ( '01', '02', '07' )
        AND ValuationAreaType   = '1'
        AND stock~StorageLocation    IS NOT INITIAL

      GROUP BY stock~Product,
               stock~Plant

      INTO TABLE @DATA(cars).

    " When stock found in service car(s) add to output table based on Product/Plant
    LOOP AT cars ASSIGNING FIELD-SYMBOL(<cars>).
      READ TABLE stockamounts WITH KEY hostpartid = <cars>-hostpartid
                                       hostlocid  = <cars>-hostlocid
           ASSIGNING FIELD-SYMBOL(<stock>).
      IF <stock> IS ASSIGNED.
        <stock>-amountcustom6 = <cars>-amountcustom6.
      ENDIF.
    ENDLOOP.

    DELETE stockamounts
           WHERE     OnHandNew     = 0
                 AND OnHandBad     = 0
                 AND AmountCustom1 = 0
                 AND AmountCustom2 = 0
                 AND AmountCustom3 = 0
                 AND AmountCustom4 = 0
                 AND AmountCustom5 = 0
                 AND AmountCustom6 = 0. " For full load, remove lines where stock = 0

  ELSE. " Partial load

    SELECT
      FROM zc_stockamounts_extwg( P_DisplayCurrency = 'EUR' ) AS stock
             INNER JOIN
               @plants AS pc ON pc~plant = stock~Plant
                 LEFT JOIN
                   I_MaterialStock_2 AS mat ON mat~Material = stock~Product AND mat~Plant = stock~Plant AND mat~StorageLocation = stock~StorageLocation
                     LEFT JOIN
                       zc_aggr_batch_stloc AS ba ON ba~Plant = pc~plant AND ba~Product = stock~Product

      FIELDS stock~Product                                                                       AS HostPartID,
             stock~Plant                                                                         AS HostlocID,

             SUM( CASE
                WHEN stock~StorageLocation IN ( 'S010', 'S020', 'S100', 'S820', 'S830', 'SJIS' )
                THEN stock~MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END              )                                                                  AS OnHandNew,
             SUM( CASE
                WHEN stock~StorageLocation    IN ( 'V200', 'V810', 'V825' )
                THEN stock~MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS OnHandBad,

             SUM( CASE
                WHEN stock~StorageLocation    IN ( 'S020', 'S100' )
                THEN stock~MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom1,
             SUM( CASE
                WHEN stock~StorageLocation = 'S200'
                THEN stock~MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom2,
             SUM( CASE
                WHEN stock~StorageLocation    IN ( 'S820', 'S830' )
                THEN stock~MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom3,
             SUM( CASE
                WHEN stock~StorageLocation = 'S010'
                THEN stock~MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom4,
             SUM( CASE
                WHEN stock~StorageLocation = 'SJIS'
                THEN stock~MatlWrhsStkQtyInMatlBaseUnit
                ELSE 0
             END        )                                                                        AS AmountCustom5,
             0                                                                                   AS AmountCustom6,
             ba~ShelfLife                                                                        AS AmountCustom7

      WHERE (where_clause)
        AND stock~\_Product-ZZ1_OS_XelusRelevant_PRD = @abap_true
        AND stock~InventoryStockType IN ( '01', '02', '07' )
        AND ValuationAreaType   = '1'
        AND stock~StorageLocation    IS NOT INITIAL
        AND MatlDocLatestPostgDate >= @p_frdate
        AND MatlDocLatestPostgDate <= @p_todate

      GROUP BY stock~Product,
               stock~Plant,
               ba~ShelfLife

      ORDER BY stock~Product
      INTO TABLE @stockamounts.

    " Selection specific for plants with service car(s)
    SELECT
      FROM zc_stockamounts_extwg( P_DisplayCurrency = 'EUR' ) AS stock
             INNER JOIN
               @car AS car ON car~plant = stock~Plant AND car~car = stock~StorageLocation

      FIELDS stock~Product                           AS HostPartID,
             stock~Plant                             AS HostlocID,
             SUM( MatlWrhsStkQtyInMatlBaseUnit )     AS AmountCustom6

      WHERE (where_clause)
        AND stock~Product IN @so_matnr
        AND stock~\_Product-ZZ1_OS_XelusRelevant_PRD = @abap_true
        AND InventoryStockType IN ( '01', '02', '07' )
        AND ValuationAreaType   = '1'
        AND stock~StorageLocation    IS NOT INITIAL

      GROUP BY stock~Product,
               stock~Plant

      INTO TABLE @DATA(cars_2).

    " When stock found in service car(s) add to output table based on Product/Plant
    LOOP AT cars_2 ASSIGNING FIELD-SYMBOL(<cars_2>).
      READ TABLE stockamounts WITH KEY hostpartid = <cars_2>-hostpartid
                                       hostlocid  = <cars_2>-hostlocid
           ASSIGNING FIELD-SYMBOL(<stock_2>).
      IF <stock_2> IS ASSIGNED.
        <stock_2>-amountcustom6 = <cars_2>-amountcustom6.
      ENDIF.
    ENDLOOP.

  ENDIF.

  " When no data is found for the selection, end query
  IF stockamounts IS INITIAL.
    WRITE / TEXT-008.
    RETURN.
  ENDIF.

  " -----------------------------------------------------------------------
  " Sent out table with selected data as JSON or CSV
  " -----------------------------------------------------------------------

  IF cb_test <> abap_true. " Excluded for testing

    IF r_api = abap_true.

      " Sent out orderplan_atb table
      CALL FUNCTION 'ZSVG_SEND_FILE_JSON'
        EXPORTING
          iv_destination  = p_dest
          iv_path_postfix = p_pstfix
          it_table        = stockamounts.
    ENDIF.

    IF r_file = abap_true.

      " Sent out orderplan_atb table
      CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
        EXPORTING
          iv_destination  = p_dest
          iv_path_postfix = p_pstfix
          iv_filename     = p_file
          it_table        = stockamounts.

    ENDIF.

  ENDIF.

  " -----------------------------------------------------------------------
  " Create ALV (test modus only)
  " -----------------------------------------------------------------------
  IF stockamounts IS NOT INITIAL AND cb_test = abap_true.

    svg_class->display_alv( table = REF #( stockamounts )
                            title = 'Stock Amounts selection' ).

  ELSE.
    RETURN.
  ENDIF.