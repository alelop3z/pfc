autocomplete = undefined
autocomplete_event = undefined
autocomplete_route = undefined
autocomplete_options = types: [ '(regions)' ]
directionsDisplay = new google.maps.DirectionsRenderer()
directionsService = new google.maps.DirectionsService()
geocoder = new google.maps.Geocoder()
elevator = new google.maps.ElevationService()
handler = Gmaps.build('Google', { markers: { clusterer: undefined  } })
markers = []
_polylines = []
polyline_color = "#ff4621"
refresh = false

calc_route = (origin, destination) ->
  _origin = new google.maps.LatLng(origin)
  _destination = new google.maps.LatLng(destination)

  request =
    origin: _origin,
    destination: _destination,
    travelMode: google.maps.TravelMode.DRIVING

  directionsService.route request, (response, status) ->
    directionsDisplay.setDirections response  if status is google.maps.DirectionsStatus.OK
    return

event_autocomplete = (_edit) ->
  autocomplete_event = document.getElementById('event_city')
  generate_autocomplete autocomplete_event

  google.maps.event.addListener autocomplete, 'place_changed', ->
    place = autocomplete.getPlace()
    if (!place.geometry)
      return

    handler.getMap().fitBounds place.geometry.viewport

  $('#event_city').keypress (e) ->
    if e.which == 13
      e.preventDefault()
      $(@).blur()
      
      if !_edit
        bounds_ne = handler.getMap().getBounds().getNorthEast()
        bounds_sw = handler.getMap().getBounds().getSouthWest()
        event_type = get_check_event_type()
        from = get_init_date("event")
        to = get_finish_date("event")

        $.getJSON "/events", {lat_ne: bounds_ne.lat(), lat_sw: bounds_sw.lat(), lng_ne: bounds_ne.lng(), lng_sw: bounds_sw.lng(), event_type: event_type, to: to, from: from}, (data) ->
          markers = handler.addMarkers(data.markers)
          console.log(data.events)
          $("DIV#right-column").html render_partial("events/events", {current: current_user().user, events: data.events})

      return

route_autocomplete = (_edit) ->
  autocomplete_route = document.getElementById('route_city')
  generate_autocomplete autocomplete_route

  google.maps.event.addListener autocomplete, 'place_changed', ->
    place = autocomplete.getPlace()
    if (!place.geometry)
      return

    handler.getMap().fitBounds place.geometry.viewport

  $('#route_city').keypress (e) ->
    if e.which == 13
      e.preventDefault()
      $(@).blur()
      
      if !_edit
        bounds_ne = handler.getMap().getBounds().getNorthEast()
        bounds_sw = handler.getMap().getBounds().getSouthWest()
        difficult = get_check_difficult()
        route_type = get_check_route_type()

        $.getJSON "/routes", {dif: difficult, lat_ne: bounds_ne.lat(), lat_sw: bounds_sw.lat(), lng_ne: bounds_ne.lng(), lng_sw: bounds_sw.lng(), route_type: route_type}, (data) ->
          markers = handler.addMarkers(data.markers)
          $("DIV#right-column").html render_partial("routes/routes", {current: current_user().user, routes: data.routes})

      return

generate_autocomplete = (_autocomplete) ->
  autocomplete = new (google.maps.places.Autocomplete)(_autocomplete, autocomplete_options)
  return

geocodePosition = (pos, object, field) ->
  geocoder.geocode { latLng: pos }, (responses) ->
    if responses and responses.length > 0
      $('#' + object + '_' + field).val(responses[0].formatted_address)
    else
      $('#' + object + '_' + field).val()
    return
  return

@codeAddress = (object, field) ->
  address = document.getElementById(object + '_' + field).value
  geocoder.geocode
    address: address
  , (results, status) ->
    if status is google.maps.GeocoderStatus.OK
      handler.map.centerOn results[0].geometry.location
      handler.removeMarkers(markers)
      placeMarker(results[0].geometry.location, object, true, true)
    return

  return

display_on_map = (position) ->
  handler.map.centerOn(lat: position.coords.latitude, lng: position.coords.longitude);

@show_event = (id, marker, object, edit = false) ->
  handler.buildMap { provider: { maxZoom: 18, minZoom: 5 }, internal: {id: id} }, ->
    if edit
      event_autocomplete(edit)

      if marker.length > 0
        _marker = marker[0]
        # placeMarker(_marker, object, true, true)
        # handler.map.centerOn({ lat: _marker.lat, lng: _marker.lng })
        markers = handler.addMarkers(marker)
        handler.map.centerOn {lat: marker[0].lat, lng: marker[0].lng}
      else
        geolocation()

      google.maps.event.addListener handler.getMap(), 'click', (event) ->
        handler.removeMarkers(markers)
        placeMarker(event.latLng, object, true, true)
        updateFormLocation(event.latLng, object)
    else
      handler.addMarkers(marker)
      handler.map.centerOn {lat: marker[0].lat, lng: marker[0].lng}
      handler.getMap().setZoom(15)

@show_events = (id, lat, lng, _markers) ->
  handler.buildMap { provider: { maxZoom: 18, minZoom: 5 }, internal: {id: id} }, ->
    event_autocomplete(false)

    if (lat == undefined || lng == undefined)
      geolocation()
    else
      handler.map.centerOn({ lat: lat, lng: lng })

    markers = handler.addMarkers(_markers)

    google.maps.event.addListener handler.getMap(), 'idle', (event) ->
      map = handler.getMap()
      bounds_ne = map.getBounds().getNorthEast()
      bounds_sw = map.getBounds().getSouthWest()
      handler.removeMarkers(markers)
      event_type = get_check_event_type()
      from = get_init_date("event")
      to = get_finish_date("event")

      $.getJSON "/events", {lat_ne: bounds_ne.lat(), lat_sw: bounds_sw.lat(), lng_ne: bounds_ne.lng(), lng_sw: bounds_sw.lng(), event_type: event_type, from: from, to: to}, (data) ->
        markers = handler.addMarkers(data.markers)
        $("DIV#right-column").html render_partial("events/events", {current: current_user().user, events: data.events})

    # Lanzo el evento al clickar en un checkbox
    $("INPUT[type=checkbox]").on 'change', (event) ->
      google.maps.event.trigger(handler.getMap(), 'idle')

    # Lanzo el evento al clickar en un checkbox
    $(".datepicker").on 'change', (event) ->
      google.maps.event.trigger(handler.getMap(), 'idle')

geolocation = ->
  if (navigator.geolocation)
    navigator.geolocation.getCurrentPosition(display_on_map)

get_check_difficult = ->
  elem = []
  $("DIV.difficult INPUT[type=checkbox]:checked").each ->
    elem.push($(@).val())
  return elem.join(",")

get_check_event_type = ->
  elem = []
  $("DIV.event-types INPUT[type=checkbox]:checked").each ->
    elem.push($(@).val())
  return elem.join(",")

get_check_route_type = ->
  elem = []
  $("DIV.route-types INPUT[type=checkbox]:checked").each ->
    elem.push($(@).val())
  return elem.join(",")

get_finish_date = (_object) ->
  return $("##{_object}_to").val()

get_init_date = (_object) ->
  return $("##{_object}_from").val()

getElevation = (event) ->
  locations = []
  elevation = 0
  # Retrieve the clicked location and push it on the array
  clickedLocation = event.latLng
  locations.push clickedLocation
  # Create a LocationElevationRequest object using the array's one value
  positionalRequest = 'locations': locations
  # Initiate the location request
  elevator.getElevationForLocations positionalRequest, (results, status) ->
    if status == google.maps.ElevationStatus.OK
      # Retrieve the first result
      if results[0]
        # Open an info window indicating the elevation at the clicked position
        elevation = parseInt results[0].elevation
        $("#points").append("<input type=\"hidden\" name=\"route[points][#{markers.length}][ele]\" value=\"#{elevation}\" />")
        return

placeMarker = (location, object = false, center_map = false, draggable = false) ->
  if location
    try
      marker = handler.addMarker
        lat: location.lat(),
        lng: location.lng(),
        { draggable: draggable }
    catch 
      marker = handler.addMarker
        lat: location.lat,
        lng: location.lng,
        { draggable: draggable }

    markers.push marker

    if center_map
      handler.map.centerOn(location)

    if object
      # Listen to drag & drop
      google.maps.event.addListener marker.serviceObject, 'dragend', (event) ->
        updateFormLocation(event.latLng, object)
        return

  return

@show_route = (id, _markers, polyline, edit = false) ->
  handler.buildMap { provider: { maxZoom: 18, minZoom: 5 }, internal: {id: id} }, ->
    if edit
      markers = handler.addMarkers(_markers)
      _polylines = []

      route_autocomplete(edit)

      if markers.length > 0
        handler.map.centerOn({ lat: markers[0].lat, lng: markers[0].lng })
      else
        geolocation()

      google.maps.event.addListener handler.getMap(), 'click', (event) ->
        placeMarker(event.latLng, false, false, false)
        $("#points").append("<input type=\"hidden\" name=\"route[points][#{markers.length}][lat]\" value=\"#{event.latLng.lat()}\" />")
        $("#points").append("<input type=\"hidden\" name=\"route[points][#{markers.length}][lng]\" value=\"#{event.latLng.lng()}\" />")
        getElevation(event)        
        _polylines.push({"lat": event.latLng.lat(), "lng": event.latLng.lng()})
        polylines = handler.addPolyline(_polylines, {strokeColor: polyline_color})  
        handler.map.centerOn(event.latLng)
        return
        
    else
      markers = handler.addMarkers(markers)
      polylines = handler.addPolyline(polyline, {strokeColor: polyline_color})
      handler.bounds.extendWith(polylines)
      handler.fitMapToBounds()

@show_routes = (id, lat, lng, _markers) ->
  handler.buildMap { provider: { maxZoom: 18, minZoom: 5 }, internal: {id: id} }, ->
    route_autocomplete(false)

    if (lat == undefined || lng == undefined)
      geolocation()
    else
      handler.map.centerOn({ lat: lat, lng: lng })

    markers = handler.addMarkers(_markers)

    google.maps.event.addListener handler.getMap(), 'idle', (event) ->
      map = handler.getMap()
      bounds_ne = map.getBounds().getNorthEast()
      bounds_sw = map.getBounds().getSouthWest()
      handler.removeMarkers(markers)
      difficult = get_check_difficult()
      route_type = get_check_route_type()

      $.getJSON "/routes", {dif: difficult, lat_ne: bounds_ne.lat(), lat_sw: bounds_sw.lat(), lng_ne: bounds_ne.lng(), lng_sw: bounds_sw.lng(), route_type: route_type}, (data) ->
        markers = handler.addMarkers(data.markers)
        $("DIV#right-column").html render_partial("routes/routes", {current: current_user().user, routes: data.routes})

    # Lanzo el evento al clickar en un checkbox
    $("INPUT[type=checkbox]").on 'change', (event) ->
      google.maps.event.trigger(handler.getMap(), 'idle')

removeMarkers = (markers) ->
  for marker in markers
    marker.removeMarkers

updateFormLocation = (location, object) ->
  $('#' + object + '_latitude').val(location.lat())
  $('#' + object + '_longitude').val(location.lng())
  geocodePosition(location, object, 'address')

updateMarkers = (markers) ->
  markers = handler.addMarkers(markers)
  handler.bounds.extendWith(markers)
  handler.fitMapToBounds()
