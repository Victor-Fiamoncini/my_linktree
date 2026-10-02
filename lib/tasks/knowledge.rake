namespace :knowledge do
  desc "Embed config/profile.yml and the GitHub READMEs in config/knowledge.yml into knowledge_chunks"
  task ingest: :environment do
    result = IngestKnowledgeUseCase.new.execute
    puts "#{result[:total]} chunks: #{result[:embedded]} embedded, #{result[:removed]} removed"
  end
end
