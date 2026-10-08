class GetResumeTool < ApplicationTool
  tool_name "get_resume"
  description "Get Victor Fiamoncini's resume: profile, work experience, and education."
  input_schema(properties: {})

  def self.perform(**)
    GetProfileUseCase.new.execute(locale: :en)
  end
end
