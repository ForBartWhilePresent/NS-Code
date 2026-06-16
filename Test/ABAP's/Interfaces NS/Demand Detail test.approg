*&---------------------------------------------------------------------*
*& Report zsvg_send_demanddetail_test
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsvg_send_demanddetail_test.


INCLUDE zsvg_send_demanddetailtop. "data declaratie


************************************************************************
*                     Selection screen                                 *
************************************************************************
SELECTION-SCREEN: BEGIN OF BLOCK b1.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(33) TEXT-002 FOR FIELD p_frdate.
    PARAMETERS: p_frdate TYPE sy-datum OBLIGATORY DEFAULT sy-datum. "Created/Changed Date

    SELECTION-SCREEN COMMENT 48(10) TEXT-003 FOR FIELD p_todate.
    PARAMETERS: p_todate TYPE sy-datum OBLIGATORY DEFAULT sy-datum. "Created/Changed Date
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(33) TEXT-004 FOR FIELD p_frtime. "Created/Changed Time
    PARAMETERS: p_frtime TYPE syst_uzeit.

    SELECTION-SCREEN COMMENT 48(10) TEXT-003 FOR FIELD p_totime. "Created/Changed Time
    PARAMETERS: p_totime TYPE syst_uzeit.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b1.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN: BEGIN OF BLOCK b2.
* Selection screen elements
  SELECT-OPTIONS: so_docnm  FOR mkpf-mblnr,     "Material Document Number
                  so_maint  FOR viaufks-aufnr,  "Maintenance Order
                  so_sales FOR vbak-vbeln.      "Sales Order

SELECTION-SCREEN: END OF BLOCK b2.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN: BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-001. "Details/Orders to send
  PARAMETERS: cb_matdc TYPE abap_bool AS CHECKBOX DEFAULT 'X', "Material Documents
              cb_maint TYPE abap_bool AS CHECKBOX DEFAULT 'X', "Maintenance Orders
              cb_sales TYPE abap_bool AS CHECKBOX DEFAULT 'X'. "Sales Orders
SELECTION-SCREEN: END OF BLOCK b3.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN: BEGIN OF BLOCK b4.

  SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(33) TEXT-s01 FOR FIELD P_json.
  PARAMETERS P_json RADIOBUTTON GROUP fle DEFAULT 'X' USER-COMMAND sel.
  SELECTION-SCREEN COMMENT 47(20) TEXT-s02 FOR FIELD P_csv.
  PARAMETERS P_csv RADIOBUTTON GROUP fle.
  SELECTION-SCREEN END OF LINE.

  PARAMETERS: p_destin TYPE char40 .              "Destination
  PARAMETERS: p_path   TYPE char100 LOWER CASE .  "Path postfix
  PARAMETERS: p_file   TYPE char100 LOWER CASE .  "File Naam

  SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN: END OF BLOCK b4.


SELECTION-SCREEN: BEGIN OF BLOCK b5 WITH FRAME.
  PARAMETERS: cb_test TYPE abap_bool AS CHECKBOX DEFAULT 'X'. "Test
SELECTION-SCREEN: END OF BLOCK b5.

*---

************************************************************************
*             Loop AT Selection screen                                 *
************************************************************************

AT SELECTION-SCREEN OUTPUT.
  DATA ls_screen TYPE screen.


  IF      P_json = abap_true.

    LOOP AT SCREEN INTO ls_screen.
      CASE ls_screen-name.
        WHEN 'P_DESTIN' OR 'P_PATH'.
          ls_screen-active = 1.
          ls_screen-input  = 1.
          MODIFY SCREEN FROM ls_screen.

        WHEN 'P_FILE'.
          ls_screen-active = 0.
          ls_screen-input  = 0.
          MODIFY SCREEN FROM ls_screen.
        WHEN '%_P_FILE_%_APP_%-TEXT'.
          ls_screen-active = 0.
          MODIFY SCREEN FROM ls_screen.
      ENDCASE.

    ENDLOOP.


  ELSEIF  P_csv  = abap_true.
    LOOP AT SCREEN INTO ls_screen.
      CASE ls_screen-name.
        WHEN 'P_FILE'.
          IF P_csv = abap_true.
            ls_screen-active = 1.
            ls_screen-input  = 1.
          ENDIF.
          MODIFY SCREEN FROM ls_screen.
        WHEN '%_P_FILE_%_APP_%-TEXT'.
          ls_screen-active = 1.
          MODIFY SCREEN FROM ls_screen.
      ENDCASE.
    ENDLOOP.
  ENDIF.

************************************************************************
*                  AT Selection screen                                 *
************************************************************************
AT SELECTION-SCREEN.

  " 1) Wisselen via radiobuttons
  IF sy-ucomm = 'SEL'.

    IF P_json  = abap_true.
      " Terug naar API: file-veld niet meer relevant
      CLEAR p_file.
    ELSEIF P_csv = abap_true.
      " Naar FILE: focus op p_file
      SET CURSOR FIELD 'P_FILE'.
    ENDIF.

    RETURN. " geen verdere checks bij wisselen
  ENDIF.

  " 2) Validatie alleen bij Execute (F8)

  IF sy-ucomm = 'ONLI'.

    " Altijd verplicht bij uitvoeren: bestemming + postfix
    IF p_destin IS INITIAL OR p_path IS INITIAL.
      MESSAGE 'Vul bestemming en postfix in.' TYPE 'E'.
    ENDIF.

    " Bij FILE ook p_file verplicht
    IF P_csv = abap_true AND p_file IS INITIAL.
      MESSAGE 'Vul ook het bestandsveld in (FILE-modus).' TYPE 'E'.
    ENDIF.

  ENDIF.



************************************************************************
*                     INITIALIZATION                                   *
************************************************************************

INITIALIZATION.
*  p_destin = gc_destination.
*  p_path   = gc_path_postfix.


  INCLUDE zsvg_send_demanddtl_test:

  *&---------------------------------------------------------------------*
*& Include zsvg_send_demanddtl_test
*&---------------------------------------------------------------------*

FORM MaterialPostingsFetch .
* Materiaal documenten

*Selection of Material Document psotings Created in the specific period and related data fetches.
  SELECT * FROM mkpf
    INTO TABLE lt_mkpf
    WHERE ( cpudt >= p_frdate
          OR ( cpudt = p_frdate AND cputm >= p_frtime ) )
    AND ( cpudt <= p_todate
          OR ( cpudt = p_todate AND cputm <= p_totime ) )
    AND mblnr IN so_docnm.


  IF sy-subrc = 0 AND lt_mkpf IS NOT INITIAL.
    SELECT mseg~*
      FROM mseg
      INNER JOIN mara ON mseg~matnr = mara~matnr
      INTO TABLE @lt_mseg
      FOR ALL ENTRIES IN @lt_mkpf
      WHERE mseg~mblnr = @lt_mkpf-mblnr
      AND mseg~mjahr = @lt_mkpf-mjahr
      AND mara~zz1_os_xelusrelevant_prd = 'X'.
  ENDIF.


*check op LT_VARTAB, variabelen tabel
  LOOP AT lt_mseg INTO ls_mseg.
    LOOP AT lt_vartab INTO ls_vartab
      WHERE param1 = ls_mseg-bwart.
    ENDLOOP.
    IF sy-subrc = 0.
      CONTINUE.
    ELSE.
      DELETE lt_mseg.
    ENDIF.
  ENDLOOP.


  IF lt_mseg IS NOT INITIAL.
    SELECT * FROM lips INTO TABLE lt_lips
      FOR ALL ENTRIES IN lt_mseg
      WHERE vbeln = lt_mseg-vbeln_im
      AND posnr = lt_mseg-vbelp_im.
    IF sy-subrc = 0.
      SELECT * FROM vbak INTO TABLE lt_vbak
        FOR ALL ENTRIES IN lt_lips
        WHERE vbeln = lt_lips-vgbel.
    ENDIF.
  ENDIF.

* entries ophalen en itab lt_file1 vullen.
  IF lt_mseg IS NOT INITIAL.
    CALL FUNCTION 'ZSVG_GET_MATERIALPOSTINGS'
      IMPORTING
        et_output = lt_file1
      TABLES
        it_mseg   = lt_mseg
        it_mkpf   = lt_mkpf
        it_vartab = lt_vartab
        it_vbak   = lt_vbak
        it_lips   = lt_lips.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form MaintenanceOrdersFetch
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM MaintenanceOrdersFetch.

  REFRESH lt_out.

* ----- STEP 1: Created Maintenance Orders ----------
  " Verbind changedocument met componenten (set-based join)
  SELECT
    FROM i_maintordchangedocumentdex AS doc
         INNER JOIN i_maintordercomponentdex AS comp ON comp~maintenanceorder = doc~maintenanceorder
         INNER JOIN I_Product AS Prod ON Prod~Product = comp~material
         INNER JOIN resb AS res ON res~rsnum = comp~reservation AND res~rspos = comp~reservationitem
         INNER JOIN viaufks AS via ON via~aufnr = doc~maintenanceorder

    FIELDS  Prod~Product,
            Prod~zz1_os_xelusrelevant_prd,
            reservation,
            reservationitem,
            doc~maintenanceorder,
            maintordercomponentinternalid,
            doc~creationdate,
            storagelocation,
            material,
            requirementquantityinbaseunit,
            maintorderopcomponentsorttext,
            quantitywithdrawninbaseunit,
            res~werks, res~bdmng, res~meins, res~wempf, res~potx2,
            via~ilart, via~tplnr, via~gstrp

    WHERE ( doc~creationdate >= @p_frdate
         OR ( doc~creationdate = @p_frdate AND doc~creationtime >= @p_frtime ) )
      AND ( doc~creationdate <= @p_todate
         OR ( doc~creationdate = @p_todate AND doc~creationtime <= @p_totime ) )
      AND doc~databasetable = 'RESB'
      AND doc~changedocitemchangetype = 'I'
      AND doc~maintenanceorder IN @so_maint
      AND comp~storagelocation LIKE 'S%'
      AND comp~maintorderopcomponentsorttext IS INITIAL
      AND Prod~zz1_os_xelusrelevant_prd = 'X'
    INTO TABLE @DATA(lt_comp1).

  DELETE ADJACENT DUPLICATES FROM lt_comp1 COMPARING reservation reservationitem maintenanceorder MaintOrderComponentInternalID.

* ----- STEP 2: Changed Maintenance Orders ----------
  " Verbind changedordchghistory met componenten

  SELECT FROM i_maintordchghistory AS chg
        INNER JOIN viaufks AS via ON via~aufnr = chg~changedocobject
         INNER JOIN i_maintordercomponentdex AS comp ON comp~maintenanceorder = chg~changedocobject
           INNER JOIN mara AS ma ON ma~matnr = comp~material
             INNER JOIN resb AS res ON res~rsnum = comp~reservation AND res~rspos = comp~reservationitem

    FIELDS reservation,
         reservationitem,
         maintenanceorder,
         maintordercomponentinternalid,
         storagelocation,
         material,
         requirementquantityinbaseunit,
         maintorderopcomponentsorttext,
         quantitywithdrawninbaseunit,
         chg~creationdate,
         chg~databasetable,
         chg~changedocdatabasetablefield,
         chg~changedocnewfieldvalue,
         chg~ChangeDocObject,
         chg~changedocpreviousfieldvalue,
         chg~changedoctablekey,
         ma~zz1_os_xelusrelevant_prd,
         res~werks, res~bdmng, res~meins, res~wempf, res~potx2,
         via~ilart, via~tplnr, via~gstrp

    WHERE ( chg~creationdate >= @p_frdate
         OR ( chg~creationdate = @p_frdate AND chg~creationtime >= @p_frtime ) )
      AND ( chg~creationdate <= @p_todate
         OR ( chg~creationdate = @p_todate AND chg~creationtime <= @p_totime ) )
      AND chg~changedocobject IN @so_maint
      AND chg~databasetable IN ('RESB', 'TJ30')
      AND chg~changedocdatabasetablefield IN ('BDMNG', 'ESTAT', 'XLOEK')
      AND ma~zz1_os_xelusrelevant_prd = 'X'
    INTO TABLE @DATA(lt_comp2).


  " JCDS status ophalen via join
  SELECT FROM @lt_comp2 AS comp
       INNER JOIN jcds ON jcds~objnr = concat( 'OR', comp~maintenanceorder )

    FIELDS jcds~objnr, jcds~stat, jcds~inact

    WHERE jcds~stat  = 'E0011'
      AND jcds~inact = ' '
    INTO TABLE @DATA(jcds).

  DELETE ADJACENT DUPLICATES FROM jcds COMPARING objnr.

* --------- OUTPUT LOGIC ----------
  LOOP AT lt_comp1 INTO DATA(ls_comp1_new).
    CLEAR: lv_quan, lv_key, lv_demstream, ls_vartab,
           ls_out.

    IF ls_comp1_new-storagelocation CP 'S*' AND ls_comp1_new-maintorderopcomponentsorttext IS INITIAL.

      IF ls_comp1_new-ilart = 'X3' OR ls_comp1_new-ilart = 'X16'.
        READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ' ' low = ls_comp1_new-ilart.
        IF sy-subrc = 0.
          lv_demstream = ls_vartab-param1.
        ENDIF.
      ELSE.
        READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_comp1_new-wempf low = ls_comp1_new-ilart.
        lv_demstream = ls_vartab-param1.
      ENDIF.
      CONCATENATE ls_comp1_new-maintenanceorder ls_comp1_new-potx2 lv_demstream
                  INTO lv_key SEPARATED BY lc_separ.
      lv_quan = ls_comp1_new-bdmng.
      SHIFT lv_quan LEFT DELETING LEADING space.

      READ TABLE lt_out INTO ls_out WITH KEY hostdmddetailid = lv_key.
      IF sy-subrc = 0.
        lv_quan += ls_out-historyamount.
        ls_out-historyamount = lv_quan.
        MODIFY lt_out FROM ls_out INDEX sy-tabix.
      ELSE.
        ls_out-hostdmddetailid = lv_key.
        ls_out-hostpartid      = ls_comp1_new-Product.
        ls_out-hostlocid       = ls_comp1_new-werks.
        ls_out-dshostid        = lv_demstream.
        ls_out-historybegdate  = ls_comp1_new-gstrp.
        ls_out-historyamount   = lv_quan.
        ls_out-demandnote      = ls_comp1_new-tplnr.
        IF lv_key <> space.
          APPEND ls_out TO lt_out.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_comp2 INTO DATA(ls_comp2_new).
    " CASE2 - Maintenance Order Status Change to Close (SLUI)
    IF ls_comp2_new-databasetable = 'TJ30' AND ls_comp2_new-changedocdatabasetablefield = 'ESTAT' AND ls_comp2_new-changedocnewfieldvalue = 'SLUI'.
      CLEAR: lv_quan, lv_demstream, ls_vartab, ls_out.
      IF ls_comp2_new-storagelocation CP 'S*' AND ls_comp2_new-maintorderopcomponentsorttext IS INITIAL AND ls_comp2_new-zz1_os_xelusrelevant_prd = 'X'.

        IF ls_comp2_new-ilart = 'X3' OR ls_comp2_new-ilart = 'X16'.
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ' ' low = ls_comp2_new-ilart.
          IF sy-subrc = 0.
            lv_demstream = ls_vartab-param1.
          ENDIF.
        ELSE.
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_comp2_new-wempf low = ls_comp2_new-ilart.
          lv_demstream = ls_vartab-param1.
        ENDIF.

        CONCATENATE ls_comp2_new-changedocobject ls_comp2_new-potx2 lv_demstream INTO lv_key SEPARATED BY lc_separ.
      ENDIF.

      DATA(maintenance_order_objnr) = |OR{ ls_comp2_new-changedocobject }|.
      READ TABLE jcds TRANSPORTING NO FIELDS WITH KEY objnr = maintenance_order_objnr.
      IF sy-subrc = 0.
        " Values remain.
      ELSE.
        READ TABLE lt_out INTO ls_out WITH KEY hostdmddetailid = lv_key.
        IF sy-subrc = 0.
          LOOP AT lt_out ASSIGNING FIELD-SYMBOL(<fs_out>).
            IF <fs_out>-hostdmddetailid(10) = lv_key(10).
              <fs_out>-historyamount = 0.
            ENDIF.
          ENDLOOP.
        ELSE.
          IF lv_demstream = space.
            SPLIT lv_key AT lc_separ INTO lv_split_01 lv_split_02 lv_demstream.
          ENDIF.
          ls_out-hostdmddetailid = lv_key.
          ls_out-hostpartid      = ls_comp2_new-Material.
          ls_out-hostlocid       = ls_comp2_new-werks.
          ls_out-dshostid        = lv_demstream.
          ls_out-historybegdate  = ls_comp2_new-gstrp.
          ls_out-historyamount   = 0.
          ls_out-demandnote      = ls_comp2_new-tplnr.
          IF lv_key <> space.
            APPEND ls_out TO lt_out.
          ENDIF.
        ENDIF.
      ENDIF.

      " CASE3 - Maintenance Order Status Change to Cancelled (ANNU)
    ELSEIF ls_comp2_new-databasetable = 'TJ30' AND ls_comp2_new-changedocdatabasetablefield = 'ESTAT' AND ls_comp2_new-changedocnewfieldvalue = 'ANNU'.
      CLEAR: lv_quan, lv_key, lv_demstream, ls_vartab, ls_out.
      IF ls_comp2_new-storagelocation CP 'S*' AND ls_comp2_new-maintorderopcomponentsorttext IS INITIAL AND ls_comp2_new-zz1_os_xelusrelevant_prd = 'X'.

        IF ls_comp2_new-ilart = 'X3' OR ls_comp2_new-ilart = 'X16'.
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ' ' low = ls_comp2_new-ilart.
          IF sy-subrc = 0.
            lv_demstream = ls_vartab-param1.
          ENDIF.
        ELSE.
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_comp2_new-wempf low = ls_comp2_new-ilart.
          lv_demstream = ls_vartab-param1.
        ENDIF.
        CONCATENATE ls_comp2_new-changedocobject ls_comp2_new-potx2 lv_demstream INTO lv_key SEPARATED BY lc_separ.
        lv_quan = 0.
        READ TABLE lt_out INTO ls_out WITH KEY hostdmddetailid = lv_key.
        IF sy-subrc = 0.
          ls_out-historyamount = lv_quan.
          MODIFY lt_out FROM ls_out INDEX sy-tabix.
        ELSE.
          ls_out-hostdmddetailid = lv_key.
          ls_out-hostpartid      = ls_comp2_new-Material.
          ls_out-hostlocid       = ls_comp2_new-werks.
          ls_out-dshostid        = lv_demstream.
          ls_out-historybegdate  = ls_comp2_new-gstrp.
          ls_out-historyamount   = lv_quan.
          ls_out-demandnote      = ls_comp2_new-tplnr.
          IF lv_key <> space.
            APPEND ls_out TO lt_out.
          ENDIF.
        ENDIF.
      ENDIF.

      " CASE4 - Maintenance Order Quantity has been adjusted
    ELSEIF ls_comp2_new-databasetable = 'RESB' AND ls_comp2_new-changedocdatabasetablefield = 'BDMNG'.
      CLEAR: lv_quan, lv_new, lv_key, lv_demstream, ls_vartab, ls_out.
      IF ls_comp2_new-storagelocation CP 'S*' AND ls_comp2_new-maintorderopcomponentsorttext IS INITIAL AND ls_comp2_new-zz1_os_xelusrelevant_prd = 'X'.

        IF ls_comp2_new-ilart = 'X3' OR ls_comp2_new-ilart = 'X16'.
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ' ' low = ls_comp2_new-ilart.
          IF sy-subrc = 0.
            lv_demstream = ls_vartab-param1.
          ENDIF.
        ELSE.
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_comp2_new-wempf low = ls_comp2_new-ilart.
          lv_demstream = ls_vartab-param1.
        ENDIF.
        CONCATENATE ls_comp2_new-changedocobject ls_comp2_new-potx2 lv_demstream INTO lv_key SEPARATED BY lc_separ.
        lv_new += ls_comp2-requirementquantityinbaseunit.
        lv_quan = lv_new.
      ENDIF.

      SHIFT ls_comp2_new-changedocpreviousfieldvalue LEFT DELETING LEADING space.
      lv_old = ls_comp2_new-changedocpreviousfieldvalue.
      IF lv_new <> lv_old.
        lv_quan = lv_new.
        READ TABLE lt_out INTO ls_out WITH KEY hostdmddetailid = lv_key.
        IF sy-subrc = 0.
          ls_out-historyamount = lv_quan.
          MODIFY lt_out FROM ls_out INDEX sy-tabix.
        ELSE.
          ls_out-hostdmddetailid = lv_key.
          ls_out-hostpartid      = ls_comp2_new-Material.
          ls_out-hostlocid       = ls_comp2_new-werks.
          ls_out-dshostid        = lv_demstream.
          ls_out-historybegdate  = ls_comp2_new-gstrp.
          ls_out-historyamount   = lv_quan.
          ls_out-demandnote      = ls_comp2_new-tplnr.
          IF lv_key <> space.
            APPEND ls_out TO lt_out.
          ENDIF.
        ENDIF.
      ENDIF.

      " CASE5 - Maintenance Order Quantity has been deleted
    ELSEIF ls_comp2_new-databasetable = 'RESB' AND ls_comp2_new-changedocdatabasetablefield = 'XLOEK'.
      CLEAR: lv_quan, lv_key, lv_demstream, ls_vartab, ls_out.
.
      IF ls_comp2_new-ilart = 'X3' OR ls_comp2_new-ilart = 'X16'.
        READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ' ' low = ls_viaufks2-ilart.
        IF sy-subrc = 0.
          lv_demstream = ls_vartab-param1.
        ENDIF.
      ELSE.
        READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_comp2_new-wempf low = ls_comp2_new-ilart.
        lv_demstream = ls_vartab-param1.
      ENDIF.
      CONCATENATE ls_comp2_new-changedocobject ls_comp2_new-potx2 lv_demstream INTO lv_key SEPARATED BY lc_separ.
      lv_quan = 0.
      READ TABLE lt_out INTO ls_out WITH KEY hostdmddetailid = lv_key.
      IF sy-subrc = 0.
        ls_out-historyamount = lv_quan.
        MODIFY lt_out FROM ls_out INDEX sy-tabix.
      ELSE.
        ls_out-hostdmddetailid = lv_key.
        ls_out-hostpartid      = ls_comp2_new-Material.
        ls_out-hostlocid       = ls_comp2_new-werks.
        ls_out-dshostid        = lv_demstream.
        ls_out-historybegdate  = ls_comp2_new-gstrp.
        ls_out-historyamount   = lv_quan.
        ls_out-demandnote      = ls_comp2_new-tplnr.
        IF lv_key <> space.
          APPEND ls_out TO lt_out.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDLOOP.

  REFRESH lt_file2.
  lt_file2 = lt_out.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SalesOrdersFetch
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SalesOrdersFetch .
* Verkoops orders

  DATA: lv_len TYPE i.

  REFRESH lt_out[].

*Selection of Sales Orders Created in the specific period and related data fetches
*using CDS view i_salesorderitem
  SELECT i_salesorderitem~*
    FROM i_salesorderitem
    INNER JOIN mara ON i_salesorderitem~material = mara~matnr
    WHERE salesorder IN @so_sales
    AND ( creationdate >= @p_frdate
        OR ( creationdate >= @p_frdate AND creationtime >= @p_frtime ) )
    AND ( creationdate <= @p_todate
          OR ( creationdate <= @p_todate AND creationtime <= @p_totime ) )
    AND mara~zz1_os_xelusrelevant_prd = 'X'
    INTO TABLE @lt_sales.

  IF sy-subrc = 0.
    SELECT  *
      FROM  mara
      INTO  TABLE lt_mara2
       FOR  ALL ENTRIES IN lt_sales
     WHERE  matnr = lt_sales-material.

*using CDS view i_salesorder
    SELECT  *
      FROM  i_salesorder
      INTO  TABLE @lt_order
       FOR  ALL ENTRIES IN @lt_sales
     WHERE  salesorder = @lt_sales-salesorder.

*using CDS view c_saleschangedocumentdex to get the changes in sales order quantity and cancellations
    SELECT  databasetable,
            changedocdatabasetablefield,
            salesdocument,
            salesdocumentitem,
            changedocnewfieldvalue
      FROM  C_SalesChangeDocItemDEX
      INTO  TABLE @lt_salesch
     WHERE  ( databasetable = 'VBEP' OR databasetable = 'VBAP' )
       AND  ( changedocdatabasetablefield = 'BMENG' OR changedocdatabasetablefield = 'ABGRU' )
       AND  salesdocument IN @so_sales
       AND  ( creationdate >= @p_frdate
        OR ( creationdate >= @p_frdate AND creationtime >= @p_frtime ) )
       AND ( creationdate <= @p_todate
        OR ( creationdate <= @p_todate AND creationtime <= @p_totime ) ).
    IF sy-subrc = 0.
*using CDS view i_salesorderitem
      SELECT  salesorder,
              salesorderitem,
              material,
              plant,
              orderquantity,
              orderquantityunit,
              ordertobasequantitydnmntr,
              ordertobasequantitynmrtr,
              committeddeliverydate
        FROM  i_salesorderitem
       INNER JOIN mara ON i_salesorderitem~material = mara~matnr
         FOR ALL ENTRIES IN @lt_salesch
       WHERE salesorder = @lt_salesch-salesdocument
        AND mara~zz1_os_xelusrelevant_prd = 'X'
       INTO TABLE @lt_sales1.

      SELECT  *
        FROM  mara
        INTO  TABLE lt_mara3
         FOR  ALL ENTRIES IN lt_sales1
       WHERE  matnr = lt_sales1-material.

*using CDS view i_salesorder
      SELECT  *
        FROM  i_salesorder
        INTO  TABLE @lt_order1
         FOR  ALL ENTRIES IN @lt_sales1
       WHERE  salesorder = @lt_sales1-salesorder.
    ENDIF.
  ENDIF.

  LOOP AT lt_sales INTO ls_sales.
*CASE1 - Creation of Sales Orders
    CLEAR: lv_quan,lv_key,lv_demstream,ls_vartab,ls_out,ls_order,ls_mara2.
* Concatenate fields to get HostDmdDetailID
    CONCATENATE ls_sales-salesorder ls_sales-salesorderitem
                INTO lv_key
                SEPARATED BY lc_separ.
    READ TABLE lt_order INTO ls_order WITH KEY salesorder = ls_sales-salesorder.
    IF sy-subrc = 0.
* Get the Record from Variable table to find the Demand Stream
      READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order-salesordertype low = ls_order-soldtoparty.
      IF sy-subrc = 0.
        lv_demstream = ls_vartab-param1.
      ELSE.
        READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order-salesordertype.
        IF sy-subrc = 0.
          lv_demstream = '9'.
        ENDIF.
      ENDIF.
    ENDIF.
* Fill quantity
    READ TABLE lt_mara2 INTO ls_mara2 WITH KEY matnr = ls_sales-material.
    IF sy-subrc = 0 AND ls_mara2-meins = ls_sales-orderquantityunit.
      lv_quan = ls_sales-orderquantity.
      SHIFT lv_quan LEFT DELETING LEADING space.
    ELSE.
      lv_quan = ls_sales-orderquantity * ( ls_sales-ordertobasequantitynmrtr / ls_sales-ordertobasequantitydnmntr ).
      SHIFT lv_quan LEFT DELETING LEADING space.
    ENDIF.
*Fill the output fields with the fetched data
    ls_out-HostDmdDetailID = lv_key.
    ls_out-HostPartID      = ls_sales-material.
    ls_out-HostLocID       = ls_sales-plant.
    ls_out-DSHostID        = lv_demstream.
    ls_out-HistoryBegDate  = ls_order-requesteddeliverydate.
    ls_out-HistoryAmount   = lv_quan.
    ls_out-DemandNote      = ' '.

    APPEND ls_out TO lt_out.
  ENDLOOP.

  LOOP AT lt_salesch INTO ls_salesch.
*CASE2 - Change of Quantity in a Sales Order
    CLEAR: lv_quan,lv_key,lv_demstream,ls_vartab,ls_out,ls_sales,ls_order,ls_mara3.
    IF ls_salesch-databasetable = 'VBEP'  AND ls_salesch-changedocdatabasetablefield = 'BMENG'.
      READ TABLE lt_sales1 INTO ls_sales1 WITH KEY salesorder = ls_salesch-salesdocument salesorderitem = ls_salesch-salesdocumentitem.
      IF sy-subrc = 0.
* Concatenate fields to get HostDmdDetailID
        CONCATENATE ls_sales1-salesorder ls_sales1-salesorderitem
                    INTO lv_key
                    SEPARATED BY lc_separ.
* Fill new quantity
        READ TABLE lt_mara3 INTO ls_mara3 WITH KEY matnr = ls_sales1-material.
        IF sy-subrc = 0 AND ls_mara3-meins = ls_sales1-orderquantityunit.
          lv_quan = ls_sales1-orderquantity.
          SHIFT lv_quan LEFT DELETING LEADING space.
        ELSE.
          lv_quan = ls_sales1-orderquantity * ( ls_sales1-ordertobasequantitynmrtr / ls_sales1-ordertobasequantitydnmntr ).
          SHIFT lv_quan LEFT DELETING LEADING space.
        ENDIF.

        READ TABLE lt_order1 INTO ls_order1 WITH KEY salesorder = ls_sales1-salesorder.
        IF sy-subrc = 0.
* Get the Record from Variable table to find the Demand Stream
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order1-salesordertype low = ls_order1-soldtoparty.
          IF sy-subrc = 0.
            lv_demstream = ls_vartab-param1.
          ELSE.
            READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order1-salesordertype.
            IF sy-subrc = 0.
              lv_demstream = '9'.
            ENDIF.
          ENDIF.
        ENDIF.
*Check If line with same key already exists in the Demands Details output table.
        READ TABLE lt_out INTO ls_out WITH KEY HostDmdDetailID = lv_key.
        IF sy-subrc = 0.
          ls_out-HistoryAmount = lv_quan.
          MODIFY lt_out FROM ls_out INDEX sy-tabix.
        ELSE.
*Fill the output fields with the fetched data
          ls_out-HostDmdDetailID = lv_key.
          ls_out-HostPartID      = ls_sales1-material.
          ls_out-HostLocID       = ls_sales1-plant.
          ls_out-DSHostID        = lv_demstream.
          ls_out-HistoryBegDate  = ls_order1-requesteddeliverydate.
          ls_out-HistoryAmount   = lv_quan.
          ls_out-DemandNote      = ' '.

          APPEND ls_out TO lt_out.
        ENDIF.
      ENDIF.

*CASE3 - Cancellation of a Sales Order
    ELSEIF ls_salesch-databasetable = 'VBAP' AND ls_salesch-changedocdatabasetablefield = 'ABGRU' AND ls_salesch-changedocnewfieldvalue = 'Z1'.
      READ TABLE lt_sales1 INTO ls_sales1 WITH KEY salesorder = ls_salesch-salesdocument salesorderitem = ls_salesch-salesdocumentitem.
      IF sy-subrc = 0.
* Concatenate fields to get HostDmdDetailID
        CONCATENATE ls_sales1-salesorder ls_sales1-salesorderitem
                    INTO lv_key
                    SEPARATED BY lc_separ.
* Fill new quantity
        lv_quan = 0.
        SHIFT lv_quan LEFT DELETING LEADING space.
        READ TABLE lt_order1 INTO ls_order1 WITH KEY salesorder = ls_sales1-salesorder.
        IF sy-subrc = 0.
* Get the Record from Variable table to find the Demand Stream
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order1-salesordertype low = ls_order1-soldtoparty.
          IF sy-subrc = 0.
            lv_demstream = ls_vartab-param1.
          ELSE.
            READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order1-salesordertype.
            IF sy-subrc = 0.
              lv_demstream = '9'.
            ENDIF.
          ENDIF.
        ENDIF.
*Check If line with same key already exists in the Demands Details output table.
        READ TABLE lt_out INTO ls_out WITH KEY HostDmdDetailID = lv_key.
        IF sy-subrc = 0.
          ls_out-HistoryAmount = lv_quan.
          MODIFY lt_out FROM ls_out INDEX sy-tabix.
        ELSE.
*Fill the output fields with the fetched data
          ls_out-HostDmdDetailID = lv_key.
          ls_out-HostPartID      = ls_sales1-material.
          ls_out-HostLocID       = ls_sales1-plant.
          ls_out-DSHostID        = lv_demstream.
          ls_out-HistoryBegDate  = ls_order1-requesteddeliverydate.
          ls_out-HistoryAmount   = lv_quan.
          ls_out-DemandNote      = ' '.

          APPEND ls_out TO lt_out.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.


*using CDS view i_salesorderitmsubsqntprocflow
  SELECT  *
    FROM  i_salesorderitmsubsqntprocflow
   WHERE ( creationdate >= @p_frdate
      OR ( creationdate >= @p_frdate AND creationtime >= @p_frtime ) )
     AND ( creationdate <= @p_todate
      OR ( creationdate <= @p_todate AND creationtime <= @p_totime ) )
     AND  subsequentdocumentcategory = 'H' "(Retourorder)
    INTO  TABLE @lt_return.


  DESCRIBE TABLE lt_return LINES lv_len.
  IF lv_len > 0.
* oorspronkelijke verkooporder
    SELECT  *
      FROM  i_salesorderitem
       FOR  ALL ENTRIES IN @lt_return
     WHERE  salesorder     = @lt_return-salesorder
       AND  salesorderitem = @lt_return-salesorderitem
      INTO  TABLE @lt_sales_orgl.
* retourregel van de oorspronkelijke verkooporder
    SELECT  *
      FROM  i_customerreturnitem
       FOR  ALL ENTRIES IN @lt_return
     WHERE  customerreturn     = @lt_return-subsequentdocument
       AND  customerreturnitem = @lt_return-subsequentdocumentitem
      INTO  TABLE @lt_sales_ret.
  ENDIF.

  LOOP AT lt_return INTO ls_return.
    CONCATENATE ls_return-salesorder ls_return-salesorderitem
                INTO lv_key
                SEPARATED BY lc_separ.
* - Nieuwe hoeveelheid
    LOOP AT lt_sales_orgl INTO ls_sales_orgl
      WHERE  salesorder     = ls_return-salesorder
         AND salesorderitem = ls_return-salesorderitem.
    ENDLOOP.
    IF sy-subrc = 0.
      LOOP AT lt_sales_ret INTO ls_sales_ret
         WHERE customerreturn     = ls_return-subsequentdocument
           AND customerreturnitem = ls_return-subsequentdocumentitem.
      ENDLOOP.
      IF sy-subrc = 0.
        lv_quan = ls_sales_orgl-orderquantity - ls_sales_ret-orderquantity.
      ENDIF.
    ENDIF.
* - lv_quan wordt Nieuwe hoeveelheid voor HistoryAmount
    READ TABLE lt_out INTO ls_out WITH KEY HostDmdDetailID = lv_key.
    IF sy-subrc = 0.
      ls_out-HistoryAmount = lv_quan.
      MODIFY lt_out FROM ls_out INDEX sy-tabix.
    ELSE.
      SELECT  *
        FROM  i_salesorder
        INTO  TABLE @lt_order_ret
       WHERE  salesorder = @ls_return-salesorder.
      READ TABLE lt_order_ret INTO ls_order_ret WITH KEY salesorder = ls_return-salesorder.
      IF sy-subrc = 0.
* Get the Record from Variable table to find the Demand Stream
        READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order_ret-salesordertype low = ls_order_ret-soldtoparty.
        IF sy-subrc = 0.
          lv_demstream = ls_vartab-param1.
        ELSE.
          READ TABLE lt_vartab INTO ls_vartab WITH KEY param2 = ls_order_ret-salesordertype.
          IF sy-subrc = 0.
            lv_demstream = '9'.
          ENDIF.
        ENDIF.
      ENDIF.
      ls_out-HostDmdDetailID = lv_key.
      ls_out-HostPartID      = ls_sales_orgl-material.
      ls_out-HostLocID       = ls_sales_orgl-plant.
      ls_out-DSHostID        = lv_demstream.
      ls_out-HistoryBegDate  = ls_order_ret-requesteddeliverydate.
      ls_out-HistoryAmount   = lv_quan.
      ls_out-DemandNote      = ' '.
      APPEND ls_out TO lt_out.
    ENDIF.
  ENDLOOP.

  REFRESH lt_file3[].
  lt_file3 = lt_out.

ENDFORM.


*----------------------------------------------------------------------
* start-of-selection
*----------------------------------------------------------------------
START-OF-SELECTION.

*Selection of Demand Stream values maintained in the Variable Table.
  SELECT  *
    FROM  zzns_variabelen
    INTO  TABLE lt_vartab
   WHERE  name = lc_name
     AND  ref = lc_ref.

* Materiaal documenten
  IF cb_matdc = abap_true.
    PERFORM MaterialPostingsFetch.
  ENDIF.

* Onderhoudsorders
  IF cb_maint = abap_true.
    PERFORM MaintenanceOrdersFetch.
  ENDIF.

* Verkoops orders
  IF cb_sales = abap_true.
    PERFORM SalesOrdersFetch.
  ENDIF.

  gv_tabname = gc_tabname.

* colleced all files for output
  IF lt_file1 IS NOT INITIAL.
    APPEND LINES OF lt_file1 TO lt_final.
  ENDIF.
  IF lt_file2 IS NOT INITIAL.
    APPEND LINES OF lt_file2 TO lt_final.
  ENDIF.
  IF lt_file3 IS NOT INITIAL.
    APPEND LINES OF lt_file3 TO lt_final.
  ENDIF.

  gv_destination  = p_destin .
  gv_path_postfix = p_path  .
  gv_file_name    = p_file .



*----------------------------------------------------------------------
* end-of-selection
*----------------------------------------------------------------------

  IF cb_test = 'X'. "display results in ALV.

    DATA(svg_class) = NEW zcl_s4_to_svg( ).

      svg_class->display_alv( table = REF #( lt_final )
                            title = 'Demand Detail selection' ).

  ELSE.
    IF P_json = 'X'.
*Send results in JSON format
      CALL FUNCTION 'ZSVG_SEND_FILE_JSON'
        EXPORTING
          iv_destination  = gv_destination
          iv_path_postfix = gv_path_postfix
          it_table        = lt_final.
    ELSEIF P_csv = 'X'.
*Send results in CSV format pipe(|) separated.
      CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
        EXPORTING
          iv_destination  = gv_destination
          iv_path_postfix = gv_path_postfix
          iv_filename     = gv_file_name
          it_table        = lt_final.
    ENDIF.
  ENDIF.