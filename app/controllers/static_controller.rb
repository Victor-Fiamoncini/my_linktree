class StaticController < ApplicationController
  def agents_md
    render plain: AgentsContent::CONTENT, content_type: "text/markdown"
  end

  def sitemap
    render layout: false, formats: :xml
  end
end
