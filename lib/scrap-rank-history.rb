require 'mechanize'
require 'json'

agent = Mechanize.new
page = agent.get('http://www.atpworldtour.com/Rankings/Singles.aspx')

is_first = true
i = 11
page.search('.rankingsContent tr').each do |row|
  break if i <= 0
  i -= 1

  if is_first
    is_first = false
    next
  end

  rank = row.search('td:first-child span').text.to_i
  #last, first = row.search('td:first-child a').text.split(',')
  #first = first[1..-1].strip
  #last = last.strip
  history = []
  url = row.search('td:first-child a').first.attr('href') + '?t=rh'
  history_page = agent.get(url)
  is_first_history = true
  history_page.search('.bioHistoryTable tr').each do |row|
    if is_first_history
      is_first_history = false
      next
    end
    day, month, year = row.search('td:first-child').text.split('.')
    break if year.to_i <= 2002
    rank_then = row.search('td:nth-child(2)').text.to_i
    rank_then = 50 if rank_then <= 0 or rank_then > 50
    history << ["#{month}/#{day}/#{year}", rank_then]
  end
  
  #result = {first: first, last: last, rank: rank, history: history}

  File.open("output/rank-history-#{rank}.js", 'w') do |f|
    f.puts history.to_json
  end
end

