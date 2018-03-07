require 'sinatra'
$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])
require 'mta-status-ical'

configure do
  mime_type :ical, 'text/calendar'
end

get '/' do
  content_type :ical
  cal = MtaStatusIcal.new
  cal.run
end
