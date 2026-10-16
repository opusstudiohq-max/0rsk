# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'rack/test'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::FooterTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_looks_up_the_address_the_server_sees
    get('/')
    assert_equal(200, last_response.status, last_response.body)
    links = Nokogiri::HTML.parse(last_response.body).xpath("//a[contains(@href,'iplocation.com')]")
    refute_empty(links, last_response.body)
    assert_includes(links.first['href'], 'ip=127.0.0.1', last_response.body)
  end

  def test_telegram_link_in_list_item
    set_cookie('glogin=test_user')
    get('/terms')
    assert_equal(200, last_response.status, last_response.body)
    li = Nokogiri::HTML.parse(last_response.body).xpath("//footer//ul//li[a[contains(@href,'t.me/zerorsk_bot')]]")
    refute_empty(li, 'Telegram link must be nested inside a list item in footer')
    refute_empty(li.first.xpath("img[contains(@src,'telegram-logo.svg')]"), 'Telegram logo in same list item')
    assert_equal('https://t.me/zerorsk_bot', li.first.xpath('a').first['href'])
    assert_equal('Telegram bot', li.first.xpath('a').first['title'])
  end

  def test_footer_structure_with_active_project
    set_cookie('glogin=test_user')
    set_cookie('0rsk-project=42')
    get('/terms')
    assert_equal(200, last_response.status, last_response.body)
    assert_empty(
      Nokogiri::HTML.parse(last_response.body).xpath('//footer//ul/*[not(self::li)]'),
      'navigation list with project cookie must only contain list items'
    )
  end

  def test_footer_valid_list_structure
    set_cookie('glogin=test_user')
    get('/terms')
    assert_equal(200, last_response.status, last_response.body)
    assert_empty(
      Nokogiri::HTML.parse(last_response.body).xpath('//footer//ul/*[not(self::li)]'),
      'ul in footer may only contain li elements'
    )
  end

  def test_footer_without_empty_items
    set_cookie('glogin=test_user')
    get('/terms')
    assert_equal(200, last_response.status, last_response.body)
    assert_empty(
      Nokogiri::HTML.parse(last_response.body).xpath("//footer//ul//li[normalize-space(text())='' and count(*) = 0]"),
      'footer should not have empty li tags'
    )
  end
end
