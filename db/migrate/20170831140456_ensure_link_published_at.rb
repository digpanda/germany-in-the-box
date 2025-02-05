class EnsureLinkPublishedAt < Mongoid::Migration
  def self.up
    Link.all.each do |link|
      unless link.published_at
        puts "For link #{link.id}, `published_at` will automatically be set to #{link.c_at}"
        link.published_at = link.c_at
        link.save
      end
    end
  end

  def self.down
  end
end
