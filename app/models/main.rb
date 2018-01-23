class Main

  # Constantes
  DIFFICULTY = [[I18n.t("main.difficulty.very_easy"), 0], [I18n.t("main.difficulty.easy"), 1], [I18n.t("main.difficulty.normal"), 2], [I18n.t("main.difficulty.difficult"), 3], [I18n.t("main.difficulty.very_difficult"), 4]]
  PER_PAGE = 20
  PRIVACITY = [[I18n.t("main.privacity.private"), true], [I18n.t("main.privacity.public"), false]]
  SEX_OPTIONS = [[I18n.t("users.form.select_sex"), ""], [I18n.t("users.form.male"), 0], [I18n.t("users.form.female"), 1]]
  TYPES = [[I18n.t("main.route_types.bmx"), 1], [I18n.t("main.route_types.ciclocross"), 2], [I18n.t("main.route_types.duatlon"), 3], [I18n.t("main.route_types.indoor"), 4], [I18n.t("main.route_types.mountain_bike"), 5], [I18n.t("main.route_types.mtb"), 6], [I18n.t("main.route_types.road"), 7], [I18n.t("main.route_types.trial"), 8], [I18n.t("main.route_types.triatlon"), 9]]

  # Métodos

  # Devuelve la dificultad
  def self.difficulty
    DIFFICULTY.map{|x| [x.first, x.last]}
  end

  # Devuelve los distintos tipos de privacidad
  def self.privacity
    PRIVACITY.map{|x| [x.first, x.last]}
  end

  # Devuelve los distintos tipos de ruta a realizar
  def self.types
    TYPES.map{|x| [x.first, x.last]}
  end

end
