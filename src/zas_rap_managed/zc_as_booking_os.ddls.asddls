@EndUserText.label: 'Projection View for Booking'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZC_AS_BOOKING_OS
  as projection on ZI_AS_BOOKING_OS as Booking
{
  key BookingUuid,
      TravelUuid,
      @Search.defaultSearchElement: true
      BookingId,
      BookingDate,
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name:'/DMO/I_Customer', element: 'CustomerID' } }]
      CustomerId,
      _Customer.LastName as CustomerName,
      @Consumption.valueHelpDefinition: [{ entity: { name:'/DMO/I_Carrier', element: 'Airline_ID' } }]
      @ObjectModel.text.element: [ 'CarrierName' ]
      _Carrier.Name      as CarrierName,
      CarrierId,
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight', element: 'ConnectionID' },
      additionalBinding: [{ localElement: 'CarrierID', element: 'AirlineID' },
                          { localElement: 'FlightDate', element: 'FlightDate', usage: #RESULT },
                          { localElement: 'FlightPrice', element: 'Price', usage: #RESULT },
                          { localElement: 'CurrencyCode', element: 'CurrencyCode', usage: #RESULT }] }]
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Currency', element: 'Currency' } }]
      CurrencyCode,
      CreatedBy,
      LastChangedBy,
      LocalLastChangedAt,
      /* Associations */
      _Carrier,
      _Connection,
      _Currency,
      _Customer,
      _Flight,
      _Travel : redirected to parent ZC_AS_TRAVEL_OS
}
