# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
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
    @gh_account = ENV['MY_GITHUB_ACCOUNT']
    @t = Time.now
    @day1 = (@t - 1.week).beginning_of_week
    @day7 = (@t - 1.week).end_of_week
    @num_day1 = @day1.strftime('%j').to_i
    @num_day7 = @day7.strftime('%j').to_i
    @date_day1 = @day1.strftime('%Y%m%d')
    @date_day7 = @day7.strftime('%Y%m%d')

    @events_url = "https://api.github.com/users/#{@gh_account}/events"
    @commits_of_wk = [0, 0, 0, 0, 0, 0, 0]

    @contribution_url = "https://github.com/users/#{@gh_account}/contributions"
    @ary_contribution = []

    @tweet_texts = []
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_API_KEY']
      config.consumer_secret     = ENV['YOUR_CONSUMER_API_SECRET_KEY']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  def add_texts_per_day
    @commits_of_wk.reverse.zip(@ary_contribution).each_with_index do |day_count, idx|
      @tweet_texts.push(create_sentence(@t - (7 - idx).day, day_count[0], day_count[1]))
    end
  end

  def aggregate_commits_per_day
    results = get_json_data(@events_url)

    7.times do |num|
      results.select do |r|
        @num_pushed_day = r['created_at'].in_time_zone('UTC').in_time_zone('Tokyo').strftime('%j').to_i
        next unless commit_is_in_range?(@num_pushed_day, @num_day1, @num_day7)

        next unless r['type'] == 'PushEvent'

        if @num_pushed_day == @num_day7 - num
          @commits_of_wk[num] += r['payload']['commits'].count
        end
      end
    end
  end

  def commit_is_in_range?(commit_day, first_day, end_day)
    commit_day.between?(first_day, end_day)
  end

  def contribution_in_range?(t1, t2, t3)
    t1.between?(t2, t3)
  end

  def correct_sentence(commit, contribution)
    com = if commit <= 1
            "#{commit}com"
          else
            "#{commit}com"
          end
    con = if contribution <= 1
            "#{contribution}cont"
          else
            "#{contribution}cont"
          end
    "#{con} - #{com}"
  end

  def create_sentence(time, num_commit, num_contribution)
    "#{time.strftime('%m')}/#{time.strftime('%d')}" \
    "(#{%w[Sun Mon Tue Wed Thur Fri Sat][time.wday]}): #{correct_sentence(num_commit, num_contribution)}"
  end

  def extract_contribution_count
    charset = nil

    html = open(@contribution_url) do |f|
      charset = f.charset
      f.read
    end

    doc = Nokogiri::HTML.parse(html, nil, charset)
    doc.css('.day').map do |row|
      t1 = row.attribute('data-date').value.gsub(/-/, '')
      next unless contribution_in_range?(t1, @date_day1, @date_day7)

      @ary_contribution.push(row.attribute('data-count').value.to_i)
    end
  end

  def get_json_data(url)
    uri = URI.parse(url)
    json = Net::HTTP.get(uri)
    JSON.parse(json)
  end

  def tweet_1week_commits
    aggregate_commits_per_day
    extract_contribution_count
    @tweet_texts.push("#{@ary_contribution.sum} contributions(#{@commits_of_wk.sum} commits) in last week.")
    add_texts_per_day
    @tweet_texts.push("\n#toshi_weekly_github_activity")
    @client.update(@tweet_texts.join("\n"))
  end
end

Tweet.new.tweet_1week_commits

# [gistを使ってJSONを返す超簡易的なAPIサーバを作る - KDE BLOG](https://kde.hateblo.jp/entry/2018/11/28/022838)
# [github apiのサンプル](https://gist.github.com/toshi-ue/200ce679e6cd46aeadde21b0e6b82c92)

# [Ruby で UTC���文字列）を JST にとにか���さっさと変換する方法 - 約束の地](https://obel.hatenablog.jp/entry/20170616/1497591134)

# [ruby 条件 範囲 - Google 検索](https://www.google.com/search?q=ruby+%E6%9D%A1%E4%BB%B6+%E7%AF%84%E5%9B%B2&oq=ruby+%E6%9D%A1%E4%BB%B6%E3%80%80%E7%AF%84%E5%9B%B2&aqs=chrome..69i57j69i64.5591j0j7&sourceid=chrome&ie=UTF-8)

# [Ruby で楽に範囲のチェックをする - Qiita](https://qiita.com/cho_co/items/2cbe429308edc93b7854)

# for debug_url
# @events_url = 'https://gist.githubusercontent.com/toshi-ue/200ce679e6cd46aeadde21b0e6b82c92/raw/e57dbf724c433065275ebba07007e728cfb73946/events.json'

# @contribution_url = 'https://github.com/users/toshi-ue/contributions'
