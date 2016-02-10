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

  option :urls, :required => true do
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
    #puts ARGV
    @urls = Array.new
    File.open(base_urls, "r") do |f|
      f.each_line do |line|
        @urls.push line
      end
    end

    @depth = depth.nil? ? 1 : depth.to_i
  end

  def crawl

    client = Mongo::Client.new('mongodb://redteam:redpassword@ds061415.mongolab.com:61415/buzzword')

    database = client.database
    p database.collections

    reindex = Array.new
    saved = 0

    @urls.each do |base_url|
      Anemone.crawl(base_url, :depth_limit => @depth) do |anemone|
        anemone.on_every_page do |page|

          unless page.doc.nil?
            raw = page.doc.xpath("//text()").to_s
            raw = raw.downcase.gsub /\W+/, ' '
            #p raw
            result = client[:raw].insert_one({ "url" => page.url.to_s, "data" => raw })
            saved = saved + 1
          end
        end
      end
    end

    puts "Total of #{saved} pages crawled"
  end

  private
end

  crawler = Crawler.new( Choice.choices.urls, 1 )
  crawler.crawl
