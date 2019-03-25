require 'base64'
require 'json'
require 'net/https'

IMAGE_FILE = './gx.jpg'

API_KEY = 'APIKEY'
API_URL = "https://vision.googleapis.com/v1/images:annotate?key=#{API_KEY}"

# 画像をbase64にエンコード
base64_image = Base64.strict_encode64(File.new(IMAGE_FILE, 'rb').read)

# APIリクエスト用のJSONパラメータの組み立て
body = {
  requests: [{
    image: {
      content: base64_image
    },
    features: [
      {
        type: 'DOCUMENT_TEXT_DETECTION',
        #maxResults: 5
      }
    ]
  }]
}.to_json

# Google Cloud Vision APIにリクエスト投げる
uri = URI.parse(API_URL)
https = Net::HTTP.new(uri.host, uri.port)
https.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri)
request["Content-Type"] = "application/json"
response = https.request(request, body)
data=JSON.parse(response.body)
# APIレスポンス出力
description=data["responses"][0]["textAnnotations"][0]["description"]
File.open("response.txt","w") do |text|
    text.puts(description)
end