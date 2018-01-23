# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.routes =

  add_comment: (params = {}, fields = {}, cb = (->)) ->
    _comments = $("DIV#comments")
    _comment = $("TEXTAREA#comment")

    req = $.post "/routes/#{params.id}/add_comment.json", fields, (data) ->
      _comment.removeClass("alert-danger").val("")
      window.routes.show({id: params.id, timestamp: _comments.attr("data-timestamp")})
      cb()
    req.error (data) ->
      _comment.addClass("alert-danger")
      cb()

  confirm_destroy_route: (params = {}, cb = (->)) ->
    _popup = $("DIV#modal")

    req = $.post "/routes/#{params.id}/destroy_route.json", (data) ->
      _popup.modal 'hide'
      $("#route_#{params.id}").remove()
      navigate_to {linkTo: "user#routes", id: data.route.user_id_to_s}
      cb()
    req.error (data) ->
      _popup.html render_partial("routes/confirm_destroy_route_error", {route: data.route})
      _popup.modal 'show'
      cb()

  create: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/routes.json", fields, (data) ->
      navigate_to {linkTo: "routes#show", id: data.route.id_to_s}
      cb()
    req.error (data) ->
      cb()

  destroy_route: (params = {}, cb = (->)) ->
    $.getJSON "/routes/#{params.id}.json", (data) ->
      if data.route.user_id_to_s == current_user().user.id_to_s
        _popup = $("DIV#modal") 
        _popup.html render_partial("routes/popup_destroy_route", {route: data.route})
        _popup.modal 'show'
        cb()
      else
        cb()

  edit: (params = {}, cb = (->)) ->
    $.getJSON "/routes/#{params.id}/edit", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "routes", current: current_user().user, user: current_user().user})
      $("DIV#right-column").html render_partial("routes/edit", {current: current_user().user, route: data.route})
      show_route("map", data.points, data.markers, true)
      cb()

  import: (params = {}, fields = {}, cb = (->)) ->
    _import_url = $("INPUT#url")
    _popup = $("DIV#modal")

    req = $.post "/routes/import.json", fields, (data) ->
      console.log "CORRECTO"
      console.log data

      _import_url.removeClass("alert-danger").val("")
      _popup.modal 'hide'
      navigate_to({linkTo: "routes#edit", id: data.route.id_to_s})
      cb()
    req.error (data) ->
      _errors = $.parseJSON(data.responseText).errors
      _import_url.addClass("alert-danger")
      cb()

  index: (params = {}, cb = (->)) ->
    $.getJSON "/routes", (data) ->
      $("SECTION#section").html render_partial("users/layout_min")
      $("#left-column").append render_partial("routes/map", {user: current_user().user, routes: data.routes})
      $("#right-column").html render_partial("users/routes_right_column", {current: current_user().user, routes: data.routes, user: current_user().user})
      $(".timeago").timeago()
      show_routes("map", undefined, undefined, data.markers)
      cb()

  new: (params = {}, cb = (->)) ->
    if params.modal == true
      _popup = $("DIV#modal")
      _popup.html render_partial("routes/modal")
      _popup.modal 'show'
      cb()
    else
      _popup = $("DIV#modal")
      _popup.modal 'hide'

      $.getJSON "/routes/new", (data) ->
        $("SECTION#section").html render_partial("users/layout")
        $("#left-column").html render_partial("users/left_column", {action: "routes", current: current_user().user, user: current_user().user})
        $("DIV#right-column").html render_partial("routes/new", {current: current_user().user, route: data.route})
        show_route("map", data.points, data.markers, true)
        cb()

  new_import: (params = {}, cb = (->)) ->
    $(".route-select").addClass("hidden")
    $(".route-import").removeClass("hidden")
    cb()

  remove: (params = {}, cb = (->)) ->
    req = $.post "/routes/#{params.id}/remove.json", (data) ->
      navigate_to {linkTo: "users#routes", id: data.user.id_to_s}
      cb()

  remove_favorite: (params = {}, cb = (->)) ->
    req = $.post "/routes/#{params.id}/remove_favorite.json", (data) ->
      $("#route_#{params.id}").removeClass("favorite")
      cb()
    
  share_email_popup: (params = {}, cb = (->)) ->
    $.getJSON "/routes/#{params.id}", (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("routes/share_email", {route: data.route})
      _popup.modal 'show'
      cb()

  share_email: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/routes/#{params.id}/share_email.json", fields, (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("routes/share_email_ok")
      _popup.modal 'show'
      cb()
    req.error (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("routes/share_email_ko")
      _popup.modal 'show'
      cb()

  show: (params = {}, cb = (->)) ->
    $.getJSON "/routes/#{params.id}", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "routes", current: current_user().user, user: current_user().user})
      $("DIV#right-column").html render_partial("routes/show", {comments: data.comments, current_user: data.current_user, route: data.route, user: data.user})
      $(".timeago").timeago()
      show_route("map", data.points, data.markers, false)
      console.log data.elevations
      drawChart(data.route.name, data.elevations)
      cb()

  update: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/routes/#{params.id}/update.json", fields, (data) ->
      navigate_to {linkTo: "routes#show", id: data.route.id_to_s}
      cb()
    req.error (data) ->
      cb()

  update_index: (params = {}, cb = (->)) ->
    $.getJSON "/routes?city=#{params.id}", (data) ->
      $("#right-column").html render_partial("users/routes_right_column", {current: current_user().user, routes: data.routes, user: current_user().user})
      $(".timeago").timeago()
      cb()

jQuery ->
