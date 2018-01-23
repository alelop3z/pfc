# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.users =

  add_comment: (params = {}, fields = {}, cb = (->)) ->
    _comments = $("DIV#comments")
    _comment = $("TEXTAREA#comment")
    
    req = $.post "/users/#{params.id}/add_comment.json", fields, (data) ->
      _comment.removeClass("alert-danger").val("")
      window.users.wall({id: params.id, timestamp: _comments.attr("data-timestamp")})
      cb()
    req.error (data) ->
      _errors = $.parseJSON(data.responseText).errors
      $("#add-comment .alert-danger").html(_errors).removeClass 'hidden'
      _comment.addClass("alert-danger")
      cb()

  add_favorite: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/users/#{params.id}/add_favorite.json?type=#{params.type}", fields, (data) ->
      _object = $("##{params.type}_#{params.id} .star")

      if _object.hasClass("favorite")
        _object.removeClass("favorite")
      else
        _object.addClass("favorite")

      window.dashboard.reload_menu_lateral()
      cb()
    req.error (data) ->
      cb()

  add_follow: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/users/#{params.id}/add_follow.json", fields, (data) ->
      $("#follow_#{params.id}").html render_partial("users/del_follow", {id: params.id})
      cb()
    req.error (data) ->
      $("#follow_#{params.id}").html render_partial("users/add_follow", {id: params.id})
      cb()

  add_message: (params = {}, fields = {}, cb = (->)) ->
    _comments = $("DIV#conversation")
    _comment = $("TEXTAREA#message")

    req = $.post "/users/#{params.id}/add_message.json", fields, (data) ->
      _comment.removeClass("alert-danger").val("")
      $("DIV#right-column").html render_partial("users/messages", {conversation: data.conversation, current: current_user().user})
      $(".timeago").timeago()
      cb()
    req.error (data) ->
      _comment.addClass("alert-danger")
      cb()

  archive: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/archive", (data) ->
      cb()

  conversation: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/conversation", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "inbox", current: current_user().user, user: current_user().user})
      $("DIV#right-column").html render_partial("users/messages", {conversation: data.conversation, current: current_user().user})
      $("BODY").animate
        scrollTop: $("#add-message").offset().top
        , 2000
      $(".timeago").timeago()
      cb()

  del_follow: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/users/#{params.id}/del_follow.json", fields, (data) ->
      $("#follow_#{params.id}").html render_partial("users/add_follow", {id: params.id})
      cb()
    req.error (data) ->
      $("#follow_#{params.id}").html render_partial("users/del_follow", {id: params.id})
    cb()

  edit_user: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/edit_user", (data) ->
      console.log data
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {current: current_user().user, user: data.user})
      $("#right-column").html render_partial("users/edit_user", {user: data.user})
      cb()

  events: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/events", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "events", current: current_user().user, user: data.user})
      $("#right-column").html render_partial("users/events_right_column", {current: current_user().user, events: data.events, user: data.user})
      cb()

  favorites: (params = {}, cb = (->)) ->
    if params.type
      _type = params.type 
    else
      _type = "route"

    $.getJSON "/users/#{params.id}/favorites?type=#{_type}", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "favorites", current: current_user().user, user: data.user})
      $("#right-column").html render_partial("users/favorites_right_column", {current: current_user().user, objects: data.objects, user: data.user, type: _type})
      cb()

  follows: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/follows", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {current: current_user().user, user: data.user})
      $("#right-column").html render_partial("users/friendships_right_column", {user: data.user, followers: data.follows})
      cb()

  followers: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/followers", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {current: current_user().user, user: data.user})
      $("#right-column").html render_partial("users/friendships_right_column", {user: data.user, followers: data.followers})
      cb()

  friendships: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/friendships", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "friendships", current: current_user().user, user: data.user})
      $("#right-column").html render_partial("users/friendships_right_column", {user: data.user, friendships: data.friendships})
      cb()

  inbox: (params = {}, cb = (->)) ->
    _url = "/users/#{params.id}/inbox"
    _url += "/filter/#{params.filter}" if params.filter
    _url += "/page/#{params.page}" if params.page

    $.getJSON _url, (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "inbox", current: current_user().user, user: data.user})
      $("DIV#right-column").html render_partial("users/conversations", {conversations: data.conversations, current: current_user().user})
      $(".timeago").timeago()
      cb()

  remove_friendship: (params = {}, cb = (->)) ->
    cb()

  routes: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/routes", (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("#left-column").html render_partial("users/left_column", {action: "routes", current: current_user().user, user: data.user})
      $("#right-column").html render_partial("users/routes_right_column", {current: current_user().user, routes: data.routes, user: data.user})
      cb()

  search: (params = {}, cb = (->)) ->
    
    cb()

  sent: (params = {}, cb = (->)) ->
    $.getJSON "/users/#{params.id}/sent", (data) ->
      cb()

  update_user: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/users/#{params.id}/update_user.json", fields, (data) ->
      navigate_to {linkTo: "users#wall", id: current_user().user.id_to_s}
      cb()
    req.error (data) ->
      cb()

  update_wall: (params = {}, cb = (->)) ->
    _comments = $("#comments")
    _loading = $("#loading")
    _timestamp = $("#comments .content").last().attr("data-timestamp")

    _url = "/users/#{params.id}/wall"
    _url += "?timestamp=#{_timestamp}"
    _loading.show()

    $.getJSON _url, (data) ->
      _comments.append render_partial("users/update_wall", {comments: data.comments, current: current_user().user, user: data.user})
      _loading.hide()
      $(".timeago").timeago()
      activateScrollInfinite()
      cb()

  wall: (params = {}, cb = (->)) ->
    # Genero la url que solicita información
    _url = "/users/#{params.id}/wall"
    _url += "?timestamp=#{params.timestamp}" if params.timestamp

    $.getJSON _url, (data) ->
      $("SECTION#section").html render_partial("users/layout")
      $("DIV#right-column").html render_partial("users/wall", {comments: data.comments, current: current_user().user, user: data.user})
      $("#left-column").html render_partial("users/left_column", {action: "wall", current: current_user().user, user: data.user})
      $(".timeago").timeago()
      cb()


@current_user = () ->
  if window.user
    window.user
  else
    $.ajax
      url: "/users/user.json",
      dataType: 'json',
      async: false,
      success: (data) ->
        window.user = data
    window.user

@reload_current_user = () ->
  if window.user
    _url = "/users/" + window.user._id + ".json"
    $.ajax
      url: _url,
      dataType: 'json',
      async: false,
      success: (data) ->
        window.user = data.user
  else
    _url = "/users/user.json"
    $.ajax
      url: _url,
      dataType: 'json',
      async: false,
      success: (data) ->
        window.user = data
  window.user

jQuery ->
  $("#submit-sign-up").bind 'click', (event) ->
    $("#user_password_confirmation").attr("value", $("#user_password").val())

  show_hidden_buttons = ->
    $(@).addClass("bg-grey")
  hide_hidden_buttons = ->
    $(@).removeClass("bg-grey")

  $("#comments .content").hover show_hidden_buttons, hide_hidden_buttons
