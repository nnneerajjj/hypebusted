ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ArticleHtmlTestHelper
  # Avo's attachments endpoint the Insert image button uploads to (R3).
  IMAGE_UPLOAD_URL = "/milo/avo_api/resources/posts/attachments".freeze

  # The side-by-side benefits block an article body uses; Trix strips its classes and nested divs.
  COMPARE_BLOCK_HTML = (%(<div class="compare">) +
    %(<div class="compare-col compare-yes"><p class="compare-title">Yes</p><ul><li>One</li></ul></div>) +
    %(<div class="compare-col compare-no"><p class="compare-title">No</p><ul><li>Two</li></ul></div>) +
    %(</div>)).freeze

  # A full article body: headings, the .compare block and a captioned gallery image.
  def article_html(blob)
    "<h2>Section heading</h2>\n<p>Intro paragraph.</p>\n<h3>Sub heading</h3>\n#{COMPARE_BLOCK_HTML}\n" +
      %(<action-text-attachment sgid="#{blob.attachable_sgid}" caption="Cap" presentation="gallery"></action-text-attachment>)
  end
end

module ActiveSupport
  class TestCase
    include ArticleHtmlTestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def image_blob(filename: "sample-product-shot.png")
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(file_fixture("sample-product-shot.png")), filename: filename, content_type: "image/png"
      ).tap(&:analyze)
    end
  end
end
