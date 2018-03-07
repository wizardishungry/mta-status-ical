require "rubygems"
require "ri_cal"
require "oga"
require "sanitize"
require "date"
require "time"
require "american_date"
require 'curb'

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

class MtaStatusIcal
  def douchebag(name)
      name =~ /\s|[a-z]|SIR/
  end

  def bus(name)
      name =~ / - /
  end

  def run

    http = Curl.get("http://web.mta.info/status/serviceStatus.txt")
    doc = Oga.parse_xml http.body_str

    RiCal::PropertyValue::DateTime::default_tzid = 'America/New_York'
    cal = RiCal.Calendar do
        add_x_property 'X-WR-CALNAME', 'MTA Subway Delays'
        add_x_property 'X-PUBLISHED-TTL', 'PT1M'
    end

    doc.css("line").map do |line|
      name =  line.css("name").first.inner_text
      status = line.css("status").first.inner_text
      text = Sanitize.clean( line.css("text").first.inner_text ).strip

      dt = line.css('Date').first.inner_text + " " + line.css('Time').first.inner_text
      STDERR.puts "DEBUG #{name} #{status} #{dt}"
      dt.strip!

      def dt_end_offset(dt)
        if dt.hour >= 12 or DateTime.now-dt > 1.0
          2
        else
          1
        end
      end

      if dt == ''
        dt = DateTime.parse(Time.now.to_s).to_date
        dtend = (DateTime.now + dt_end_offset(DateTime.now)).to_date
      else
        dt = DateTime.parse(dt).to_datetime
        dtend = DateTime.parse( (DateTime.now + dt_end_offset(dt) ).to_date.to_s )
      end

      if text =~ /until ([[:alpha:]]{3} \d+)/
        # FIXME what is this shit
        STDERR.puts "FF #{$1}"
      end

      if status != "GOOD SERVICE" and not douchebag name and not bus name
        cal.events << RiCal.Event do
          summary "#{name} #{status.titleize}"
          dtstart     dt
          dtend       dtend
          location    name
          description text

          if not status =~ /Planned|Good/i
            alarm do
              description "#{name} #{status.titleize}"
            end
          end

        end
      end
    end
    return cal.to_s
  end
end
