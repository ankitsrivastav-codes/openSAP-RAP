CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS: BEGIN OF travel_status,
                 open      TYPE c LENGTH 1 VALUE 'O', " Open
                 accepted  TYPE c LENGTH 1 VALUE 'A', "Accepted
                 cancelled TYPE c LENGTH 1 VALUE 'X', "Cancelled
               END OF travel_status.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS is_update_granted IMPORTING has_before_image      TYPE abap_bool
                                        overall_status        TYPE /dmo/overall_status
                              RETURNING VALUE(update_granted) TYPE abap_bool.

    METHODS is_delete_granted IMPORTING has_before_image      TYPE abap_bool
                                        overall_status        TYPE /dmo/overall_status
                              RETURNING VALUE(delete_granted) TYPE abap_bool.

    METHODS is_create_granted RETURNING VALUE(create_granted) TYPE abap_bool.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS recalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~recalcTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setInitialStatus.

    METHODS calculateTravelID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~calculateTravelID.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels)
    FAILED failed.

    result = VALUE #( FOR travel IN travels
                        LET is_accepted = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                  THEN if_abap_behv=>fc-o-disabled
                                                  ELSE if_abap_behv=>fc-o-enabled )
                            is_rejected = COND #( WHEN travel-OverallStatus = travel_status-cancelled
                                                  THEN if_abap_behv=>fc-o-disabled
                                                  ELSE if_abap_behv=>fc-o-enabled )
                        IN ( %tky = travel-%tky
                             %action-acceptTravel = is_accepted
                             %action-rejectTravel = is_rejected )
                     ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD acceptTravel.

    " Set the new overall status
    MODIFY ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                    OverallStatus = travel_status-accepted ) )
    FAILED failed
    REPORTED reported.

    " Fill the response table
    READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel ) ).

  ENDMETHOD.

  METHOD recalcTotalPrice.

    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY travel
    FIELDS ( BookingFee CurrencyCode )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      amount_per_currencycode = VALUE #( ( amount = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
      ENTITY Travel BY \_Booking
      FIELDS ( FlightPrice CurrencyCode )
      WITH VALUE #( ( %tky = <travel>-%tky ) )
      RESULT DATA(bookings).

      LOOP AT bookings INTO DATA(booking) WHERE CurrencyCode IS NOT INITIAL.

        COLLECT VALUE ty_amount_per_currencycode( amount = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode )
                                             INTO amount_per_currencycode.
      ENDLOOP.

      CLEAR <travel>-TotalPrice.

      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).

        IF single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
          EXPORTING
          iv_amount = single_amount_per_currencycode-amount
          iv_currency_code_source = single_amount_per_currencycode-currency_code
          iv_currency_code_target = <travel>-CurrencyCode
          iv_exchange_rate_date = cl_abap_context_info=>get_system_date(  )
          IMPORTING
          ev_amount = DATA(total_booking_price_per_curr)
          ).
          <travel>-TotalPrice += total_booking_price_per_curr.

        ENDIF.

      ENDLOOP.

    ENDLOOP.


    MODIFY ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TotalPrice )
    WITH CORRESPONDING #( travels ).

  ENDMETHOD.

  METHOD rejectTravel.

    " Set the new overall status
    MODIFY ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                    OverallStatus = travel_status-cancelled ) )
    FAILED failed
    REPORTED reported.

    " Fill the response table
    READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel ) ).

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY Travel
    EXECUTE recalcTotalPrice
    FROM CORRESPONDING #( keys )
    REPORTED DATA(executed_reported).

    reported = CORRESPONDING #( DEEP executed_reported ).

  ENDMETHOD.

  METHOD setInitialStatus.

    READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE OverallStatus IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                          OverallStatus = travel_status-open ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD calculateTravelID.

    READ ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE TravelId IS INITIAL.

    CHECK travels IS NOT INITIAL.

    SELECT SINGLE FROM zas_rap_travel
    FIELDS MAX( travel_id ) AS travelID
    INTO @DATA(max_travelid).

    MODIFY ENTITIES OF ZI_as_travel_os IN LOCAL MODE
    ENTITY travel
    UPDATE
    FROM VALUE #( FOR travel IN travels INDEX INTO i (
                      %tky = travel-%tky
                      TravelID = max_travelid + 1
                      %control-TravelId = if_abap_behv=>mk-on  ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD validateAgency.

    READ ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY Travel
    FIELDS ( AgencyId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    agencies  = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = agencyID EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.

    IF agencies IS NOT INITIAL.

      SELECT FROM /dmo/agency FIELDS agency_id
      FOR ALL ENTRIES IN @agencies
      WHERE agency_id = @agencies-agency_id
      INTO TABLE @DATA(agencies_db).

    ENDIF.

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky = travel-%tky
                      %state_area = 'VALIDATE_AGENCY' )
      TO reported-travel.

      IF travel-agencyID IS INITIAL OR NOT line_exists(  agencies_db[ agency_id = travel-agencyid ] ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_Area = 'VALIDATE_AGENCY'
                        %msg = NEW zas_cm_travel_os( severity = if_abap_behv_message=>severity-error
                                                     textid   = zas_cm_travel_os=>agency_unknown
                                                     agencyid = travel-AgencyId )
                      %element-agencyid = if_abap_behv=>mk-on )
        TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF zi_As_travel_os IN LOCAL MODE
    ENTITY Travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    customers  = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.

      SELECT FROM /dmo/customer FIELDS customer_id
      FOR ALL ENTRIES IN @customers
      WHERE customer_id = @customers-customer_id
      INTO TABLE @DATA(customers_db).

    ENDIF.

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky = travel-%tky
                      %state_area = 'VALIDATE_CUSTOMER' )
      TO reported-travel.

      IF travel-CustomerId IS INITIAL OR NOT line_exists(  customers_db[ customer_id = travel-customerid ] ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_Area = 'VALIDATE_CUSTOMER'
                        %msg = NEW zas_cm_travel_os( severity = if_abap_behv_message=>severity-error
                                                     textid   = zas_cm_travel_os=>customer_unknown
                                                     agencyid = travel-CustomerId )
                      %element-customerid = if_abap_behv=>mk-on )
        TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.


    READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY travel
    FIELDS ( travelid begindate enddate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky = travel-%tky
                      %state_area = 'VALIDATE_DATES' )
      TO reported-travel.

      IF travel-EndDate < travel-BeginDate.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = NEW zas_cm_travel_os( severity = if_abap_behv_message=>severity-error
                                                     textid = zas_cm_travel_os=>date_interval
                                                     travelid = travel-TravelId
                                                     begindate = travel-BeginDate
                                                     enddate = travel-EndDate
                                                      )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate = if_abap_behv=>mk-on )
        TO reported-travel.

      ELSEIF travel-BeginDate < cl_abap_context_info=>get_system_date( ).

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = NEW zas_cm_travel_os( severity = if_abap_behv_message=>severity-error
                                                     textid = zas_cm_travel_os=>begin_date_before_system_date
                                                     begindate = travel-BeginDate
                                                      )
                        %element-BeginDate = if_abap_behv=>mk-on )
        TO reported-travel.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD is_create_granted.

  ENDMETHOD.

  METHOD is_delete_granted.

  ENDMETHOD.

  METHOD is_update_granted.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateBookingID FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateBookingID.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalPrice.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calculateBookingID.

    DATA max_bookingid TYPE /dmo/booking_id.
    DATA update TYPE TABLE FOR UPDATE zi_as_travel_os\\Booking.

    " Read all travels for the requested bookings.
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY Booking BY \_Travel
      FIELDS ( TravelUUID )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    " Process all affected Travels. Read respective bookings, determine the max-id and update the bookings without ID.
    LOOP AT travels INTO DATA(travel).
      READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
        ENTITY Travel BY \_Booking
          FIELDS ( BookingID )
        WITH VALUE #( ( %tky = travel-%tky ) )
        RESULT DATA(bookings).

      " Find max used BookingID in all bookings of this travel
      max_bookingid ='0000'.
      LOOP AT bookings INTO DATA(booking).
        IF booking-BookingID > max_bookingid.
          max_bookingid = booking-BookingID.
        ENDIF.
      ENDLOOP.

      " Provide a booking ID for all bookings that have none.
      LOOP AT bookings INTO booking WHERE BookingID IS INITIAL.
        max_bookingid += 10.
        APPEND VALUE #( %tky      = booking-%tky
                        BookingID = max_bookingid
                      ) TO update.
      ENDLOOP.
    ENDLOOP.

    " Update the Booking ID of all relevant bookings
    MODIFY ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY Booking
      UPDATE FIELDS ( BookingID ) WITH update
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD calculateTotalPrice.

    " Read all travels for the requested bookings.
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY Booking BY \_Travel
      FIELDS ( TravelUUID )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      FAILED DATA(read_failed).

    " Trigger calculation of the total price
    MODIFY ENTITIES OF zi_as_travel_os IN LOCAL MODE
    ENTITY Travel
      EXECUTE recalcTotalPrice
      FROM CORRESPONDING #( travels )
    REPORTED DATA(execute_reported).

    reported = CORRESPONDING #( DEEP execute_reported ).

  ENDMETHOD.

ENDCLASS.
