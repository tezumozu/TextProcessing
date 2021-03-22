require_relative 'QuestTokenList'
require_relative 'ErrorKing'
require 'strscan'

class QuestRuner
	@@tokenToDef = {
		:sentences => 'sentenceBlock',
		:if => 'ifSentence',
		:for => 'forSentence',
		:break => 'breakSentence',
		:print => 'printSentence',
		:damage => 'damageSentence',
		:define => 'defineSentece',
		:sbst => 'substitutionSentence',

		:add => 'add',
		:sub => 'sub',
		:mul => 'mul',
		:div => 'div',

		:gre => 'gre',#>
		:gore => 'gore',
		:lre => 'lre',#<
		:lore => 'lore',
		:equ => 'equ',

		:or => 'or',
		:and => 'and',

		:lpar => 'lpar'
	}


	def initialize()
	end


	def run(block,fileName)
		if !block.instance_of?(Array) then
			return
		end
		@fileName = fileName
		@variableHash = {}
		begin
			sentenceBlock(block)
		rescue => exception
			raise exception
		end
		
	end


	def sentenceBlock(block)
		block[1].each{|line|
			if line.nil? then
				break
			end
			send(@@tokenToDef[line[0]],line)
		}
	end


	def ifSentence(block)#if
		#if tf t f
		#式の計算
		tf = expression(block[1],block[4])

		if tf == 0 then
			tf = false
		end
		
		if tf then
			sentenceBlock(block[2][1])
		else
			#はい の分の行数を足す
			sentenceBlock(block[3][1])
		end
	end


	def forSentence(block)
		count = expression(block[1],block[4])

		#数値かどうか
		if !count.instance_of?(Float) then
			raise ErrorKing.newCreate(:runTimeError).errorText(block[4],@fileName)
		end

		@variableHash[block[2]] = count
		while @variableHash[block[2]] > 0 do
			begin
				sentenceBlock(block[3])
			rescue => exception#breakからのメッセージを監視
				if exception.message == "break" then	#break文からだったら
					break #コンテニュ
				else
					raise exception
				end
			end
		end
	end


	def breakSentence(block)
		#変数が定義されているか
		if !@variableHash.has_key?(block[1]) then
			raise ErrorKing.newCreate(:runTimeError).errorText(block[2],@fileName)
		end
		raise "break"
		return
	end


	def printSentence(block)
		puts expression(block[1],block[2])
		return
	end


	def damageSentence(block)
		#変数が定義されているか
		if !@variableHash.has_key?(block[1]) then
			raise ErrorKing.newCreate(:runTimeError).errorText(block[3],@fileName)
		end

		@variableHash[block[1]] -= expression(block[2],block[3])
		return
	end


	def defineSentece(block)
		@variableHash[block[1]] = nil
		return
	end


	def substitutionSentence(block)
		#変数が定義されているか
		if !@variableHash.has_key?(block[1]) then
			raise ErrorKing.newCreate(:runTimeError).errorText(block[3],@fileName)
		end
		@variableHash[block[1]] = expression(block[2],block[3])

		return
	end


	def expression(expr,line)
		if	!expr.instance_of?(Array)	
			return literal(expr,line)
		end
		begin
			case expr[0]
			when :add
				return expression(expr[1],line) + expression(expr[2],line)
			when :sub
				return expression(expr[1],line) - expression(expr[2],line)
			when :mul
				return expression(expr[1],line) * expression(expr[2],line)
			when :mod
				return expression(expr[1],line) % expression(expr[2],line)
			when :div
				expr = expression(expr[1],line) / expression(expr[2],line)
				if expr == Float::INFINITY then#0除算
					raise ErrorKing.newCreate(:ZeroDiv).errorText(line,@fileName)
				end
				return expr
	
			when :equ
				return expression(expr[1],line) == expression(expr[2],line)
			when :LorE
				return expression(expr[1],line) <= expression(expr[2],line)
			when :lre
				return expression(expr[1],line) < expression(expr[2],line)
			when :GorE
				return expression(expr[1],line) >= expression(expr[2],line)
			when :gre
				return expression(expr[1],line) > expression(expr[2],line)
	
			when :or
				l = checkFalse(expression(expr[1],line)) #左辺
				r = checkFalse(expression(expr[2],line)) #右辺
				return l || r
			when :and
				l = checkFalse(expression(expr[1],line)) #左辺
				r = checkFalse(expression(expr[2],line)) #右辺
				return l && r
	
			when :lpar
				return expression(expr[1],line)
			end
		rescue => exception
			if exception.instance_of?(NoMethodError) then
				raise ErrorKing.newCreate(:runTimeError).errorText(line,@fileName)
			end
			raise exception
		end
	end


	def checkFalse(token) #0やnilの場合のみfalseとする
		if token.nil? || token == 0 then 
			token = false
		end

		return token
	end

	def literal(token,line)

		#数値か
		if token.instance_of?(Float) then
			return token
		end

		#テキストか
		if !(result = token.scan(/'(.+)'/)[0]).nil? then
			return result[0]
		end

		#変数か
		if @variableHash.has_key?(token) then#変数が定義されているか
			return @variableHash[token]
		else
			raise ErrorKing.newCreate(:runTimeError).errorText(line,@fileName)
		end
	end
end
