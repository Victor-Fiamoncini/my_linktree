module UseCases
  class ListServicesUseCase
    def initialize(database: ConfigDatabase.new)
      @database = database
    end

    def execute
      @database.services
    end
  end
end
