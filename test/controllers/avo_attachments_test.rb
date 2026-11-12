require "test_helper"

# The "Insert image" button uploads through Avo's existing attachments endpoint (R3).
class AvoAttachmentsTest < ActionDispatch::IntegrationTest
  FILENAME = "sample-product-shot.png".freeze

  def upload_image
    post IMAGE_UPLOAD_URL, params: {
      file: fixture_file_upload(FILENAME, "image/png"), filename: FILENAME, key: "tmp/test/sample.png"
    }
  end

  test "logged-out upload redirects to login and creates no blob" do
    assert_no_difference "ActiveStorage::Blob.count" do
      upload_image
    end
    assert_redirected_to "/session/new"
  end

  test "non-super-admin upload redirects home and creates no blob" do
    sign_in_as users(:two)
    assert_no_difference "ActiveStorage::Blob.count" do
      upload_image
    end
    assert_redirected_to "/"
  end

  test "super admin upload returns the sgid, url and href of a new image blob" do
    sign_in_as users(:one)
    assert_difference "ActiveStorage::Blob.count", 1 do
      upload_image
    end
    assert_response :success

    json = response.parsed_body
    %w[sgid url href].each { |key| assert json[key].present?, "missing #{key} in #{json}" }
    blob = ActionText::Attachable.from_attachable_sgid(json["sgid"])
    assert_equal ActiveStorage::Blob.last, blob
    assert_equal "image/png", blob.content_type
  end

  # R3d: the tag the Insert image button writes renders like a Trix upload
  test "uploaded image inserted as a tag in HTML mode renders as a captioned figure and cover image" do
    sign_in_as users(:one)
    upload_image
    assert_response :success
    json = response.parsed_body
    sgid = json["sgid"]
    blob = ActionText::Attachable.from_attachable_sgid(sgid)

    target = posts(:one)
    tag = %(<action-text-attachment sgid="#{sgid}" content-type="image/png" filename="#{FILENAME}" ) +
      %(url="#{ERB::Util.html_escape(json["url"])}" href="#{ERB::Util.html_escape(json["href"])}" ) +
      %(caption="Cap &amp; more" presentation="gallery"></action-text-attachment>)
    patch "/milo/resources/posts/#{target.id}", params: { post: {
      html_editor: "1", content_html: "<h2>Hi</h2>\n#{tag}", published_at: 1.day.ago
    } }
    assert_response :redirect
    sign_out

    get "/posts/#{target.reload.slug}"
    assert_response :success
    assert_select "article figure img[loading=lazy][decoding=async][alt=?]", "Cap & more"
    assert_select "article figure figcaption", text: "Cap & more"
    og_image = css_select('meta[property="og:image"]').first
    assert og_image, "expected og:image meta"
    assert_match %r{\Ahttp.*/#{Regexp.escape(blob.signed_id)}/#{Regexp.escape(blob.filename.to_s)}\z}, og_image["content"]
    assert_equal blob, target.cover_image.blob
  end
end
