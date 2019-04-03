require 'base64'
require 'json'
require 'net/https'
require 'inifile'

#ファイルを読み込む処理
setting=IniFile.load("./setting.ini")
#APIキーをINIファイル内のAPI-KEYの情報から取得
API_KEY = setting['API']['KEY']
#画像から認識する方式をiniファイル内のGET_INFOMATION-TYPEから取得
TYPE=setting['GET_INFOMATION']['TYPE']
#読み込んだ情報をもとに実際のリクエストのURLを作成
API_URL = "https://vision.googleapis.com/v1/images:annotate?key=#{API_KEY}"

IMG=ARGV[0]
def create_request()
  # 画像をbase64にエンコード
  base64_image = Base64.strict_encode64(File.new(IMG, 'rb').read)

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
def file_write(payload,filename)
  File.open(filename,"w") do |text|
    text.puts(payload)
  end
end
file_write(description,"dump.txt")

# 取得した情報からポケモンの名称を取得
def get_name(description)
  # 取得されたテキストデータそれぞれについて処理を実行(0にあるサマリーを除く)
  for num in 1..description.length-1 do
    # 対象のテキストデータが"たね"でかつ、次のテキストデータが"。"である時
    if(description[num]["description"]=="たね" && description[num+1]["description"]=="。") then
      # さらに次のテキストデータにあるポケモンの名称を返す
      return description[num+2]["description"]
      break
    # 対象のテキストデータが"1進化"もしくは"2進化"を含む時
    elsif (description[num]["description"].include?("1進化") || description[num]["description"].include?("2進化")) then
      #対象のデータの後半にポケモンの名称が含まれるため、4文字目以降の名称を返す
      return description[num]["description"].slice(3,(description[num]["description"].length-1))
      break
    # 対象のテキストデータが"進化"を含む時
    elsif (description[num]["description"].include?("進化")) then
      # 対象データの3文字目以降にポケモンの名称が含まれるため、3文字目以降の名称を返す
      return description[num]["description"].slice(2,(description[num]["description"].length-1))
      break
    end
  end
  return "404"
end
name=get_name(description)

# 取得した情報から、ポケモンの属性を取得
def serch_attribute(description)
  #情報それぞれについて確認を実行
  description.each do |line|
    # 情報が"\n"を含まないデータに対して実行
    if line["description"].include?("\n")==false then
      # 対象のデータをcontentに格納
      content=line["description"]
      # 対象のデータが"ポケモン"を含む時
      if content.include?("ポケモン") then
        # "ポケモン"の前に含まれる文字列を返す
        return content.split("ポケモン",2)[0]
        break
      end
    end
  end
  return "404"
end
attribute=serch_attribute(description)


# カードの詳細情報を取得
def get_cardinfo(description)
  # 配列の要素数を取得
  leng=description.length
  # 結果を格納する配列を生成
  card_info=[]
  # もとデータ全ての情報に対して実行
  for num in 0..leng-1 do
    # contentにテキストデータを格納
    content=description[num]["description"]
    #テキストデータが"/"を含む時
    if content.include?("/") then
      # サン・ムーンシリーズであることを示す"SM","sm"が含まれる文字列の時
      if description[num-1]["description"].include?("sm") ||description[num-1]["description"].include?("SM") then
        # 対象の文字列の長さを取得
        len=description[num-1]["description"].length
        # SMシリーズの番号を結果の配列に追加
        card_info.push(description[num-1]["description"].slice(0..4))
        # シリーズの中のカードの番号を取得
        card_info.push(description[num-1]["description"].slice(len-1,3))
        # シリーズのカードの全体の番号を取得
        card_info.push(description[num+1]["description"].slice(0..2))
        return card_info
        break
      end
    end
  end
  return "404"
end
info=get_cardinfo(description)
#ファイル書き出しし処理ファイル書き出し処理
def file_write(payload)
  # ファイル名をポケモンの名称にする
  filename=payload[4]+".txt"
  File.open(filename,"w") do |text|
    text.puts(payload)
  end
end
# カード情報が取得できたらその他の属性情報等を追加
if info!="404" then
  info.push(attribute)
  info.push(name)
  #ファイル書き出し処理
  file_write(info)
end


