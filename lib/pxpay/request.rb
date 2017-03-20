module Pxpay
  # The request object to send to Payment Express
  class Request
    require 'pxpay/error'
    require 'rest_client'
    require 'nokogiri'
    require 'builder'


    attr_accessor :post

    def initialize(id, price, options = {})
      @post = build_xml(id, price, options)
    end

    def px_pay_url

      response = ::RestClient.post(Pxpay::Base.pxpay_request_url, post)
      response_text = ::Nokogiri::XML(response)

      if response_text.at_css('Request').attributes['valid'].value == '1'
        url = response_text.at_css('URI')
      else
        if Pxpay::Base.pxpay_user_id && Pxpay::Base.pxpay_key
          Rails.logger.error('Error response pxpay  request.rb - ' + response_text.at_css('Request').inner_html.inspect)
          raise Pxpay::Error, response_text.at_css('Request').inner_html
        else
          raise Pxpay::MissingKey, 'Your Pxpay config is not set up properly, run rails generate pxpay:install'
        end
      end

      return URI::extract(url.children.first.text).first.gsub('&amp;', '&')
    end

    private

    def build_xml(id, price, options)

      xml = ::Builder::XmlMarkup.new
      xml.GenerateRequest do
        xml.PxPayUserId ::Pxpay::Base.pxpay_user_id
        xml.PxPayKey ::Pxpay::Base.pxpay_key
        xml.AmountInput sprintf('%.2f', price)
        xml.TxnType options[:txn_type] ? options[:txn_type].to_s.capitalize : 'Purchase'
        xml.CurrencyInput 'NZD'
        xml.MerchantReference id.to_s
        xml.UrlSuccess options[:url_success] || ::Pxpay::Base.url_success
        xml.UrlFail options[:url_failure] || ::Pxpay::Base.url_failure
        xml.EmailAddress options[:email_address] if options[:email_address]
      end
    end
  end
end
