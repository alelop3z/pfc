# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.events =

  add_comment: (params = {}, fields = {}, cb = (->)) ->
    _comments = $("DIV#comments")
    _comment = $("TEXTAREA#comment")

    req = $.post "/events/#{params.id}/add_comment.json", fields, (data) ->
      _comment.removeClass("alert-danger").val("")
      window.events.show({id: params.id, timestamp: _comments.attr("data-timestamp")})
      cb()
    req.error (data) ->
      _comment.addClass("alert-danger")
      cb()

  add_favorite: (params = {}, cb = (->)) ->
    req = $.post "/events/#{params.id}/add_favorite.json", (data) ->
      $("#event_#{params.id}").addClass("favorite")
      cb()

  confirm_destroy_event: (params = {}, cb = (->)) ->
    _popup = $("DIV#modal")

    req = $.post "/events/#{params.id}/destroy_event.json", (data) ->
      _popup.modal 'hide'
      $("#event_#{params.id}").remove()
      navigate_to {linkTo: "user#events", id: data.event.user_id_to_s}
      cb()
    req.error (data) ->
      _popup.html render_partial("routes/confirm_destroy_event_error", {event: data.event})
      _popup.modal 'show'
      cb()

  create: (params = {}, fields = {}, cb = (->)) ->
    console.log fields
    
    req = $.post "/events.json", fields, (data) ->
      navigate_to {linkTo: "events#show", id: data.event.id_to_s}
      cb()
    req.error (data) ->
      _errors = $.parseJSON(data.responseText).errors
      $(".alert-danger").html(_errors).removeClass 'hidden'
      cb()

  destroy_event: (params = {}, cb = (->)) ->
    $.getJSON "/events/#{params.id}.json", (data) ->
      if data.event.user_id_to_s == current_user().user.id_to_s
        _popup = $("DIV#modal") 
        _popup.html render_partial("events/popup_destroy_event", {event: data.event})
        _popup.modal 'show'
        cb()
      else
        cb()

  edit: (params = {}, cb = (->)) ->
    $.getJSON "/events/#{params.id}/edit", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "events", current: current_user().user, user: current_user().user})
      $("DIV#right-column").html render_partial("events/edit", {current: current_user().user, event: data.event})
      show_event("map", data.markers, "event", true)
      cb()

  index: (params = {}, cb = (->)) ->
    $.getJSON "/events", (data) ->
      $("SECTION#section").html render_partial("users/layout_min")
      $("#left-column").html render_partial("events/map", {events: data.events, user: current_user().user})
      $("DIV#right-column").html render_partial("events/events", {current: current_user().user, events: data.events})
      show_events("map", undefined, undefined, data.markers)
      cb()

  new: (params = {}, cb = (->)) ->
    $.getJSON "/events/new", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "events", current: current_user().user, user: current_user().user})
      $("DIV#right-column").html render_partial("events/new", {current: current_user().user, event: data})
      show_event("map", data.marker, "event", true)
      cb()

  remove: (params = {}, cb = (->)) ->
    req = $.post "/events/#{params.id}/remove.json", (data) ->
      navigate_to {linkTo: "users#events", id: data.user.id_to_s}
      cb()

  remove_favorite: (params = {}, cb = (->)) ->
    req = $.post "/events/#{params.id}/remove_favorite.json", (data) ->
      $("#event_#{params.id}").removeClass("favorite")
      cb()

  share_email_popup: (params = {}, cb = (->)) ->
    $.getJSON "/events/#{params.id}", (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("events/share_email", {event: data.event})
      _popup.modal 'show'
      cb()

  share_email: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/events/#{params.id}/share_email.json", fields, (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("events/share_email_ok")
      _popup.modal 'show'
      cb()
    req.error (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("events/share_email_ko")
      _popup.modal 'show'
      cb()

  show: (params = {}, cb = (->)) ->
    $.getJSON "/events/#{params.id}", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "events", current: current_user().user, user: current_user().user})
      $("DIV#right-column").html render_partial("events/show", {comments: data.comments, current_user: data.current_user, event: data.event, user: data.user})
      show_event("map", data.markers, "event", false)
      $(".timeago").timeago()
      cb()

  update: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/events/#{params.id}/update.json", fields, (data) ->
      navigate_to {linkTo: "events#show", id: data.event.id_to_s}
      cb()
    req.error (data) ->
      _errors = $.parseJSON(data.responseText).errors
      
      cb()

jQuery ->
  $(document).on "change", "#event_address", (e) ->
    codeAddress("event", "address")