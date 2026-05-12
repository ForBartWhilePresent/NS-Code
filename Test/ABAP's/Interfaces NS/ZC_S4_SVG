CLASS zcl_s4_to_svg DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_error,
             line_number   TYPE i,
             matnr         TYPE matnr,
             purchase_item TYPE ebelp,
             message       TYPE string,
           END OF ty_error.

    TYPES: BEGIN OF ty_convert_result,
             converted_quantity TYPE ekpo-menge,
             error              TYPE ty_error,
           END OF ty_convert_result.

    METHODS convert_material
      IMPORTING material      TYPE matnr
                POUnit        TYPE bstme
                BaseUnit      TYPE meins
                quantity      TYPE ekpo-menge
                po_item       TYPE ebelp
      RETURNING VALUE(result) TYPE ty_convert_result.

    METHODS get_work_day
      IMPORTING !date      TYPE dats
      RETURNING VALUE(day) TYPE dats.

    METHODS add_work_day
      IMPORTING !date      TYPE dats
                days       TYPE i
      RETURNING VALUE(day) TYPE dats.

    METHODS display_alv
      IMPORTING !table TYPE REF TO data
                !title TYPE lvc_title OPTIONAL.

    METHODS read_text_matnr
      IMPORTING matnr         TYPE matnr
                !id           TYPE tdid
                !language     TYPE spras
                !object       TYPE tdobject
                delimiter     TYPE char1
                !replace      TYPE char1 OPTIONAL
      RETURNING VALUE(tdline) TYPE char255.

    METHODS change_delimiter
      IMPORTING !text          TYPE string
                delimiter      TYPE char1
                !replace       TYPE char1
      RETURNING VALUE(changed) TYPE string.

    METHODS create_where_clause
      IMPORTING !name               TYPE char30
                !ref                TYPE char30
      RETURNING VALUE(where_clause) TYPE string
      RAISING   cx_sy_itab_line_not_found.

    DATA msg_text TYPE string.

    CONSTANTS cal TYPE char2 VALUE 'NL'.

ENDCLASS.


CLASS zcl_s4_to_svg IMPLEMENTATION.
  METHOD convert_material.
    CLEAR msg_text.

    CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
      EXPORTING
        i_matnr              = material
        i_in_me              = pounit
        i_out_me             = baseunit
        i_menge              = quantity
      IMPORTING
        e_menge              = result-converted_quantity
      EXCEPTIONS
        error_in_application = 1
        error                = 2
        OTHERS               = 3.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    result-converted_quantity = 0. " When error quantity is set to zero.

    " Collect error message(s)
    CALL FUNCTION 'MESSAGE_TEXT_BUILD'
      EXPORTING
        msgid               = sy-msgid
        msgnr               = sy-msgno
        msgv1               = sy-msgv1
        msgv2               = sy-msgv2
        msgv3               = sy-msgv3
        msgv4               = sy-msgv4
      IMPORTING
        message_text_output = msg_text.

    " Save in error structure
    result-error-line_number   = sy-tabix.
    result-error-matnr         = material.
    result-error-purchase_item = po_item.
    result-error-message       = msg_text.
  ENDMETHOD.

  METHOD get_work_day.
    CALL FUNCTION 'BKK_GET_NEXT_WORKDAY'
      EXPORTING
        i_date      = date
        i_calendar1 = cal
      IMPORTING
        e_workday   = day.
  ENDMETHOD.

  METHOD add_work_day.
    CALL FUNCTION 'FKK_ADD_WORKINGDAY'
      EXPORTING
        i_date      = date
        i_days      = days
        i_calendar1 = cal
      IMPORTING
        e_date      = day.
  ENDMETHOD.

  METHOD display_alv.
    TRY.
        DATA lr_alv       TYPE REF TO cl_salv_table.
        DATA lr_functions TYPE REF TO cl_salv_functions.
        DATA lr_settings  TYPE REF TO cl_salv_display_settings.
        DATA lr_layout    TYPE REF TO cl_salv_layout.
        DATA lv_title     TYPE lvc_title.
        DATA key          TYPE salv_s_layout_key.

        FIELD-SYMBOLS <lt_any> TYPE STANDARD TABLE.

        ASSIGN table->* TO <lt_any>.
        IF sy-subrc <> 0.
          MESSAGE 'No valid table passed' TYPE 'I' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        cl_salv_table=>factory( IMPORTING r_salv_table = lr_alv
                                CHANGING  t_table      = <lt_any> ).

        lr_functions = lr_alv->get_functions( ).
        lr_functions->set_all( abap_true ).

        IF title IS SUPPLIED AND title IS NOT INITIAL.
          lv_title = title.
        ELSE.
          lv_title = 'ALV Output'.
        ENDIF.

        lr_settings = lr_alv->get_display_settings( ).
        lr_settings->set_striped_pattern( cl_salv_display_settings=>true ).
        lr_settings->set_list_header( lv_title ).

        lr_layout = lr_alv->get_layout( ).
        key-report = sy-repid.
        lr_layout->set_key( key ).
        lr_layout->set_save_restriction( cl_salv_layout=>restrict_none ).

        lr_alv->get_columns( )->set_optimize( abap_true ).

        lr_alv->display( ).

      CATCH cx_salv_msg.
        MESSAGE 'Unable to show ALV' TYPE 'I' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD read_text_matnr.
    DATA name  TYPE thead-tdname.
    DATA lines TYPE TABLE OF tline.

    name = matnr. " Assign matnr to name
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id                      = id
        language                = language
        name                    = name
        object                  = object
      TABLES
        lines                   = lines             " Result table
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.

    IF sy-subrc = 0.

      LOOP AT lines INTO DATA(line).

        IF replace IS NOT INITIAL.
          line-tdline = change_delimiter( text      = |{ line-tdline }|
                                          delimiter = delimiter
                                          replace   = replace ).
        ENDIF.

        IF tdline IS INITIAL.
          tdline = line-tdline.
        ELSE.
          tdline = |{ tdline }{ line-tdline }|.
        ENDIF.
      ENDLOOP.

    ENDIF.
  ENDMETHOD.

  METHOD change_delimiter.
    changed = replace( val  = text
                       sub  = delimiter
                       with = replace
                       occ  = 0 ).
  ENDMETHOD.

  METHOD create_where_clause.

    SELECT param1, opti, low FROM zzns_variabelen
      INTO TABLE @DATA(vartab)
      WHERE name = @name
        AND ref  = @ref.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ELSE.

      where_clause = REDUCE string(
      INIT string TYPE string
      FOR GROUPS group OF row1 IN vartab GROUP BY ( param1 = row1-param1 )
      NEXT string = COND string(
        WHEN string IS INITIAL
        THEN |( { REDUCE string(
               INIT sg TYPE string
               FOR gr IN GROUP group
               NEXT sg = COND string(
                          WHEN sg IS INITIAL
                          THEN |{ gr-param1 } { gr-opti } '{ gr-low }'|
                          ELSE |{ sg } OR { gr-param1 } { gr-opti } '{ gr-low }'| ) )
             } )|
        ELSE string && | AND ( { REDUCE string(
                              INIT sg TYPE string
                              FOR gr IN GROUP group
                              NEXT sg = COND string(
                                       WHEN sg IS INITIAL
                                       THEN |{ gr-param1 } { gr-opti } '{ gr-low }'|
                                       ELSE sg && | OR { gr-param1 } { gr-opti } '{ gr-low }'| ) ) } )| ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.