require 'test_helper'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
end

class RepayTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Repay
  end

  test "aquire ach_token" do
    VCR.use_cassette('repay/vault_token_request_a', :allow_playback_repeats => true) do
      customer_id = "123"
      account_holder = "Jerry Smith"
      account_number = "000090911252122222222"
      routing_number = "061113415"
      zip_code = "30506"
      assert_not_nil(Repay::AchToken.new(customer_id, account_holder, routing_number, account_number, zip_code).ach_token)
    end

  end

  test "aquire ach_token with invalid routing number" do
    VCR.use_cassette('repay/invalid_vault_token_request_a', :allow_playback_repeats => true) do
      customer_id = "123"
      account_holder = "Jerry Smith"
      account_number = "000123099000123540001252"
      routing_number = "xxxxxxxxxxx"
      zip_code = "30506"
      assert_nil(Repay::AchToken.new(customer_id, account_holder, routing_number, account_number, zip_code).ach_token)
    end
  end

  test "use ach_token to make payment" do
    VCR.use_cassette('repay/vault_token_request_b', :allow_playback_repeats => true) do
      @customer_id = "321"
      account_holder = "Jerry Smith"
      account_number = "13510999011003250012122"
      routing_number = "061113415"
      zip_code = "30506"
      @ach_token = Repay::AchToken.new(@customer_id, account_holder, routing_number, account_number, zip_code).ach_token
    end

    @amount = random_amount
    VCR.use_cassette('repay/valid_ach_payment', :allow_playback_repeats => true) do
      r1 = Repay::AchTokenPayment.new(@ach_token, @customer_id, @amount.to_s).payment
      assert_equal(r1["message"],"Approved - DEMO")
    end

    VCR.use_cassette('repay/valid_ach_payment', :allow_playback_repeats => true) do
      r2 = Repay::AchTokenPayment.new(@ach_token, @customer_id, @amount).payment
      assert_equal(r2["message"],"Approved - DEMO")
    end


    VCR.use_cassette('repay/invalid_ach_payment', :allow_playback_repeats => true) do
      r3 = Repay::AchTokenPayment.new(@ach_token, @customer_id, invalid_random_amount).payment
      assert_nil(r3["message"])
      assert_equal(r3["status"], "error")
    end


  end

  def random_amount
    # random even money
    a = rand(9)
    a % 2 == 0 ? a : a += 1
    b = rand(9)
    b % 2 == 0 ? b : b += 1
    c = rand(9)
    c % 2 == 0 ? c : c += 1
    return Money.new("#{a}#{b}#{c}".to_i)
  end

  def invalid_random_amount
    # random odd money
    a = rand(9)
    a % 2 == 0 ? a+=1 : a
    b = rand(9)
    b % 2 == 0 ? b += 1 : b
    c = rand(9)
    c % 2 == 0 ? c += 1 : c
    return Money.new("#{a}#{b}#{c}".to_i)
  end

end
