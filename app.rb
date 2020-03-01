require 'sinatra'
require_relative 'tweet.rb'

# URL'/'でアクセス
get '/' do
  'under construction'
end

# URL'/random_tweet'でアクセス
get '/tweet_1week_commits' do
  Tweet.new.tweet_1week_commits
  # 'Please check your tweet'
end
