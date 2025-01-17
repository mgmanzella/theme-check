# frozen_string_literal: true
require "test_helper"

class MissingTemplateTest < Minitest::Test
  def test_reports_missing_snippet
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% include 'one' %}
        {% render 'two' %}
      END
    )
    assert_offenses(<<~END, offenses)
      'snippets/one.liquid' is not found at templates/index.liquid:1
      'snippets/two.liquid' is not found at templates/index.liquid:2
    END
  end

  def test_do_not_report_if_snippet_exists
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% include 'one' %}
        {% render 'two' %}
      END
      "snippets/one.liquid" => <<~END,
        hey
      END
      "snippets/two.liquid" => <<~END,
        there
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_missing_section
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% section 'one' %}
      END
    )
    assert_offenses(<<~END, offenses)
      'sections/one.liquid' is not found at templates/index.liquid:1
    END
  end

  def test_do_not_report_if_section_exists
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% section 'one' %}
      END
      "sections/one.liquid" => <<~END,
        hey
      END
    )
    assert_offenses("", offenses)
  end

  def test_ignore_missing
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new(ignore_missing: [
        "snippets/icon-*",
        "sections/*",
      ]),
      "templates/index.liquid" => <<~END,
        {% render 'icon-nope' %}
        {% section 'anything' %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_creates_missing_snippet
    theme = make_theme(
      "templates/index.liquid" => <<~END,
        {% include 'one' %}
        {% render 'two' %}
      END
    )

    analyzer = ThemeCheck::Analyzer.new(theme, [ThemeCheck::MissingTemplate.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    missing_files = ["snippets/one.liquid", "snippets/two.liquid"]
    assert(missing_files.all? { |file| theme.storage.files.include?(file) })
  end

  def test_creates_missing_section
    theme = make_theme(
      "templates/index.liquid" => <<~END,
        {% section 'one' %}
      END
    )

    analyzer = ThemeCheck::Analyzer.new(theme, [ThemeCheck::MissingTemplate.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    missing_files = ["sections/one.liquid"]
    assert(missing_files.all? { |file| theme.storage.files.include?(file) })
  end
end
