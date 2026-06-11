module Kiwoom
  class ApiError < StandardError
    attr_reader :endpoint, :api_id, :response_code, :body

    def initialize(message, endpoint:, api_id: nil, response_code: nil, body: nil)
      super(message)
      @endpoint = endpoint
      @api_id = api_id
      @response_code = response_code
      @body = body
    end
  end
end
