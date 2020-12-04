#! /usr/bin/ruby1

#命令を表すクラス ver.2変更点
class OrderRuner
    def self.orderRun(order)
        send(order[0],order)
    end


    #P
    def self.P(order)
        if order[1] != nil || order[2] != nil || order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        flag = ED.getPrompt
        ED.setPrompt (not flag)
    end


     #a
     def self.a(order)
        if order[2] != nil || order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[1] == nil then
            order[1] = ED.getLineCount
        end
        
        ED.setInsertMode(true)
        ED.setLineCount(order[1])
    end


    #i
    def self.i(order)
        if order[2] != nil || order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[1] == nil then
            order[1] = ED.getLineCount
        end
        
        ED.setInsertMode(true)
        ED.setLineCount(order[1] - 1)
    end
    
    #w
    def self.w(order)
        if order[1] != nil || order[2] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[3].nil? then
            order[3] = FileEditer.getCurrentFileName
        end
        
        FileEditer.setNotSave(false)
        FileEditer.writeFile(order[3])
    end
    

    #wq
    def self.wq(order)
        if !order[1].nil? || !order[2].nil? then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[3].nil? then
            order[3] = FileEditer.getCurrentFileName
        end
        
        FileEditer.setNotSave(false)
        FileEditer.writeFile(order[3])
        ED.setQuit(true)
    end
    
    
    #q
    def self.q(order)
        if !(order[1].nil?) || !(order[2].nil?) || !(order[3].nil?) then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if FileEditer.getNotSave then
            raise "?(保存していない気がする...)"
            return
        end
        ED.setQuit(true)
    end
    
    
    #n
    def self.n(order)
        if  order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[1] == nil then
            order[1] = ED.getLineCount
        end

        if order[2] == nil then
            order[2] = order[1]
        end

        FileEditer.printFile(order[1] - 1,order[2] - 1,true)
        ED.setLineCount(order[2])
    end
    
    
    #p
    def self.p(order)
        if  order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[1] == nil then
            order[1] = ED.getLineCount
        end

        if order[2] == nil then
            order[2] = order[1]
        end
        FileEditer.printFile(order[1] - 1,order[2] - 1,false)
        ED.setLineCount(order[2])
    end
    
    
    #c
    def self.c(order)
        if order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[1] == nil then
            order[1] = ED.getLineCount
        end

        if order[2] == nil then
            order[2] = order[1]
        end

        FileEditer.setNotSave(true)
        ED.setInsertMode(true)
        FileEditer.removeLine(order[1] - 1,order[2] - 1)
        ED.setLineCount(order[1]-1)
    end
    
    
    #d
    def self.d(order)
        if order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[1] == nil then
            order[1] = ED.getLineCount
        end

        if order[2] == nil then
            order[2] = order[1]
        end

        FileEditer.setNotSave(true)
        FileEditer.removeLine(order[1] - 1,order[2] - 1)
        ED.setLineCount(order[1])
    end
    
    
     #j
     def self.j(order)
        if order[1] == nil || order[2] == nil || order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end
        FileEditer.joinLine(order[1] - 1,order[2] - 1)
        ED.setLineCount(order[1])
    end
    
    
    #= 行数を教える
    def self.putsLineNum(order)
        if order[2] != nil || order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if order[1].nil? then
            order[1] = ED.getLineCount
        end
        puts order[1].to_s
    end


    #改行
    def self.indention(order)
        if order[3] != nil then
            raise "?(命令が間違っている気がする...)"
            return
        end

        if !order[2].nil? then
            order[1] = order[2]
        end

        if order[1].nil? then
            order[1] = ED.getLineCount + 1
        end
        
        if FileEditer.getFileArrayLength < order[1] then
            raise "?(EoFな気がする...)"
            return
        end

        ED.setLineCount(order[1])
        FileEditer.printFile(ED.getLineCount-1,ED.getLineCount-1,false)
    end

end



#ファイルデータもとい配列をいじるクラス
class FileEditer
    @@fileArray = []#1要素がテキストファイルの一行に相当する配列
    @@notSave = false
    @@currentFileName = nil

    def self.setFile(file_name)
        begin
            file = open(file_name)
        rescue
            raise "?(ファイル名がおかしい気がする...)"
            return
        end
            @@currentFileName = file_name
        
        file.each do |line|
            @@fileArray << line.chomp
        end

        file.close
    end


    def self.addLine(l,data)
        @@fileArray.insert(l,data)
    end


    def self.removeLine(n,m)
        if n > m || @@fileArray.length < m then #行数の範囲外にアクセスした場合
            raise "?(行数がおかしい気がする...)"
            return
        end
        @@fileArray[n,m - n+1] = []
    end


    def self.writeFile(fileName)
        text = ""
        for i in 0..@@fileArray.length-1 do
            text += @@fileArray[i]+"\n"
        end
        puts text#確認用
        begin
            File.open(fileName,"w"){|f|
                f.write(text)
            }
        rescue
            puts "?(ファイル名がおかしい気がする...)"
            return
        end
        return
    end


    def self.printFile(n,m,flag)
        if n > m || @@fileArray.length < m || n < 0 then #行数の範囲外にアクセスした場合
            raise "?(行数がおかしい気がする...)"
            return
        end
        for i in n..m do
            text = @@fileArray[i]
            if flag then
                text = (i+1).to_s + "\t" + @@fileArray[i]
            end
            puts text
        end
    end


    def self.joinLine(n,m)
        if n >= m || @@fileArray.length < m then #行数の範囲外にアクセスした場合
            raise "?(行数がおかしい気がする...)"
            return
        end

        joinText = ""
        for i in n..m do
            joinText += @@fileArray[i]
        end

        removeLine(n,m)
        addLine(n,joinText)
    end


    def self.matchPatternLines(pattern,startLine)
        result = []
        if startLine > @@fileArray.length
            raise "?(行数がおかしい気がする)"
            return
        end
        for i in startLine-1..@@fileArray.length - 1 do
            if pattern.match(@@fileArray[i]) != nil then
                result << i+1
            end    
        end

        if result.length < 1 then
            raise "?(パターンにマッチしなかった気がする...)"
            return
        end

        return result
        
    end


    def self.getFileArrayLength
        return @@fileArray.length
    end


    def self.setNotSave(flag)
        @@notSave = flag
    end


    def self.getNotSave
        return @@notSave
    end

    def self.getCurrentFileName
        return @@currentFileName
    end
end



#edクラス ネストが深かったので分割(それでも深い)
class ED
    @@quit = false #終了を表すフラグ
    @@insertMode = false
    @@promptFlag = true
    @@prompt = "*"
    @@lineCount = 0 #現在何行目か

    def self.run

        if @@insertMode then#元もモードは2つしかないから雑にif分岐
            text = STDIN.gets.chomp #入力受け取り
            if /^\.$/.match(text) != nil then#もし「.」だったら
                @@insertMode = false
                return#後の処理をスルー
            end

            #if .のみの入力処理をこの辺で入れたい
            FileEditer.setNotSave(true)
            FileEditer.addLine(@@lineCount,text)
            @@lineCount = @@lineCount+1

        else#通常の入力待ち

            if @@promptFlag then#プロンプト文字の出力
                print "*".chomp
            end
            
            begin
                text = STDIN.gets#read
                order = eval(text)
                print_(order)
            rescue => e
                puts e
                return
            end
        end
    end


    #命令かどうか判定 ver.1の変更点
    def self.eval(text)
        if text == nil then
            raise "?(命令がおかしい気がする....)"
            return
        end

        addr = /[0-9]+|[$.,;]|\/(?:(?!(?!\\)\/).)*\// #正規表現はマッチした最初の行になる
        cmnd = /\n|wq|zn|klc|[a-zA-Z=]/
        prmt = /.+/#+でないと何も入っていない文字型が入ってしまいnilではなくなる
        order  = /\A(?:(#{addr})(?:,(#{addr}))?)?(#{cmnd})(?:\s(#{prmt}))?\Z/
        order =~ text
        result = [$3,$1,$2,$4]#命令,アドレス1,アドレス2,パラメ-タの順に格納

        if !(/^\n$/.match(result[0]).nil?)then #改行だったら
            result[0] = "indention"
        end

        if !(/^[=]$/.match(result[0]).nil?)then #=だったら
            result[0] = "putsLineNum"
        end
        
        begin
            addresToNum(result)
        rescue => e
            raise e
            return
        end

        return result
    end


    #文字列のアドレスを数値に変換,特殊なアドレスを数字に変換
    def self.addresToNum(order)
        if order[1] == "," then
            order[1] = 1
            order[2] = FileEditer.getFileArrayLength
            return #インスタンスは参照型なので

        elsif order[1] == ";" then
            order[1] = @lineCount
            order[2] = FileEditer.getFileArrayLength
            return

        elsif /\/.+\//.match(order[1]) != nil && order[1] == order[2] then#同じパターンが2つ与えられた時
            begin
                /\/(.+)\// =~ order[1]
                pattern = Regexp.compile($1);
            rescue
                raise "?(パターンになっていない気がする...)"
                return
            end
            lines = FileEditer.matchPatternLines(pattern,0)
            order[1] = lines[0]
            order[2] = lines[lines.length - 1]
            return
        end

        matchStartLine = 0#パターンマッチを行い始めるライン
        for i in 1..2 do
            if order[i] == "$" then
                order[i] = FileEditer.getFileArrayLength
                next

            elsif order[i] == "." then
                order[i] = @@lineCount
                next

            elsif /\/.+\//.match(order[i]) != nil then
                begin
                    /\/(.+)\// =~ order[i]
                    pattern = Regexp.compile($1);
                rescue
                    raise "?(パターンになっていない気がする...)"
                    return
                end
                lines = FileEditer.matchPatternLines(pattern,matchStartLine)
                order[i] = lines[0]
                matchStartLine = lines[0]+1
                next
            end

            if !order[i].nil? then
                order[i] = order[i].to_i
            end
        end

        return
    end


    #処理を実行 ver.1の変更点
    def self.print_(orderData)
        begin
            OrderRuner.orderRun(orderData)
        rescue => e
            raise e
            return
        end
    end


    #もっと隠蔽したほうが利口 そこまで設計に頭が回らんばい
    def self.setQuit(flag)
        @@quit = flag
    end

    def self.getQuit
        return @@quit
    end


    def self.setInsertMode(flag)
        @@insertMode = flag
    end
    

    def self.setPrompt(flag)
        @@promptFlag = flag
    end


    def self.setLineCount(num)
        @@lineCount = num
    end

    def self.getLineCount
        return @@lineCount
    end


    def self.checkDollar(text)
        if text == "$" then
            return FileEditer.getFileArrayLength.to_s
        end
        return text
    end

    def self.getPrompt
        return @@promptFlag
    end
end


#mainクラス
class Main
    def initialize
        begin
            FileEditer.setFile(ARGV[0])#ファイルを開く オプションを想定していない
            ED.setLineCount(FileEditer.getFileArrayLength)
        rescue
            puts "ファイルが指定されていません"
        end
        loop do
            ED.run
            if ED.getQuit then
                break
            end
        end
    end
end

#main処理
Main.new