require "active_storage/service/s3_service"

module ActiveStorage
  class Service
    # S3 service whose files are public and served from a CDN host (Cloudflare) instead of the bucket URL.
    # Unlike `public: true` on the stock S3 service it sends no ACL, so the bucket can keep ACLs disabled.
    class CdnS3Service < S3Service
      def initialize(cdn_host:, **options)
        super(**options, public: true)
        upload_options.delete(:acl)
        @cdn_host = cdn_host.chomp("/")
      end

      private
        def public_url(key, **)
          "#{@cdn_host}/#{key}"
        end
    end
  end
end
