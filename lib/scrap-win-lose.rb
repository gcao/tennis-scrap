# encoding=utf-8
$: << File.dirname(__FILE__)

require 'mechanize'
require 'json'
require 'cloudant_adapter'
require 'pp'

agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari'

players = {
  roger_federer: {
    name: 'Roger Federer',
    url: 'http://en.wikipedia.org/wiki/Roger_Federer_career_statistics'
  },
  novak_djokovic: {
    name: 'Novak Djokovic',
    url: 'http://en.wikipedia.org/wiki/Novak_Djokovic_career_statistics'
  },
  andy_murray: {
    name: 'Andy Murray',
    url: 'http://en.wikipedia.org/wiki/Andy_Murray_career_statistics'
  },
  rafael_nadal: {
    name: 'Rafael Nadal',
    url: 'http://en.wikipedia.org/wiki/Rafael_Nadal_career_statistics'
  }
}

# PLEASE NOTE: the '–' is a special chars directly copied from the wikipedia page.
#              It is not the regular '-'.
col1_pattern = /Overall Win–Loss/

players.each do |key, value|
  page = agent.get(value[:url])

  data = [] # [year, win, lose]

  page.search('.wikitable tr').each do |row|
    col1 = row.search('th:first-child').text
    next if col1 !~ col1_pattern
    
    row.search('th').each do |col|
      content = col.text
      next if content =~ col1_pattern
      # See note above regarding '-'
      break if content !~ /(\d+)–(\d+)/

      data << [$1.to_i, $2.to_i]
    end
    break
  end
  pp data

  # Add year
  data = (0..(data.length - 1)).reduce([]) do |result, i|
    win, lose = *data[i]
    year = 2013 - (data.length - 1 - i)
    result << [year, win, lose]
  end
  pp data

  # Remove data prior to 2003
  data.reject! {|row| row[0] < 2003 }
  pp data

  id     = "#{key}_win_lose"
  result = {name: value[:name], data: data}

  CloudantAdapter.new.save id, result
  sleep 2

  File.write("../tennis/source/data/#{id}.json", result.to_json)
end

