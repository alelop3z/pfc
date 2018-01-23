@popped = false
@initialURL = window.location.href
@cache = {}
@current_state = {}
@destination_state = {}

if window.addEventListener
  window.addEventListener "popstate", (e) ->
    initialPop = !window.popped && window.location.href == window.initialURL
    window.popped = true

    if initialPop
      return
    else
      if e.state
        navigate_to e.state
      else
        window.location = window.location

@navigate_to = (data, params = false) ->
  if data.linkTo.indexOf('#')==0
    c = data.linkTo.split('#')[1]
    a = data.linkTo.split('#')[2]
  else
    c = data.linkTo.split('#')[0]
    a = data.linkTo.split('#')[1]

  if params
    eval "#{c}.#{a}(data, params)"
  else
    @current_state = @destination_state if data.linkTo.indexOf('#')!=0
    @destination_state = data if data.linkTo.indexOf('#')!=0
    eval "#{c}.#{a}(data)"
    @current_state = data if data.linkTo.indexOf('#')!=0

@activateScrollInfinite = () ->
  $(document).on "scroll", (e) ->
    scrollInfinite()    

@scrollInfinite = () ->
  if ($(window).scrollTop() == $(document).height() - $(window).height())
    $(document).off 'scroll'
    _loading = $("#loading")
    
    if _loading and _loading.data("controller") != undefined
      eval("window.#{_loading.data("controller")}.#{_loading.data("action")}({id: '#{_loading.data("id")}'})")

jQuery ->
  $(document).on "click", "A[rel=external]", (e) ->
    e.preventDefault()
    window.open $(@).attr('href')

  # Gestión de formularios y enlaces con elementos data
  $(document).on "click", "a[data-link-to], button[data-link-to]", (e) ->
    e.preventDefault()
    fix_last_screen_was = window.fix_last_screen
    navigate_to $(@).data()
    if !window.fix_last_screen && !fix_last_screen_was && $(@).data().linkTo.indexOf('#')!=0
      window.last_screen = $(@).data()
    history.pushState $(@).data(), $(@).text(), $(@).attr('href') unless $(@).data().linkTo.indexOf('#')==0

  $(document).on "submit", "form[data-link-to]", (e) ->
    e.preventDefault()
    navigate_to $(@).data(), $(@).serializeArray()

  $(document).on "focus", "INPUT#search", (e) ->
    $("DIV.form-group-search").addClass("complete")

  $(document).on "focus", ".datetimepicker", (e) ->
    $(@).datetimepicker

  $(document).on "focus", ".datepicker", (e) ->
    $(@).datetimepicker pickTime: false

  $(document).on "blur", "INPUT#search", (e) ->
    if $(@).val().length == 0
      $("DIV.form-group-search").removeClass("complete")

  $(document).on "focus", "#add-comment TEXTAREA, #add-message TEXTAREA", (e) ->
    $(@).parent("DIV.post").removeClass("col-xs-10").addClass("col-xs-12")
    $(@).addClass("complete")
    $(".remaining").removeClass("hidden")

  $(document).on "blur", "#add-comment TEXTAREA, #add-message TEXTAREA", (e) ->
    if $(@).val().length == 0
      $(@).parent("DIV.post").removeClass("col-xs-12").addClass("col-xs-10")
      $(@).removeClass("complete")
      $(".remaining").addClass("hidden")

  $(document).on "click", ".user-image IMG", (e) ->
    $("#user_avatar").click();

  $(document).on "scroll", (e) ->
    scrollInfinite()

  $(document).on 'keyup', "INPUT#search", (e) ->
    _url = "/users/search.json?text=#{$(@).val()}"

    $(@).autocomplete(
      source: (request, response) ->
        $.ajax
          url: _url
          data:
            featureClass: "P"
            style: "full"
            maxRows: 12
            name_startsWith: request.term

          success: (data) ->
            response $.map(data.users, (item) ->
              icon: item.photo.replace("/detail/", "/thumb/")
              label: item.name
              value: item.id_to_s
            )
            return

        return

      minLength: 2
      select: (event, ui) ->
        navigate_to {linkTo: 'users#show', id: ui.item.value}
        return
    ).data("ui-autocomplete")._renderItem = (ul, item) ->
      $("<li>").append("<a data-id=#{item.value} data-link-to=users#wall href=/users/#{item.value}/wall><img src=#{item.icon} />" + item.label + "</a>").appendTo ul
