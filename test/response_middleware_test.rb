require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ResponseMiddlewareTest < Faraday::TestCase
  def setup
    @conn = Faraday.new do |b|
      b.response :raise_error
      b.adapter :test do |stub|
        stub.get('ok')        { [200, {'Content-Type' => 'text/html'}, '<body></body>'] }
        stub.get('not-found') { [404, {'X-Reason' => 'because'}, 'keep looking'] }
        stub.get('error')     { [500, {'X-Error' => 'bailout'}, 'fail'] }
      end
    end
  end

  def test_success
    response = @conn.get('ok')
    assert response.success?
  end
  
  def test_raises_not_found
    error = assert_raises Faraday::Error::ResourceNotFound do
      @conn.get('not-found')
    end
    assert_equal 'the server responded with status 404', error.message
    assert_equal 'because', error.response[:headers]['X-Reason']
  end
  
  def test_raises_error
    error = assert_raises Faraday::Error::ClientError do
      @conn.get('error')
    end
    assert_equal 'the server responded with status 500', error.message
    assert_equal 'bailout', error.response[:headers]['X-Error']
  end
end
