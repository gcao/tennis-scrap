$: << File.dirname(__FILE__)

require 'mechanize'
require 'json'

agent = Mechanize.new
page  = agent.get('http://www.atpworldtour.com/Tournaments/Event-Calendar.aspx')

page.search('.calendarTable tr').each do |row|
  tournament = row.search('td:nth-child(3) a').text.strip
  puts %Q(    tournament: "#{tournament}",)
end

