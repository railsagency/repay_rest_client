#NOTES:
  # 1. transaction_type has to be 'sale' to successfully generate an ach_token
  #    for the account
  # 2. the ach_token itself will change if any information surrounding the stored
  #    payment method changes, e.g. account_number, routing_number, name_on_check
  #    customer_id
module Repay
  class AchTokenPayment
    def initialize ach_token, customer_id, amount
      @auth_header = {
        "Authorization" => "apptoken #{ENV['REPAY_API_TOKEN']}"
      }.freeze

      @form_id = ENV['REPAY_USE_STORED_ACH_FORM_ID']
      @customer_id    ||= customer_id
      @ach_token      ||= ach_token
      @amount         ||= amount.to_s #makes it possible to pass Money type for this param
      @session_params ||= {
        "amount" => amount,
        "customer_id" => "#{@customer_id}",
        "transaction_type" => "sale",
        "ach_token" => @ach_token,
        "convenience_fee" => "0.00",
        "payment_type" => "recurring"
      }
    end

    def session_token
      #this is basically a mutex, if someone else makes this request, mine will no longer work for transactions
      return nil unless @form_id
      url = "#{ENV['REPAY_REST_BASE']}/checkout/merchant/api/v1/checkout-forms/#{@form_id}/paytoken"
      begin
        @session_request ||= RestClient.post url, @session_params.to_json, { :content_type => "application/json"}.merge(@auth_header)
        return nil if @session_request.code != 200
        @session_token ||= JSON.parse(@session_request.body)["paytoken"]
      rescue => e
        ErrorLogger.new(e, @session_params).paytoken_use_ach_error
        return nil
      end
    end

    def payment
      return nil unless session_token
      url = "#{ENV['REPAY_REST_BASE']}/checkout/merchant/api/v1/checkout-forms/#{@form_id}/token-payment"
      begin
        @ach_request ||= RestClient.post url, payment_params(session_token).to_json, { :content_type => "application/json"}.merge(@auth_header)
        return nil if @ach_request.code != 200
        @payment ||= JSON.parse(@ach_request.body)
      rescue => e
        ErrorLogger.new(e, payment_params(session_token)).use_ach_token_error
        return nil
      end
    end

    def payment_params(session)
      @payment_params ||= {
        "amount" => @amount, #must be this amount for testing purposes
        "customer_id" => "#{@customer_id}",
        "ach_token" => "#{@ach_token}",
        "transaction_type" => "sale",
        "paytoken" => "#{session}",
        "convenience_fee" => "0.00",
        "payment_type" => "recurring"
      }
    end

  end
end
