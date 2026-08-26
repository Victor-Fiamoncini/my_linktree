class ConfigDatabase
  def profile
    { name: data[:name], experiences: data[:experiences], education: data[:education] }
  end

  def services
    data[:services]
  end

  private

  def data
    @data ||= YAML.load_file(Rails.root.join("config/profile.yml")).deep_symbolize_keys
  end
end
