require "test_helper"

class ActiveStorageBlobPartialTest < ActionView::TestCase
  test "previewable blob that is not an image renders its preview" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("%PDF-1.4"), filename: "buyers-guide.pdf", content_type: "application/pdf")
    blob.define_singleton_method(:previewable?) { true }

    render partial: "active_storage/blobs/blob", locals: { blob: blob }

    assert_select "figure img[alt=?]", "Buyers guide"
  end
end
