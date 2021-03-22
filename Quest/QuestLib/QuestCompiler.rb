require_relative 'QuestTokenList'
require_relative 'ErrorKing'
require 'strscan'

class QuestCompiler
	def initialize
		@indent = 0
		@infor = false
		@file = nil
		@variableHash = {}
	end

	def test
		return :test
	end

	def compile (file)
		@indent = 0

		@file = UngetsFile.new(file)
		
		sentenceBlock()
	end


	def sentenceBlock() #文列
		#文列を収める配列、1要素が1文
		block = []
		stnc = sentence()
		block << stnc
		while !stnc.nil? do
			stnc = sentence()
			block << stnc
		end 
		return [:block,block]
	end


	def sentence()#文
		stnc = getSentence()

		#同じブロック内であるかどうか
		if !(indentCount(stnc) == @indent) then
			ungetSentence(stnc)
			return nil
		end

		#tabを取り除く
		stnc = removeTab(stnc)

		#文であるかどうか
		if ! ( result = defineSentence(stnc) ).nil? then
			return result
		elsif ! ( result = printSentence(stnc) ).nil? then
			return result
		elsif ! ( result = forSentence(stnc) ).nil? then
			return result
		elsif ! ( result = ifSentence(stnc) ).nil? then
			return result
		elsif ! ( result = damageSentence(stnc) ).nil? then
			return result
		elsif ! ( result = breakSentence(stnc) ).nil? then
			return result
		elsif ! ( result = substitutionSentence(stnc) ).nil? then
			return result
		end

		#文でないなら
		raise ErrorKing.newCreate(:syntaxError).errorText(@file.getLineNum,@file.getBaseName)
		ungetSentence(stnc)
		return nil
	end


	def ifSentence(stnc)#if文
		result = []
		line = @file.getLineNum
		#正規表現
		regx = /＊「|は ただしいですか \?|#{$expression}/
		#スキャナの生成
		scanner = NotNilUngetsScanner.new(stnc,regx)

		if !(scanner.gets_token() == "＊「") then #ifでないなら
			return nil #抜ける
		end

		result << :if
		result << logic(scanner) #tf判断ようの式
		if !(scanner.gets_token == "は ただしいですか ?") then #ちゃんと文法に沿っているか
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		@indent += 1 #ブロックに入ったので
		result << ifTFSentence("はい")
		result << ifTFSentence("いいえ")
		@indent -= 1

		result << line
		return result
	end

	def ifTFSentence(tf)#はい,いいえの文法
		#true,falseの処理
		stnc = getSentence()
		line = @file.getLineNum
		#同じブロック内であるかどうか
		if !(indentCount(stnc) == @indent) then
			return nil
		end
		#tabを取り除く
		stnc = removeTab(stnc)

		scanner = NotNilUngetsScanner.new(stnc,/はい|いいえ/)
		if !(scanner.gets_token() == tf) then #はい|いいえかどうか
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		@indent += 1
		block = sentenceBlock()
		@indent -= 1

		if tf == "はい" then
			return [true,block,line]
		else
			return [false,block,line]
		end
		
	end


	def forSentence(stnc)#for文
		result = []
		line = @file.getLineNum
		#正規表現
		regx = /HP|の|#{$expression}|が あらわれた !/
		#スキャナの生成
		scanner = NotNilUngetsScanner.new(stnc,regx)

		if !(scanner.gets_token() == "HP") then #forでないなら
			return nil #抜ける
		end

		#式か
		hp = logic(scanner)
		if hp.nil? then
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		#構文どおりなら[の]がスルー
		scanner.gets_token()

		vari = nil
		if (vari = scanner.gets_token.scan(/\s*(#{$variable})\s*/)[0][0]).nil? then#変数かどうか
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		@infor = true
		@indent += 1
		block = sentenceBlock()
		@infor = false
		@indent -= 1

		result = [:for,hp,vari,block,line]

		return result

	end


	def damageSentence(stnc)#ダメージ文 -= の役割
		line = @file.getLineNum
		#damage文か
		if !(expr = stnc.scan(/\A(.+) に (.+) の ダメージ !\Z/)[0]) then
			return nil
		end

		#for文外はエラー
		if !@infor then 
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		#変数かどうか
		vari = nil
		if (vari = expr[0].scan(/\s*(#{$variable})\s*/)[0][0]).nil? then
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		#式を取得
		expr = logic(NotNilUngetsScanner.new(expr[1],$expression))
		if expr.nil? then
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		return [:damage,vari,expr,line]
	end


	def defineSentence(stnc)#変数定義文
		line = @file.getLineNum
		#正規表現
		regx = /なまえをいれてください|#{$variable}/
		#スキャナの生成
		scanner = NotNilUngetsScanner.new(stnc,regx)

		#変数定義文か
		if !(scanner.gets_token() == "なまえをいれてください") then
			return nil
		end

		vari = literal(scanner.gets_token)
		if vari.nil? then#変数かどうか
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		return [:define,vari,line]
	end


	def substitutionSentence(stnc) #代入文
		line = @file.getLineNum
		#代入文か
		if (expr = stnc.scan(/\A(.+) は (.+) を てにいれた !\Z/)[0]).nil? then
			return nil
		end
		
		vari = nil
		if (vari = expr[0].scan(/\s*(#{$variable})\s*/)[0][0]).nil? then#変数かどうか
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		#スキャナの生成
		scanner = NotNilUngetsScanner.new(expr[1],$expression)
		result = [:sbst,vari,logic(scanner),line]
		return result
	end



	def printSentence(stnc)#print文
		line = @file.getLineNum
		expr = nil
		#出力文であるか
		if (expr = stnc.scan(/\A(.+) の しゅつりょく !\Z/))[0].nil? then #出力文であるかどうか
			return nil
		end
		expr = expr[0][0]
		#式の取得
		#スキャナの生成
		scanner = NotNilUngetsScanner.new(expr,$expression)
		expr = logic(scanner)
		if expr.nil? then
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		result = [:print,expr,line]
		return result
	end


	def breakSentence(stnc)#break文
		line = @file.getLineNum
		#break文か
		if (expr = stnc.scan(/\A(.+) は にげだした !\Z/)[0]).nil? then
			return nil
		end

		#for文外はエラー
		if !@infor then 
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		expr = expr[0]

		#変数かどうか
		vari = nil
		if (vari = expr.scan(/\s*(#{$variable})\s*/)[0][0]).nil? then
			raise ErrorKing.newCreate(:syntaxError).errorText(line,@file.getBaseName)
		end

		return [:break,vari,line]
	end


	#演算
	def logic(scanner)#論理演算子
		result = equalSgin(scanner)
		sgin = scanner.gets_token

		while $tokenList[sgin] == :or || $tokenList[sgin] == :and do
			result = [$tokenList[sgin],result,equalSgin(scanner)]
			sgin = scanner.gets_token
		end

		scanner.ungets_token(sgin)
		return result
	end


	def equalSgin(scanner)#等号、不等号
		result = expression(scanner)
		sgin = scanner.gets_token()

		while $tokenList[sgin] == :equ || $tokenList[sgin] == :gre || $tokenList[sgin] == :GorE || $tokenList[sgin] == :lre || $tokenList[sgin] == :LorE do
			result = [$tokenList[sgin],result,expression(scanner)]
			sgin = scanner.gets_token()
		end

		scanner.ungets_token(sgin)
		return result
	end


	def expression(scanner)#たすひき
		result = term(scanner)
		sgin = scanner.gets_token

		while $tokenList[sgin] == :add || $tokenList[sgin] == :sub do
			result = [$tokenList[sgin],result,term(scanner)]
			sgin = scanner.gets_token
		end

		scanner.ungets_token(sgin)
		return result
	end


	def term(scanner)#かける
		result = factor(scanner)
		sgin = scanner.gets_token
		while $tokenList[sgin] == :mul || $tokenList[sgin] == :div|| $tokenList[sgin] == :mod do
			result = [$tokenList[sgin],result,factor(scanner)]
			sgin = scanner.gets_token
		end

		scanner.ungets_token(sgin)
		return result
	end


	def factor(scanner)#値や括弧
		factor = scanner.gets_token
		result = nil
		if $tokenList[factor] == :lpar then#括弧の開始
			result = [:lpar,logic(scanner)]
			scanner.gets_token #終端記号を取り除く
		else
			result = literal(factor)
		end

		return result
	end


	def literal(token)#数値、変数、テキスト
		result = nil
		if token.nil? then#nilチェック
			return nil
		end
		#数値か
		if !token.scan(/[0-9]+/)[0].nil? then
			return result = token.to_f

		#テキストか
		elsif !(result = token.scan(/'.+'/)[0]).nil? then
			return result

		#変数か
		elsif !token.scan(/\A\s*#{$variable}\s*\Z/)[0].nil? then#変数か
			return result = token
		end

		raise ErrorKing.newCreate(:syntaxError).errorText(@file.getLineNum,@file.getBaseName)
		return nil
	end


	#センテンス
	def getSentence()
		return @file.ungetableGetS()
	end

	def ungetSentence(sentence)
		if sentence.nil? then
			return
		end
		@file.ungetS(sentence)
	end


	#インデント関係
	def indentCount(text) #indentを数える
		result = 0
		if text.nil? then#nilチェック
			return nil
		end

		text.chars.each {|c|
			if !(c == "\t") then
				break
			end
			result += 1
		}
		return result
	end

	def removeTab(text)
		result = ""
		flag = true
		text.chars.each {|c|
			if flag then
				if c == "\t" then
					next
				end
				flag = false
			end

			result += c
		}
		return result
	end
end



class UngetsFile #ungetsを可能に
	@file = nil
	@unget_pos = 0
	

	def initialize(file)
		@file = file
		@lineNum = 0
	end


	def ungetableGetS()
		result = nil
		while result.nil? do #空白文字のみをスルー
			@lineNum += 1
			@unget_pos = @file.pos
			result = @file.gets #1行取得
			if result.nil? then#EoF
				return nil
			end

			if !result.match(/\A\s+\Z/).nil? then
				result = nil
			end
		end
		return result
	end


	def ungetS(line)
		if line.nil? then
			return
		end

		@lineNum -= 1
		@file.pos = @unget_pos
	end


	def getBaseName()
		return File.basename(@file.path())
	end


	def getLineNum()
		return @lineNum
	end
end



class NotNilUngetsScanner #引数がnil以外の時にungetするスキャナー

	def initialize(text,regx)
		@scanner = StringScanner.new(text)
		@regx = regx
	end

	def	gets_token()
		
		@scanner.scan(/\s+/)
		return @scanner.scan(@regx)
	end

	def	ungets_token	(token)
		if token.nil? then
			return
		end
		@scanner.unscan()
	end
end