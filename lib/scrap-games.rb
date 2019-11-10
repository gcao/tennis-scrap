$: << File.dirname(__FILE__)

require 'mechanize'
require 'json'
require 'ostruct'
require 'cloudant_adapter'
require 'pp'

# TODO:
# Tournament:
#   Name
#   Location
#   Start / end date
#   Tournament type: grand slam, ATP Tour Finals, ATP 1000, 500, 250, Olympics, Davis Cup etc
#   Court type: hard, clay, grass, carpet
#   Indoor / outdoor
# Game:
#   Round
#   Opponent name
#   Opponent ranking
#   Game result
#   Walk over: true/false
#   First round bye: true/false
#   Date

def translate_tournament_type type, name
  if type =~ /_grandslam_/
    'grandslam'
  elsif type =~ /_atp_finals/
    'atpfinal'
  elsif type =~ /_1000/
    'atp1000'
  elsif type =~ /_500/
    'atp500'
  elsif type =~ /_250/
    'atp250'
  elsif name =~ /olympics/i
    'olympics'
  else
    'other'
  end
end

# Set struct
#   is_winner: true/false
#   won_games
#   lost_games
#   is_tiebreak
#   tiebreak_score
def translate_score_to_set set_score
  set = {}
  if set_score =~ /-/
    won_games, lost_games = set_score.split '-'
  else
    won_games = set_score[0]
    lost_games = set_score[1]
    if set_score =~ /^(76|67)(\d+)$/
      set[:is_tiebreak] = true
      set[:tiebreak_score] = $2
    end
  end

  set[:is_winner] = won_games.to_i > lost_games.to_i
  set[:won_games] = won_games.to_i
  set[:lost_games] = lost_games.to_i

  set
end

# Update game info based on score
#   format: best-of-three / best-of-five / other
#   not_finished: true/false - whether myself or the opponent retire during the game
#   is_walk_over: true/false
#   is_deciding_set: true/false
#   won_tie_breaks
#   lost_tie_breaks
#   won_bagels
#   lost_bagels
#   is_comeback_win: true/false
#   is_comeback_lost: true/false
#   sets:
#     is_winner: true/false
#     won_games
#     lost_games
#     is_tiebreak
#     tiebreak_score
#
# Example game result
# 63 676 75
# 75 63
# 46 46
# 63 64
# 46 764 60
# 63 75
# 61 64 40 (RET)
# 63 64 64
# 671 46 63 36
# (W/O)
#
def update_game game
  if game[:score] =~ /w\/o/i
    game[:is_walk_over] = true
    return
  end

  if game[:score] =~ /ret/i
    game[:not_finished] = true
  end

  scores = game[:score].gsub(/[^\d -]/, '').split ' '
  sets = scores.map{|score| translate_score_to_set score}
  # game[:sets] = sets
  game[:score] = game[:score].gsub(/76(\d+)/, '76(\1)').gsub(/67(\d+)/, '67(\1)')

  sets_won = sets.count{|set| set[:is_winner] }
  sets_lost = sets.count - sets_won
  max = [sets_won, sets_lost].max
  if max == 2
    game[:format] = 'best-of-three'
  elsif max == 3
    game[:format] = 'best-of-five'
  else
    game[:format] = 'other'
  end

  # Tiebreaks
  won_tiebreaks = sets.count{|set| set[:is_winner] && set[:is_tiebreak]}
  if won_tiebreaks > 0
    game[:won_tiebreaks] = won_tiebreaks
  end
  lost_tiebreaks = sets.count{|set| !set[:is_winner] && set[:is_tiebreak]}
  if lost_tiebreaks > 0
    game[:lost_tiebreaks] = lost_tiebreaks
  end

  # Bagels
  won_bagels = sets.count{|set| set[:is_winner] && set[:is_bagel]}
  if won_bagels > 0
    game[:won_bagels] = won_bagels
  end
  lost_bagels = sets.count{|set| !set[:is_winner] && set[:is_bagel]}
  if lost_bagels > 0
    game[:lost_bagels] = lost_bagels
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
  page.search('.activity-tournament-table').each do |row|
    i -= 1
    break if i < 0

    if is_first
      is_first = false
      next
    end

    tournament_name = row.search('.title-content .tourney-title').text.strip

    tournament_dates = row.search('.tourney-dates').text.strip.split('-')
    date = Date.parse tournament_dates[0]
    if tournament_dates.length > 1
      end_date = Date.parse tournament_dates[1]
    end
    location = row.search('.tourney-location').text.strip

    is_indoor = false

    court_type_parts = row.search('.tourney-details:nth-child(2) .item-details').text.gsub(/\r|\n/, '').strip.split(/ +/)
    if court_type_parts.first == 'I'
      is_indoor = true
    end
    court_type = court_type_parts.last

    img = row.search('.tourney-badge-wrapper img')
    if img.empty?
      type = 'other'
    else
      type_img = img.attr('src').value.strip
      type = translate_tournament_type type_img, tournament_name
    end

    games = row.search('.mega-table tr').map do |tr|
      round = tr.search('td:first-child').text.strip
      opponent = tr.search('td:nth-child(3) a').text.strip
      rank = tr.search('td:nth-child(2)').text.strip
      rank = rank.to_i
      result = tr.search('td:nth-child(4)').text
      result = result =~ /^W/ ? 'W' : result =~ /^L/ ? 'L' : ''
      score = tr.search('td:nth-child(5)').text.strip
      game = {
        round: round,
        opponent: opponent,
        rank: rank,
        is_winner: result == 'W',
        result: result,
        score: score,
      }
      update_game game
      game
    end

    if type == 'grandslam'
      format = 'best-of-five'
    else
      format = 'best-of-three'
    end

    tournament = {
      name: tournament_name,
      date: date,
      location: location,
      type: type,
      format: format,
      court_type: court_type,
      is_indoor: is_indoor,
      games: games
    }
    if end_date
      tournament[:end_date] = end_date
    end
    tournaments << tournament
  end

  tournaments
end

def is_current_year? year
  year.to_i == Time.now.year
end

def scrap_player player, start_year
  id = player.id + "_games"
  file_name = "../tennis/source/data/#{id}.json"
  result = {}
  if File.exists? file_name
    result = JSON.load File.open(file_name)
  end
  # result.delete 'data'
  result['generated_at'] = Time.now.to_i
  result['name'] = player.name
  result['tournaments'] ||= {}

  current_year = Time.now.year
  start_year.upto(current_year) do |year|
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
    start_year: 1998,
    url:  'https://www.atptour.com/en/players/roger-federer/f324/player-activity?year=YEAR',
  ),
  OpenStruct.new(
    id:   'novak_djokovic',
    name: 'Novak Djokovic',
    start_year: 2003,
    url:  'https://www.atptour.com/en/players/novak-djokovic/d643/player-activity?year=YEAR',
  ),
  OpenStruct.new(
    id:   'rafael_nadal',
    name: 'Rafael Nadal',
    start_year: 2001,
    url:  'https://www.atptour.com/en/players/rafael-nadal/n409/player-activity?year=YEAR',
  ),
  OpenStruct.new(
    id:   'andy_murray',
    name: 'Andy Murray',
    start_year: 2005,
    url:  'https://www.atptour.com/en/players/andy-murray/mc10/player-activity?year=YEAR',
  ),
  OpenStruct.new(
    id:   'david_ferrer',
    name: 'David Ferrer',
    start_year: 2000,
    end_year: 2019,
    url:  'https://www.atptour.com/en/players/david-ferrer/f401/player-activity?year=YEAR',
  ),
  # OpenStruct.new(
  #   id:   'daniil_medvedev',
  #   name: 'Daniil Medvedev',
  #   start_year: 2014,
  #   url:  'https://www.atptour.com/en/players/daniil-medvedev/mm58/player-activity?year=YEAR',
  # ),
]

start_year = 1998

if ARGV.length > 0
  start_year = ARGV[0].to_i
end

players.each do |player|
  if player[:start_year] && player[:start_year] > start_year
    scrap_player player, player[:start_year]
  else
    scrap_player player, start_year
  end
end
