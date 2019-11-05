$: << File.dirname(__FILE__)

require 'mechanize'
require 'json'
require 'cloudant_adapter'

agent = Mechanize.new
page = agent.get('http://www.atpworldtour.com/Rankings/Singles.aspx')

rankings = []
is_first = true
page.search('.table-rankings tr').each do |row|
  if is_first
    is_first = false
    next
  end

  rank = row.search('td:first-child').text.to_i
  name = row.search('td:nth-child(4) a').text
  i = name.rindex ' '
  first = name[0..i-1]
  last = name[i+1..-1]
  #name = "#{first.strip} #{last.strip}"
  points = row.search('td:nth-child(6)').text.sub(',', '').to_i
  rankings << {rank: rank, first: first, last: last, points: points}
end

id     = 'rankings'
result = {generated_at: Time.now.to_i, data: rankings[0..49]}

CloudantAdapter.new.save id, result

File.write("../tennis/source/data/#{id}.json", result.to_json)

