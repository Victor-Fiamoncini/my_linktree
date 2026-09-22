class StaticController < ApplicationController
  def agents_md
    render plain: AgentsContent.markdown, content_type: "text/markdown"
  end

  def llms_txt
    render plain: AgentsContent.llms_txt, content_type: "text/plain"
  end

  def sitemap
    render layout: false, formats: :xml
  end
end
