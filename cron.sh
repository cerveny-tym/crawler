#! /bin/bash

cd /f2f/crawler
bundle exec ruby crawler.rb >> /f2f/crawler/crawl.log 2>&1
java -DMONGODB_PASSWORD=redpassword  -jar word-processor-0.0.1-SNAPSHOT.jar  >> /f2f/crawler/processor.log 2>&1
