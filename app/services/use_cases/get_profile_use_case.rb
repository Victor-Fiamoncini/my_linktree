module UseCases
  class GetProfileUseCase
    def initialize(database: ConfigDatabase.new)
      @database = database
    end

    def execute
      @database.profile
    end
  end
end
