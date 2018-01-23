module EcoTemplateHandler
  def self.call(template)
    Eco.render(template.source.inspect, template.locals)
  end
end

ActionView::Template.register_template_handler(:eco, EcoTemplateHandler)