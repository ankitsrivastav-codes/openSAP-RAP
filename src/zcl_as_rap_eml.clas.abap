CLASS zcl_as_rap_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AS_RAP_EML IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    READ ENTITIES OF zi_as_travel_os
    ENTITY Travel
    ALL FIELDS WITH VALUE #( ( TravelUUID = 'F5F000B079C268AE180095021DD9AF70' ) )
    RESULT DATA(Lt_Travel).

    out->write( lt_travel ).


    READ ENTITIES OF zi_As_travel_os
    ENTITY Travel BY \_Booking
    ALL FIELDS WITH VALUE #( ( TravelUUID = 'F5F000B079C268AE180095021DD9AF70' ) )
    RESULT DATA(Lt_Bookings)
    FAILED DATA(lt_failed)
    REPORTED DATA(lt_reported).

    out->write( Lt_Bookings ).


    MODIFY ENTITIES OF zi_as_travel_os
    ENTITY travel
    UPDATE SET FIELDS WITH VALUE #( ( TravelUUID = 'F5F000B079C268AE180095021DD9AF70'
                                      Description = 'Test Update - OpenSAP RAP' ) )
    FAILED lt_failed
    REPORTED lt_reported.


    CLEAR lt_travel.

    READ ENTITIES OF zi_as_travel_os
    ENTITY Travel
    ALL FIELDS WITH VALUE #( ( TravelUUID = 'F5F000B079C268AE180095021DD9AF70' ) )
    RESULT Lt_Travel.
    out->write( lt_travel ).

*    COMMIT ENTITIES RESPONSE OF zi_as_travel_os
*    FAILED DATA(lt_fail_commit)
*    REPORTED DATA(lt_report_commit).

    MODIFY ENTITIES OF zi_as_travel_os
    ENTITY travel
    CREATE SET FIELDS
    WITH VALUE #( (
                    %cid = 'MyContextID_1'
                    AgencyID = '70012'
                    CustomerId = '14'
                    BeginDate = cl_abap_context_info=>get_system_date( )
                    EndDate = cl_abap_context_info=>get_system_date( ) + 10
                    Description = 'Test Create - OpenSAP RAP'
     ) )
    MAPPED DATA(lt_mapped)
    FAILED lt_failed
    REPORTED lt_reported.

    out->write( lt_mapped-travel ).

*    COMMIT ENTITIES RESPONSE OF zi_as_travel_os
*    FAILED DATA(lt_fail_commit)
*    REPORTED DATA(lt_report_commit).


    MODIFY ENTITIES OF zi_As_travel_os
    ENTITY Travel
    DELETE FROM VALUE #( ( traveluuid = '' ) )
    FAILED lt_failed
    REPORTED lt_reported.

*    COMMIT ENTITIES RESPONSE OF zi_as_travel_os
*    FAILED DATA(lt_fail_commit)
*    REPORTED DATA(lt_report_commit).


  ENDMETHOD.
ENDCLASS.
