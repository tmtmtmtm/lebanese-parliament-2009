#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def data_at(url)
  noko = noko_for(url)
  noko.xpath('//table[.//th[contains(.,"Religion")]]/tr[td]').map do |tr|
    tds = tr.css('td')

    data = {
      name:           tds[0].css('a')&.first&.text&.tidy || tds[0].text.tidy,
      wikiname:       tds[0].xpath('.//a[not(@class="new")]/@title').text,
      area:           tds[2].text.tidy,
      religion:       tds[3].text.tidy,
      party:          tds[1].text.tidy,
      party_wikiname: tds[1].xpath('.//a[not(@class="new")]/@title').text,
      term:           2009,
      source:         url.to_s,
    }

    notes = tds[4].text.to_s
    if (capture = notes.match /Until (\d+ \w+ \d+)/i).to_a.any?
      end_date = Date.parse(capture.captures.first).to_s rescue binding.pry
    end
    if (capture = notes.match /Elected (\d+ \w+ \d+)/i).to_a.any?
      start_date = Date.parse(capture.captures.first).to_s rescue binding.pry
    end
    data
  end
end

url = 'https://en.wikipedia.org/wiki/Members_of_the_2009%E2%80%9317_Lebanese_Parliament'
data = data_at(url)
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
ScraperWiki.save_sqlite(%i(name area party term), data)
