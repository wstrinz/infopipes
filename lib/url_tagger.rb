require 'open-uri'
require 'uri'
require 'json'

class UrlTagger
  attr_reader :calais_client, :readability_key

  def initialize(calais_key:, readability_key:)
    @calais_client = OpenCalais::Client.new(api_key: calais_key)
    @readability_key = readability_key
    #@pocket_client = Pocket.client(consumer_key: pocket_consumer_key, access_token: pocket_access_token)
  end

  def readability_parse_url(url)
    enc_url = URI.encode(url)
    req_url = "https://www.readability.com/api/content/v1/parser?url=#{enc_url}&token=#{readability_key}"
    resp = open(req_url)
    if resp.status[0] == "200"
      JSON.parse(resp.read)
    else
      raise "parse url failed failed: #{resp.inspect}"
    end
  end

  def get_tags(text)
    resp = calais_client.enrich(text)
    resp.topics.concat(resp.tags)
  end

  def scrub_html(html)
    Sanitize.fragment(html).strip.gsub(/[\n\t]/,' ')
  end

  def tags_for(url)
    parsed = readability_parse_url(url)
    if parsed["word_count"] == 0
      []
    else
      scrubbed = scrub_html(parsed["content"])
      get_tags(scrubbed)
    end
  end
end
