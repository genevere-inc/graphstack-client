# Graphstack Client

Ruby client for Graphstack messaging API.

## Installation

Add to your Gemfile:

```ruby
gem "graphstack-client", git: "https://github.com/genevere-inc/graphstack-client.git"
```

## Configuration

```ruby
Graphstack.configure do |config|
  config.api_key = ENV["GRAPHSTACK_API_KEY"]
  config.base_url = ENV["GRAPHSTACK_BASE_URL"]
  config.webhook_secret = ENV["GRAPHSTACK_WEBHOOK_SECRET"]
end
```

## Usage

### Send RCS Message

```ruby
# To new conversation
Graphstack.client.personagraph.rcs.send_message(
  to: ["+15551234567"],
  content: "Hello!"
)

# To existing conversation
Graphstack.client.personagraph.rcs.send_message(
  conversation_id: "uuid",
  content: "Follow up!"
)
```

### Typing Indicators

```ruby
Graphstack.client.personagraph.rcs.start_typing(conversation_id)
Graphstack.client.personagraph.rcs.stop_typing(conversation_id)
```

### Reactions

```ruby
Graphstack.client.personagraph.rcs.react(message_id, reaction: "love")
```

### Contact Card

```ruby
Graphstack.client.personagraph.rcs.share_contact(conversation_id)
```

### Fetch Messages

```ruby
result = Graphstack.client.personagraph.rcs.get_messages(conversation_id, limit: 20)
messages = result[:messages]
```

### Memos (Hosted Markdown)

```ruby
result = Graphstack.client.personagraph.memos.create(
  content: "# Hello\n\nThis is markdown",
  title: "My Document",
  conversation_id: conversation_id
)
url = result[:url]
```

### Webhook Verification

```ruby
event = Graphstack::Webhook.verify_and_parse!(
  payload: request.raw_post,
  headers: {
    "svix-id" => request.headers["svix-id"],
    "svix-timestamp" => request.headers["svix-timestamp"],
    "svix-signature" => request.headers["svix-signature"]
  },
  secret: ENV["WEBHOOK_SECRET"]
)

if event.type == "message.created" && event.user_message?
  # Process user message
  conversation_id = event.conversation_id
  content = event.content
end
```

## License

MIT
