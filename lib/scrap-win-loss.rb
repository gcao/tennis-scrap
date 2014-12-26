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
  },
  david_ferrer: {
    name: 'David Ferrer',
    url: 'http://en.wikipedia.org/wiki/David_Ferrer_career_statistics'
  },
  tomas_berdych: {
    name: 'Tomáš Berdych',
    url: 'http://en.wikipedia.org/wiki/Tom%C3%A1%C5%A1_Berdych'
  },
  juan_martin_del_potro: {
    name: 'Juan Martin del Potro',
    url: 'http://en.wikipedia.org/wiki/Juan_Martin_del_Potro_career_statistics'
  },
  jo_wilfried_tsonga: {
    name: 'Jo-Wilfried Tsonga',
    url: 'http://en.wikipedia.org/wiki/Jo-Wilfried_Tsonga_career_statistics'
  },
}

dash            = "[-–]" # There are two different dashes found on the page
col1_pattern    = /Overall Win#{dash}Loss/
gs_col1_pattern = /Win#{dash}Loss/

def process_data data
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
  data
end

players.each do |key, value|
  page = agent.get(value[:url])

  gs_data_processed = false
  gs_data = [] # [year, win, lose]
  data    = [] # [year, win, lose]

  page.search('.wikitable tr').each do |row|
    pattern = gs_data_processed ? col1_pattern : gs_col1_pattern

    col1 = row.search('th:first-child').text
    next if col1 !~ pattern
    
    row.search('th').each do |col|
      content = col.text
      next if content =~ pattern
      # See note above regarding '-'
      break if content !~ /(\d+)#{dash}(\d+)/

      (gs_data_processed ? data : gs_data) << [$1.to_i, $2.to_i]
    end

    break if gs_data_processed # Break from the loop on second pattern match

    gs_data_processed = true
  end

  pp key
  # Filter out data included by mistake
  data.reject! {|d| d[1] > 100 }
  gs_data.reject! {|d| d[1] > 30 }

  data    = process_data data
  gs_data = process_data gs_data

  id     = "#{key}_win_loss"
  result = {name: value[:name], data: data, gs_data: gs_data}

  CloudantAdapter.new.save id, result
  sleep 2

  File.write("../tennis/source/data/#{id}.json", result.to_json)
end

