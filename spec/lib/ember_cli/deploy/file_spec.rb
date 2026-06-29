require 'tmpdir'
require 'ember_cli/deploy/file'

describe EmberCli::Deploy::File do
  describe '#index_html' do
    context 'when the file is missing' do
      it 'raises a BuildError' do
        deploy = EmberCli::Deploy::File.new(build_app)

        expect { deploy.index_html }.to raise_error(EmberCli::BuildError)
      end
    end

    it "returns the contents of the app's `index_file`" do
      app = build_app
      create_index(app.dist_path, '<html></html>')
      deploy = EmberCli::Deploy::File.new(app)

      index_html = deploy.index_html

      expect(index_html).to eq('<html></html>')
    end
  end

  describe '#mountable?' do
    it 'returns true' do
      deploy = EmberCli::Deploy::File.new(build_app)

      mountable = deploy.mountable?

      expect(mountable).to be true
    end
  end

  describe '#to_rack' do
    it 'returns a callable Rack app' do
      deploy = EmberCli::Deploy::File.new(build_app)

      rack_app = deploy.to_rack

      expect(rack_app).to respond_to(:call)
    end

    it 'serves files from the dist_path' do
      app = build_app
      app.dist_path.join('test.js').write('var a = 1;')
      deploy = EmberCli::Deploy::File.new(app)
      rack_app = deploy.to_rack

      env = Rack::MockRequest.env_for('/test.js')
      status, _headers, _body = rack_app.call(env)

      expect(status).to eq(200)
    end

    it 'merges public_file_server headers into the response' do
      stub_public_file_server_headers('Cache-Control' => 'public, max-age=300')
      app = build_app
      app.dist_path.join('test.js').write('var a = 1;')
      deploy = EmberCli::Deploy::File.new(app)
      rack_app = deploy.to_rack

      env = Rack::MockRequest.env_for('/test.js')
      _status, response_headers, _body = rack_app.call(env)

      expect(response_headers['cache-control']).to eq('public, max-age=300')
    end

    it 'downcases header keys for Rack 3 compatibility' do
      stub_public_file_server_headers(
        'Cache-Control' => 'public, max-age=300',
        'X-Custom' => 'value'
      )
      app = build_app
      app.dist_path.join('test.js').write('var a = 1;')
      deploy = EmberCli::Deploy::File.new(app)
      rack_app = deploy.to_rack

      env = Rack::MockRequest.env_for('/test.js')
      _status, response_headers, _body = rack_app.call(env)

      expect(response_headers).to include('cache-control' => 'public, max-age=300')
      expect(response_headers).to include('x-custom' => 'value')
    end

    it 'handles missing public_file_server headers' do
      stub_public_file_server_headers(nil)
      app = build_app
      app.dist_path.join('test.js').write('var a = 1;')
      deploy = EmberCli::Deploy::File.new(app)
      rack_app = deploy.to_rack

      env = Rack::MockRequest.env_for('/test.js')
      status, _headers, _body = rack_app.call(env)

      expect(status).to eq(200)
    end
  end

  def create_index(directory, contents)
    directory.join('index.html').write(contents)
  end

  def build_app
    tmpdir = Pathname.new(Dir.mktmpdir)

    double(dist_path: tmpdir, check_for_errors!: false)
  end

  def stub_public_file_server_headers(headers)
    expect(Rails.configuration).to receive(:public_file_server).at_least(:once).and_return(
      double(headers: headers)
    )
  end
end
