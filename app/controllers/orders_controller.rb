require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'dotenv'

Dotenv.load


class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]

  # POST /orders or /orders.json
  def create
    access_token = get_paypal_access_token
    amount = order_params[:amount]
    currency = order_params[:currency]
    paypal_order = create_paypal_order(access_token, amount, currency)

    @order = Order.new(paypal_order_id: paypal_order["id"], amount: amount, currency: currency, status: paypal_order["status"])

    respond_to do |format|
      if @order.save
        format.json { render json: @order, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /orders/1/capture
  def capture
    paypalOrderId = params[:id]
    
    res = capture_payment(paypalOrderId)

    puts res

    @order = Order.find_by(paypal_order_id: paypalOrderId)
    @order.update(status: res["status"])

    puts "bla"
    respond_to format.json { render json: @order, status: :created }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.require(:order).permit(:amount, :currency)
    end

    def get_paypal_access_token
      uri = URI("https://api.sandbox.paypal.com/v1/oauth2/token")
      request = Net::HTTP::Post.new(uri)
      
      credentials = "#{ENV['CLIENT_ID']}:#{ENV['CLIENT_SECRET']}"
      puts "credentials: #{credentials}"
      encoded_credentials = Base64.strict_encode64(credentials)

      puts "encoded_credentials: #{encoded_credentials}"

      # Set header for basic authentication
      request.add_field('Authorization', "Basic #{encoded_credentials}")
      request.set_form_data('grant_type' => 'client_credentials')
    
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    
      if response.is_a?(Net::HTTPSuccess)
        body = JSON.parse(response.body)
        body["access_token"]
      else
        raise "Error obtaining access token: #{response.body}"
      end
    end

    def create_paypal_order(access_token, amount, currency)
      uri = URI("https://api.sandbox.paypal.com/v2/checkout/orders")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
        intent: "CAPTURE",
        purchase_units: [
          {
            amount: {
              currency_code: currency,
              value: amount
            }
          }
        ],
        application_context: {
          return_url: "localhost:3000/order/success",
          cancel_url: "localhost:3000/order/cancel"
        }
      })
    
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        raise "Error creating order: #{response.body}"
      end
    end

    def capture_payment(order_id)
      access_token = get_paypal_access_token
      uri = URI("https://api.sandbox.paypal.com/v2/checkout/orders/#{order_id}/capture")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({})

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        raise "Error creating order: #{response.body}"
      end
    end
end
