require "rails_helper"

RSpec.describe "Job match", type: :system do
  let(:use_case) { instance_double(MatchJobUseCase) }

  before do
    allow(MatchJobUseCase).to receive(:new).and_return(use_case)
    visit root_path(locale: "en")
  end

  it "renders the summary paragraphs without citations or sources" do
    allow(use_case).to receive(:execute).and_return(
      summary: [
        { text: "Strong Rails fit.", citations: [ { source: 0, cited_text: "Built a Rails app" }, { source: 1, cited_text: "Built a CLI" } ] },
        { text: " <b>Solid</b> API design.", citations: [] }
      ],
      sources: [ { title: "alpha", url: "https://github.com/octo/alpha" }, { title: "beta", url: "https://github.com/octo/beta" } ],
      usage: { input_tokens: 1, output_tokens: 1 }
    )

    fill_in "job_description", with: "Senior Rails engineer"
    click_button "Check the fit"

    expect(page).to have_content("Strong Rails fit. <b>Solid</b> API design.")
    expect(page).not_to have_content("[1]")
    expect(page).not_to have_link("alpha")
    # Model output is text, never markup.
    expect(page).to have_content("<b>Solid</b> API design.")
    expect(page).to have_button("Check the fit")
  end

  it "shows the field error and banner when the server rejects the description" do
    allow(use_case).to receive(:execute).and_raise(ValidationError.new(job_description: "must be at most 6000 characters"))

    fill_in "job_description", with: "Too long, pretend"
    click_button "Check the fit"

    expect(page).to have_content("must be at most 6000 characters")
    expect(page).to have_content("Check the job description and try again.")
  end
end
