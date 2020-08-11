$: << File.dirname(__FILE__)

require 'mechanize'
require 'yaml'
require 'json'
require 'cloudant_adapter'

def scrap_rank_history player, url = nil
  player['rank'] = row.search('.player-ranking-position .data-number').text
  url ||= "https://www.atptour.com/en/players/andy-murray/#{player['atptour_id']}/rankings-history"
  history_page = agent.get(url)
  history_page.search('#playerRankHistoryContainer tbody tr').each do |row|
    year, month, day = row.search('td:first-child').text.split('.')
    # break if year.to_i <= 2002
    rank_text = row.search('td:nth-child(2)').text
    unless rank_text.empty?
      if rank_text.index(',') or rank_text.index('T')
        rank = 50
      else
        rank = rank_text.to_i
        rank = 50 if rank <= 0 or rank > 50
      end
    end
    history << ["#{month}/#{day}/#{year}", rank]
  end

  while history.last[1] >= 50
    second_to_last = history[history.length - 2]
    break if second_to_last and second_to_last[1] < 50

    history.pop
  end
  
  id     = "#{first}_#{last}_rank_history".downcase.gsub(/[ -]/, '_')
  result = {first: player['first'], last: player['last'], rank: player['rank'], history: history}

  CloudantAdapter.new.save id, result
  sleep 2

  File.write("../tennis/source/data/#{id}.json", result.to_json)
end

players = []

agent = Mechanize.new
page = agent.get('http://www.atpworldtour.com/Rankings/Singles.aspx')

page.search('.table-rankings tbody tr').take(50).each do |row|
  rank = row.search('td.rank-cell').text.to_i
  first, last = row.search('td.player-cell a').text.split(' ')
  first = first.strip
  last = last.strip
  
  history = []
  url = row.search('td.player-cell a').first.attr('href')
  url.sub!('overview', 'rankings-history')
  history_page = agent.get(url)
  history_page.search('#playerRankHistoryContainer tbody tr').each do |row|
    year, month, day = row.search('td:first-child').text.split('.')
    # break if year.to_i <= 2002
    rank_text = row.search('td:nth-child(2)').text
    unless rank_text.empty?
      if rank_text.index(',') or rank_text.index('T')
        rank = 50
      else
        rank = rank_text.to_i
        rank = 50 if rank <= 0 or rank > 50
      end
    end
    history << ["#{month}/#{day}/#{year}", rank]
  end

  while history.last[1] >= 50
    second_to_last = history[history.length - 2]
    break if second_to_last and second_to_last[1] < 50

    history.pop
  end
  
  id     = "#{first}_#{last}_rank_history".downcase.gsub(/[ -]/, '_')
  result = {first: first, last: last, rank: rank, history: history}

  CloudantAdapter.new.save id, result
  sleep 2

  File.write("../tennis/source/data/#{id}.json", result.to_json)
end
