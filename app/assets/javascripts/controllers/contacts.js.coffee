# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.contacts =

  index: (params = {}, cb = (->)) ->
    _popup = $("DIV#modal")
    _popup.html render_partial("contacts/modal")
    _popup.modal 'show'
    cb()

  send: (params = {}, fields = {}, cb = (->)) ->
    req = $.post "/contacts/send", fields, (data) ->
      $("#follow_#{params.id}").html render_partial("users/del_follow", {id: params.id})
      cb()
    req.error (data) ->
      $("#follow_#{params.id}").html render_partial("users/add_follow", {id: params.id})
    cb()