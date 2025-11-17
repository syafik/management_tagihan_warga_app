class TripayCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def callback
    # Get callback data
    callback_signature = request.headers['X-Callback-Signature']
    json_payload = request.raw_post

    # Parse callback params
    merchant_ref = params[:merchant_ref]
    status = params[:status]

    # Log incoming callback
    Rails.logger.info "Tripay callback received - Merchant Ref: #{merchant_ref}, Status: #{status}"
    Rails.logger.debug "Callback signature: #{callback_signature}"
    Rails.logger.debug "Raw payload: #{json_payload}"

    # Verify signature
    tripay_service = TripayService.new
    unless tripay_service.verify_callback_signature(callback_signature, json_payload)
      Rails.logger.warn "Invalid Tripay callback signature for reference: #{merchant_ref}"
      Rails.logger.debug "Expected signature calculation based on payload"
      render json: { success: false, message: 'Invalid signature' }, status: :unauthorized
      return
    end

    # Find payment
    payment = Payment.find_by(reference: merchant_ref)
    unless payment
      Rails.logger.error "Payment not found for reference: #{merchant_ref}"
      render json: { success: false, message: 'Payment not found' }, status: :not_found
      return
    end

    # Update payment based on status
    case status
    when 'PAID'
      handle_paid_callback(payment, params)
    when 'EXPIRED'
      payment.mark_as_expired!
      Rails.logger.info "Payment expired: #{merchant_ref}"
    when 'FAILED'
      payment.mark_as_failed!
      Rails.logger.info "Payment failed: #{merchant_ref}"
    when 'REFUND'
      payment.update!(status: 'REFUND')
      Rails.logger.info "Payment refunded: #{merchant_ref}"
    end

    render json: { success: true }
  rescue => e
    Rails.logger.error "Tripay callback error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, message: 'Internal error' }, status: :internal_server_error
  end

  private

  def handle_paid_callback(payment, callback_params)
    # Use transaction with pessimistic lock to prevent race condition with show action
    Payment.transaction do
      # Lock the payment record to prevent concurrent processing
      payment = Payment.lock.find(payment.id)

      return if payment.paid? # Already processed

      # Mark payment as paid
      paid_at = callback_params[:paid_at] ? Time.at(callback_params[:paid_at]) : Time.current
      payment.mark_as_paid!(paid_at)

      # Update tripay_response with full callback data
      payment.update!(
        tripay_response: payment.tripay_response.merge(
          'callback_received' => callback_params.to_unsafe_h,
          'callback_received_at' => Time.current.to_s
        )
      )
    end

    # Process the payment success using shared method from PaymentsController
    # This ensures we don't have duplicate code and avoid double processing
    # Note: process_payment_success has its own transaction and locking mechanism
    payments_controller = PaymentsController.new
    payments_controller.send(:process_payment_success, payment)

    Rails.logger.info "Payment callback processed: #{payment.reference}"
  end
end
