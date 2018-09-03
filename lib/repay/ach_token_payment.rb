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
      @form_id_ep = "#{ENV['REPAY_REST_BASE']}/checkout/merchant/api/v1/checkout".freeze
      @form_id_params = {
        "payment_method"=> "ach_token",
        "StorePayment"=> "true"
      }
      @customer_id    ||= customer_id
      @ach_token      ||= ach_token
      @amount         ||= amount
      @session_params ||= {
        "amount" => amount,
        "customer_id" => "#{@customer_id}",
        "transaction_type" => "sale",
        "ach_token" => @ach_token
      }
    end

    def checkout_form_id
      # we don't think this changes, but its less brittle if we fetch it every time
      @form_id_request ||= RestClient.post @form_id_ep, @form_id_params.to_json, { :content_type => "application/json"}.merge(@auth_header)
      return nil unless @form_id_request.code == 200
      @checkout_form_id ||= JSON.parse(@form_id_request.body)['checkout_form_id']
    end

    def session_token
      #this is basically a mutex, if someone else makes this request, mine will no longer work for transactions
      return nil unless checkout_form_id
      url = "#{ENV['REPAY_REST_BASE']}/checkout/merchant/api/v1/checkout-forms/#{checkout_form_id}/paytoken"
      @session_request ||= RestClient.post url, @session_params.to_json, { :content_type => "application/json"}.merge(@auth_header)
      return nil if @session_request.code != 200
      @session_token ||= JSON.parse(@session_request.body)["paytoken"]
    end

    def payment
      return nil unless session_token
      url = "#{ENV['REPAY_REST_BASE']}/checkout/merchant/api/v1/checkout-forms/#{checkout_form_id}/token-payment"
      @ach_request ||= RestClient.post url, payment_params(session_token).to_json, { :content_type => "application/json"}.merge(@auth_header)
      return nil if @ach_request.code != 200
      @payment ||= JSON.parse(@ach_request.body)
    end

    def payment_params(session)
      @payment_params ||= {
        "amount" => @amount, #must be this amount for testing purposes
        "customer_id" => "#{@customer_id}",
        "ach_token" => "#{@ach_token}",
        "transaction_type" => "sale",
        "paytoken" => "#{session}"
      }
    end

  end
end
