-- Capitalize text or make it lowercase / uppercase. Select lines, run the script, choose from the 5 options.

script_name="Change capitalization"
script_description="Capitalizes text or makes it lowercase or uppercase"
script_author="unanimated"
script_version="2.1"

-- Unicode support: this is used for capitalisation of non-standard characters. Add more if your language requires it.
unilow={"ä","ö","ü","ë","å","ø","æ","á","é","í","ó","ú","ý","à","è","ì","ò","ù","ç","ï","â","ê","î","ô","û","č","ď","ě","ň","ř","š","ť","ž","ů","ñ","ａ","ｂ","ｃ","ｄ","ｅ","ｆ","ｇ","ｈ","ｉ","ｊ","ｋ","ｌ","ｍ","ｎ","ｏ","ｐ","ｑ","ｒ","ｓ","ｔ","ｕ","ｖ","ｗ","ｘ","ｙ","ｚ"}
unihigh={"Ä","Ö","Ü","Ë","Å","Ø","Æ","Á","É","Í","Ó","Ú","Ý","À","È","Ì","Ò","Ù","Ç","Ï","Â","Ê","Î","Ô","Û","Č","Ď","Ě","Ň","Ř","Š","Ť","Ž","Ů","Ñ","Ａ","Ｂ","Ｃ","Ｄ","Ｅ","Ｆ","Ｇ","Ｈ","Ｉ","Ｊ","Ｋ","Ｌ","Ｍ","Ｎ","Ｏ","Ｐ","Ｑ","Ｒ","Ｓ","Ｔ","Ｕ","Ｖ","Ｗ","Ｘ","Ｙ","Ｚ"}

function lowercase(subs, sel)
    for x, i in ipairs(sel) do
            line=subs[i]
	    text=line.text
	    text=text
	    :gsub("^","}")
	    :gsub("\\n","small_break")
	    :gsub("\\N","large_break")
	    :gsub("\\h","hard_space")
	    :gsub("}([^{]*)",function(l) return "}"..l:lower() end)
	    for u=1,#unilow do
		text=text:gsub(unihigh[u],unilow[u])
	    end
	    text=text
	    :gsub("small_break","\\n")
	    :gsub("large_break","\\N")
	    :gsub("hard_space","\\h")
	    :gsub("^}","")
	    line.text=text
	    subs[i]=line
    end
end

function uppercase(subs, sel)
    for x, i in ipairs(sel) do
            line=subs[i]
	    text=line.text
	    text=text
	    :gsub("^","}")
	    :gsub("\\n","SMALL_BREAK")
	    :gsub("\\N","LARGE_BREAK")
	    :gsub("\\h","HARD_SPACE")
	    :gsub("}([^{]*)", function (u) return "}"..u:upper() end)
	    for u=1,#unilow do
		text=text:gsub(unilow[u],unihigh[u])
	    end
	    text=text
	    :gsub("SMALL_BREAK","\\n")
	    :gsub("LARGE_BREAK","\\N")
	    :gsub("HARD_SPACE","\\h")
	    :gsub("^}","")
	    line.text=text
	    subs[i]=line
    end
end

function capitalines(subs, sel)
    for x, i in ipairs(sel) do
            line=subs[i]
	    text=line.text
	    text=text
	    :gsub("^([^{])","{}%1")
	    :gsub("^({[^}]-}['\"]?)(%l)([^{]-)", function (e,f,g) return e..f:upper()..g end)
	    :gsub(" i([ ',])"," I%1")
	    :gsub("\\Ni([ ',])","\\NI%1")
	    for u=1,#unilow do
		text=text:gsub("^({[^}]-}['\"]?)"..unilow[u],"%1"..unihigh[u])
	    end
	    text=text
	    :gsub("^{}","")
	    line.text=text
	    subs[i]=line
    end
end

function sentences(subs, sel)
    for x, i in ipairs(sel) do
            line=subs[i]
	    text=line.text
	    text=text
	    :gsub("^([^{])","{}%1")
	    :gsub("^({[^}]-}['\"]?)(%l)([^{]-)", function (e,f,g) return e..f:upper()..g end)
	    :gsub("([%.?!]%s)(%l)", function (k,l) return k..l:upper() end)
	    :gsub("([%.?!]%s\\N)(%l)", function (k,l) return k..l:upper() end)
	    :gsub(" i([ ',])"," I%1")
	    :gsub("\\Ni([ ',])","\\NI%1")
	    for u=1,#unilow do
		text=text
		:gsub("^({[^}]-}['\"]?)"..unilow[u],"%1"..unihigh[u])
		:gsub("([%.?!]%s)"..unilow[u],"%1"..unihigh[u])
		:gsub("([%.?!]%s?\\N)"..unilow[u],"%1"..unihigh[u])
	    end
	    text=text
	    :gsub("^{}","")
	    line.text=text
	    subs[i]=line
    end
end

word={"The","A","An","At","As","On","Of","Or","For","Nor","With","Without","Within","To","Into","Onto","Unto","And","But","In","Inside","By","Till","From","Over","Above","About","Around","After","Against","Along","Below","Beneath","Beside","Between","Beyond","Under","Until","Via"}

vord={"the","a","an","at","as","on","of","or","for","nor","with","without","within","to","into","onto","unto","and","but","in","inside","by","till","from","over","above","about","around","after","against","along","below","beneath","beside","between","beyond","under","until","via"}

function capitalize(subs, sel)
    for x, i in ipairs(sel) do
            line=subs[i]
	    text=line.text
	    text=text
	    :gsub("^","}")
	    :gsub("\\n","*small_break*")
	    :gsub("\\N","*large_break*")
	    :gsub("\\h","*hard_space*")
	    :gsub("([%s\"}%(%-%=]['\"]?)(%l)(%l-)",function(e,f,g) return e..f:upper()..g end)	-- after: space " } ( - =
	    :gsub("(break%*)(%l)(%l-)",function(h,j,k) return h..j:upper()..k end)			-- after \N
	    for u=1,#unilow do
		text=text:gsub("([%s\"}%(%-%=]['\"]?)"..unilow[u].."(%l-)","%1"..unihigh[u].."%2")
	    end
	    text=text:gsub("^}","")

	    for r=1,#word do
	    w=word[r]	    v=vord[r]
	    text=text:gsub("([^%.%:])%s"..w.."%s","%1 "..v.." ")
	    text=text:gsub("([^%.%:])%s({[^}]-})"..w.."%s","%1 %2"..v.." ")
	    end

	    -- other stuff
	    text=text
	    :gsub("$","#")
	    :gsub("(%s?)([IVXLCDM])([ivxlcdm]+)([%s%p#])",function (s,r,m,e) return s..r..m:upper()..e end)	-- Roman numbers
	    :gsub("LID","Lid")
	    :gsub("DIM","Dim")
	    :gsub("Ok([%s%p#])","OK%1")
	    :gsub("%-San([%s%p#])","-san%1")
	    :gsub("%-Kun([%s%p#])","-kun%1")
	    :gsub("%-Chan([%s%p#])","-chan%1")
	    :gsub("%-Sama([%s%p#])","-sama%1")
	    :gsub("%-Dono([%s%p#])","-dono%1")
	    :gsub("#$","")
	    :gsub("%*small_break%*","\\n")
	    :gsub("%*large_break%*","\\N")
	    :gsub("%*hard_space%*","\\h")

	    line.text=text
	    subs[i]=line
    end
end

function capital(subs, sel)
	dialog_config=
	{
	    {x=1,y=0,width=1,height=1,class="label",
		label="Words - Capitalize All Words Like in Titles",
	    },
	    {x=1,y=1,width=1,height=1,class="label",
		label="        Lines - Capitalize first word in selected lines",
	    },
	    {x=1,y=2,width=1,height=1,class="label",
		label="                Sentences - Capitalize first word in each sentence",
	    },
	    {x=1,y=3,width=1,height=1,class="label",
		label="                        Lowercase - make text in selected lines lowercase",
	    },
	    {x=1,y=4,width=1,height=1,class="label",
		label="                                Uppercase - MAKE TEXT IN SELECTED LINES UPPERCASE",
	    },
	} 	
	pressed, results=aegisub.dialog.display(dialog_config,
	{"Words","Lines","Sentences","lowercase","UPPERCASE","Cancel"},{close='Cancel'})
	if pressed=="Cancel" then aegisub.cancel() end
	
	if pressed=="Words" then lowercase(subs, sel) capitalize(subs, sel) end
	if pressed=="Lines" then capitalines(subs, sel) end
	if pressed=="Sentences" then sentences(subs, sel) end
	if pressed=="lowercase" then lowercase(subs, sel) end
	if pressed=="UPPERCASE" then uppercase(subs, sel) end
	
	aegisub.set_undo_point(script_name)
	return sel
end

aegisub.register_macro(script_name, script_description, capital)