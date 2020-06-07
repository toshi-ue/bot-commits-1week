# frozen_string_literal: true

require 'net/https'
require 'uri'
require 'json'
require 'date'
require 'twitter'
require 'active_support/time'
require 'dotenv'
# require 'pry'
Dotenv.load

class Tweet
  def initialize
    @t = Time.now
    @beginning_time_of_last_week = (@t - 1.week).beginning_of_week
    @end_time_of_last_week = (@t - 1.week).end_of_week
    @arr_per_commits = [0, 0, 0, 0, 0, 0, 0]
    @my_github_account = ENV['MY_GITHUB_ACCOUNT']
    @tweet_texts = []
    @github_push_events_datas = "https://api.github.com/users/#{@my_github_account}/events"

    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_API_KEY']
      config.consumer_secret     = ENV['YOUR_CONSUMER_API_SECRET_KEY']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  def tweet_1week_commits
    @tweet_texts.push("total #{@arr_per_commits.sum}commits in last week.")
    aggregate_commits_per_day
    add_texts_per_day
    @client.update(@tweet_texts.join("\n"))
  end

  def aggregate_commits_per_day
    uri = URI.parse(@github_push_events_datas)
    json = Net::HTTP.get(uri)
    results = JSON.parse(json)

    7.times do |num|
      results.select do |r|
        next unless r['type'] == 'PushEvent'

        push_event_created_time = r['created_at'].in_time_zone('UTC').in_time_zone + 9.hours

        next unless push_event_created_time >= @beginning_time_of_last_week

        if push_event_created_time <= @end_time_of_last_week
          @arr_per_commits[num] += r['payload']['commits'].count
        end
      end
    end
  end

  def add_texts_per_day
    @arr_per_commits.reverse.each_with_index do |c, idx|
      @tweet_texts.push(make_text_with_day_of_the_week(@t - (7 - idx).day, c))
    end
  end

  def make_text_with_day_of_the_week(time, commit_sum)
    "#{time.strftime('%m')}/#{time.strftime('%d')}" \
    "(#{%w[日 月 火 水 木 金 土][time.wday]}): #{commit_sum}commits"
  end
end

# Tweet.new.tweet_1week_commits

# Tweet.new.tweet_1week_commits

# [gistを使ってJSONを返す超簡易的なAPIサーバを作る - KDE BLOG](https://kde.hateblo.jp/entry/2018/11/28/022838)
# [github apiのサンプル](https://gist.github.com/toshi-ue/200ce679e6cd46aeadde21b0e6b82c92)

# @github_push_events_datas = 'https://gist.githubusercontent.com/toshi-ue/200ce679e6cd46aeadde21b0e6b82c92/raw/e57dbf724c433065275ebba07007e728cfb73946/events.json'

# p @github_push_events_datas
# uri = URI.parse(@github_push_events_datas)
# json = Net::HTTP.get(uri)
# results = JSON.parse(json)
# puts results
# puts results.count
# puts results[0]['created_at'].in_time_zone('UTC').in_time_zone + 9.hours
# puts JSON.parse(json)
# str_time = results[0]['created_at'].in_time_zone('UTC').in_time_zone

# puts results[2]['type']
# puts results[2]['payload']['commits'].count
# p 'aaa'
