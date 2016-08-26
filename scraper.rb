#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(URI.encode(URI.decode(url))).read)
end

def scrape_list(term, url)
  noko = noko_for(url)
  noko.css('#List_of_members').xpath('.//preceding::*').remove
  noko.css('#References').xpath('.//following::*').remove
  noko.xpath('.//table/tr[td]').each do |tr|
    td = tr.css('td')
    data = {
      name:         td[0].text,
      wikiname:     td[0].xpath('.//a[not(@class="new")]/@title').text,
      party_colour: td[1].attr('style')[/background-color: #(\w+)/, 1],
    }
    if td.count == 3
      data[:party] = 'IND'
      data[:type] = td[2].text
    elsif td.count == 4
      data.merge!(party:          td[2].text,
                  party_wikiname: td[2].xpath('.//a[not(@class="new")]/@title').text,
                  type:           td[3].text)
    else
      data.merge!(party:             td[2].text,
                  party_wikiname:    td[2].xpath('.//a[not(@class="new")]/@title').text,
                  constituency:      td[3].text,
                  district:          td[4].text,
                  district_wikiname: td[4].xpath('.//a[not(@class="new")]/@title').text)
    end
    data[:term] = term
    ScraperWiki.save_sqlite(%i(name party_colour term), data)
  end
end

scrape_list(9, 'https://en.wikipedia.org/wiki/List_of_members_of_the_ninth_Parliament_of_Uganda')
