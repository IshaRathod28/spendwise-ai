class TransactionCategorizer
  CATEGORIES = {
    "Food & Dining" => ["restaurant", "food", "domino", "pizza", "zomato", "swiggy", "cafe", "coffee", "meal", "lunch", "dinner", "breakfast", "mcdonald", "kfc", "burger", "drink", "cold drink", "beverage", "juice", "soda", "coke", "pepsi", "tea", "snack", "bakery", "sweet", "ice cream", "dessert"],
    "Transportation" => ["uber", "ola", "cab", "taxi", "metro", "bus", "train", "flight", "petrol", "fuel", "parking"],
    "Shopping" => ["amazon", "flipkart", "myntra", "shopping", "mall", "store", "clothes", "fashion"],
    "Groceries" => ["grocery", "vegetables", "fruits", "supermarket", "bigbasket", "blinkit", "instamart", "zepto"],
    "Utilities" => ["electricity", "water", "gas", "internet", "broadband", "mobile", "recharge", "bill"],
    "Entertainment" => ["movie", "cinema", "netflix", "spotify", "prime", "hotstar", "game", "gaming"],
    "Healthcare" => ["doctor", "hospital", "medicine", "pharmacy", "health", "clinic", "medical"],
    "Education" => ["school", "college", "course", "book", "tuition", "fees", "education"],
    "Rent" => ["rent", "flat", "house", "apartment", "society", "maintenance"],
    "Personal Care" => ["salon", "spa", "gym", "fitness", "parlour", "grooming"],
    "Other" => []
  }

  def initialize(extracted_info)
    @extracted_info = extracted_info
    @note = extracted_info["note"] || extracted_info["description"] || ""
    @merchant = extracted_info["merchant"] || extracted_info["payee"] || ""
  end

  def categorize
    # Use AI for intelligent categorization
    category = categorize_with_ai
    
    # Fallback to keyword matching if AI fails
    category = categorize_with_keywords if category.nil? || category.empty?
    
    category || "Other"
  end

  private

  def categorize_with_ai
    return nil unless ENV['OPENAI_API_KEY']
    
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    prompt = <<~PROMPT
      You are an intelligent expense categorization assistant. Categorize this transaction into ONE of these categories: #{CATEGORIES.keys.join(', ')}
      
      Transaction details:
      - Note/Description: #{@note}
      - Merchant/Payee: #{@merchant}
      
      Category Guidelines:
      - "Food & Dining": Any food, drinks, beverages, restaurants, cafes, food delivery, cold drinks, juices, snacks, ice cream, etc.
      - "Transportation": Travel, ride-sharing, public transport, fuel, parking, flights, trains, etc.
      - "Shopping": Online/offline shopping, clothes, electronics, fashion items, etc.
      - "Groceries": Supermarket, vegetables, fruits, household items, groceries, etc.
      - "Utilities": Bills for electricity, water, gas, internet, mobile recharge, etc.
      - "Entertainment": Movies, streaming services, games, leisure activities, etc.
      - "Healthcare": Medical expenses, doctor visits, medicines, pharmacy, etc.
      - "Education": School, college, courses, books, tuition fees, etc.
      - "Rent": House rent, apartment rent, society maintenance, etc.
      - "Personal Care": Salon, spa, gym, fitness, grooming, beauty, etc.
      - "Other": Anything that doesn't fit the above categories
      
      Return ONLY the exact category name from the list above, nothing else.
    PROMPT
    
    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: prompt }
        ],
        max_tokens: 50,
        temperature: 0.3
      }
    )
    
    category = response.dig("choices", 0, "message", "content")&.strip
    
    # Validate category
    CATEGORIES.keys.include?(category) ? category : nil
  rescue => e
    Rails.logger.error "AI categorization failed: #{e.message}"
    nil
  end

  def categorize_with_keywords
    text = "#{@note} #{@merchant}".downcase
    
    # Check for partial matches and word boundaries for better accuracy
    CATEGORIES.each do |category, keywords|
      return category if keywords.any? { |keyword| text.include?(keyword.downcase) }
    end
    
    # Additional smart fallback - if AI fails and no keyword match
    # Try to infer from common patterns
    return "Food & Dining" if text.match?(/\b(eat|ate|drink|drank|lunch|dinner|breakfast|meal|snack)\b/)
    
    "Other"
  end
end
