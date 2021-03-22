class ErrorKing #王様っぽいエラー構文を出力するクラス
	@@errorMap = {
		:error => "エラー",
		:syntaxError => "しんたっくすエラー",
		:runTimeError => "らんたいむエラー",
		:ZeroDiv => "ゼロじょざん"
	}

	def initialize
		@e_kind = :error
	end

	def self.newCreate(e_kind)
		result = self.new
		result.setEKind(e_kind)
		return result
	end

	def setEKind(kind)
		@e_kind = kind
	end

	def errorText(line,fileName)
		return "\nおお " + fileName + ":" + line.to_s + " !\n" + @@errorMap[@e_kind] + " とは なにごとだ !\nしかたのない やつだな。\nおまえに もう いちど\nきかいを あたえよう !\nふたたび このようなことが\nおこらぬことを\nわしは いのっている !"
	end
end