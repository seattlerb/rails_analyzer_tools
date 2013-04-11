require 'hoe'
require './lib/analyzer_tools'

Hoe.new 'rails_analyzer_tools', AnalyzerTools::VERSION do |p|
  p.rubyforge_name = 'seattlerb'
  p.author = 'Eric Hodel'
  p.email = 'drbrain@segment7.net'
  p.summary = p.paragraphs_of('README.md', 1).join ' '
  p.description = p.paragraphs_of('README.md', 2).join ' '
  p.url = p.paragraphs_of('README.md', 3).join ' '
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")

  p.extra_deps << ['SyslogLogger', '>= 1.4.0']
end

# vim: syntax=Ruby

