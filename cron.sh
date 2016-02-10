#! /bin/bash

cd /f2f/crawler
bundle exec ruby crawler.rb >> /f2f/crawler/crawl.log 2>&1
