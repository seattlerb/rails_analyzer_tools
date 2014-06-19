require 'socket'
require 'thread'
require 'uri'

##
# A fast web crawler that stays on the site it started from.  Crawler
# randomly picks a URL from the page retrieved and follows it.  If
# can't find a URL for the next page, Crawler starts over from the
# beginning.
#
# Crawler is multi-threaded and can run as many threads as you
# choose.

class Crawler

  ##
  # Array of response times in seconds.

  attr_reader :times

  ##
  # Creates a new Crawler that will start at +start_url+ and run +threads+
  # concurrent threads.

  def initialize(start_url, threads = 1, cookies = nil)
    raise ArgumentError, "Thread count must be more than 0" if threads < 1
    @start_url = start_url
    @thread_count = threads
    @threads = ThreadGroup.new
    @times = []
    @cookies = cookies
  end

  ##
  # Begins crawling.

  def run
    url = @start_url

    @thread_count.times do
      Thread.start do
        @threads.add Thread.current
        loop do
          puts ">>> #{url}"
          body = timed_request url
          url = extract_url_from body, url
        end
      end
      Thread.pass
    end

    @threads.list.first.join until @threads.list.empty?
  end

  ##
  # Stops crawling.

  def stop
    @threads.list.first.kill until @threads.list.empty?
  end

  ##
  # Performs a request of +url+ and returns the request body.

  def do_request(url)
    req = []
    req << "GET #{url.request_uri} HTTP/1.0"
    req << "Host: #{url.host}"
    req << "User-Agent: RubyCrawl"
    req << "Cookie: #{@cookies}" if @cookies
    req << ""
    req << ""
    req = req.join "\r\n"
    puts req

    begin
      s = TCPSocket.new url.host, url.port
      s.write req
      s.flush
      response = s.read
    ensure
      s.close unless s.nil?
    end

    headers, body = response.split(/\r\n\r\n/)

    headers = headers.split(/\r\n/)
    status = headers.shift
    headers = Hash[*headers.map { |h| h.split ': ', 2 }.flatten]

    puts status

    case status
    when / 302 / then
      body = "href=\"#{headers['Location']}\""
    when / 500 / then
      body = "href=\"#{@start_url}\""
    end

    return body
  end

  ##
  # Returns the amount of time taken to execute the given block.

  def time
    start_time = Time.now.to_f
    yield
    end_time = Time.now.to_f
    return end_time - start_time
  end

  ##
  # Performs a request of +url+ and records the time taken into times.
  # Returns the body of the request.

  def timed_request(url)
    body = nil
    @times << time { body = do_request(url) }
    return body
  end

  ##
  # Returns a random URL on the same site as +original_url+ from +body+ using
  # +original_url+ to resolve relative paths.  If no URL valid is found then
  # the start URL is returned.

  def extract_url_from(body, original_url)
    urls = body.scan(/href="(.+?)"/)
    until urls.empty? do
      begin
        rand_url = urls.delete_at(rand(urls.length)).first
        new_url = original_url + rand_url
        return new_url if new_url.host == original_url.host
      rescue URI::InvalidURIError
        retry
      end
    end

    return @start_url
  end

end

