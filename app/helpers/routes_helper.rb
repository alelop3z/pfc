module RoutesHelper

  def draw_static_route_map(route, points, size = "512x512")
    raw "<img src=\"http://maps.google.com/maps/api/staticmap?path=color:0x8988E1|weight:4|enc:#{points}&amp;size=#{size}&amp;sensor=false\" alt=\"#{route.name}\" />"
  end

end