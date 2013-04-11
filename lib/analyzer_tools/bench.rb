require 'socket'
require 'thread'
require 'uri'

##
# Bench measures load time for a particular page.  You can run it
# multi-threaded to test web server performance, or single threaded to test
# the performance of a single page.

class Bench

  ##
  # Creates a new Bench instance that will +requests+ fetches of +uri+ using
  # +thread+ concurrent threads.

  def initialize(uri, requests, threads = 1, cookies = nil)
    raise ArgumentError, "Thread count must be more than 0" if threads < 1
    @uri = uri
    @total_requests = requests
    @tenths = @total_requests > 10 ? @total_requests / 10 : 1
    @hundredths = @total_requests > 100 ? @total_requests / 100 : 1
    @num_requests = requests
    @threads = threads
    @cookies = cookies
  end

  ##
  # Starts the benchmark.  Returns an Array of request times in seconds.

  def run
    done = false
    times = []
    threads = ThreadGroup.new
    count_m = Mutex.new

    @threads.times do
      Thread.start do
        threads.add Thread.current
        until @num_requests <= 0 do
          count_m.synchronize do
            if @num_requests % @tenths == 0 then
              print @num_requests
            elsif @num_requests % @hundredths == 0 then
              print '.'
            end
            @num_requests -= 1
          end
          $stdout.flush
          times << time_request
        end
      end
      Thread.pass
    end

    threads.enclose

    threads.list.each { |t| t.join }
    puts

    return times
  end

  ##
  # Performs a request.

  def do_request
    s = TCPSocket.new @uri.host, @uri.port
    s.puts "GET #{@uri.request_uri} HTTP/1.0\r\n"
    s.puts "Host: #{@uri.host}\r\n"
    s.puts "User-Agent: RubyBench\r\n"
    s.puts "Cookie: #{@cookies}\r\n" if @cookies
    s.puts "\r\n"
    s.flush
    response = s.read
  ensure
    s.close unless s.nil?
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
  # Returns the time taken to perform a request.

  def time_request
    time do
      do_request
    end
  end

end

