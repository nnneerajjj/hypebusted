require "test_helper"

class AvoPostsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @post = posts(:one)
  end

  test "opens a post in Avo by its id" do
    get "/milo/resources/posts/#{@post.id}"

    assert_response :success
    assert_includes response.body, @post.title
  end

  test "failed slug change keeps the form pointed at the same post" do
    other = posts(:two)

    patch "/milo/resources/posts/#{@post.id}", params: { post: { slug: other.slug } }

    assert_response :unprocessable_content
    assert_select "form[action=?]", "/milo/resources/posts/#{@post.id}"
    assert_equal "first-blog-post", @post.reload.slug
    assert_equal other.slug, other.reload.slug
  end

  test "admin-entered slug is saved normalized" do
    patch "/milo/resources/posts/#{@post.id}", params: { post: { slug: " New Slug Here " } }

    assert_equal "new-slug-here", @post.reload.slug
  end

  # Raw HTML editing ("Edit as HTML")
  HTML_WRAPPER = "[data-resource-edit-target='contentHtmlTextareaWrapper']".freeze
  TRIX_WRAPPER = "[data-resource-edit-target='contentTrixWrapper']".freeze
  HTML_TOGGLE = "input[type=checkbox][name='post[html_editor]']".freeze

  def wrapper_classes(selector)
    node = css_select(selector).first
    assert node, "expected #{selector}"
    node["class"].to_s.split
  end

  def assert_html_toggle(checked:)
    toggle = css_select(HTML_TOGGLE).first
    assert toggle, "expected Edit as HTML checkbox"
    assert_equal checked, toggle["checked"].present?, "checkbox checked should be #{checked}"
    assert_includes toggle["data-action"].to_s, "resource-edit#toggle"
    targets = toggle["data-resource-edit-toggle-targets-param"].to_s
    assert_includes targets, "contentTrixWrapper"
    assert_includes targets, "contentHtmlTextareaWrapper"
  end

  def assert_trix_mode
    assert_html_toggle(checked: false)
    assert_includes wrapper_classes(HTML_WRAPPER), "hidden"
    assert_not_includes wrapper_classes(TRIX_WRAPPER), "hidden"
  end

  def html_textarea_text
    node = css_select("textarea[name='post[content_html]']").first
    assert node, "expected content_html textarea"
    node.text
  end

  def edit_post
    get "/milo/resources/posts/#{@post.id}/edit"
    assert_response :success
  end

  def update_post(**attrs)
    patch "/milo/resources/posts/#{@post.id}", params: { post: attrs }
  end

  test "edit form has trix, Edit as HTML toggle and HTML textarea in trix mode" do
    edit_post
    assert_select "[name='post[content]']"
    assert_trix_mode
    assert_equal @post.content.body.to_html, html_textarea_text
    assert_select "#{HTML_WRAPPER} textarea.font-mono[rows='100']"
    # Avo's autogrow sizes the textarea while hidden (height 0), so a min-height keeps it 100 lines tall.
    assert_select "#{HTML_WRAPPER} textarea[style*='min-height: 100lh']"
  end

  test "edit form textarea shows action-text-attachment tags verbatim" do
    blob = image_blob
    @post.update!(content: %(<div>Intro<action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment></div>))
    edit_post
    assert_equal @post.reload.content.body.to_html, html_textarea_text
    assert_includes html_textarea_text, "<action-text-attachment"
  end

  test "edit form shows the hint about markup being stripped" do
    edit_post
    assert_select "[data-resource-edit-target='htmlEditorBooleanWrapper']", text: /strip/i
  end

  test "new form has trix, Edit as HTML toggle and empty HTML textarea" do
    get "/milo/resources/posts/new"
    assert_response :success
    assert_select "[name='post[content]']"
    assert_trix_mode
    assert_equal "", html_textarea_text.strip
  end

  test "saving in HTML mode uses content_html and ignores trix content" do
    update_post(html_editor: "1", content_html: "<h1>Raw</h1>", content: "<div>trix</div>")
    assert_response :redirect
    assert_equal "<h1>Raw</h1>", @post.reload.content.body.to_html
  end

  test "saving in trix mode uses trix content and ignores content_html" do
    update_post(html_editor: "0", content_html: "<h1>Raw</h1>", content: "<div>trix</div>")
    assert_response :redirect
    assert_equal "<div>trix</div>", @post.reload.content.body.to_html
  end

  test "saving without html_editor uses trix content" do
    update_post(content_html: "<h1>Raw</h1>", content: "<div>trix</div>")
    assert_response :redirect
    assert_equal "<div>trix</div>", @post.reload.content.body.to_html
  end

  test "CRLF from the HTML textarea is stored as LF" do
    update_post(html_editor: "1", content_html: "<div>a</div>\r\n<div>b</div>")
    assert_response :redirect
    body = @post.reload.content.body.to_html
    assert_includes body, "<div>b</div>"
    assert_not_includes body, "\r"
  end

  test "blank HTML in HTML mode is rejected and re-renders in HTML mode" do
    original = @post.content.body.to_html
    update_post(html_editor: "1", content_html: "", content: original)
    assert_response :unprocessable_content
    assert_equal original, @post.reload.content.body.to_html
    assert_includes response.body, "can&#39;t be blank"
    assert_html_toggle(checked: true)
    assert_not_includes wrapper_classes(HTML_WRAPPER), "hidden"
    assert_includes wrapper_classes(TRIX_WRAPPER), "hidden"
  end

  test "failed save in HTML mode keeps the submitted HTML in the textarea" do
    update_post(html_editor: "1", content_html: "<div>kept</div>", slug: posts(:two).slug)
    assert_response :unprocessable_content
    assert_equal "<div>kept</div>", html_textarea_text
  end

  test "edit page always opens in trix mode after an HTML save" do
    update_post(html_editor: "1", content_html: "<div>x</div>")
    edit_post
    assert_trix_mode
  end

  test "HTML saved in HTML mode shows in trix and textarea on next edit" do
    update_post(html_editor: "1", content_html: "<div><strong>Bold</strong></div>")
    assert_response :redirect
    edit_post
    trix_input = css_select("[name='post[content]']").first
    trix_value = trix_input["value"].presence || trix_input.text
    assert_includes trix_value, "<strong>Bold</strong>"
    assert_includes html_textarea_text, "<strong>Bold</strong>"
  end

  test "trix-saved content shows in the HTML textarea on next edit" do
    update_post(html_editor: "0", content: "<div><em>From trix</em></div>")
    assert_response :redirect
    edit_post
    assert_equal @post.reload.content.body.to_html, html_textarea_text
    assert_includes html_textarea_text, "<em>From trix</em>"
  end

  test "creating a post in HTML mode saves the HTML body" do
    assert_difference "Post.count", 1 do
      post "/milo/resources/posts", params: { post: {
        title: "Created HTML", post_type: "review", slug: "created-html",
        html_editor: "1", content_html: "<div>Created via HTML</div>"
      } }
    end
    assert_equal "<div>Created via HTML</div>", Post.find_by!(slug: "created-html").content.body.to_html
  end

  test "show page has no HTML source field" do
    get "/milo/resources/posts/#{@post.id}"
    assert_response :success
    assert_select "[data-field-id='content_html']", count: 0
    assert_select "[data-field-id='html_editor']", count: 0
    assert_not_includes response.body, "Content (HTML)"
  end

  test "index has no HTML columns" do
    get "/milo/resources/posts"
    assert_response :success
    assert_not_includes response.body, "Content (HTML)"
    assert_not_includes response.body, "Edit as HTML"
  end

  # Tag selection (multiple select of existing tags)
  TAG_SELECT = "select[name='post[tag_ids_input][]']".freeze

  test "new form lists all tags as options" do
    get "/milo/resources/posts/new"
    assert_response :success
    assert_select "#{TAG_SELECT} option", count: Tag.count
    values = css_select("#{TAG_SELECT} option").map { |option| option["value"] }
    assert_equal Tag.ids.map(&:to_s).sort, values.sort
  end

  test "edit form preselects current tags" do
    edit_post
    assert_select "#{TAG_SELECT} option[selected][value=?]", tags(:one).id.to_s
  end

  test "create saves selected tags" do
    assert_difference "Post.count", 1 do
      post "/milo/resources/posts", params: { post: {
        title: "Created Tagged", post_type: "review", slug: "created-tagged",
        content: "<div>Tagged</div>", tag_ids_input: [ tags(:two).id.to_s, tags(:three).id.to_s ]
      } }
    end
    created = Post.find_by!(slug: "created-tagged")
    assert_equal [ tags(:two).id, tags(:three).id ].sort, created.tag_ids.sort
  end

  test "update replaces tag set" do
    update_post(tag_ids_input: [ tags(:three).id.to_s ])
    assert_response :redirect
    assert_equal [ tags(:three).id ], @post.reload.tag_ids
  end

  test "clearing all tags works" do
    update_post(tag_ids_input: [ "" ])
    assert_response :redirect
    assert_empty @post.reload.tags
  end

  test "omitting tag_ids_input leaves tags unchanged" do
    update_post(title: "Renamed Without Tag Field")
    assert_response :redirect
    assert_equal [ tags(:one).id ], @post.reload.tag_ids
  end

  test "failed save keeps tags and re-renders selection" do
    update_post(title: "", tag_ids_input: [ tags(:three).id.to_s ])
    assert_response :unprocessable_content
    assert_equal [ tags(:one).id ], @post.reload.tag_ids
    assert_select "#{TAG_SELECT} option[selected][value=?]", tags(:three).id.to_s
  end

  test "unknown and non-numeric tag ids are ignored" do
    update_post(tag_ids_input: [ "999999", "abc", "9999999999999999999999", tags(:two).id.to_s ])
    assert_response :redirect
    assert_equal [ tags(:two) ], @post.reload.tags.to_a
  end

  test "saving in HTML mode keeps tags" do
    update_post(html_editor: "1", content_html: "<h1>x</h1>", tag_ids_input: [ tags(:two).id.to_s ])
    assert_response :redirect
    assert_equal [ tags(:two) ], @post.reload.tags.to_a
  end
end
