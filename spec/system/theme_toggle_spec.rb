require "rails_helper"

RSpec.describe "Theme toggle", type: :system do
  def background_color
    page.evaluate_script("getComputedStyle(document.body).backgroundColor")
  end

  def theme_color_meta
    find("meta[name='theme-color']", visible: false)[:content]
  end

  # Only the active flavor's badge is visible, so this is the flavor the Theme card highlights.
  def highlighted_flavor
    find("span", text: /\Aactive\z/i).find(:xpath, "preceding-sibling::a").text
  end

  it "switches to Latte and keeps it across a reload" do
    visit root_path(locale: "en")

    expect(page).to have_css('html[data-theme="frappe"]', visible: :all)
    expect(background_color).to eq("rgb(48, 52, 70)")

    find("header nav ul button[data-action='theme#toggle']").click

    expect(page).to have_css('html[data-theme="latte"]', visible: :all)
    expect(page).to have_css("header nav ul button[aria-pressed='true']")
    expect(background_color).to eq("rgb(239, 241, 245)")

    visit root_path(locale: "en")

    expect(page).to have_css('html[data-theme="latte"]', visible: :all)
    expect(background_color).to eq("rgb(239, 241, 245)")
  end

  it "switches back to Frappé" do
    visit root_path(locale: "en")

    2.times { find("header nav ul button[data-action='theme#toggle']").click }

    expect(page).to have_css('html[data-theme="frappe"]', visible: :all)
    expect(background_color).to eq("rgb(48, 52, 70)")
  end

  it "flips the theme from the switch in the Theme card, keeping the header button in sync" do
    visit root_path(locale: "en")

    find("button[role='switch']").click

    expect(page).to have_css('html[data-theme="latte"]', visible: :all)
    expect(page).to have_css("button[role='switch'][aria-checked='true']")
    expect(page).to have_css("header nav ul button[aria-pressed='true']")
    expect(page).to have_css("button[role='switch'][title='Switch to dark theme']")
    expect(page).to have_css("header nav ul button[title='Switch to dark theme']")

    find("button[role='switch']").click

    expect(page).to have_css('html[data-theme="frappe"]', visible: :all)
    expect(page).to have_css("button[role='switch'][aria-checked='false']")
    expect(page).to have_css("button[role='switch'][title='Switch to light theme']")
  end

  it "moves the active highlight in the Theme card and the browser chrome color with the theme" do
    visit root_path(locale: "en")

    expect(highlighted_flavor).to eq("Catppuccin Frappé")
    expect(theme_color_meta).to eq("#8caaee")

    find("button[role='switch']").click

    expect(page).to have_css('html[data-theme="latte"]', visible: :all)
    expect(highlighted_flavor).to eq("Catppuccin Latte")
    expect(theme_color_meta).to eq("#1e66f5")
  end

  it "toggles from the mobile header" do
    page.driver.resize(375, 800)
    visit root_path(locale: "en")

    expect(page).to have_no_css("header nav ul button[data-action='theme#toggle']")

    find("header nav > div button[data-action='theme#toggle']").click

    expect(page).to have_css('html[data-theme="latte"]', visible: :all)
    expect(background_color).to eq("rgb(239, 241, 245)")
  ensure
    page.driver.resize(1200, 800)
  end
end
