*&---------------------------------------------------------------------*
*& Report ztest_voor_infor_api_call
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_voor_infor_api_call.

" --- Doel-API:
CONSTANTS prefix TYPE string VALUE 'https://gateway.apiportaltst.ns.nl/infor-ln-files-api/public/files/' ##NO_TEXT.

DATA location    TYPE string                VALUE 'AWS_S3/Vault%2FWork%2F' ##NO_TEXT.
DATA filename    TYPE string                VALUE 'FILE-0000041_0001.PDF' ##NO_TEXT.
DATA destination TYPE string                VALUE 'infor-ln-files-api'.
DATA http_client TYPE REF TO if_http_client.
DATA lt_headers  TYPE tihttpnvp.

DATA lt_solix    TYPE solix_tab.
DATA file_pdf    TYPE string
                 VALUE 'C:\Users\bart.eichholtz\OneDrive - myBrand Conclusion\Documenten\SAP\ABAP\NS\test.pdf'.
DATA file_b64    TYPE string
                 VALUE 'C:\Users\bart.eichholtz\OneDrive - myBrand Conclusion\Documenten\SAP\ABAP\NS\base64demo.txt'.
DATA base64_test TYPE string.
DATA tab         TYPE TABLE OF string.

" ------------------------
" 1. API call voor PDF
" ------------------------

DATA(pdf_api) = |{ prefix }{ location }{ filename }|.
cl_http_client=>create_by_url( EXPORTING  url    = pdf_api
                               IMPORTING  client = http_client
                               EXCEPTIONS OTHERS = 1 ).

IF sy-subrc <> 0.
  WRITE / 'HTTP client maken voor PDF mislukt!'.
  EXIT.
ENDIF.

DATA emptybuffer TYPE xstring.

emptybuffer = ''.

http_client->request->set_data( data = emptybuffer ).

" Set HTTP headers and method
http_client->request->set_version( if_http_request=>co_protocol_version_1_1 ).

SELECT SINGLE * INTO @DATA(customizing) FROM zapicustomizing WHERE destination = @destination. " Check of er een record is gevonden en stel header in, werkt alleen op 200
IF sy-subrc <> 0.
  http_client->request->set_header_field( name  = |Ocp-Apim-Subscription-Key|
                                          value = |3f4e5b9ca190428a8fbad40ea088235b| ).
ELSE.
  http_client->request->set_header_field( name  = |{ customizing-subscription_name }|
                                          value = |{ customizing-subscription_value }| ).
ENDIF.

http_client->request->set_header_field( name  = |Cache-Control|
                                        value = |no-cache| ).

http_client->request->set_method( method = if_http_request=>co_request_method_get ).

" GET request
http_client->send( EXCEPTIONS http_communication_failure = 1
                              http_invalid_state         = 2
                              http_processing_failed     = 3
                              http_invalid_timeout       = 4
                              OTHERS                     = 5 ).
IF sy-subrc <> 0.
  http_client->get_last_error( IMPORTING code    = DATA(lv_rc)
                                         message = DATA(lv_msg) ).
  RETURN.
ENDIF.

" Receive response
http_client->receive( EXCEPTIONS OTHERS = 1 ).

" Check response status
http_client->response->get_status( IMPORTING code   = DATA(code)
                                             reason = DATA(reason) ).

http_client->response->get_header_fields( CHANGING fields = lt_headers ). " Optional: header logging.

DATA(pdf_cdata) = http_client->response->get_cdata( ). " PDF data in base64 (cdata).
DATA(pdf_raw) = http_client->response->get_raw_message( ). " Hele response body als string (voor debuggen, niet efficiënt voor grote PDF's).
DATA(pdf_data) = http_client->response->get_data( ). " PDF data als xstring (voor debuggen, niet efficiënt voor grote PDF's).

http_client->close( ).

IF code <> 200.
  WRITE: / 'PDF-request fout:', code, reason.
  EXIT.
ENDIF.

IF pdf_cdata IS INITIAL.
  WRITE / 'Geen PDF data ontvangen!, verder met test data'.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING  filename = file_b64
               filetype = 'ASC'
    TABLES     data_tab = tab
    EXCEPTIONS OTHERS   = 1.

  IF sy-subrc = 0.
    base64_test = REDUCE string( INIT s TYPE string
      FOR line IN tab NEXT s = s && line ).
  ENDIF.

ENDIF.

" ------------------------
" 2. Base64 → xstring → solix_tab en opslaan in bestand
" ------------------------

IF pdf_cdata IS NOT INITIAL.
  " Gebruik de ontvangen PDF data
  DATA(decoded) = cl_http_utility=>if_http_utility~decode_x_base64( encoded = pdf_cdata ).
  lt_solix = cl_bcs_convert=>xstring_to_solix( iv_xstring = decoded ).
  DATA(size) = xstrlen( decoded ).

ELSE.
  " Gebruik de test data uit bestand (base64)
  DATA(decodedx) = cl_http_utility=>if_http_utility~decode_x_base64( encoded = base64_test ).
  lt_solix = cl_bcs_convert=>xstring_to_solix( iv_xstring = decodedx ).
  size = xstrlen( decodedx ).

ENDIF.

cl_gui_frontend_services=>gui_download( EXPORTING bin_filesize          = size
                                                  filename              = file_pdf
                                                  filetype              = 'BIN'
                                                  trunc_trailing_blanks = space
                                        CHANGING  data_tab              = lt_solix ).

IF sy-subrc = 0.
  WRITE: / 'PDF opgeslagen als:', file_pdf.
ELSE.
  WRITE / 'Fout bij opslaan PDF.'.
ENDIF.
