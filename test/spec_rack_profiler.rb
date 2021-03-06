# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'

begin
  require 'rack/contrib/profiler'

  describe 'Rack::Profiler' do
    app = lambda { |env| Time.new; [200, {'Content-Type' => 'text/plain'}, ['Oh hai der']] }
    request = Rack::MockRequest.env_for("/", :params => "profile=process_time")

    def profiler(app, options = {})
      Rack::Lint.new(Rack::Profiler.new(app, options))
    end

    specify 'printer defaults to RubyProf::CallStackPrinter' do
      profiler = Rack::Profiler.new(nil, {}) # Don't use Rack::Lint to haev access to the middleware instance variable
      _(profiler.instance_variable_get('@printer')).must_equal RubyProf::CallStackPrinter
      _(profiler.instance_variable_get('@times')).must_equal 1
    end

    specify 'called multiple times via query params' do
      req = Rack::MockRequest.env_for("/", :params => "profile=process_time&profiler_runs=4")
      body = profiler(app).call(req)[2]
      _(body.to_enum.to_a.join).must_match(/Time#initialize \[4 calls, 4 total\]/)
    end

    specify 'CallStackPrinter has Content-Type test/html' do
      headers = profiler(app, :printer => :call_stack).call(request)[1]
      _(headers).must_equal "Content-Type"=>"text/html"
    end

    specify 'FlatPrinter and GraphPrinter has Content-Type text/plain' do
      %w(flat graph).each do |printer|
        headers = profiler(app, :printer => printer.to_sym).call(request)[1]
        _(headers).must_equal "Content-Type"=>"text/plain"
      end
    end

    specify 'GraphHtmlPrinter has Content-Type text/html' do
      headers = profiler(app, :printer => :graph_html).call(request)[1]
      _(headers).must_equal "Content-Type"=>"text/html"
    end
  end

rescue LoadError => boom
  $stderr.puts "WARN: Skipping Rack::Profiler tests (ruby-prof not installed)"
end
