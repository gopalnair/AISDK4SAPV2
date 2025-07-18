CLASS zcl_peng_azoai_sdk_v1_complet DEFINITION
  PUBLIC
  INHERITING FROM zcl_peng_azoai_sdk_compl_base
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS zif_aisdk_azoai_comp_compl~create REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_peng_azoai_sdk_v1_complet IMPLEMENTATION.
  METHOD zif_aisdk_azoai_comp_compl~create.
*****************************************************************************************************************
* Class          : ZCL_PENG_AZOAI_SDK_V1_COMPLET
* Method         : zif_peng_azoai_sdk_comp_compl~create
* Created by     : Gopal Nair
* Date           : Apr 6, 2023
*-------------------------------------------------------------------------------------------------------------
* Description
*-------------------------------------------------------------------------------------------------------------
* Performs a completion based on prompts and other parameters.
*
* A Completion operation is about asking the AI engine something, and getting a response. The asking part of this
* interaction is called "prompts". Prompt Engineering is used to create prompts which will guide the AI engine to
* understand exactly what you are asking for, and respond meaningfully for the context of the question.
*-------------------------------------------------------------------------------------------------------------
*                       Modification History
*-------------------------------------------------------------------------------------------------------------
* Apr 6, 2023 // Gopal Nair // Initial Version
*****************************************************************************************************************

    DATA:
        l_completions_create TYPE zif_peng_azoai_sdk_types=>ty_completion_input.

*   Check if the operation is permitted for the run profile by asking profile handler.
    _objconfig->get_runprofile_handler( )->zif_aisdk_centralcontrol~perform_operation(
      EXPORTING
        component_type = _component_type
        operation      = zif_aisdk_azoai_constants=>c_component_operations-create
    ).


    l_completions_create = prompts.

*   If there are no prompts entered by the user, then put in 1 entry with empty string.
*    IF l_completions_create-prompt[] IS INITIAL.
*      APPEND '' TO l_completions_create-prompt.
*      RETURN.
*    ENDIF.

*   Set a default max token count, if not set.
    IF l_completions_create-max_tokens IS INITIAL.
      l_completions_create-max_tokens = 16.
    ENDIF.

*   Set default number of responses as 1, if not set.
    IF l_completions_create-n IS INITIAL.
      l_completions_create-n = 1.
    ENDIF.

*   Set the user info of invoker. This is for mis-use prevention feature available in Azure Open AI.
    l_completions_create-user = sy-uname.


* Get the actual URL and HTTP communication objects from helper layer.
    _objsdkhelper->get_httpobjs_from_uripattern(
      EXPORTING
        uri_pattern            = _objconfig->get_accesspoint_provider( )->get_urltemplate(
                                                                                            component = _component_type
                                                                                            operation = zif_aisdk_azoai_constants=>c_component_operations-create
                                                                                         )   "{endpoint}/openai/deployments/{deployment-id}/completions?api-version={version}'
        ivobj_config           = _objconfig
        ivt_templatecomponents = VALUE #(  ( name = zif_aisdk_azoai_uripatterns=>template_ids-deploymentid value = deploymentid ) ) "Deployment ID.
      IMPORTING
        ov_url                 = DATA(actual_url)
        ovobj_http             = DATA(lo_http)
        ovobj_http_rest        = DATA(lo_http_rest)
    ).

*   Prepare the body and set it
    DATA(lo_request) = lo_http_rest->if_rest_client~create_request_entity( ).
    lo_request->set_content_type( iv_media_type = 'application/json' ).
    DATA(post_data) = to_lower( /ui2/cl_json=>serialize( data = l_completions_create  compress = /ui2/cl_json=>c_bool-true ) ) .
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
