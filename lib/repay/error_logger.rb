#NOTES:
  # 1. transaction_type has to be 'sale' to successfully generate an ach_token
  #    for the account
  # 2. the ach_token itself will change if any information surrounding the stored
  #    payment method changes, e.g. account_number, routing_number, name_on_check
  #    customer_id
module Repay
  class ErrorLogger
    def initialize e, params
      @e ||= e
      @params ||= params
    end

    def paytoken_initial_store_error
      pp "xxxx Repay Client ERROR ( PayToken: initial ach storage ) ==> #{specific_error}"
      detail
    end

    def get_ach_token_error
      pp "xxxx Repay Client ERROR ( ACH Storage: storying payment info ) ==> #{specific_error}"
      detail
    end

    def paytoken_use_ach_error
      binding.pry
      pp "xxxx Repay Client ERROR ( PayToken: for existing ach info ) ==> #{specific_error}"
      detail
    end

    def use_ach_token_error
      pp "xxxx Repay Client ERROR ( ACH Token: pulling a payment ) ==> #{specific_error}"
      detail
    end

    def specific_error
      body = JSON.parse(@e.response.body)
      name = body['errors'].first['name']
      description = body['errors'].first['description']
      error_detail = [name,description].reject{|element| element.empty?}.join(": ")
      return error_detail
    end

    def detail
      detail = @params.map{|k,v| "#{k}: #{v}"}.join(", ")
      pp ":::::::: Details - #{detail}"
      pp "--------------------------------------------------------------------"
    end

  end
end
