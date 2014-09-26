class Feed < ActiveRecord::Base
	validates :url, :title, presence: true

	has_many :entries

	has_many :subscriptions
	has_many :users, through: :subscriptions

	has_many :feed_categories
	has_many :categories, through: :feed_categories

	def self.find_or_create_by_url(url)
		feed = Feed.find_by_feed_url(url)

		if !feed
			fj_feed = Feedjira::Feed.fetch_and_parse(url)

			if fj_feed.class == Fixnum 
				return nil
			else
				feed = Feed.create!({
					feed_url: url,
					url: fj_feed.url, 
					title: fj_feed.title, 
					description: fj_feed.description
				})
			end
		end
		feed.get_entries
		return feed
	end

	def get_entries
		fj_feed = Feedjira::Feed.fetch_and_parse(self.feed_url)
		existing_entry_urls = self.entries.pluck(:url)
		if fj_feed == 0 
			puts "dead url: #{fj_feed.title}"
		else
			fj_feed.entries.each do |entry|
				unless existing_entry_urls.include?(entry.url)
					Entry.create_by_fj(entry.url, self.id)
				end
			end
		end
	end
end
