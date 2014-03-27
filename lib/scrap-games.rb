$: << File.dirname(__FILE__)

require 'mechanize'
require 'json'
require 'ostruct'
require 'cloudant_adapter'

def translate_tournament_type type
  if type =~ /DC/
    'daviscup'
  elsif type =~ /GS/
    'grandslam'
  elsif type =~ /WC/
    'atpfinal'
  elsif type =~ /1000|SU/
    'atp1000'
  elsif type =~ /500/
    'atp500'
  elsif type =~ /olympics/ or type =~ /ol\s*$/i
    'olympics'
  else
    'other'
  end
end

def scrap_year player, year
  agent = Mechanize.new
  url   = player.url.sub('YEAR', year.to_s)
  puts url
  page  = agent.get(url)

  tournaments = []

  is_first = true
  i = 100
  page.search('.commonProfileContainer').each do |row|
    i -= 1
    break if i < 0

    if is_first
      is_first = false
      next
    end

    tournament_name = row.search('p:first-child a').text.strip

    tournament_parts = row.search('p:first-child').text.strip.split(';')
    next unless tournament_parts and tournament_parts.length > 0

    date = Date.parse tournament_parts[1]
    type = translate_tournament_type tournament_parts[2]

    games = row.search('tr:not(.bioTableHead)').map do |tr|
      round = tr.search('td:first-child').text.strip
      opponent = tr.search('td:nth-child(2) a').text.strip
      rank = tr.search('td:nth-child(3)').text.strip
      rank = rank.to_i
      result = tr.search('td:nth-child(4)').text
      result = result =~ /^W/ ? 'W' : result =~ /^L/ ? 'L' : ''
      {round: round, opponent: opponent, rank: rank, result: result}
    end
    tournaments << {name: tournament_name, date: date, type: type, games: games}
  end

  tournaments
end

def is_current_year? year
  year.to_i == Time.now.year
end

def scrap_player player
  id = player.id + "_games"
  file_name = "../tennis/source/data/#{id}.json"
  result = {}
  if File.exists? file_name
    result = JSON.load File.open(file_name)
  end
  result.delete 'data'
  result['generated_at'] = Time.now.to_i
  result['name'] = player.name
  result['tournaments'] ||= {}

  current_year = Time.now.year
  current_year.downto(1995) do |year|
    year = year.to_s
    next if result['tournaments'][year] and not is_current_year? year
    result['tournaments'][year] = scrap_year player, year
    result['tournaments'].delete year if result['tournaments'][year].empty?
  end
  File.write(file_name, result.to_json)
  CloudantAdapter.new.save id, result

  # Games of current year
  current_games = result['tournaments'][current_year.to_s]
  current_games_id = "#{id}_#{current_year}"
  File.write "../tennis/source/data/#{current_games_id}.json", current_games.to_json
  CloudantAdapter.new.save current_games_id, {data: current_games}
end

players = [
  OpenStruct.new(
    id:   'roger_federer',
    name: 'Roger Federer',
    url:  'http://www.atpworldtour.com/Tennis/Players/Top-Players/Roger-Federer.aspx?t=pa&y=YEAR&m=s&e=0'
  ),
  OpenStruct.new(
    id:   'novak_djokovic',
    name: 'Novak Djokovic',
    url:  'http://www.atpworldtour.com/Tennis/Players/Top-Players/Novak-Djokovic.aspx?t=pa&y=YEAR&m=s&e=0'
  ),
  OpenStruct.new(
    id:   'rafael_nadal',
    name: 'Rafael Nadal',
    url:  'http://www.atpworldtour.com/Tennis/Players/Top-Players/Rafael-Nadal.aspx?t=pa&y=YEAR&m=s&e=0'
  ),
  OpenStruct.new(
    id:   'andy_murray',
    name: 'Andy Murray',
    url:  'http://www.atpworldtour.com/Tennis/Players/Top-Players/Andy-Murray.aspx?t=pa&y=YEAR&m=s&e=0'
  ),
  OpenStruct.new(
    id:   'david_ferrer',
    name: 'David Ferrer',
    url:  'http://www.atpworldtour.com/Tennis/Players/Top-Players/David-Ferrer.aspx?t=pa&y=YEAR&m=s&e=0'
  ),
]

players.each do |player|
  scrap_player player
end

