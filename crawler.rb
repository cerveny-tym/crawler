#!/usr/bin/env ruby
# encoding: UTF-8

require "rubygems"
require "bundler/setup"
require 'choice'
require 'anemone'
require 'pry-byebug'
require 'mongo'

Choice.options do
  header 'Application options:'

  separator 'Required:'

  option :urls, :required => false do
    short '-u'
    long '--url=<file>'
    desc 'The base url'
  end

  option :depth, :required => false do
    short '-d'
    long '--depth=<n>'
    desc 'The depth of links to follow-up'
  end

  separator 'Common:'

  option :help do
    short '-h'
    long '--help'
    desc 'Show this message.'
  end
end

class Crawler

  Mongo::Logger.logger.level = Logger::WARN

  def initialize(base_urls, depth)
    @client = Mongo::Client.new('mongodb://redteam:redpassword@ds061415.mongolab.com:61415/buzzword')
    puts @client.database.collections.to_s

    @urls = Array.new
    if base_urls.nil?
      documents = @client[:urls].find
      documents.each do |document|
        @urls.push document["url"]
      end
    else
      File.open(base_urls, "r") do |f|
        f.each_line do |line|
          @urls.push line
        end
      end
    end
    puts "Crawling: #{@urls}"

    @depth = depth.nil? ? 1 : depth.to_i
  end

  def crawl
    reindex = Array.new
    saved = 0

    @urls.each do |base_url|
      raw_collection = @client[:raw]
      Anemone.crawl(base_url, :depth_limit => @depth) do |anemone|
        anemone.on_every_page do |page|

          unless page.doc.nil?
            raw_data = page.doc.xpath("//text()").to_s
            raw_data = raw_data.downcase.gsub /\W+/, ' '
            #p raw
            #result = raw_collection.insert_one({ "url" => page.url.to_s, "data" => raw_data })
            # result = raw_collection.update_one (
            #   { "url" => page.url.to_s },
            #   { "$inc" => { "url" => page.url.to_s, "data" => raw_data }}
            # )
result = raw_collection.update_one({ :name => page.url.to_s }, { :data => raw_data })
            saved = saved + 1
          end
        end
      end
    end

    puts "Total of #{saved} pages crawled"
  end

  private
end

crawler = Crawler.new( nil, 1 )
crawler.crawl
