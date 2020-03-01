require 'net/https'
require 'uri'
require 'json'
require 'date'
require 'twitter'
require "active_support/time"
require 'dotenv'
# require 'pry'
Dotenv.load

class Tweet
  # 初期化
  def initialize
    @t = Time.now
    @t_1day_ago = @t - 1.day
    @arr_per_commits = [0, 0, 0, 0, 0, 0, 0]
    @my_github_account = ENV['MY_GITHUB_ACCOUNT']
    @tweet_texts =[]
    @github_push_events_datas = "https://api.github.com/users/#{@my_github_account}/events"

    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_API_KEY']
      config.consumer_secret     = ENV['YOUR_CONSUMER_API_SECRET_KEY']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  # 1週間のコミット数をtweetする
  def tweet_1week_commits
    @tweet_texts.push("total #{@arr_per_commits.sum}commits in last week.")
    aggregate_commits_per_day
    add_texts_per_day
    @client.update(@tweet_texts.join("\n"))
  end

  # コミット数を1日ごとに集計する
  def aggregate_commits_per_day
    uri = URI.parse(@github_push_events_datas)
    json = Net::HTTP.get(uri)
    results = JSON.parse(json)

    7.times do |num|
      results.select do |r|
        str_time = r["created_at"].in_time_zone("UTC").in_time_zone
        if(r["type"] == "PushEvent")
          if((str_time >= (@t_1day_ago - num.day).beginning_of_day) && (str_time <= (@t_1day_ago - num.day).end_of_day))
            @arr_per_commits[num] += 1
          end
        end
      end
    end
  end

  # @tweet_textsに1日ごとのコミット数を含めた文章を追加する
  def add_texts_per_day
    (@arr_per_commits.reverse).each_with_index do |c, idx|
      @tweet_texts.push(make_text_with_day_of_the_week(@t - (7 - idx).day, c))
    end
  end

  # 曜日付きの文章に変換
  def make_text_with_day_of_the_week(time, commit_sum)
    "#{time.strftime("%m")}/#{time.strftime("%d")}" \
    "(#{%w(日 月 火 水 木 金 土)[time.wday]}): #{commit_sum.to_s}commits"
  end
end

Tweet.new.tweet_1week_commits
