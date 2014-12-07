$: << File.dirname(__FILE__)

require 'mechanize'
require 'json'
require 'cloudant_adapter'

def detect_tournament_type type_str
  case type_str
  when /250/         then 'atp250'
  when /500/         then 'atp500'
  when /1000/        then 'atp1000'
  when /atp final/i  then 'atptourfinal'
  when /grand slam/i then 'grandslam'
  when /davis/i      then 'daviscup'
  else                    type_str
  end
end


agent = Mechanize.new
page = agent.get('http://www.atpworldtour.com/Tournaments/Event-Calendar.aspx')

ROW_CSS   = '.calendarTable tr'
COL_CSS   = "td:nth-child(3)"
NAME_CSS  = "#{COL_CSS} a"
PLACE_CSS = "#{COL_CSS} :nth-child(3)"
TIME_CSS  = "td:nth-child(2)"

tournaments = []
page.search(ROW_CSS).each do |row|
  tournament = {}
  tournaments << tournament
  tournament['name' ]         = row.search(NAME_CSS).text.strip
  tournament['url'  ]         = row.search(NAME_CSS).first.attr('href')
  tournament['place'] = place = row.search(PLACE_CSS).text.strip

  geo = JSON.parse agent.get('http://maps.googleapis.com/maps/api/geocode/json', address: place, sensor: false).body
  sleep 0.2
  begin
    location = geo['results'].first['geometry']['location']
    tournament['latitude' ] = location['lat']
    tournament['longitude'] = location['lng']
  rescue => e
    puts e
  end

  day, month, year = row.search(TIME_CSS).text.split('.')
  tournament['start'] = Date.new(year.to_i, month.to_i, day.to_i)

  if logo = row.search('td:nth-child(1) img').first
    tournament['type'] = detect_tournament_type logo.attr('title')
  end

  if title_holder = row.search('td.lastCell a:first-child').first
    tournament['title_holder'] = {name: title_holder.text.strip, url: title_holder.attr('href')}
  end

  puts tournament
end

id     = 'tournaments'
result = {generated_at: Time.now, data: tournaments}

#CloudantAdapter.new.save id, result

File.write("../tennis/source/data/#{id}.json", result.to_json)

