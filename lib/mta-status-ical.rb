require "rubygems"
require "ri_cal"
require "nokogiri"
require "open-uri"
require "sanitize"
require "date"
require "time"


class String
  def titleize
    split(/(\W)/).map(&:capitalize).join
  end
end

def douchebag(name)
    name =~ /\s|[a-z]|SIR/
end


def bus(name)
    name =~ / - /
end

doc = Nokogiri::XML(open "http://www.mta.info/status/serviceStatus.txt")

cal = RiCal.Calendar do
end


doc.css("line").map do |line|
  name =  line.css("name").first.content
  status = line.css("status").first.content
  text = Sanitize.clean( line.css("text").first.content ).strip
  #puts "#{name} #{status} #{text}"
  if status != "GOOD SERVICE" and
    not douchebag name and not bus name
        cal.events << RiCal.Event do
            summary "#{name} #{status.titleize}"
            dtstart     (DateTime.parse(Time.now.to_s)).to_date
            dtend       (DateTime.parse(Time.now.to_s) + 1).to_date
            location    name
            description text 
        end
  end
end

puts cal
