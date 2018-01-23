window.dashboard =
	reload_menu_lateral: (params = {}, cb = (->)) ->
		$.ajax
			url: "/users/user.json",
			dataType: 'json',
			async: false,
			success: (data) ->
				window.user = data

				if parseInt(data.user.num_routes) > 0
					$(".nav-pills A[data-link-to=users#routes] .badge").removeClass("hidden").html(data.user.num_routes)
				else
					$(".nav-pills A[data-link-to=users#routes] .badge").addClass("hidden")

				if parseInt(data.user.num_events) > 0
					$(".nav-pills A[data-link-to=users#events] .badge").removeClass("hidden").html(data.user.num_events)
				else
					$(".nav-pills A[data-link-to=users#events] .badge").addClass("hidden")

				if parseInt(data.user.num_favorites) > 0
					$(".nav-pills A[data-link-to=users#favorites] .badge").removeClass("hidden").html(data.user.num_favorites)
				else
					$(".nav-pills A[data-link-to=users#favorites] .badge").addClass("hidden")

				if parseInt(data.user.num_conversations) > 0
					$(".nav-pills A[data-link-to=users#inbox] .badge").removeClass("hidden").html(data.user.num_conversations)
				else
					$(".nav-pills A[data-link-to=users#inbox] .badge").addClass("hidden")

		cb()

	reload_menu: (params={}, cb = (->)) ->
		$.ajax
			url: "/users/user.json",
			dataType: 'json',
			async: false,
			success: (data) ->
				window.user = data

		$.getJSON "/users/reload_menu.json", (data) ->
			if parseInt(data.user.count_messages.unreads) > 0
				$("NAV .navbar-right .conversations .badge").removeClass("hidden").html(data.user.count_messages.unreads)
			else
				$("NAV .navbar-right .conversations .badge").addClass("hidden")
			cb()

jQuery ->
	if current_user().user.name
		setInterval ()->
				window.dashboard.reload_menu()
			, 60000

	if current_user().user.name
		window.dashboard.reload_menu()
