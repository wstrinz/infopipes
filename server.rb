require 'sinatra'
require 'omniauth'
require 'omniauth-feedly'
require 'omniauth-pocket'
require 'rest-client'
require "erb"
require "json"
require "uri"
# require "sinatra/reloader" if development?
require './lib/key_manager'

# from https://groups.google.com/forum/#!topic/feedly-cloud/V7MElMqQXsU
OAUTH_ID = "sandbox"
OAUTH_SECRET = "JSSBD6FZT72058P51XEG"

enable :sessions

use OmniAuth::Builder do
  provider :feedly, OAUTH_ID, OAUTH_SECRET, :callback_path => "/", client_options: {
        site: 'https://sandbox.feedly.com'
    }

  provider :pocket, client_id: ENV['POCKET_CONSUMER_KEY'] || ->(){raise "requires POCKET_CONSUMER_KEY env var"}.call()
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

# hax b/c callback url restrictions (https://groups.google.com/forum/#!topic/feedly-cloud/POW2Pze-4BA)
get "/" do
  if params[:code]
    access_code = params[:code]
    state = params[:state]

    token_params = { 'code' => access_code,
      'client_id' => OAUTH_ID,
      'client_secret' => OAUTH_SECRET,
      'state' => state,
      'grant_type' => 'authorization_code',
      'redirect_uri' => 'http://localhost:8080/'
    }


    result = RestClient.post("https://sandbox.feedly.com/v3/auth/token", token_params)

    puts result

    parsed = JSON.parse(result)

    token = parsed["access_token"].to_s
    puts "parsed token"
    puts token

    manager = KeyManager.new
    manager[:feedly] = token
    manger.save

    "you got the token   #{token}"
  else
    redirect "/login"
  end
end

get "/login" do
  manager = KeyManager.new
  current_session_desc = URI.escape(session[:auth].to_s)
  erb <<-ERB
  <ul>
  <li><a href='/auth/feedly'>Login with feedly</a> (currently have #{manager[:feedly]})</li>
  <li><a href='/auth/pocket'>Login with pocket</a> (currently have #{manager[:pocket]})</li>
  <li>
    <form action="/auth/readability/callback" method="get">
      <label>Readability Key: <input name="readability_key" value="#{manager[:readability]}"/></label><br />
      <input type="submit" value="Set" />
  </ul>
  <div id="current_creds">
    <code>#{h current_session_desc}</code>
  ERB
end

post "/" do
  auth = request.env['omniauth.auth']
  session[:auth] = auth
  auth.inspect
end

get '/auth/:name/callback' do
  manager = KeyManager.new

  dislay_key = ""
  auth = request.env['omniauth.auth']
  case params[:name]
  when "pocket"
    manager[:pocket] = auth["credentials"]["token"]
    display_key = manager[:pocket]
  when "readability"
    manager[:readability] = params[:readability_key]
    display_key = manager[:readability]
  else
    raise "unknown provider"
  end

end
