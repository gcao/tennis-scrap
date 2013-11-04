$: << File.dirname(__FILE__)

require 'cloudant_adapter'

CloudantAdapter.new.save 'ticket_urls', data: [
  {
      name: "US Open",
      url:  "http://www.ticketcity.com/tennis-tickets/us-open-tennis-tickets.html"
  },
  {
      name: "Coupe Rogers",
      url:  "http://www.ticketcity.com/tennis-tickets/rogers-cup-mens-tennis-canada-tickets.html"
  },
  {
      name: "Western & Southern Open",
      url:  "http://www.ticketcity.com/tennis-tickets/western-and-southern-open-tickets.html"
  },
  {
      name: "Australian Open",
      url:  "http://www.ticketcity.com/tennis-tickets/australian-open-tennis-tickets.html"
  },
  {
      name: "BNP Paribas Open",
      url:  "http://www.ticketcity.com/tennis-tickets/australian-open-tennis-tickets.html"
  },
  {
      name: "Sony Open Tennis",
      url:  "http://www.ticketcity.com/tennis-tickets/sony-ericsson-open-tennis-tickets.html"
  },
  {
      name: "Wimbledon",
      url:  "http://www.ticketcity.com/tennis-tickets/wimbledon-tennis-tickets.html"
  }
]
