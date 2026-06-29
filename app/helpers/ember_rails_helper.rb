require "html_page/capture"

# Helper for rendering Ember CLI applications within Rails views.
#
# Include this module in your controllers or use it as a view helper
# to serve Ember apps with optional Rails-injected content.
module EmberRailsHelper
  # Renders an Ember CLI application by name.
  #
  # Triggers a build of the Ember app (in development/test), then renders
  # its index.html as the response. An optional block can inject Rails
  # content into the Ember app's +<head>+ and +<body>+ sections.
  #
  # @param name [Symbol, String] the registered Ember app name (as defined
  #   in the EmberCli initializer)
  # @param block [Proc] optional block yielding +head+ and +body+ content
  #   to inject into the Ember index.html
  #
  # @example Basic usage in a controller action
  #   def index
  #     render_ember_app :frontend
  #   end
  #
  # @example Injecting Rails content into the Ember app
  #   def index
  #     render_ember_app :frontend do |head, body|
  #       head << csrf_meta_tags
  #       body << "Hello from Rails"
  #     end
  #   end
  def render_ember_app(name, &block)
    EmberCli[name].build

    markup_capturer = HtmlPage::Capture.new(self, &block)

    head, body = markup_capturer.capture

    render html: EmberCli[name].index_html(head: head, body: body).html_safe
  end
end
