require 'base64'
require 'json'
require 'net/https'
require 'inifile'

setting=IniFile.load("./setting.ini")
IMAGE_FILE = setting['IMAGE']['PATH']
API_KEY = setting['API']['KEY']
TYPE=setting['GET_INFOMATION']['TYPE']
p TYPE
API_URL = "https://vision.googleapis.com/v1/images:annotate?key=#{API_KEY}"

def create_request()
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
          type: TYPE,
        }
      ]
    }]
  }.to_json
  return body
end
body=create_request()
def send_request(body)
  # Google Cloud Vision APIにリクエスト投げる
  uri = URI.parse(API_URL)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request["Content-Type"] = "application/json"
  response = https.request(request, body)
  return response
end
response=send_request(body)
data=JSON.parse(response.body)
# APIレスポンス出力
description=data["responses"][0]["textAnnotations"]

def file_write(description)
  File.open("response.txt","w") do |text|
    text.puts(description)
  end
end
file_write(description)