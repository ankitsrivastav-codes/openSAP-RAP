@EndUserText.label: 'Booking'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true
define view entity ZC_AS_BOOKING_U_OS
  as projection on ZI_AS_BOOKING_U_OS
{
      @Search.defaultSearchElement: true
  key TravelID,
      @Search.defaultSearchElement: true
  key BookingID,
      BookingDate,
      @Consumption.valueHelpDefinition: [ { entity: { name:     '/DMO/I_Customer',
                                                   element:     'CustomerID' } } ]
      CustomerID,
      @Consumption.valueHelpDefinition: [ { entity: { name:     '/DMO/I_Carrier',
                                                   element:     'AirlineID' } } ]
      CarrierID,
      @Consumption.valueHelpDefinition: [ { entity: { name:    '/DMO/I_Flight',
                                                      element: 'ConnectionID' },
                                            additionalBinding: [ { localElement: 'FlightDate',
                                                                   element:      'FlightDate',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CarrierID',
                                                                        element: 'AirlineID',
                                                                          usage: #RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                        element: 'Price',
                                                                          usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                        element: 'CurrencyCode',
                                                                          usage: #RESULT } ]
                                            } ]
      ConnectionID,
      FlightDate,
      FlightPrice,
      @Consumption.valueHelpDefinition: [ {entity: { name:    'I_Currency',
                                                     element: 'Currency' } } ]
      CurrencyCode,

      /* Associations */
      _Carrier,
      _Customer,
      _Travel : redirected to parent ZC_AS_TRAVEL_U_OS
}
