require 'thread'
require 'curses' rescue nil

##
# RailsStat displays a the current requests and lines logged per second.
# Default interval is 10 seconds.

class RailsStat

  class << self
    attr_reader :lines
  end

  ##
  #   RailsStat.start 'online-43things.log', 'online-43people.log', 10
  #
  # Starts a new RailsStat for +filenames+ that prints every +interval+
  # seconds.
  #
  # Stats for multiple log files requires curses.

  def self.start(*args)
    interval = 10
    interval = Float(args.pop) if Float(args.last) rescue nil

    stats = []

    if args.length > 1 and not defined? Curses then
      $stderr.puts "Multiple logfile support requires curses"
      exit 1
    end

    if defined? Curses then
      Curses.init_screen
      Curses.clear
      Curses.addstr "Collecting data...\n"
      Curses.refresh
      @lines = []
    end

    args.each_with_index do |filename, offset|
      stat = self.new File.open(filename), interval, offset
      stat.start
      stats << stat
    end

    stats.each { |stat| stat.thread.join }
  end

  ##
  # The log reading thread

  attr_reader :thread

  ##
  # Current status line

  attr_reader :status

  ##
  # Creates a new RailsStat that will listen on +io+ and print every
  # +interval+ seconds.  +offset+ is only used for multi-file support.

  def initialize(io, interval, offset = 0)
    @io = io
    @io_path = File.basename io.path rescue 'unknown'
    @interval = interval.to_f
    @offset = offset

    @mutex = Mutex.new
    @status = ''
    @last_len = 0
    @lines = 0
    @count = 0
    @thread = nil
  end

  ##
  # Starts the RailsStat running.  This method never returns.

  def start
    trap 'INT' do
      Curses.close_screen if defined? Curses
      exit
    end
    start_printer
    read_log
  end

  def print
    if defined? Curses then
      Curses.setpos @offset, 0
      Curses.addstr ' ' * @last_len
      Curses.setpos @offset, 0
      Curses.addstr "#{@io_path}\t#{@status}"
      Curses.refresh
    else
      print "\r"
      print ' ' * @last_len
      print "\r"
      print @status
      $stdout.flush
    end
  end

  private

  ##
  # Starts a thread that prints log information every +interval+ seconds.

  def start_printer
    Thread.start do
      lines_sec = 0
      count_sec = 0

      loop do
        sleep @interval

        @mutex.synchronize do
          lines_sec = @lines / @interval
          count_sec = @count / @interval
          @lines = 0
          @count = 0
        end

        @status = "%5.1f req/sec, %6.1f lines/sec" % [count_sec, lines_sec]

        print

        @last_len = status.length
      end
    end
  end

  ##
  # Starts a thread that reads from +io+, updating RailsStat counters as it
  # goes.

  def read_log
    @thread = Thread.start do
      @io.tail_lines do |line|
        @mutex.synchronize { @lines += 1 }
        @mutex.synchronize { @count += 1 } if line =~ /Completed in /
      end
    end
  end

end

