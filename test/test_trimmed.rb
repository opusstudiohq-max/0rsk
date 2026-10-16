# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/trimmed'
require_relative 'test__helper'

class Rsk::TrimmedTest < TestCase
  def test_standalone_paren_does_not_truncate_early
    trimmed = Rsk::Trimmed.new(
      'Failure reason (investigated yesterday) occurred in subsystem and caused delay in deployment',
      60
    ).to_s
    assert_includes(trimmed, 'investigated yesterday')
    assert_operator(trimmed.length, :<=, 60)
  end

  def test_unclosed_paren_does_not_prevent_content
    trimmed = Rsk::Trimmed.new(
      'Warning (unclosed note with lots of additional details following up to the max limit',
      50
    ).to_s
    assert_includes(trimmed, 'lots of additional')
    assert_operator(trimmed.length, :<=, 50)
  end

  def test_multiple_unmatched_parens_in_text
    trimmed = Rsk::Trimmed.new(
      'Status: (1) first (2) second (3) third (and unclosed fourth note that extends very far',
      55
    ).to_s
    assert_includes(trimmed, '(2) second')
    assert_operator(trimmed.length, :<=, 55)
  end

  def test_valid_markdown_link_preserved_when_fits
    trimmed = Rsk::Trimmed.new(
      'See [documentation](https://example.com/docs) for full instructions and details',
      50
    ).to_s
    assert_includes(trimmed, '[documentation](https://example.com/docs)')
    assert_operator(trimmed.length, :<=, 50)
  end

  def test_valid_markdown_link_not_broken_on_trim
    trimmed = Rsk::Trimmed.new(
      'Prefix [important link](https://example.com/very/long/destination/url) postfix',
      30
    ).to_s
    assert_equal(trimmed.count('['), trimmed.count(']'))
    assert_equal(trimmed.count('('), trimmed.count(')'))
    assert_operator(trimmed.length, :<=, 30)
  end

  def test_standalone_parens_and_markdown_links
    trimmed = Rsk::Trimmed.new(
      'Report (draft v1): see [tracker](https://0rsk.com/t/123) for details (updated recently)',
      65
    ).to_s
    assert_includes(trimmed, 'Report (draft v1)')
    assert_includes(trimmed, '[tracker](https://0rsk.com/t/123)')
    assert_equal(trimmed.count('['), trimmed.count(']'))
    assert_operator(trimmed.length, :<=, 65)
  end

  def test_cuts_on_line_boundary_with_paren_in_line
    assert_equal(
      "First line (with note)\nSecond line...",
      Rsk::Trimmed.new("First line (with note)\nSecond line\nThird line with extra information", 40).to_s
    )
  end

  def test_markdown_link_with_paren_in_title
    trimmed = Rsk::Trimmed.new('Link: [item (v2)](https://example.com) followed by extra remarks', 45).to_s
    assert_includes(trimmed, '[item (v2)](https://example.com)')
    assert_operator(trimmed.length, :<=, 45)
  end
end
