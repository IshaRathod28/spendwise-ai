class PaymentImageExtractor
  def initialize(image_file)
    @image_file = image_file
  end

  def extract_payment_info
    # Convert image to base64 for OpenAI Vision API
    image_data = encode_image(@image_file)
    
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "This is a payment screenshot from GPay, Paytm, PhonePe, or similar payment app. Extract the following information and return as JSON: amount (numeric value only), note/description (payment purpose/note), merchant/payee name, date if visible. If any field is not found, set it to null. Return only valid JSON without markdown formatting."
              },
              {
                type: "image_url",
                image_url: {
                  url: "data:image/jpeg;base64,#{image_data}"
                }
              }
            ]
          }
        ],
        max_tokens: 500
      }
    )
    
    # Parse the response
    content = response.dig("choices", 0, "message", "content")
    parse_response(content)
  rescue => e
    Rails.logger.error "Error extracting payment info: #{e.message}"
    { error: e.message }
  end

  private

  def encode_image(image_file)
    # Handle both file path and uploaded file object
    if image_file.respond_to?(:read)
      Base64.strict_encode64(image_file.read)
    else
      Base64.strict_encode64(File.read(image_file))
    end
  end

  def parse_response(content)
    # Remove markdown code blocks if present
    json_content = content.gsub(/```json\n?/, '').gsub(/```\n?/, '').strip
    JSON.parse(json_content)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse OpenAI response: #{content}"
    { error: "Failed to parse response", raw_content: content }
  end
end
