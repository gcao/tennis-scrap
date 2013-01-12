$: << File.dirname(__FILE__)

require 'mechanize'
require 'json'
require 'cloudant_adapter'

agent = Mechanize.new
page = agent.get('http://www.atpworldtour.com/Rankings/Singles.aspx')

rankings = []
is_first = true
page.search('.rankingsContent tr').each do |row|
  if is_first
    is_first = false
    next
  end

  rank = row.search('td:first-child span').text.to_i
  last, first = row.search('td:first-child a').text.split(',')
  #name = "#{first.strip} #{last.strip}"
  points = row.search('td:nth-child(2)').text.sub(',', '').to_i
  rankings << {rank: rank, first: first[1..-1], last: last.strip, points: points}
end

id     = 'rankings'
result = {generated_at: Time.now, data: rankings[0..49]}

CloudantAdapter.new.save id, result

File.open("../tennis-web/data/#{id}.js", 'w') do |f|
  f.puts "var #{id} = #{result.to_json};"
end

