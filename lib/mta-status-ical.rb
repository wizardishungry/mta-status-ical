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

class RiCal::Component::Calendar
  def export_x_properties_to(export_stream) #:nodoc:
    x_properties.each do |name, props|
	  props.each do | prop |
		export_stream.puts("#{name}#{prop}")
	  end
	end
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
    add_x_property 'X-WR-CALNAME', 'MTA Subway Delays'
    add_x_property 'X-PUBLISHED-TTL', 'PT1M'
end

doc.css("line").map do |line|
  name =  line.css("name").first.content
  status = line.css("status").first.content
  text = Sanitize.clean( line.css("text").first.content ).strip
  dt = line.css('Date').first.content + line.css('Time').first.content
  dt.strip!
  #puts "DEBUG #{name} #{status} #{text} #{dt}"
  if status != "GOOD SERVICE" and
    not douchebag name and not bus name
        cal.events << RiCal.Event do
            summary "#{name} #{status.titleize}"
            dtstart     (DateTime.parse(dt!='' ? dt : Time.now.to_s)).to_date
            dtend       (DateTime.parse(Time.now.to_s) + 1).to_date
            location    name
            description text 
			if not status =~ /Planned/
			  alarm do
			    description "FF #{name} #{status.titleize}"
			  end
			end
        end
  end
end

puts cal
