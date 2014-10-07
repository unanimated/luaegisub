script_name="Runemap"
script_description="おまえ　は　ばか　だから"
script_author="unanimated"
script_version="1.0"

re=require'aegisub.re'

function map(subs,sel)
GUI={
  {x=0,y=11,width=17,class="label",label="Romaji"},
  {x=0,y=12,width=17,class="edit",name="rmj"},
  {x=18,y=11,width=17,class="label",label="Hiragana"},
  {x=18,y=12,width=17,class="edit",name="hrg"},
  {x=36,y=11,width=17,class="label",label="Katakana"},
  {x=36,y=12,width=17,class="edit",name="ktk"},
  {x=0,y=8,width=53,class="edit",name="hrgc",
  value="あいうえお   やゆよ   かきくけこ   さしすせそ   たちつてと   なにぬねの   はひふへほ   まみむめも   らりるれろ   がぎぐげご   ざじずぜぞ   だぢづでど   ばびぶべぼ   ぱぴぷぺぽ   わをん   っゃゅょー"},
  {x=0,y=9,width=53,class="edit",name="ktkc",
  value="アイウエオ   ヤユヨ   カキクケコ   サシスセソ   アイウエト   ナ二ヌネノ   ハヒフヘホ   マミムメモ   ラリルレロ   ガギグゲゴ   ザジズゼゾ   ダヂヅデド   バビブベボ   パピプペポ   ワヲン   ッャュョー"},
}

a1={"a","i","u","e","o","ya","yu","yo"}
a2={"あ","い","う","え","お","や","ゆ","よ"}
a3={"ア","イ","ウ","エ","オ","ヤ","ユ","ヨ"}

ka1={"ka","ki","ku","ke","ko","kya","kyu","kyo"}
ka2={"か","き","く","け","こ","きゃ","きゅ","きょ"}
ka3={"カ","キ","ク","ケ","コ","キャ","キュ","キョ"}

sa1={"sa","shi","su","se","so","sha","shu","sho"}
sa2={"さ","し","す","せ","そ","しゃ","しゅ","しょ"}
sa3={"サ","シ","ス","セ","ソ","シャ","シュ","ショ"}

ta1={"ta","chi","tsu","te","to","cha","chu","cho"}
ta2={"た","ち","つ","て","と","ちゃ","ちゅ","ちょ"}
ta3={"タ","チ","ツ","テ","ト","チャ","チュ","チョ"}

na1={"na","ni","nu","ne","no","nya","nyu","nyo"}
na2={"な","に","ぬ","ね","の","にゃ","にゅ","にょ"}
na3={"ナ","二","ヌ","ネ","ノ","ニャ","ニュ","ニョ"}

ha1={"ha","hi","fu","he","ho","hya","hyu","hyo"}
ha2={"は","ひ","ふ","へ","ほ","ひゃ","ひゅ","ひお"}
ha3={"ハ","ヒ","フ","ヘ","ホ","ヒャ","ヒュ","ヒョ"}

ma1={"ma","mi","mu","me","mo","mya","myu","myo"}
ma2={"ま","み","む","め","も","みゃ","みゅ","みょ"}
ma3={"マ","ミ","ム","メ","モ","ミャ","ミュ","ミョ"}

ra1={"ra","ri","ru","re","ro","rya","ryu","ryo"}
ra2={"ら","り","る","れ","ろ","りゃ","りゅ","りょ"}
ra3={"ラ","リ","ル","レ","ロ","リャ","リュ","リョ"}

ga1={"ga","gi","gu","ge","go","gya","gyu","gyo"}
ga2={"が","ぎ","ぐ","げ","ご","ぎゃ","ぎゅ","ぎょ"}
ga3={"ガ","ギ","グ","ゲ","ゴ","ギャ","ギュ","ギョ"}

za1={"za","ji","zu","ze","zo","ja","ju","jo"}
za2={"ざ","じ","ず","ぜ","ぞ","じゃ","じゅ","じょ"}
za3={"ザ","ジ","ズ","ゼ","ゾ","ジャ","ジュ","ジョ"}

da1={"da","ji","zu","de","do","ja","ju","jo"}
da2={"だ","ぢ","づ","で","ど","ぢゃ","ぢゅ","ぢょ"}
da3={"ダ","ヂ","ヅ","デ","ド","ヂャ","ヂュ","ヂョ"}

ba1={"ba","bi","bu","be","bo","bya","byu","byo"}
ba2={"ば","び","ぶ","べ","ぼ","びゃ","びゅ","びょ"}
ba3={"バ","ビ","ブ","ベ","ボ","ビャ","ビュ","ビョ"}

pa1={"pa","pi","pu","pe","po","pya","pyu","pyo"}
pa2={"ぱ","ぴ","ぷ","ぺ","ぽ","ぴゃ","ぴゅ","ぴょ"}
pa3={"パ","ピ","プ","ペ","ポ","ピャ","ピュ","ピョ"}

wa1={"wa","wo","n","_","-"}
wa2={"わ","を","ん","っ","ー"}
wa3={"ワ","ヲ","ン","ッ","ー"}

for i=1,8 do
    n=i-1
    t1={x=n,y=0,class="label",name=a1[i].."1",label=a1[i]} table.insert(GUI,t1)
    t2={x=n,y=1,class="label",name=a1[i].."2",label=a2[i]} table.insert(GUI,t2)
    t3={x=n,y=2,class="label",name=a1[i].."3",label=a3[i]} table.insert(GUI,t3)
    t4={x=n,y=4,class="label",name=ra1[i].."1",label=ra1[i]} table.insert(GUI,t4)
    t5={x=n,y=5,class="label",name=ra1[i].."2",label=ra2[i]} table.insert(GUI,t5)
    t6={x=n,y=6,class="label",name=ra1[i].."3",label=ra3[i]} table.insert(GUI,t6)
    n=i+8
    t1={x=n,y=0,class="label",name=ka1[i].."1",label=ka1[i]} table.insert(GUI,t1)
    t2={x=n,y=1,class="label",name=ka1[i].."2",label=ka2[i]} table.insert(GUI,t2)
    t3={x=n,y=2,class="label",name=ka1[i].."3",label=ka3[i]} table.insert(GUI,t3)
    t4={x=n,y=4,class="label",name=ga1[i].."1",label=ga1[i]} table.insert(GUI,t4)
    t5={x=n,y=5,class="label",name=ga1[i].."2",label=ga2[i]} table.insert(GUI,t5)
    t6={x=n,y=6,class="label",name=ga1[i].."3",label=ga3[i]} table.insert(GUI,t6)
    n=i+17
    t1={x=n,y=0,class="label",name=sa1[i].."1",label=sa1[i]} table.insert(GUI,t1)
    t2={x=n,y=1,class="label",name=sa1[i].."2",label=sa2[i]} table.insert(GUI,t2)
    t3={x=n,y=2,class="label",name=sa1[i].."3",label=sa3[i]} table.insert(GUI,t3)
    t4={x=n,y=4,class="label",name=za1[i].."1",label=za1[i]} table.insert(GUI,t4)
    t5={x=n,y=5,class="label",name=za1[i].."2",label=za2[i]} table.insert(GUI,t5)
    t6={x=n,y=6,class="label",name=za1[i].."3",label=za3[i]} table.insert(GUI,t6)
    n=i+26
    t1={x=n,y=0,class="label",name=ta1[i].."1",label=ta1[i]} table.insert(GUI,t1)
    t2={x=n,y=1,class="label",name=ta1[i].."2",label=ta2[i]} table.insert(GUI,t2)
    t3={x=n,y=2,class="label",name=ta1[i].."3",label=ta3[i]} table.insert(GUI,t3)
    t4={x=n,y=4,class="label",name=da1[i].."1",label=da1[i]} table.insert(GUI,t4)
    t5={x=n,y=5,class="label",name=da1[i].."2",label=da2[i]} table.insert(GUI,t5)
    t6={x=n,y=6,class="label",name=da1[i].."3",label=da3[i]} table.insert(GUI,t6)
    n=i+35
    t1={x=n,y=0,class="label",name=na1[i].."1",label=na1[i]} table.insert(GUI,t1)
    t2={x=n,y=1,class="label",name=na1[i].."2",label=na2[i]} table.insert(GUI,t2)
    t3={x=n,y=2,class="label",name=na1[i].."3",label=na3[i]} table.insert(GUI,t3)
    t4={x=n,y=4,class="label",name=ba1[i].."1",label=ba1[i]} table.insert(GUI,t4)
    t5={x=n,y=5,class="label",name=ba1[i].."2",label=ba2[i]} table.insert(GUI,t5)
    t6={x=n,y=6,class="label",name=ba1[i].."3",label=ba3[i]} table.insert(GUI,t6)
    n=i+44
    t1={x=n,y=0,class="label",name=ha1[i].."1",label=ha1[i]} table.insert(GUI,t1)
    t2={x=n,y=1,class="label",name=ha1[i].."2",label=ha2[i]} table.insert(GUI,t2)
    t3={x=n,y=2,class="label",name=ha1[i].."3",label=ha3[i]} table.insert(GUI,t3)
    t4={x=n,y=4,class="label",name=pa1[i].."1",label=pa1[i]} table.insert(GUI,t4)
    t5={x=n,y=5,class="label",name=pa1[i].."2",label=pa2[i]} table.insert(GUI,t5)
    t6={x=n,y=6,class="label",name=pa1[i].."3",label=pa3[i]} table.insert(GUI,t6)
    n=i+53
    t1={x=n,y=0,class="label",name=ma1[i].."1",label=ma1[i]} table.insert(GUI,t1)
    t2={x=n,y=1,class="label",name=ma1[i].."2",label=ma2[i]} table.insert(GUI,t2)
    t3={x=n,y=2,class="label",name=ma1[i].."3",label=ma3[i]} table.insert(GUI,t3)
    if i<6 then
    t4={x=n,y=4,class="label",name=wa1[i].."1",label=wa1[i]} table.insert(GUI,t4)
    t5={x=n,y=5,class="label",name=wa1[i].."2",label=wa2[i]} table.insert(GUI,t5)
    t6={x=n,y=6,class="label",name=wa1[i].."3",label=wa3[i]} table.insert(GUI,t6)
    end
end

    repeat
    if P=="Transcribe" then
	R=res.rmj
	H=res.hrg
	K=res.ktk
	if R=="" then RC=0 else RC=1 end
	if H=="" then HC=0 else HC=1 end
	if K=="" then KC=0 else KC=1 end
	if RC+HC+KC>1 then t_error("Error: Multiple inputs.") rom=R hira=H kata=K
	elseif RC+HC+KC==1 then
	rom="" hira="" kata=""
	    -- hiragana
	    if HC==1 then
		hira=H
		tab={}
		chars=re.find(H,".ゃ?")
		for l=1,#chars do
		    table.insert(tab,chars[l].str)
		end
		for i=1,#tab do
		    local c=tab[i]
		    name=getname(c)
		    romc=getchar(name,"1")
		    katac=getchar(name,"3")
		    rom=rom..romc
		    kata=kata..katac
		end
	    -- katakana
	    elseif KC==1 then
		kata=K
		tab={}
		chars=re.find(K,".ャ?")
		for l=1,#chars do
		    table.insert(tab,chars[l].str)
		end
		for i=1,#tab do
		    local c=tab[i]
		    name=getname(c)
		    romc=getchar(name,"1")
		    hirac=getchar(name,"2")
		    rom=rom..romc
		    hira=hira..hirac
		end
	    -- romaji
	    else
		rom=R:gsub("%-"," ")
		tab={}
		for chars in rom:gmatch(".-[aeiou]") do
		    if chars:match("n.y?[aeiou]") then
			table.insert(tab,"n")
			table.insert(tab,chars:match("n(.y?[aeiou])"))
		    elseif chars:match("n%s.-[aeiou]") then
			table.insert(tab,"n")
			table.insert(tab,"　")
			table.insert(tab,chars:match("^n%s(.-[aeiou])"))
		    elseif chars:match("^%s.-[aeiou]") then
			table.insert(tab,"　")
			table.insert(tab,chars:match("^%s(.-[aeiou])"))
		    elseif chars:match("^.")==chars:match("^.(.)") then
			table.insert(tab,"_")
			table.insert(tab,chars:match("^.(.y?[aeiou])"))
		    else
			table.insert(tab,chars)
		    end
		end
		if rom:match("n$") then table.insert(tab,"n") end
		for i=1,#tab do
		    local c=tab[i]
		    name=getname(c)
		    hirac=getchar(name,"2")
		    katac=getchar(name,"3")
		    hira=hira..hirac
		    kata=kata..katac
		end
	    end
	    rom=rom:gsub("_(.)","%1%1") :gsub("(.)%-","%1%1")
	end
	for k,v in ipairs(GUI) do
	  if v.name=="rmj" then v.value=rom end
	  if v.name=="hrg" then v.value=hira end
	  if v.name=="ktk" then v.value=kata end
	end
    end
    buttons={"Transcribe","Exit"}
    P,res=aegisub.dialog.display(GUI,buttons,{ok='Transcribe',close='Exit'})
    until P=="Exit"
    if P=="Exit" then aegisub.cancel() end
    return sel
end

function getname(c)
    local n
    for k,v in ipairs(GUI) do
	if v.label==c then n=v.name end
    end
    n=n or c
    n=n:gsub("%d","")
    return n
end

function getchar(n,t)
    local c
    for k,v in ipairs(GUI) do
	if v.name==n..t and c==nil then c=v.label end
    end
    c=c or n
    return c
end

function t_error(message,cancel)
  aegisub.dialog.display({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then aegisub.cancel() end
end

aegisub.register_macro(script_name,script_description,map)