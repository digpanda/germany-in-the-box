json.array!(@messages) do |message|
  json.extract! message, :id, :content, :sender, :receiver, :sender_name, :sender_imgurl, :created_at
  json.url message_url(message, format: :json)
end
