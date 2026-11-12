require "test_helper"

class BlobImageSourceTest < ActionView::TestCase
  include ApplicationHelper

  Processed = Struct.new(:url)
  Representation = Struct.new(:processed)
  Service = Struct.new(:public?)
  FakeBlob = Struct.new(:service, :representation_args) do
    def representation(**args)
      self.representation_args = args
      @representation ||= Representation.new(Processed.new("https://cdn.hypebusted.com/variant-key"))
    end
  end

  test "uses the direct CDN URL of the processed variant when the service is public" do
    blob = FakeBlob.new(Service.new(true))
    assert_equal "https://cdn.hypebusted.com/variant-key", blob_image_source(blob, resize_to_limit: [ 1400, nil ], format: :webp)
    assert_equal({ resize_to_limit: [ 1400, nil ], format: :webp }, blob.representation_args)
  end

  test "keeps the Rails representation route when the service is private" do
    blob = FakeBlob.new(Service.new(false))
    assert_same blob.representation, blob_image_source(blob, format: :webp)
  end
end
