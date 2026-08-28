require "rails_helper"

RSpec.describe "Contact form", type: :system do
  before { visit root_path }

  it "submits via JS, hides the button, and shows a success message in its place" do
    fill_in "name", with: "Jane"
    fill_in "email", with: "jane@example.com"
    fill_in "message", with: "Hello from a real browser!"

    click_button "Reach Out"

    expect(page).to have_content("Thank you for your message!")
    expect(page).not_to have_button("Reach Out")
    expect(page).to have_current_path(root_path)
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "hides the button and shows a field-level error when the email is invalid" do
    fill_in "name", with: "Jane"
    fill_in "email", with: "not-an-email"
    fill_in "message", with: "Hello!"

    # Bypass native HTML5 email-format validation so the request actually reaches the server,
    # exercising this app's own validation instead of the browser's built-in constraint checking.
    page.execute_script(<<~JS)
      document.querySelector('[data-controller="contact-form"]').noValidate = true
    JS

    click_button "Reach Out"

    expect(page).to have_content("is invalid")
    expect(page).to have_content("Check the highlighted fields and try again.")
    expect(page).not_to have_button("Reach Out")
    expect(page).to have_field("name", with: "Jane")
    expect(ActionMailer::Base.deliveries.size).to eq(0)
  end

  it "shows a rate-limit error after exceeding the submission limit" do
    fill_in "name", with: "Jane"
    fill_in "email", with: "jane@example.com"
    fill_in "message", with: "Hello!"
    click_button "Reach Out"

    # The button is hidden after the first response, so later attempts resubmit the (now-reset)
    # form directly, the same way pressing Enter in a text field would trigger it without a
    # visible button.
    2.times do
      fill_in "name", with: "Jane"
      fill_in "email", with: "jane@example.com"
      fill_in "message", with: "Hello!"
      page.execute_script(<<~JS)
        document.querySelector('[data-controller="contact-form"]').requestSubmit()
      JS
    end

    expect(page).to have_content("Too many requests")
  end
end
