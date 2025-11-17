# API controller for transactions - inherits from ApiController for JSON responses
class Api::V1::TransactionsController < ApiController
  # Skip CSRF verification for API endpoints (using JSON)
  skip_before_action :verify_authenticity_token, raise: false
  
  # GET /api/v1/transactions
  # Returns all transactions with optional pagination
  # Query params:
  #   - page: Page number (default: 1)
  #   - per_page: Items per page (default: 50, max: 100)
  def index
    # Get pagination parameters with defaults
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i
    per_page = 50 if per_page <= 0 || per_page > 100
    
    # Calculate offset for pagination
    offset = (page - 1) * per_page
    
    # Get total count for metadata
    total_count = Transaction.count
    total_pages = (total_count.to_f / per_page).ceil
    
    # Fetch transactions with pagination and order by newest first
    transactions = Transaction.order(created_at: :desc)
                             .limit(per_page)
                             .offset(offset)
                             .map do |transaction|
      transaction.as_json.merge(
        payment_screenshot_url: transaction.payment_screenshot.attached? ? 
          rails_blob_url(transaction.payment_screenshot) : nil
      )
    end
    
    # Return transactions with metadata for Flutter
    render json: {
      transactions: transactions,
      meta: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages,
        has_more: page < total_pages
      }
    }
  end

  def create
    note = params[:note]
    amount = params[:amount]
    merchant = params[:merchant]

    # Use AI categorizer for automatic categorization
    extracted_info = {
      "note" => note,
      "description" => note,
      "merchant" => merchant,
      "payee" => merchant
    }
    
    categorizer = TransactionCategorizer.new(extracted_info)
    category = categorizer.categorize

    transaction = Transaction.create(
      note: note,
      amount: amount,
      merchant: merchant,
      category: category
    )

    render json: transaction, status: :created
  end

  # New endpoint: Upload payment screenshot and auto-create transaction
  def create_from_image
    unless params[:image].present?
      return render json: { error: "No image provided" }, status: :unprocessable_entity
    end

    begin
      # Extract payment information from image using AI Vision
      extractor = PaymentImageExtractor.new(params[:image])
      extracted_info = extractor.extract_payment_info

      if extracted_info[:error]
        return render json: { 
          error: "Failed to extract payment info", 
          details: extracted_info[:error] 
        }, status: :unprocessable_entity
      end

      # Categorize the transaction using AI
      categorizer = TransactionCategorizer.new(extracted_info)
      category = categorizer.categorize

      # Create transaction
      transaction = Transaction.new(
        amount: extracted_info["amount"],
        note: build_note(extracted_info),
        category: category
      )

      # Attach the screenshot
      transaction.payment_screenshot.attach(params[:image])

      if transaction.save
        render json: {
          transaction: transaction.as_json.merge(
            payment_screenshot_url: rails_blob_url(transaction.payment_screenshot)
          ),
          extracted_info: extracted_info,
          message: "Transaction created successfully from payment screenshot"
        }, status: :created
      else
        render json: { error: transaction.errors.full_messages }, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Error processing payment image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { 
        error: "Failed to process payment image", 
        details: e.message 
      }, status: :internal_server_error
    end
  end

  # DELETE /api/v1/transactions/:id
  # Deletes a specific transaction by ID
  def destroy
    # Find the transaction by ID
    transaction = Transaction.find_by(id: params[:id])
    
    # If transaction not found, return error
    if transaction.nil?
      render json: { error: "Transaction not found" }, status: :not_found
      return
    end
    
    # Delete the transaction
    if transaction.destroy
      # Return success message
      render json: { message: "Transaction deleted successfully" }, status: :ok
    else
      # Return error if deletion failed
      render json: { error: "Failed to delete transaction" }, status: :unprocessable_entity
    end
  end

  private

  def categorize_note(note)
    return "Food" if note.to_s.downcase.include?("domino") || note.to_s.downcase.include?("zomato") || note.to_s.downcase.include?("swiggy")
    return "Travel" if note.to_s.downcase.include?("uber") || note.to_s.downcase.include?("ola") || note.to_s.downcase.include?("flight")
    return "Rent" if note.to_s.downcase.include?("rent") || note.to_s.downcase.include?("flat")
    "Other"
  end

  def build_note(extracted_info)
    parts = []
    parts << extracted_info["note"] if extracted_info["note"].present?
    parts << "to #{extracted_info['merchant']}" if extracted_info["merchant"].present?
    parts << "on #{extracted_info['date']}" if extracted_info["date"].present?
    
    parts.any? ? parts.join(" ") : "Payment"
  end
end
