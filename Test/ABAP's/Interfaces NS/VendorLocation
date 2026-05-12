*&---------------------------------------------------------------------*
*& Report zsvg_send_vendorlocation
*&---------------------------------------------------------------------*
*& This interface includes sending the vendor location
*& from S4-Hana to SVG via CPI.
*& The data is sent as a single CSV file.
*&---------------------------------------------------------------------*
REPORT zsvg_send_vendorlocation.

INCLUDE zsvg_send_vendor_loc. " Data declaration and selection screen:

*&---------------------------------------------------------------------*
*& Include zsvg_send_vendor_loc
*&---------------------------------------------------------------------*

TABLES: ekko, lfa1.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS: so_vls FOR ekko-lifnr, " Supplier
                  so_vld FOR lfa1-erdat. " Creation date

  PARAMETERS: p_po  TYPE ekko-ekorg DEFAULT '5900'. " Purchasing organization.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_dest   TYPE string LOWER CASE OBLIGATORY, " Destination via variant: 'SCO_CPI_SVG'
              p_pstfix TYPE string LOWER CASE OBLIGATORY, " Postfix via variant: '/http/sco/svg'
              p_venloc TYPE char100 LOWER CASE OBLIGATORY. " Via variant

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS cb_test TYPE abap_bool AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b3.

" -----------------------------------------------------------------------
" Start data selection, and create output table
" -----------------------------------------------------------------------

SELECT FROM I_SupplierPurchasingOrg

  FIELDS Supplier                                              AS HostVendorLocID,
         Supplier                                              AS VendorLocName,
         \_Supplier-SupplierName                               AS Description,
         CASE WHEN \_Supplier-PurchasingIsBlocked = @abap_true
              THEN \_Supplier-PurchasingIsBlocked
              ELSE PurchasingIsBlockedForSupplier
              END                                              AS VendorLocCust1

  WHERE Supplier                IN @so_vls
    AND \_Supplier-CreationDate IN @so_vld
    AND ( PurchasingOrganization = @p_po OR @p_po IS INITIAL )

  INTO TABLE @DATA(vendor_loc).

" When no data is found for selection, end query
IF vendor_loc IS INITIAL.
  WRITE / TEXT-004.
  RETURN.
ENDIF.

" -----------------------------------------------------------------------
" Sent out table as CSV
" -----------------------------------------------------------------------

IF cb_test <> abap_true. " Excluded for testing

  " Sent out orderplan_h table
  CALL FUNCTION 'ZSVG_SEND_FILE_CSV'
    EXPORTING iv_destination  = p_dest
              iv_path_postfix = p_pstfix
              iv_filename     = p_venloc
              it_table        = vendor_loc.
ENDIF.

" -----------------------------------------------------------------------
" Create ALV (test modus only)
" -----------------------------------------------------------------------
IF cb_test = abap_true.

  " Initiate class and use applicable method
  NEW zcl_s4_to_svg( )->display_alv( table = REF #( vendor_loc )
                                     title = 'Vendor location selection' ).

ELSE.
  RETURN.
ENDIF.