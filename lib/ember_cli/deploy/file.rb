# frozen_string_literal: true

require 'rack'
require 'ember_cli/errors'

module EmberCli
  module Deploy
    # Serves an EmberCLI application from the filesystem via Rack.
    class File
      def initialize(app)
        @app = app
      end

      def mountable?
        true
      end

      def to_rack
        headers = rack_headers
        files = Rack::Files.new(app.dist_path.to_s)

        lambda { |env|
          status, response_headers, body = files.call(env)
          [status, response_headers.merge(headers), body]
        }
      end

      def index_html
        if index_file.exist?
          index_file.read
        else
          check_for_error_and_raise!
        end
      end

      private

      attr_reader :app

      def rack_headers
        config = Rails.configuration

        if config.respond_to?(:public_file_server) &&
           config.public_file_server&.headers
          config.public_file_server.headers.transform_keys(&:downcase)
        else
          {}
        end
      end

      def check_for_error_and_raise!
        app.check_for_errors!

        raise BuildError, <<-MSG
          EmberCLI failed to generate an `index.html` file.
        MSG
      end

      def index_file
        app.dist_path.join('index.html')
      end
    end
  end
end
