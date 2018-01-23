# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.comments =

  confirm_destroy_comment: (params = {}, cb = (->)) ->
    _popup = $("DIV#modal")

    req = $.post "/comments/#{params.id}/destroy.json", (data) ->
      _popup.modal 'hide'
      $("#comment_#{params.id}").remove()
      cb()
    req.error (data) ->
      _popup.html render_partial("comments/confirm_destroy_comment_error", {comment: data.comment, current: current_user().user})
      _popup.modal 'show'
      cb()

  destroy: (params = {}, cb = (->)) ->
    $.getJSON "/comments/#{params.id}.json", (data) ->
      if data.comment.user_id_to_s == current_user().user.id_to_s
        _popup = $("DIV#modal") 
        _popup.html render_partial("comments/popup_destroy_comment", {comment: data.comment})
        _popup.modal 'show'
        cb()
      else
        cb()

  edit: (params = {}, cb = (->)) ->
    $.getJSON "/comments/#{params.id}/edit.json", (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("comments/edit", {comment: data.comment})
      _popup.modal 'show'
      cb()

  mark_as_offensive: (params = {}, cb = (->)) ->
    req = $.post "/comments/#{params.id}/mark_as_offensive.json", (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("comments/mark_as_offensive_ok")
      _popup.modal 'show'
      cb()
    req.error (data) ->
      _popup = $("DIV#modal")
      _popup.html render_partial("comments/mark_as_offensive_ko")
      _popup.modal 'show'
      cb()

  update: (params = {}, fields = {}, cb = (->)) ->
    _popup = $("DIV#modal")
    
    req = $.post "/comments/#{params.id}/update.json", fields, (data) ->
      console.log data.comment
      console.log current_user().user 
      $("#comment_#{params.id}").html render_partial("users/content_comment", {comment: data.comment, current: current_user().user})
      _popup.modal 'hide'
      cb()
    req.error (data) ->
      _popup.html render_partial("comments/edit_error", {comment: data.comment, current: current_user().user})
      cb()