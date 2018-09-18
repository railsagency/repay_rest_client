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
    VCR.use_cassette('repay/form_id_request', :allow_playback_repeats => true) do
      VCR.use_cassette('repay/paytoken_request', :allow_playback_repeats => true) do
        VCR.use_cassette('repay/vault_token_request', :allow_playback_repeats => true) do
          customer_id = "123"
          account_holder = "Jerry Smith"
          account_number = "00000005509214111112"
          routing_number = "121202221"
          assert_not_nil(Repay::AchToken.new(customer_id, account_holder, routing_number, account_number).ach_token)
        end
      end
    end

  end

  test "aquire ach_token with invalid routing number" do
    VCR.use_cassette('repay/form_id_request', :allow_playback_repeats => true) do
      VCR.use_cassette('repay/paytoken_request', :allow_playback_repeats => true) do
        VCR.use_cassette('repay/vault_token_request', :allow_playback_repeats => true) do
          customer_id = "123"
          account_holder = "Jerry Smith"
          account_number = "00000005509214111112"
          routing_number = "xxxxxxxxxxx"
          assert_nil(Repay::AchToken.new(customer_id, account_holder, routing_number, account_number).ach_token)
        end
      end
    end

  end

  test "use ach_token to make payment" do
    VCR.use_cassette('repay/second_form_id_request', :allow_playback_repeats => true) do
      VCR.use_cassette('repay/second_paytoken_request', :allow_playback_repeats => true) do
        VCR.use_cassette('repay/second_vault_token_request', :allow_playback_repeats => true) do
          @customer_id = "123"
          account_holder = "Jerry Smith"
          account_number = "000000666666012841812"
          routing_number = "121202221"
          @ach_token = Repay::AchToken.new(@customer_id, account_holder, routing_number, account_number).ach_token
        end
      end
    end
    VCR.use_cassette('repay/ach_payment_form_id_request', :allow_playback_repeats => true) do
      VCR.use_cassette('repay/ach_payment_paytoken_request', :allow_playback_repeats => true) do
        VCR.use_cassette('repay/ach_payment', :allow_playback_repeats => true) do
          amount = random_amount
          r = Repay::AchTokenPayment.new(@ach_token, @customer_id, amount).payment
          assert_equal(r["message"],"Approved - DEMO")
        end
      end
    end
  end

  def random_amount
    a = rand(9)
    a % 2 == 0 ? a : a += 1
    b = rand(9)
    b % 2 == 0 ? b : b += 1
    c = rand(9)
    c % 2 == 0 ? c : c += 1
    return "#{a}.#{b}#{c}"
  end
end
