#NOTES:
  # 1. transaction_type has to be 'sale' to successfully generate an ach_token
  #    for the account
  # 2. the ach_token itself will change if any information surrounding the stored
  #    payment method changes, e.g. account_number, routing_number, name_on_check
  #    customer_id
module Repay
  class AchToken
    def initialize funding_package_id, account_holder, routing_number, account_number
      @auth_header = {
        "Authorization" => "apptoken #{ENV['REPAY_API_TOKEN']}"
      }.freeze

      @form_id = ENV['REPAY_SAVE_ACH_FORM_ID']
      @customer_id    ||= funding_package_id
      @account_holder ||= account_holder
      @routing_number ||= routing_number
      @account_number ||= account_number
      @session_params ||= {
        "amount"           => "0.00",
        "customer_id"      => "#{@customer_id}",
        "transaction_type" => "sale",
        "convenience_fee"  => "0.00",
        "payment_type"     => "recurring"
      }
    end



    def session_token
      #this is basically a mutex, if someone else makes this request, mine will no longer work for transactions
      url = "#{ENV['REPAY_REST_BASE']}/checkout/merchant/api/v1/checkout-forms/#{@form_id}/paytoken"
      return nil unless @form_id
      begin
        @session_request ||= RestClient.post url, @session_params.to_json, { :content_type => "application/json"}.merge(@auth_header)
        return nil if @session_request.code != 200
        @session_token ||= JSON.parse(@session_request.body)["paytoken"]
      rescue => e
        Errorlogger.new(e, @session_params).paytoken_initial_store_error
        return nil
      end
    end

    def ach_token
      #this (hopefully) gives us a token we can use indefinitely to pull/post payments
      return nil unless session_token
      url = "#{ENV['REPAY_REST_BASE']}/checkout/merchant/api/v1/checkout-forms/#{@form_id}/token-payment"
      begin
        @ach_request ||= RestClient.post url, token_params(session_token).to_json, { :content_type => "application/json"}.merge(@auth_header)
      rescue => e
        ErrorLogger.new(e, token_params(session_token)).get_ach_token_error
        return nil
      end
      @ach_token ||= JSON.parse(@ach_request.body)["saved_payment_method"]["token"]
    end

    def token_params(session)
      @token_params ||= {
        "amount"              => "0.00", #must be this amount for testing purposes
        "name_on_check"       => "#{@account_holder}",
        "ach_account_number"  => "#{@account_number}",
        "ach_routing_number"  => "#{@routing_number}",
        "customer_id"         => "#{@customer_id}",
        "transaction_type"    => "sale",
        "save_payment_method" => "true",
        "paytoken"            => "#{session}",
        "convenience_fee"     => "0.00",
        "payment_type"        => "recurring"
      }
    end

  end
end
