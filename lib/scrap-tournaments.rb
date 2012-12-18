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
  when /davis/       then 'daviscup'
  else                    type_str
  end
end


agent = Mechanize.new
page = agent.get('http://www.atpworldtour.com/Tournaments/Event-Calendar.aspx')

tournaments = []
page.search('.calendarTable tr').each do |row|
  tournament = {}
  tournaments << tournament
  tournament['name']  = row.search('td:nth-child(3) a').text.strip
  tournament['url']   = row.search('td:nth-child(3) a').first.attr('href')
  tournament['place'] = place = row.search('td:nth-child(3) :nth-child(3)').text.strip

  geo = JSON.parse agent.get('http://maps.googleapis.com/maps/api/geocode/json', address: place, sensor: false).body
  sleep 0.2
  begin
    location = geo['results'].first['geometry']['location']
    tournament['latitude'] = location['lat']
    tournament['longitude'] = location['lng']
  rescue => e
    puts e
  end

  day, month, year = row.search('td:nth-child(2)').text.split('.')
  tournament['start'] = Date.new(year.to_i, month.to_i, day.to_i)

  if logo = row.search('td:nth-child(1) img').first
    tournament['type'] = detect_tournament_type logo.attr('title')
  end

  if title_holder = row.search('td.lastCell a:first-child').first
    tournament['title_holder'] = {name: title_holder.text.strip, url: title_holder.attr('href')}
  end
end

result = {generated_at: Time.now, data: tournaments}

CloudantAdapter.new.save 'tournaments', result

#File.open('output/tournaments.js', 'w') do |f|
#  f.puts result.to_json
#end

