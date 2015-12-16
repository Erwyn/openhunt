# == Schema Information
#
# Table name: projects
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  description    :string           not null
#  url            :string           not null
#  normalized_url :string           not null
#  user_id        :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Project < ActiveRecord::Base
  belongs_to :user

  has_many :votes

  before_save :normalize_url
  def normalize_url
    self.normalized_url = self.class.normalize_url(self.url)
  end

  def self.normalize_url(url)
    url = url.to_s
    url = url.gsub(/\\/,'')
    url = url.gsub("http://", "").gsub("https://", "")

    # remove trailing slash (if it doesn't have query params)
    url = url[0...-1] if url.ends_with?("/") and !url.include?("?")

    # TODO: remove url junk like UTM, etc

    url
  end


  def self.featured(page = nil, per_page = nil)
    page ||= 1
    per_page ||= Settings.featured_per_page

    # calculate offset
    offset = (page - 1)*per_page
    offset = 0 if offset <= 0

    # TODO: improve performance:
    #         - use pure SQL to run calculation & sorting on the database
    #         - http://sorentwo.com/2013/12/30/let-postgres-do-the-work.html

    # Project.all.sort_by(&:score).limit(per_page).offset(offset)
    # 'sort_by' returns an array. Do we need an ActiveRecord Relation instead?
    Project.all.sort_by(&:score).reverse.slice(offset, per_page)
  end

  # Discussing HackerNews algorithm:
  # https://medium.com/hacking-and-gonzo/how-hacker-news-ranking-algorithm-works-1d9b0cf2c08d#.bkaj2mpm1
  # Here is the older, simpler algorithm
  def score
    votes = votes_count - 1 # votes_count minus the submitter's own vote
    hours_since_submission = (Time.now.hour - created_at.hour).abs
    gravity = 1.8 # gravity defaults to 1.8 in news.arc

    votes / (hours_since_submission + 2) ** gravity
  end
end
