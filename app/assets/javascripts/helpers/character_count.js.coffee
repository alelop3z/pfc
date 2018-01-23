jQuery ->
  $(document).on 'keyup change input paste', '#add-comment #message, #add-comment #comment', (e) ->
    _span = $(".remaining")
    _length = $(@).val().length
    _length_remaining = _span.attr("data-length-remaining")
    _count = parseInt(_length_remaining) - parseInt(_length)
    _span.attr("data-count", _count)

    if _count < 0 
      $("#add-comment INPUT").attr("disabled", true)
      $("#add-comment").addClass("error")
    else
      $("#add-comment INPUT").attr("disabled", false)
      $("#add-comment").removeClass("error")