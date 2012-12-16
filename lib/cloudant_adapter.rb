require 'mechanize'
require 'json'
require 'logem'

class CloudantAdapter
  def initialize options = {}
    @logger = Logem::Logger.new self
    @username = options[:username] || ENV['CLOUDANT_USER']
    @password = options[:password] || ENV['CLOUDANT_PASS']
    @database = options[:database] || ENV['CLOUDANT_DB'] || 'tennis'

    @url = "http://gcao.cloudant.com/#{@database}"
    @logger.debug "URL: #{@url}"
  end

  def read id
    @logger.debug "Reading document whose id is #{id}"
    agent = Mechanize.new
    JSON.parse agent.get("#{@url}/#{id}").body
  rescue Mechanize::ResponseCodeError
    @logger.debug 'Not found'
    nil
  end

  def save id, data
    data['_id'] = id
    if found = read(id)
      data['_rev'] = found['_rev']
    end

    agent = Mechanize.new
    agent.auth @username, @password
    agent.post @url, data
  end
end