# Rack::ETag adds a body-digest ETag to every 200 response. A "no-store" response
# (e.g. a super admin's page) must never be cached or revalidated, so drop the ETag.
class NoStoreWithoutEtag
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers.delete("etag") if headers["cache-control"].to_s.include?("no-store")
    [ status, headers, body ]
  end
end
