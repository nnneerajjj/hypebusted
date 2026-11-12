# The importmap for Avo pages: the app importmap plus the admin-only pins in config/importmap_avo.rb.
# Rendered by app/views/avo/partials/_head.html.erb.
module AvoImportmap
  PATH = Rails.root.join("config/importmap_avo.rb")

  # Rebuilt per request while code reloads, so changed asset digests show up; memoized otherwise.
  def self.map
    return @map if @map

    map = Importmap::Map.new
    (Rails.application.config.importmap.paths + [ PATH ]).each { |path| map.draw(path) }
    Rails.application.config.cache_classes ? (@map = map) : map
  end
end
