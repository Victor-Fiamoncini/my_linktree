# Rebuilds the RAG corpus. Idempotent: only chunks whose content changed are re-embedded, and
# chunks no source produces anymore are deleted.
class IngestKnowledgeUseCase
  def initialize(
    embedder: OpenaiEmbedder.new,
    github: GithubReadmeClient.new,
    profile: GetProfileUseCase.new,
    services: ListServicesUseCase.new,
    chunker: ChunkTextUseCase.new,
    config: Rails.application.config_for(:knowledge)
  )
    @embedder = embedder
    @github = github
    @profile = profile
    @services = services
    @chunker = chunker
    @config = config
  end

  def execute
    documents = (profile_documents + readme_documents).uniq { |document| document[:content_hash] }
    existing = KnowledgeChunk.pluck(:content_hash).to_set
    fresh = documents.reject { |document| existing.include?(document[:content_hash]) }
    embeddings = fresh.any? ? @embedder.embed(fresh.map { |document| document[:content] }) : []

    removed = KnowledgeChunk.transaction do
      fresh.zip(embeddings).each { |document, embedding| KnowledgeChunk.create!(document.merge(embedding: embedding)) }

      KnowledgeChunk.where.not(content_hash: documents.map { |document| document[:content_hash] }).delete_all
    end

    { total: documents.size, embedded: fresh.size, removed: removed }
  end

  private

  def profile_documents
    profile = @profile.execute(locale: :en)
    experience_url = "#{SeoConfig::SITE_URL}/en#experience"

    experiences = profile[:experiences].map do |experience|
      document(
        source_type: "experience",
        source_ref: "experience:#{experience[:id]}",
        title: "#{experience[:role]} at #{experience[:company]}",
        url: experience_url,
        content: experience_text(profile[:name], experience)
      )
    end

    education = document(
      source_type: "education",
      source_ref: "education",
      title: "Education",
      url: experience_url,
      content: "#{profile[:name]} — Education\n\n" + profile[:education].map { |entry| "- #{entry[:degree]} in #{entry[:field]}, #{entry[:institution]}" }.join("\n")
    )

    services = document(
      source_type: "services",
      source_ref: "services",
      title: "Services offered",
      url: "#{SeoConfig::SITE_URL}/en",
      content: "#{profile[:name]} — Services offered\n\n" + @services.execute(locale: :en).map { |service| "- #{service[:name]}: #{service[:description]}" }.join("\n")
    )

    experiences + [ education, services ]
  end

  def experience_text(name, experience)
    period = "#{experience[:start_date]} to #{experience[:current] ? "present" : experience[:end_date]}"
    stack = { "Backend" => :backend, "Frontend" => :frontend, "Infrastructure" => :infra, "Other tools" => :other_tools }
      .filter_map { |label, key| "#{label}: #{experience[key].join(", ")}" if experience[key].present? }

    [ "#{name} — #{experience[:role]} at #{experience[:company]} (#{period}, #{experience[:country_name]})", *stack, "", experience[:description] ].join("\n")
  end

  def readme_documents
    owner = @config[:github_owner]

    @config[:repos].flat_map do |repo|
      readme = @github.fetch(owner: owner, repo: repo)

      next [] if readme.blank?

      @chunker.execute(text: readme, title: "GitHub project #{repo}").each_with_index.map do |content, index|
        document(
          source_type: "github_readme",
          source_ref: "#{repo}##{index}",
          title: repo,
          url: "https://github.com/#{owner}/#{repo}",
          content: content
        )
      end
    end
  end

  # Title and url join the hash so a metadata-only change replaces the row. source_ref stays out:
  # it shifts with chunk position and nothing downstream reads it.
  def document(content:, **attributes)
    key = attributes.values_at(:source_type, :title, :url).push(content).to_json

    attributes.merge(content: content, content_hash: Digest::SHA256.hexdigest(key))
  end
end
