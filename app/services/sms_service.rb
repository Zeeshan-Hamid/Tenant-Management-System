# frozen_string_literal: true

require "uri"
require "json"
require "openssl"
require "net/http"

class SmsService
  # ZONG_API_URL should point to something like:
  # "https://cbs.zong.com.pk/reachrestapi/home/SendQuickSMS"
  ZONG_API_URL = ENV["ZONG_API_URL"]

  def self.send_payment_confirmation(phone_number, amount)
    formatted_phone = format_phone_number(phone_number)
    message = "Your rent payment of #{amount} has been confirmed. Thank you!"

    url = URI.parse(ZONG_API_URL)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true if url.scheme == "https"
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    # request['Cookie'] = 'BIGipServer~Project_6464807550b74e93989844d13ed8caaa~CBS-443=rd6o00000000000000000000ffffac15a663o443; TS01fbfa4b=01f7c6c54d8dadee565cb96f4882ed3ce2046bebb7ded43dec53f0b30f8b05f18c97ec46b99adb72b39011eaeb235486ea3490c35841cec193d110209ea50a974812a5a4b8'

    payload = {
      "loginId" => ENV["ZONG_LOGIN_ID"],
      "loginPassword" => ENV["SMS_SERVICE_PASSWORD"],
      "Destination" => formatted_phone,
      "Mask" => ENV["ZONG_SENDER_ID"] || "",
      "Message" => message,
      "UniCode" => "0",
      "ShortCodePrefered" => "n"
    }

    request.body = JSON.dump(payload)

    response = https.request(request)

    if response.code == "200"
      true
    else
      Rails.logger.error "Failed to send SMS: #{response.body}"
      false
    end
  rescue StandardError => e
    Rails.logger.error "SMS Service Error: #{e.message}"
    false
  end

  def self.format_phone_number(phone)
    # Convert to Zong's required format (e.g., "923xxxxxxxxx")
    number = phone.gsub(/\D/, "")
    number.start_with?("0") ? "92#{number[1..]}" : number
  end
end
