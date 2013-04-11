# rails_analyzer_tools

Tools for analyzing the performance of web sites.

Rails Analyzer Tools contains Bench, a simple web page benchmarker,
Crawler, a tool for beating up on web sites, RailsStat, a tool for
monitoring Rails web sites, and IOTail, a tail(1) method for Ruby IOs.

http://seattlerb.rubyforge.org/rails_analyzer_tools

Bug reports:

http://rubyforge.org/tracker/?func=add&group_id=1513&atid=5921

## Bench

Bench lets you benchmark the performance of a particular page.  Simply give
the URL, the number of requests to run and the number of threads to run in
parallel.

You really, really, really don't want to run bench against a live website.

    $ bench -u http://coop.robotcoop.com/ -r 50 -c 2
    50....45....40....35....30....25....20....15....10....5....
    Total time: 10.7073893547058
    Average time: 0.214147787094116

## Crawler

Crawler lets you exercise a server by crawling it really fast.  It picks URLs
at random from the returned page and always stays on the same host.  When you
kill it with a ^C it prints out a summary.

You really, really, really don't want to run crawl against a live website.

    $ crawl -u http://coop.robotcoop.com/ -c 2
    >>> http://coop.robotcoop.com/
    GET / HTTP/1.0
    Host: coop.robotcoop.com
    User-Agent: RubyCrawl

    ...

    ^C
    Total time: 0.355171680450439
    Requests: 3
    Average time: 0.118390560150146

## RailsStat

RailsStat displays the approximate number of requests, queries, and lines
logged per second in 10 (or whatever) second intervals.  Simply give it the
path to your production log for a live Rails site and you're done:

    $ rails_stat /var/log/production.log
    ~ 2.1 req/sec, 23.0 queries/sec, 32.8 lines/sec

## IOTail

IOTail tails a file like the tail system utility.  This lets you collect data
from a live log file.

