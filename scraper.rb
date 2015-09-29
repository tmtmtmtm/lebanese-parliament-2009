#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//table[.//th[contains(.,"Religion")]]/tr[td]').each do |tr|
    tds = tr.css('td')

    data = { 
      name: tds[0].text.tidy,
      wikiname: tds[0].xpath('.//a[not(@class="new")]/@title').text,

      area: tds[2].text.tidy,

      religion: tds[3].text.tidy,

      party: tds[1].text.tidy,
      party_wikiname: tds[1].xpath('.//a[not(@class="new")]/@title').text,
      term: 2009,
      source: url.to_s,
    }
    ScraperWiki.save_sqlite([:name, :area, :party, :term], data)
  end
end

scrape_list('https://en.wikipedia.org/wiki/Members_of_the_2009%E2%80%9317_Lebanese_Parliament')
