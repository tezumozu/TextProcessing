def makeCommancList()
    result = []

    #正規表現の定義

    result[0] = /^(s|t[stn]|n)(.*)/ #impを表す正規表現
    cmdMap = {}#impをキーとし、操作を表現する正規表現,またその操作を表すProcを要素としてもつリスト

    stacNeedParameters = {}#パラメーターが必要かどうか
    stacNeedParameters["s"] = true #nil == falseとされるので必要なものだけ
    cmdMap["s"] = [/^(s|n[stn])(.*)/ ,stacNeedParameters]#スタック

    dontNeedParameters = {}#便宜上？とりあえず便利なので空の連想配列
    #使いまわして節約
    cmdMap["ts"] = [/^(s[stn]|t[st])(.*)/ ,dontNeedParameters]#演算処理

    cmdMap["tt"] = [/^(s|t)(.*)/ ,dontNeedParameters]#ヒープ
    

    flowNeedParameters = {}
    flowNeedParameters["ss"] = true
    flowNeedParameters["st"] = true
    flowNeedParameters["sn"] = true
    flowNeedParameters["ts"] = true
    flowNeedParameters["tt"] = true
    cmdMap["n"] = [/^(s[stn]|t[stn]|nn)(.*)/ ,flowNeedParameters]#Flow

    #節約
    cmdMap["tn"] = [/^(s[st]|t[st])(.*)/ ,dontNeedParameters]#IO

    result[1] = cmdMap

    return result
end



def strToBinary(str)#文字列を2真数に変換する
    #commandListうち、\s = 0 , \t = 1
    result = ""
    count = 0
    str.chars.each {|data| #単純に文字列を01に変
        count += 1
        if data == "s" then
            result += "0"
        elsif data == "t" then
            result += "1"
        elsif str.length != count then #最後の文字以外でnがきたらエラー(デバッグ用)
            raise "エラー"
        end
    }

    return result
end



class StackAndHeapEditer #後に使うので
    @@stac = []
    @@hiep = {}
    @@programCounter = 0
    @@cmdMap = {}
    @@endFlag = false
    @@callPoint = [];#呼び出し元を記録するためのスタック
    @@orders = []

    def self.run(orders)
        @@orders = orders

        @@cmdMap["s"] = Stac.new#スタック
        @@cmdMap["tt"] = Heap.new#ヒープ
        @@cmdMap["ts"] = Arithmetic.new#演算処理
        @@cmdMap["n"] = Flow.new#Flow
        @@cmdMap["tn"] = StacIo.new#IO

        while !@@endFlag
            order = @@orders[@@programCounter]
            
            #print @@programCounter.to_s + "\t"
            #p order
            #p @@stac
            #p @@hiep
            
            if order[2].nil?
                @@cmdMap[order[0]].send(order[1])
            else
                @@cmdMap[order[0]].send(order[1],order[2])
            end
            
            @@programCounter += 1

            if @@programCounter >= @@orders.length then
                if  @@callPoint.length != 0 then
                    @@programCounter = @@callPoint.pop()+1
                else
                    @@endFlag = true
                end
            end
            #p @@stac
            #p @@hiep
            #print "\n"
        end
        
    end


    def charToBinary(char)#ネーミングセンスの敗北
        num = char[0].ord
        return numToBinaly(num)
    end

    def numToBinaly(num)
        code = "0"
        if num < 0 then
            code = "1"
            num = num* -1
        end
        str = code + num.to_s(2)

        return str
    end

    def binalyToNum(binaly)
        code = 1
        if binaly[0] == "1" then
            code = -1
        end

        num = binaly[1..binaly.length-1].to_i(2)*code

        return num
    end

    def binalyToString(binaly)
        num = binalyToNum(binaly)
        return num.chr
    end
end


class Stac < StackAndHeapEditer
    def s (parameter)#プッシュ parameterあり
        
        @@stac.push( parameter )
    end


    def ts (parameter)#n版目をコピー parameterあり
        data = @@stac[ @@stac.length - binalyToNum(parameter) ] 
        @@stac.push(data) 
    end


    def ns ()#一番上を複製
        data = @@stac[ @@stac.length - 1 ] 
        @@stac.push(data)
    end

    def nt ()#1,2を入れ替える
        data1 = @@stac.pop()
        data2 = @@stac.pop()
        @@stac.push(data1)
        @@stac.push(data2)
    end


    def nn ()#一番上を捨てる(ポップ)
        @@stac.pop()
    end
end



class Heap < StackAndHeapEditer
    def s ()#ストア
        data = @@stac.pop()
        index = @@stac.pop()
        @@hiep[index.to_s] = data
    end

    
    def t ()#ゲット
        index = @@stac.pop()
        data = @@hiep[index]
        @@stac.push(data)
    end
end



class Arithmetic < StackAndHeapEditer
    def ss () #加算
        data2 = @@stac.pop()
        data1 = @@stac.pop()

        sum = binalyToNum(data1) + binalyToNum(data2)

        @@stac.push( numToBinaly(sum) )
    end

    
    def st () #減算
        data2 = @@stac.pop()
        data1 = @@stac.pop()

        sum = binalyToNum(data1) - binalyToNum(data2)

        @@stac.push( numToBinaly(sum) )
    end


    def sn() #掛け算
        data2 = @@stac.pop()
        data1 = @@stac.pop()

        sum = binalyToNum(data1) * binalyToNum(data2)

        @@stac.push( numToBinaly(sum) )
    end


    def tt () #剰余算
        data2 = @@stac.pop()
        data1 = @@stac.pop()

        sum = binalyToNum(data1) % binalyToNum(data2)

        @@stac.push( numToBinaly(sum) )
    end


    def ts ()#割り算
        data2 = @@stac.pop()
        data1 = @@stac.pop()
        p binalyToNum(data1)
        p binalyToNum(data2)
        
        sum = binalyToNum(data1) / binalyToNum(data2)

        p sum

        @@stac.push( numToBinaly(sum) )
    end
end



class Flow < StackAndHeapEditer
    @@labels = {}
    def ss (parameter)#パラメータあり ラベルをセット
        @@labels[parameter] = @@programCounter
    end

    
    def st (parameter)#パラメータあり ラベルのある部分からサブルーチンとして実行
        @@callPoint.push(@@programCounter)
        sn(parameter)
    end


    def sn(parameter)#パラメータあり プログラムカウンタをラベルのある場所へ
        @@programCounter = @@labels[parameter]
        if @@programCounter.nil? then
            for i in 0..@@orders.length-1 do #正しいコードなら一回しか回らないはず
                if @@orders[i][1] == "ss" && @@orders[i][0] == "n" then#見つかったら
                    @@labels[@@orders[i][2]] = i
                end
            end
        else
            return #見つかったらリターン
        end

        @@programCounter = @@labels[parameter]
        if @@programCounter.nil? then
            #ここに来るということは見つからなかった
            raise "undifined Label \nin programCount:\t" + @@programCounter.to_s
            return
        end
    end


    def ts (parameter)#パラメータあり もしスタックの先頭が0ならラベルにジャンプ
        if binalyToNum(@@stac.pop()) == 0 then
            sn(parameter)#ジャンプ命令を実行
        end
    end


    def tt (parameter)#パラメータあり もしスタックの先頭が負の数ならならラベルにジャンプ
        if binalyToNum(@@stac.pop()) < 0 then
            sn(parameter)#ジャンプ命令を実行
        end
    end

    
    def tn () #パラメータあり サブルーチンを終了し、元の場所へ
        @@programCounter = @@callPoint.pop()
    end


    def nn ()#パラメータあり プログラムの終了
        @@endFlag = true
    end
end



class StacIo < StackAndHeapEditer
    @@inputStr =[]
    def ss () #文字列
        data = @@stac.pop()
        data = binalyToString(data)

        print data
    end

    
    def st () #数字
        print binalyToNum(@@stac.pop())
    end


    def tt ()#数値
        index = @@stac.pop()
        num = STDIN.gets.to_i #入力受け取り

        str = numToBinaly(num)
        @@hiep[index] = str
    end

    def ts ()# 文字列
        index = @@stac.pop()
        if @@inputStr.length == 0 then
            text = STDIN.gets #入力受け取り
            @@inputStr = text.chars.reverse
        end

        @@hiep[index] = charToBinary(@@inputStr.pop())
    end
end



#whitespaceを表すクラス
class Whitespace
    @@commandStr = [" ","\t","\n"] #使用する文字列　0から 0 = \s , 1 = \t , 2 = \n の役割　字句解析で使用

    def self.compile(file)
        @@commandList = makeCommancList()#構文解析で使用
        
        #字句解析
        fileStr = self.lexiAnalysis(file)
        #構文解析

        begin
            orders = self.parsting(fileStr) 
        rescue => e
            p e
        end
        #p orders #今回はここまで
        #実行
        begin
            StackAndHeapEditer.run(orders)
        rescue => e
            p e
        end
    end
    
    def self.lexiAnalysis(file) #ファイルから意味のある文字列のみのデータに変換、s・t・nに置換(字句解析)
        result = ""

        #正規表現の生成
        regexp = Regexp.compile("("+@@commandStr[0]+"|"+ @@commandStr[1] +"|"+ @@commandStr[2]+")")

        file.each {|line|
            dataList = line.scan(regexp)
            if dataList.nil? then
                next
            end

            dataList.each {|data| #扱いやすい文字に変換
                if data[0] == @@commandStr[0] then
                    result += "s"
                elsif data[0] == @@commandStr[1] then
                    result += "t"
                elsif data[0] == @@commandStr[2] then
                    result += "n"
                end
            }
        } 
        return result
    end

    def self.parsting(str) #文字列から構文構造にまとめるimp,コマンド,(パラメータ)を1のレコードとした２次元配列を返す
        #先頭から検索
        result = [] #二次元配列 (後になる)

        while str.length > 0 do #文字列がなくなるまで
            recoad = [] # 0 = imp 1 = cmd 2 = parameter

            @@commandList[0] =~ str #impとそれ以降に区切る
            recoad[0] = $1 #imp
            str = $2 #残り

            if recoad[0].nil? then#impがない
                raise "no imp"
            end
            
            @@commandList[1] [recoad[0]] [0] =~ str#cmdとそれ以降に区切る
            recoad[1] = $1 #cmd
            

            if recoad[1].nil? then #cmdがない
                raise "no command"
            end

            str = $2 #残り

            if @@commandList[1] [recoad[0]] [1] [recoad[1]] then #パラメータが必要なら ここ汚い
                /^([st]+n)(.*)/ =~ str
                recoad[2] = strToBinary($1) #パラメータを二進数の文字列に変換
                str = $2#残り

                if recoad[2].nil? then #cmdがない
                    raise "no parameter"
                end
            else#パラメータが必要なければ
                recoad[2] = nil
            end
            #p recoad
            result << recoad #レコードを追加
        end

        return result#結果を返す
    end

    def self.run(orders)

    end
end



#ファイル読み込み
fileName = ARGV[0]#ファイル名取得

begin
   file = open(fileName)
rescue => e
   raise e
   return
end

Whitespace.compile(file)