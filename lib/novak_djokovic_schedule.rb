$: << File.dirname(__FILE__)

require 'json'
require 'cloudant_adapter'

id   = File.basename(__FILE__).sub(/\.rb$/, '')
data = {
  name: "Novak Djokovic",
  generated_at: Time.now.to_i,
  data: [
    {
      tournament: "Australian Open",
    },
    {
      tournament: "BNP Paribas Open",
    },
    {
      tournament: "Miami Open, presented by Itau",
    },
    {
      tournament: "Monte-Carlo Rolex Masters",
    },
    {
      tournament: "Mutua Madrid Open",
    },
    {
      tournament: "Internazionali BNL d'Italia",
    },
    {
      tournament: "Roland Garros",
    },
    {
      tournament: "Wimbledon",
    },
    {
      tournament: "Rogers Cup",
    },
    {
      tournament: "Western & Southern Open - Cincinnati",
    },
    {
      tournament: "US Open",
    },
    {
      tournament: "Shanghai Rolex Masters",
    },
    {
      tournament: "Swiss Indoors Basel",
    },
    {
      tournament: "BNP Paribas Masters",
    },
    {
      tournament: "Barclays ATP World Tour Finals",
    },
      #result:     "",
      #defeated:   "",
      #lost_to:    "",
  ]
}

CloudantAdapter.new.save id, data

File.write("../tennis/source/data/#{id}.json", data.to_json)

__END__
    tournament: "Brisbane International presented by Suncorp",
    tournament: "Qatar ExxonMobil Open",
    tournament: "Aircel Chennai Open",
    tournament: "Apia International Sydney",
    tournament: "Heineken Open",
    tournament: "Australian Open",
    tournament: "Davis Cup First Round",
    tournament: "Ecuador Open Quito",
    tournament: "Open Sud de France",
    tournament: "PBZ Zagreb Indoors",
    tournament: "ABN AMRO World Tennis Tournament",
    tournament: "Memphis Open",
    tournament: "Copa Claro",
    tournament: "Rio Open presented by Claro",
    tournament: "Open 13",
    tournament: "Delray Beach Open by The  Venetian® Las Vegas",
    tournament: "Dubai Duty Free Tennis Championships",
    tournament: "Abierto Mexicano Telcel",
    tournament: "Brasil Open 2014",
    tournament: "BNP Paribas Open",
    tournament: "Miami Open, presented by Itau",
    tournament: "Davis Cup Quarter-finals",
    tournament: "Grand Prix Hassan II",
    tournament: "Fayez Sarofim & Co. U.S. Men's Clay Court Championship",
    tournament: "Monte-Carlo Rolex Masters",
    tournament: "Barcelona Open Banc Sabadell",
    tournament: "BRD Nastase Tiriac Trophy",
    tournament: "BMW Open by FWU AG",
    tournament: "Mutua Madrid Open",
    tournament: "Internazionali BNL d'Italia",
    tournament: "Open de Nice Côte d’Azur",
    tournament: "Roland Garros",
    tournament: "Gerry Weber Open",
    tournament: "Aegon Championships",
    tournament: "Topshelf Open",
    tournament: "Aegon International",
    tournament: "Wimbledon",
    tournament: "SkiStar Swedish Open",
    tournament: "MercedesCup",
    tournament: "Hall of Fame Tennis Championships",
    tournament: "bet-at-home Open",
    tournament: "Claro Open Colombia",
    tournament: "BB&T Atlanta Open",
    tournament: "Crédit Agricole Suisse Open Gstaad",
    tournament: "Vegeta Croatia Open Umag",
    tournament: "Austrian Open",
    tournament: "Citi Open",
    tournament: "Rogers Cup",
    tournament: "Western & Southern Open - Cincinnati",
    tournament: "Winston-Salem Open",
    tournament: "US Open",
    tournament: "Davis Cup Semi-finals",
    tournament: "Geneva Open",
    tournament: "Garanti Koza Istanbul Open",
    tournament: "Moselle Open",
    tournament: "Malaysian Open, Kuala Lumpur",
    tournament: "Shenzhen Open",
    tournament: "China Open",
    tournament: "Rakuten Japan Open Tennis Championships",
    tournament: "Shanghai Rolex Masters",
    tournament: "Kremlin Cup by Bank of Moscow",
    tournament: "If Stockholm Open",
    tournament: "Erste Bank Open",
    tournament: "Valencia Open 500",
    tournament: "Swiss Indoors Basel",
    tournament: "BNP Paribas Masters",
    tournament: "Barclays ATP World Tour Finals",
    tournament: "Davis Cup World Group Final",

