CLASS zcl_peng_oai_sdk_v1_embeding DEFINITION
  PUBLIC
  INHERITING FROM zcl_peng_azoai_sdk_embed_base
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS zif_aisdk_azoai_comp_embed~create REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_peng_oai_sdk_v1_embeding IMPLEMENTATION.
  METHOD zif_aisdk_azoai_comp_embed~create.
*****************************************************************************************************************
* Class          : ZCL_PENG_AZOAI_SDK_V1_EMBEDING
* Method         : zif_peng_azoai_sdk_comp_embed~create
* Created by     : Gopal Nair
* Date           : Jun 9, 2023
*-------------------------------------------------------------------------------------------------------------
* Description
*-------------------------------------------------------------------------------------------------------------
*
*-------------------------------------------------------------------------------------------------------------
*                       Modification History
*-------------------------------------------------------------------------------------------------------------
* Jun 9, 2023 // GONAIR // Initial Version
*****************************************************************************************************************
    TYPES: BEGIN OF ty_oai_embeddinginput,
             model TYPE string.
             INCLUDE TYPE zif_peng_azoai_sdk_types=>ty_embeddings_input.
           TYPES: END OF ty_oai_embeddinginput.

    DATA:
          l_embeddings_oai_input    TYPE ty_oai_embeddinginput.

    MOVE-CORRESPONDING inputs TO l_embeddings_oai_input.
    l_embeddings_oai_input-model = deploymentid.


*   Check if the operation is permitted for the run profile by asking profile handler.
    _objconfig->get_runprofile_handler( )->zif_aisdk_centralcontrol~perform_operation(
      EXPORTING
        component_type = _component_type
        operation      = zif_aisdk_azoai_constants=>c_component_operations-create
    ).

* Get the actual URL and HTTP communication objects from helper layer.
    _objsdkhelper->get_httpobjs_from_uripattern(
      EXPORTING
        uri_pattern            = _objconfig->get_accesspoint_provider( )->get_urltemplate(
                                                                                            component = _component_type
                                                                                            operation = zif_aisdk_azoai_constants=>c_component_operations-create
                                                                                         )
        ivobj_config           = _objconfig
      IMPORTING
        ov_url                 = DATA(actual_url)
        ovobj_http             = DATA(lo_http)
        ovobj_http_rest        = DATA(lo_http_rest)
    ).

*   Prepare the body and set it
    DATA(lo_request) = lo_http_rest->if_rest_client~create_request_entity( ).
    lo_request->set_content_type( iv_media_type = 'application/json' ).
    DATA(post_data) = /ui2/cl_json=>serialize(
                                               data = l_embeddings_oai_input
                                               compress = abap_true
                                               pretty_name = /ui2/cl_json=>pretty_mode-low_case
                                             ).
    lo_request->set_string_data( iv_data = post_data ).

*   Trigger the network operation.
    lo_http_rest->if_rest_client~post( io_entity = lo_request ).

*   Get Status, results and error if any from helper layer.
    _objsdkhelper->do_receive(
      EXPORTING
        ivobj_http_client = lo_http
        ivobj_http_rest   = lo_http_rest
      IMPORTING
        ov_statuscode     = statuscode
        ov_statusdescr    = statusreason
        ov_jsonstring     = json
      CHANGING
        iov_result        = response
        iov_error         = error
    ).


  ENDMETHOD.

ENDCLASS.
