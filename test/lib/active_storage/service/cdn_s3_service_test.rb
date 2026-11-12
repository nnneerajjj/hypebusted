require "test_helper"
require "active_storage/service/cdn_s3_service"

class CdnS3ServiceTest < ActiveSupport::TestCase
  setup do
    @service = ActiveStorage::Service::CdnS3Service.new(
      bucket: "hypebusted", region: "us-east-1", access_key_id: "x", secret_access_key: "y",
      cdn_host: "https://cdn.hypebusted.com/",
      upload: { cache_control: "public, max-age=31536000, immutable" }
    )
  end

  test "serves permanent URLs from the CDN host" do
    assert_equal "https://cdn.hypebusted.com/abc123", @service.url("abc123", expires_in: 5.minutes, disposition: :inline, filename: ActiveStorage::Filename.new("a.png"), content_type: "image/png")
  end

  test "is public" do
    assert_predicate @service, :public?
  end

  test "does not send an ACL so the bucket can keep ACLs disabled" do
    assert_not_includes @service.upload_options.keys, :acl
  end

  test "keeps the long-lived Cache-Control header on uploads" do
    assert_equal "public, max-age=31536000, immutable", @service.upload_options[:cache_control]
  end
end
