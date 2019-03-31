require 'base64'
require 'json'
require 'net/https'
require 'inifile'

setting=IniFile.load("./setting.ini")
IMAGE_FILE = setting['IMG']['PATH']
API_KEY = setting['API']['KEY']
TYPE=setting['GET_INFOMATION']['TYPE']
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

def get_name(description)
  for num in 1..description.length-1 do
    if(description[num]["description"]=="たね" && description[num+1]["description"]=="。") then
      return description[num+2]["description"]
      break
    elsif (description[num]["description"].include?("1進化") || description[num]["description"].include?("2進化")) then
      return description[num]["description"].slice(3,(description[num]["description"].length-1))
      break
    elsif (description[num]["description"].include?("進化")) then
      return description[num]["description"].slice(2,(description[num]["description"].length-1))
      break
    end
  end
end
name=get_name(description)
def serch_attribute(description)
  description.each do |line|
    if line["description"].include?("\n")==false then
      content=line["description"]
      if content.include?("ポケモン") then
        return content.split("ポケモン",2)[0]
        break
      end
    end
  end
  return "404"
end
attribute=serch_attribute(description)

def get_cardinfo(description)
  leng=description.length
  card_info=[]
  for num in 0..leng-1 do
    content=description[num]["description"]
    if content.include?("/") then
      if description[num-1]["description"].include?("sm") ||description[num-1]["description"].include?("SM") then
        len=description[num-1]["description"].length
        card_info.push(description[num-1]["description"].slice(0..4))
        card_info.push(description[num-1]["description"].slice(len-1,3))
        card_info.push(description[num+1]["description"].slice(0..2))
        return card_info
        break
      end
    end
  end
  return "404"
end
info=get_cardinfo(description)
if info!="404" then
  info.push(attribute)
  info.push(name)
end
p info
def file_write(payload)
  File.open("response.txt","w") do |text|
    text.puts(payload)
  end
end
file_write(info)