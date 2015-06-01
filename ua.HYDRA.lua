-- Manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#hydra

script_name="HYDRA"
script_description="A multi-headed typesetting tool"
script_author="unanimated"
script_url1="http://unanimated.xtreemhost.com/ts/hydra.lua"
script_url2="https://raw.githubusercontent.com/unanimated/luaegisub/master/hydra.lua"
script_version="5.0"
script_namespace="ua.HYDRA"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
    script_version="5.0.0"
    depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

re=require'aegisub.re'
clipboard=require("aegisub.clipboard")

order="\\r\\fad\\fade\\an\\q\\blur\\be\\bord\\shad\\fn\\fs\\fsp\\fscx\\fscy\\frx\\fry\\frz\\c\\2c\\3c\\4c\\alpha\\1a\\2a\\3a\\4a\\xbord\\ybord\\xshad\\yshad\\pos\\move\\org\\clip\\iclip\\b\\i\\u\\s\\p"
noneg2="|bord|shad|xbord|ybord|fs|blur|be|fscx|fscy|"

--	HYDRA HEAD 9	--
function hh9(subs,sel)
	-- get colours + tags from input
	getcolours()
	shft=res.int
	tags=""
	tags=gettags(tags)
	transform=tags
	ortags=tags
	ortrans=transform
	retags=tags:gsub("\\","\\\\")
	z0=-1

    for z,i in ipairs(sel) do
	progress("Hydralizing line: "..z.."/"..#sel)
	prog=math.floor((z+0.5)/#sel*100)	aegisub.progress.set(prog)
	line=subs[i]
	text=line.text
	linecheck()
	
	if not text:match("^{\\") then text="{\\hydra}"..text end
	
	-- tag position
	place=res.linetext or ""
	if place:match("*") then pl1,pl2,pl3=place:match("(.*)(%*)(.*)") pla=1 else pla=0 end
	if res.tagpres~="--- presets ---" and res.tagpres~=nil then pla=1 end
	
    -- transforms
    if trans==1 and GO then z0=z0+1
	
	tin=res.trin tout=res.trout
	if res.tend then
	tin=line.end_time-line.start_time-res.trin
	tout=line.end_time-line.start_time-res.trout
	end
	
	if tmode==1 then
	    if res.int~=0 then TF=shft*z0 else TF=0 end
	    tnorm="\\t("..tin+TF..","..tout+TF..","..res.accel..",\\alltagsgohere)}"
	    if place:match("*") then
		initags=text:match("^{\\[^}]-}") or ""
		orig=text
		replace=place:gsub("%*","{"..tnorm)
		v1=text:gsub("%b{}","")
		v2=replace:gsub("%b{}","")
		if v1==v2 then text=initags..textmod(orig,replace) end
	    else
		text=text:gsub("^({\\[^}]*)}","%1"..tnorm)
	    end
	end
	if tmode==2 then text=text:gsub("^(.-\\t%b())",function(t) return t:gsub("%)$","\\alltagsgohere)") end) end
	if tmode==3 then text=text:gsub("(\\t%b())",function(t) return t:gsub("%)$","\\alltagsgohere)") end) end
	if tmode==4 then
	  if res.int~=0 then
    	    tagtab={}
	    for tt in text:gmatch(".-{\\[^}]*}") do table.insert(tagtab,tt) end
	    END=text:match("^.*{\\[^}]*}(.-)$")
	    for t=1,#tagtab do sf=t-1
	      tagtab[t]=tagtab[t]:gsub("({\\[^}]*)}","%1\\t("..tin+shft*sf..","..tout+shft*sf..","..res.accel..",\\alltagsgohere)}")
	    end
	    nt=END
	    for a=#tagtab,1,-1 do nt=tagtab[a]..nt end
	    text=nt
	  else text=text:gsub("({\\[^}]*)}","%1\\t("..tin..","..tout..","..res.accel..",\\alltagsgohere)}")
	  end
	end
	
	if res.add and res.add~=0 then transform=addbyline(transform,ortrans) end
	
	if tmode<4 and res.relative then
	    stags=text:match(STAG) or ""
	    for tag,val in transform:gmatch("(\\%a+)([%d%.%-]+)") do
		if stags:match(tag) then oldval=stags:match(tag.."([%d%.%-]+)")
		    transform=transform:gsub(tag..esc(val),tag..oldval+val)
		end
	    end
	end
	text=text:gsub("\\alltagsgohere",transform)
	if tmode==4 and res.relative then
	    text=text:gsub(ATAG,function(tg)
	      for tag,val in transform:gmatch("(\\%a+)([%d%.%-]+)") do
		if tg:match(tag) then oldval=tg:match(tag.."([%d%.%-]+)")
		    transform2=transform:gsub(tag..esc(val),tag..oldval+val)
		    tg=tg:gsub("(.*\\t.-)"..transform,"%1"..transform2)
		end
	      end
	    return tg end)
	end
	text=text:gsub("\\t%(0,0,1,","\\t(")
	:gsub("\\t(%b())",function(tr) return "\\t"..duplikill(tr) end)
	
    -- non transform, ie. the regular stuff
    elseif GO then z0=z0+1
	-- temporarily block transforms
	text=text:gsub(ATAG,function(tg) return duplikill(tg) end)
	:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
	
	if res.add and res.add~=0 then tags=addbyline(tags,ortags) end
	
	if tags~="" then
	  if pla==1 then
		initags=text:match(STAG) or ""
		orig=text
		v1=orig:gsub("%b{}","")
	    -- BEFORE LAST CHARACTER
	    if res.tagpres=="before last char." then
		text=text:gsub("({\\[^}]-)}(.)$","%1"..tags.."}%2")
		if orig==text then text=text:gsub("([^}])$","{"..tags.."}%1") end
		if orig==text then text=text:gsub("([^}])({[^\\}]-})$","{"..tags.."}%1%2") end
	    -- SOMEWHERE IN THE MIDDLE
	    elseif res.tagpres=="in the middle" or res.tagpres:match("of text") then
		clean=text:gsub("%b{}","") :gsub("%s?\\[Nn]%s?"," ")
		text=text:gsub("%*","_ast_")
		lngth=math.floor(clean:len()*fak)
		text="*"..text
		text=text:gsub("%*({\\[^}]-})","%1*")
		m=0
		if lngth>0 then
		  repeat text=text:gsub("%*(%b{})","%1*") :gsub("%*(.)","%1*") :gsub("%*(%s?\\[Nn]%s?)","%1*") m=m+1 until m==lngth
		end
		text=text:gsub("%*","{"..tags.."}") :gsub("({"..esc(tags).."})(%b{})","%2%1") :gsub("_ast_","*")
	    -- PATTERN
	    elseif res.tagpres=="custom pattern" then
		pl1=esc(pl1)	pl3=esc(pl3)
		text=text:gsub(pl1.."({\\[^}]-)}"..pl3,pl1.."%1"..tags.."}"..pl3)
		if orig==text then text=text:gsub(pl1..pl3,pl1.."{"..tags.."}"..pl3) end
	    -- SECTION
	    elseif res.tagpres=="section" then
		tags2=""
		for tg in tags:gmatch("\\%d?%a+") do
		  txt1=text:match("^.-"..esc(place)) or ""
		  local tg2=txt1:match("^.*("..tg.."[^\\}%a]+).-$") or tg
		  tags2=tags2..tg2
		end
		text=text:gsub("^(.-)("..esc(place).."%s*)(.*)$","%1{"..tags.."}%2{"..tags2.."}%3")
	    -- CHARACTER
	    elseif res.tagpres=="every char." then
		replace=re.sub(text:gsub("%b{}",""),"([\\w[:punct:]\\s])","{"..retags.."}\\1")
		replace=replace:gsub("%b{}%s%b{}\\%b{}N"," \\N"):gsub("%b{}\\%b{}N","\\N")
		v2=replace:gsub("%b{}","")
		if v1==v2 then text=initags..textmod(orig,replace) end
	    -- WORD
	    elseif res.tagpres=="every word" then
		replace=text:gsub("%b{}",""):gsub("%S+","{"..tags.."}%1"):gsub("(%b{})\\N","\\N%1")
		v2=replace:gsub("%b{}","")
		if v1==v2 then text=initags..textmod(orig,replace) end
	    -- TEXT POSITION
	    elseif res.tagpres=="text position" then
		v2=text:gsub("%b{}","")
		pmax=re.find(v2,".")
		pos=tonumber(place:match("^%-?%d+")) or 0
		addpos=tonumber(place:match(".([%+%-]%d+)")) or 0
		if pos<0 then pos=#pmax+pos end
		split=pos+addpos*z0
		if split<0 then split=0 end
		if split<#pmax then
			be4=re.sub(v2,"^(.{"..split.."}).*","\\1")
			aft=re.sub(v2,"^.{"..split.."}","")
			text=be4.."{"..tags.."}"..aft
			if v1==v2 then text=initags..textmod(orig,text) end
		end
	    else
	    -- AT ASTERISK POINT
		replace=place:gsub("%*","{"..tags.."}")
		v2=replace:gsub("%b{}","")
		if v1==v2 then text=initags..textmod(orig,replace) end
	    end
	    text=tagmerge(text)
	    :gsub("{(\\[^}]-)}\\N{(\\[^}]-)}","\\N{%1%2}")
	  else
	    -- REGULAR START TAGS
	    for t in tags:gmatch("\\%d?%a[^\\]*") do text=addtag3(t,text) end
	  end
	  text=text:gsub(ATAG,function(tg) return duplikill(tg) end)
	end
	
	-- strikeout
	if res.strike then
	    if text:match("^{[^}]-\\s[01]") then text=text:gsub("\\s([01])",function(a) return "\\s"..(1-a) end)
	    else strik=text:match("\\s([01])") or "1"
		text=text:gsub("\\s([01])",function(a) return "\\s"..(1-a) end)	:gsub("^({\\[^}]*)}","%1\\s"..strik.."}")
	    end
	end
	-- underline
	if res.under then
	    if text:match("^{[^}]-\\u[01]") then text=text:gsub("\\u([01])",function(a) return "\\u"..(1-a) end)
	    else unter=text:match("\\u([01])") or "1"
		text=text:gsub("\\u([01])",function(a) return "\\u"..(1-a) end)	:gsub("^({\\[^}]*)}","%1\\u"..unter.."}")
	    end
	end
	-- bold
	if res.bolt then
	    if text:match("^{[^}]-\\b[01]") then text=text:gsub("\\b([01])",function(a) return "\\b"..(1-a) end)
	    else bolt=text:match("\\b([01])") or "1"
		text=text:gsub("\\b([01])",function(a) return "\\b"..(1-a) end)	:gsub("^({\\[^}]*)}","%1\\b"..bolt.."}")
	    end
	end
	-- italics
	if res.italix then
	    if text:match("^{[^}]-\\i[01]") then text=text:gsub("\\i([01])",function(a) return "\\i"..(1-a) end)
	    else italix=text:match("\\i([01])") or "1"
		text=text:gsub("\\i([01])",function(a) return "\\i"..(1-a) end)	:gsub("^({\\[^}]*)}","%1\\i"..italix.."}")
	    end
	end
	-- \fad
	if res.fade then
	    IN=res.fadin OUT=res.fadout fGO=1
	    if res.glo then
		if z<#sel then OUT=0 end
		if z>1 then IN=0 end
		if IN==0 and OUT==0 then fGO=0 end
	    end
	    text=text:gsub("\\fad%([%d%.%,]-%)","")
	    if fGO==1 then text=text:gsub("^{\\","{\\fad("..IN..","..OUT..")\\") end
	end
	-- \q2
	if res.q2 then
	    if text:match("\\q2") then text=text:gsub("\\q2","") else text=text:gsub("^{\\","{\\q2\\") end
	end
	-- \an
	if res.an1 then
	    if text:match("\\an%d") then text=text:gsub("\\an(%d)","\\an"..res.an2) else text=text:gsub("^{\\","{\\an"..res.an2.."\\") end
	end
	-- raise layer
	if res.layer then
	if lay+res.layers<0 then t_error("Layers can't be negative.") else lay=lay+res.layers end
	end
	
	-- unblock transforms
	text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
	
    end
    -- the end
	
	text=text:gsub("\\hydra","") :gsub("{}","") :gsub("\\t%([^\\%)]-%)","")
	line.text=text
	line.layer=lay
	subs[i]=line
	end
end

function getcolours()
col={} alfalfa={}
    for c=1,4 do
    colur=res["c"..c]:gsub("#(%x%x)(%x%x)(%x%x).*","&H%3%2%1&")
    table.insert(col,colur)
      if res.alfas then
      alpa=res["c"..c]:match("#%x%x%x%x%x%x(%x%x)")
	if alpa~=nil then
          table.insert(alfalfa,alpa)
          if res["k"..c] then res["arf"..c]=true res["alph"..c]=alfalfa[c] end
	end
      end
      if res.aonly then res["k"..c]=false end
    end
end

function gettags(tags)
	if res.reuse then
		if lastags then
			if res.show then msgbox(lastags) end
			return lastags
		else t_error("No tags to reuse",1) end
	end
	if res["blur1"] then tags=tags.."\\blur"..res["blur2"] end
	if res["be1"] then tags=tags.."\\be"..res["be2"] end
	if res["bord1"] then tags=tags.."\\bord"..res["bord2"] end
	if res["shad1"] then tags=tags.."\\shad"..res["shad2"] end
	if res["fs1"] then tags=tags.."\\fs"..res["fs2"] end
	if res["spac1"] then tags=tags.."\\fsp"..res["spac2"] end
	if res["fscx1"] then tags=tags.."\\fscx"..res["fscx2"] end
	if res["fscy1"] then tags=tags.."\\fscy"..res["fscy2"] end
	if res["xbord1"] then tags=tags.."\\xbord"..res["xbord2"] end
	if res["ybord1"] then tags=tags.."\\ybord"..res["ybord2"] end
	if res["xshad1"] then tags=tags.."\\xshad"..res["xshad2"] end
	if res["yshad1"] then tags=tags.."\\yshad"..res["yshad2"] end
	if res["frz1"] then tags=tags.."\\frz"..res["frz2"] end
	if res["frx1"] then tags=tags.."\\frx"..res["frx2"] end
	if res["fry1"] then tags=tags.."\\fry"..res["fry2"] end
	if res["fax1"] then tags=tags.."\\fax"..res["fax2"] end
	if res["fay1"] then tags=tags.."\\fay"..res["fay2"] end
	if res["k1"] then tags=tags.."\\c"..col[1] end
	if res["k2"] then tags=tags.."\\2c"..col[2] end
	if res["k3"] then tags=tags.."\\3c"..col[3] end
	if res["k4"] then tags=tags.."\\4c"..col[4] end
	if res["arfa"] then tags=tags.."\\alpha&H"..res["alpha"].."&" end
	if res["arf1"] then tags=tags.."\\1a&H"..res["alph1"].."&" end
	if res["arf2"] then tags=tags.."\\2a&H"..res["alph2"].."&" end
	if res["arf3"] then tags=tags.."\\3a&H"..res["alph3"].."&" end
	if res["arf4"] then tags=tags.."\\4a&H"..res["alph4"].."&" end
	lastags=tags
	if res.show then msgbox(tags) end
	if res["moretags"] and res["moretags"]~="\\" then tags=tags..res["moretags"] end
	return tags
end

function addbyline(tags,ortags)
	tags=ortags:gsub("\\(%a%a+)([%d%.%-]+)",function(t,v)
		if t~="an" and t~="fn" then
			nv=rnd2dec(v+res.add*z0)
			if nv<0 and noneg2:match("|"..t.."|") then nv=0 end
			return "\\"..t..nv
		else return "\\"..t..v end
		end)
	return tags
end

function linecheck()
	lay=line.layer	sty=line.style	act=line.actor	eff=line.effect
	GO=nil local lGO,sGO,aGO,eGO
	if res.applay=="All Layers" or tonumber(res.applay)==lay then lGO=true end
	if res.applst=="All Styles" or res.applst==sty then sGO=true end
	if res.applac=="All Actors" or res.applac==act then aGO=true end
	if res.applef=="All Effects" or res.applef==eff then eGO=true end
	if lGO and sGO and aGO and eGO then GO=true end
	if loaded<3 then GO=true end
end

--	GRADIENTS	--
function hydradient(subs,sel)
	GT=res.gtype:match("^....")
	strip=res.stripe
	acc=res.accel
	styleget(subs)
	getcolours()
	tags=""
	tags=gettags(tags)
	if tags=="" then ak() end
	ortags=tags
	retags=tags:gsub("\\","\\\\")
	gcpos=res.linetext gcl=nil
	if res.middle and gcpos:match("*") then gc1,gc2=gcpos:match("^(.-)%*(.-)$") gcl=gc1:len() end
	GBCn=tonumber(gcpos:match("^%d$")) or 1
	if GT=="by l" then GBL=0 z1=0
		for z,i in ipairs(sel) do line=subs[i] linecheck() if GO then GBL=GBL+1 end end
		table.sort(sel,function(a,b) return a>b end)
	end
    for z=#sel,1,-1 do
	i=sel[z]
	line=subs[i]
        text=line.text
	orig=text
	visible=text:gsub("%b{}","")
	text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end) :gsub("\\1c","\\c")
	initags=text:match(STAG) or ""
	sr=stylechk(line.style)
	linecheck()
	
	-- hori/vert
	if GO and GT:match("r") then
	  x1,y1,x2,y2=initags:match("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
	  if not x1 then t_error(res.gtype.." gradient: Missing rectangular clip on line "..z,1) end
	  x1=math.floor(x1) y1=math.floor(y1) x2=math.ceil(x2) y2=math.ceil(y2)
	  if GT=="vert" then total=math.ceil((y2-y1)/strip) else total=math.ceil((x2-x1)/strip) end
	  if total<2 then t_error("This won't create any gradient.\nDecrease the pxl/stripe setting.",true) end
	  
	  for l=1,total do
	    L=l count=total
	    half=math.ceil(total/2)
	    if res.middle then count=half
		if L>half then L=total-L+1 end
	    end
	    stags=initags
	    text2=text
	    for tg,V2 in tags:gmatch("(\\%d?%a+)([^\\]+)") do
		V1=initags:match("^{[^}]-"..tg.."([%d%-&][^\\}]*)") or tag2style(tg,sr)
		if tg:match("fr") and res.short then V1=shortrot(V1) end
		if tg:match("\\[fbs]") then VC=numgrad(V1,V2,count,L,acc) end
		if tg:match("\\[%dac]") then VC=acgrad(V1,V2,count,L,acc) end
		stags=addtag3(tg..VC,stags)
		stags=stags:gsub("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d)
			if GT=="vert" then b=y1+(l-1)*strip d=b+strip a=x1 c=x2 end
			if GT=="hori" then a=x1+(l-1)*strip c=a+strip b=y1 d=y2 end
			return "clip("..a..","..b..","..c..","..d end)
		text2=text2:gsub("(.)("..ATAG..")",function(a,tblok)
			V1i=tblok:match("^{[^}]-"..tg.."([%d%-&][^\\}]*)")
			if V1i and tg:match("\\[fbs]") then VC=numgrad(V1i,V2,count,L,acc) end
			if V1i and tg:match("\\[%dac]") then VC=acgrad(V1i,V2,count,L,acc) end
			tblok=addtag3(tg..VC,tblok)
			return a..tblok end)
	    end
	    l2=line
	    l2.text=text2:gsub(STAG,stags) :gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
	    if l==1 then text=l2.text
	    else subs.insert(i+l-1,l2) end
	  end
	  if z<#sel then for s=z+1,#sel do sel[s]=sel[s]+total-1 end end
	  for s=1,total-1 do table.insert(sel,i+s) end
	end
	
	-- by character
	letrz=re.find(visible,".")
	if GBCn>#letrz then GO=nil end
	if GO and GT=="by c" then
	  LTR={}
	  TAG={}
	  letrz=re.find(visible,".{"..GBCn.."}")
	  rest=re.sub(visible,".{"..GBCn.."}","")
	  for l=1,#letrz do
	    table.insert(LTR,letrz[l].str)
	    table.insert(TAG,"")
	  end
	  if rest~="" then table.insert(LTR,rest) table.insert(TAG,"") end
	  for tg,V2 in tags:gmatch("(\\%d?%a+)([^\\]+)") do
	    V1=text:match("^{[^}]-"..tg.."([%d%-&][^\\}]*)") or tag2style(tg,sr)
	    if tg:match("fr") and res.short then V1=shortrot(V1) end
	    initags=addtag3(tg..V1,initags)
	    for l=2,#LTR do
		L=l count=#LTR
		half=math.ceil(#LTR/2)
		if gcl and gc1..gc2==visible then
			if l<=gcl then count=gcl else count=#LTR-gcl L=#LTR-l+1 end
		elseif res.middle then count=half
			if L>half then L=#LTR-L+1 end
		end
		if tg:match("\\[fbs]") then VC=numgrad(V1,V2,count,L,acc) end
		if tg:match("\\[%dac]") then VC=acgrad(V1,V2,count,L,acc) end
		TAG[l]=TAG[l]..tg..VC
	    end
	  end
	  nt=LTR[1]
	  for l=2,#LTR do nt=nt.."{"..TAG[l].."}"..LTR[l] end
	  text=initags..textmod(orig,nt)
	  text=text:gsub(ATAG,function(tg) return duplikill(tg) end)
	end
	
	-- by line
	if GO and GT=="by l" then z1=z1+1
	   L=z1 total=GBL count=GBL
	   half=math.ceil(total/2)
	   if res.middle then count=half
		if L>half then L=total-L+1 end
	   end
	   stags=initags
	   for tg,V2 in tags:gmatch("(\\%d?%a+)([^\\]+)") do
		V1=initags:match("^{[^}]-"..tg.."([%d%-&][^\\}]*)") or tag2style(tg,sr)
		if tg:match("fr") and res.short then V1=shortrot(V1) end
		if tg:match("\\[fbs]") then VC=numgrad(V1,V2,count,L,acc) end
		if tg:match("\\[%dac]") then VC=acgrad(V1,V2,count,L,acc) end
		stags=addtag3(tg..VC,stags)
	   end
	   text=text:gsub(STAG,stags) :gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
	end
	
	text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
        line.text=text
	subs[i]=line
    end
    return sel
end

--	SPECIAL FUNCTIONS	--
function special(subs,sel)
  SF=res.spec
  if res.spec:match"transform" or res.spec:match"strikeout" then
    styleget(subs)
    getcolours()
    transphorm=""
    transphorm=gettags(transphorm)
  end
  if res.spec=="select overlaps" then sel=selover(subs)
  else
    for z=#sel,1,-1 do
        i=sel[z]
	progress(res.spec..": "..#sel-z.."/"..#sel)
	prog=math.floor((#sel-z+0.5)/#sel*100)
 	aegisub.progress.set(prog)
	line=subs[i]
        text=line.text
	layer=line.layer
	linecheck()
	if GO then res.spec=SF else res.spec="nope" end
	text=text:gsub("\\1c","\\c")
	
	if text:match("\\fscx") and text:match("\\fscy") then
	scalx=text:match("\\fscx([%d%.]+)")
	scaly=text:match("\\fscy([%d%.]+)")
	  if res.spec=="fscx -> fscy" then text=text:gsub("(\\fscy)[%d%.]+","%1"..scalx) end
	  if res.spec=="fscy -> fscx" then text=text:gsub("(\\fscx)[%d%.]+","%1"..scaly) end
	end
	
	if res.spec=="move colour tag to first block" then
		tags=text:match(STAG) or ""
		text=text:gsub(STAG,"")
		klrs=""
		for klr in text:gmatch("\\[1234]?c&H%x+&") do klrs=klrs..klr end
		text=text:gsub("(\\[1234]?c&H%x+&)","") :gsub("{}","")
		text=tags.."{"..klrs.."}"..text
		text=tagmerge(text)
		:gsub(ATAG,function(tg) return duplikill(tg) end)
	end
	
	if res.spec=="convert clip <-> iclip" then
		text=text:gsub("\\(i?)clip",function(k) if k=="" then return "\\iclip" else return "\\clip" end end)
	end
	
	-- CLEAN UP TAGS
	if res.spec=="clean up tags" then
	    text=text:gsub("{\\\\k0}","") :gsub("{(\\[^}]-)} *\\N *{(\\[^}]-)}","\\N{%1%2}")
	    text=tagmerge(text)
	    text=text:gsub("({\\[^}]-){(\\[^}]-})","%1%2") :gsub("{.-\\r","{\\r") :gsub("^{\\r([\\}])","{%1")
	    text=text:gsub("\\fad%(0,0%)","") :gsub(ATAG.."$","")
	     for tgs in text:gmatch(ATAG) do
  	      tgs2=tgs
	      :gsub("\\([\\}])","%1")
	      :gsub("(\\%a+)([%d%-]+%.%d+)",function(a,b) if not a:match("\\fn") then b=rnd2dec(b) end return a..b end)
	      :gsub("(\\%a+)%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c) b=rnd2dec(b) c=rnd2dec(c) return a.."("..b..","..c..")" end)
	      :gsub("(\\%a+)%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d,e)
		b=rnd2dec(b) c=rnd2dec(c) d=rnd2dec(d) e=rnd2dec(e) return a.."("..b..","..c..","..d..","..e end)
	      tgs2=duplikill(tgs2)
	      tgs2=extrakill(tgs2)
	      text=text:gsub(esc(tgs),tgs2)
	      :gsub("^({\\[^}]-)\\frx0\\fry0","%1")
	     end
	end
	
	-- SORT TAGS
	if res.spec=="sort tags in set order" then
	  text=text:gsub("\\a6","\\an8") :gsub("\\1c","\\c")
	  -- run for each set of tags
	  for tags in text:gmatch(ATAG) do
	  orig=tags
	  tags=tags:gsub("{.-\\r","{\\r")
	    -- save & nuke transforms
	    trnsfrm=""
	    for t in tags:gmatch("\\t%b()") do trnsfrm=trnsfrm..t end
	    tags=tags:gsub("\\t%b()","")
	  ord=""
	    -- go through tags, save them in order, and delete from tags
	      for tg in order:gmatch("\\[%a%d]+") do
		tag=tags:match("("..tg.."[^\\}]-)[\\}]")
		if tg=="\\fs" then tag=tags:match("(\\fs%d[^\\}]-)[\\}]") end
		if tg=="\\fad" then tag=tags:match("(\\fad%([^\\}]-)[\\}]") end
		if tg=="\\c" then tag=tags:match("(\\c&[^\\}]-)[\\}]") end
		if tg=="\\i" then tag=tags:match("(\\i[^%a\\}]-)[\\}]") end
		if tg=="\\s" then tag=tags:match("(\\s[^%a\\}]-)[\\}]") end
		if tg=="\\p" then tag=tags:match("(\\p[^%a\\}]-)[\\}]") end
		if tag then ord=ord..tag etag=esc(tag) tags=tags:gsub(etag,"") end
	      end
	    -- attach whatever got left
	    if tags~="{}" then ord=ord..tags:match("{(.-)}") end
	    ordered="{"..ord..trnsfrm.."}"
	    text=text:gsub(esc(orig),ordered)
	  end
	end
	
	-- CLIP TO DRAWING
	if res.spec=="convert clip to drawing" then
	  if not text:match("\\clip") then ak() end
	  text=text:gsub("^({\\[^}]-}).*","%1")
	  text=text:gsub("^({[^}]*)\\clip%(m(.-)%)([^}]*)}","%1%3\\p1}m%2")
	  if text:match("\\pos") then
	    local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	    xx=round(xx) yy=round(yy)
	    ctext=text:match("}m ([%d%a%s%-]+)")
	    if not ctext then t_error("Vectorial clip missing.",1) end
	    ctext2=ctext:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return a-xx.." "..b-yy end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub(ctext,ctext2)
	  end
	  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
	  if text:match("\\an") then text=text:gsub("\\an%d","\\an7") else text=text:gsub("^{","{\\an7") end
	  if text:match("\\fscx") then text=text:gsub("(\\fscx)[%d%.]+","%1100") else text=text:gsub("\\p1","\\fscx100%1") end
	  if text:match("\\fscy") then text=text:gsub("(\\fscy)[%d%.]+","%1100") else text=text:gsub("\\p1","\\fscy100%1") end
	end
	
	-- DRAWING TO CLIP
	if res.spec=="convert drawing to clip" then
	  if not text:match("\\p1") then ak() end
	  text=text:gsub("^({[^}]*)\\p1([^}]-})(m [^{]*)","%1\\clip(%3)%2")
	  scx=text:match("\\fscx([%d%.]+)") or 100
	  scy=text:match("\\fscy([%d%.]+)") or 100
	  if text:match("\\pos") then
	    local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	    xx=round(xx) yy=round(yy)
	    ctext=text:match("\\clip%(m ([^%)]+)%)")
	    ctext2=ctext:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return round(a*scx/100+xx).." "..round(b*scy/100+yy) end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub(ctext,ctext2)
	  end
	  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
	end
	
	-- STRIKEOUT TO SELECTED
	if res.spec=="convert strikeout to selected" then
	  ST1=transphorm ST2=transphorm:gsub("(\\%d?%a+)[^\\]+","%1")
	  text=text:gsub("\\s1",ST1):gsub("\\s0",ST2)
	end
	
	-- 3D SHADOW
	if res.spec=="create 3D effect from shadow" then
	  xshad=text:match("^{[^}]-\\xshad([%d%.%-]+)")	or 0	ax=math.abs(xshad)
	  yshad=text:match("^{[^}]-\\yshad([%d%.%-]+)")	or 0	ay=math.abs(yshad)
	  if ax>ay then lay=math.floor(ax) else lay=math.floor(ay) end
	
	  text2=text:gsub("^({\\[^}]-)}","%1\\3a&HFF&}")	:gsub("\\3a&H%x%x&([^}]-)(\\3a&H%x%x&)","%1%2")
	
	  for l=lay,1,-1 do
	    line2=line	    f=l/lay
	    txt=text2	    if l==1 then txt=text end
	    line2.text=txt
	    :gsub("\\xshad([%d%.%-]+)",function(a) xx=tostring(f*a) xx=xx:gsub("([%d%-]+%.%d%d)%d+","%1") return "\\xshad"..xx end)
	    :gsub("\\yshad([%d%.%-]+)",function(a) yy=tostring(f*a) yy=yy:gsub("([%d%-]+%.%d%d)%d+","%1") return "\\yshad"..yy end)
	    line2.layer=layer+(lay-l)
	    subs.insert(i+1,line2)
	  end
	
	  if xshad~=0 and yshad~=0 then subs.delete(i) end
	end
	
	-- CLIP GRID
	if res.spec=="chequerboard clip" then
	    text=text:gsub("^({[^}]-)\\clip%([^%)]+%)","%1")
	    :gsub("^({\\[^}]-)}","%1\\clip(m 100 100 l 140 100 l 140 180 l 180 180 l 180 140 l 100 140 m 180 100 l 220 100 l 220 180 l 260 180 l 260 140 l 180 140 m 260 100 l 300 100 l 300 180 l 340 180 l 340 140 l 260 140 m 340 100 l 380 100 l 380 180 l 420 180 l 420 140 l 340 140 m 420 100 l 460 100 l 460 180 l 500 180 l 500 140 l 420 140 m 500 100 l 540 100 l 540 180 l 580 180 l 580 140 l 500 140 m 580 100 l 620 100 l 620 180 l 660 180 l 660 140 l 580 140 m 660 100 l 700 100 l 700 180 l 740 180 l 740 140 l 660 140 m 740 100 l 780 100 l 780 180 l 820 180 l 820 140 l 740 140 m 820 100 l 860 100 l 860 180 l 900 180 l 900 140 l 820 140 m 900 100 l 940 100 l 940 180 l 980 180 l 980 140 l 900 140 m 980 100 l 1020 100 l 1020 180 l 1060 180 l 1060 140 l 980 140 m 100 180 l 140 180 l 140 260 l 180 260 l 180 220 l 100 220 m 180 180 l 220 180 l 220 260 l 260 260 l 260 220 l 180 220 m 260 180 l 300 180 l 300 260 l 340 260 l 340 220 l 260 220 m 340 180 l 380 180 l 380 260 l 420 260 l 420 220 l 340 220 m 420 180 l 460 180 l 460 260 l 500 260 l 500 220 l 420 220 m 500 180 l 540 180 l 540 260 l 580 260 l 580 220 l 500 220 m 580 180 l 620 180 l 620 260 l 660 260 l 660 220 l 580 220 m 660 180 l 700 180 l 700 260 l 740 260 l 740 220 l 660 220 m 740 180 l 780 180 l 780 260 l 820 260 l 820 220 l 740 220 m 820 180 l 860 180 l 860 260 l 900 260 l 900 220 l 820 220 m 900 180 l 940 180 l 940 260 l 980 260 l 980 220 l 900 220 m 980 180 l 1020 180 l 1020 260 l 1060 260 l 1060 220 l 980 220 m 100 260 l 140 260 l 140 340 l 180 340 l 180 300 l 100 300 m 180 260 l 220 260 l 220 340 l 260 340 l 260 300 l 180 300 m 260 260 l 300 260 l 300 340 l 340 340 l 340 300 l 260 300 m 340 260 l 380 260 l 380 340 l 420 340 l 420 300 l 340 300 m 420 260 l 460 260 l 460 340 l 500 340 l 500 300 l 420 300 m 500 260 l 540 260 l 540 340 l 580 340 l 580 300 l 500 300 m 580 260 l 620 260 l 620 340 l 660 340 l 660 300 l 580 300 m 660 260 l 700 260 l 700 340 l 740 340 l 740 300 l 660 300 m 740 260 l 780 260 l 780 340 l 820 340 l 820 300 l 740 300 m 820 260 l 860 260 l 860 340 l 900 340 l 900 300 l 820 300 m 900 260 l 940 260 l 940 340 l 980 340 l 980 300 l 900 300 m 980 260 l 1020 260 l 1020 340 l 1060 340 l 1060 300 l 980 300 m 100 340 l 140 340 l 140 420 l 180 420 l 180 380 l 100 380 m 180 340 l 220 340 l 220 420 l 260 420 l 260 380 l 180 380 m 260 340 l 300 340 l 300 420 l 340 420 l 340 380 l 260 380 m 340 340 l 380 340 l 380 420 l 420 420 l 420 380 l 340 380 m 420 340 l 460 340 l 460 420 l 500 420 l 500 380 l 420 380 m 500 340 l 540 340 l 540 420 l 580 420 l 580 380 l 500 380 m 580 340 l 620 340 l 620 420 l 660 420 l 660 380 l 580 380 m 660 340 l 700 340 l 700 420 l 740 420 l 740 380 l 660 380 m 740 340 l 780 340 l 780 420 l 820 420 l 820 380 l 740 380 m 820 340 l 860 340 l 860 420 l 900 420 l 900 380 l 820 380 m 900 340 l 940 340 l 940 420 l 980 420 l 980 380 l 900 380 m 980 340 l 1020 340 l 1020 420 l 1060 420 l 1060 380 l 980 380 m 100 420 l 140 420 l 140 500 l 180 500 l 180 460 l 100 460 m 180 420 l 220 420 l 220 500 l 260 500 l 260 460 l 180 460 m 260 420 l 300 420 l 300 500 l 340 500 l 340 460 l 260 460 m 340 420 l 380 420 l 380 500 l 420 500 l 420 460 l 340 460 m 420 420 l 460 420 l 460 500 l 500 500 l 500 460 l 420 460 m 500 420 l 540 420 l 540 500 l 580 500 l 580 460 l 500 460 m 580 420 l 620 420 l 620 500 l 660 500 l 660 460 l 580 460 m 660 420 l 700 420 l 700 500 l 740 500 l 740 460 l 660 460 m 740 420 l 780 420 l 780 500 l 820 500 l 820 460 l 740 460 m 820 420 l 860 420 l 860 500 l 900 500 l 900 460 l 820 460 m 900 420 l 940 420 l 940 500 l 980 500 l 980 460 l 900 460 m 980 420 l 1020 420 l 1020 500 l 1060 500 l 1060 460 l 980 460 m 100 500 l 140 500 l 140 580 l 180 580 l 180 540 l 100 540 m 180 500 l 220 500 l 220 580 l 260 580 l 260 540 l 180 540 m 260 500 l 300 500 l 300 580 l 340 580 l 340 540 l 260 540 m 340 500 l 380 500 l 380 580 l 420 580 l 420 540 l 340 540 m 420 500 l 460 500 l 460 580 l 500 580 l 500 540 l 420 540 m 500 500 l 540 500 l 540 580 l 580 580 l 580 540 l 500 540 m 580 500 l 620 500 l 620 580 l 660 580 l 660 540 l 580 540 m 660 500 l 700 500 l 700 580 l 740 580 l 740 540 l 660 540 m 740 500 l 780 500 l 780 580 l 820 580 l 820 540 l 740 540 m 820 500 l 860 500 l 860 580 l 900 580 l 900 540 l 820 540 m 900 500 l 940 500 l 940 580 l 980 580 l 980 540 l 900 540 m 980 500 l 1020 500 l 1020 580 l 1060 580 l 1060 540 l 980 540)}")
	end
	
	-- BACK AND FORTH TRANSFORM
	if res.spec=="back and forth transform" and res.int>0 then
	    if defaref and line.style=="Default" then sr=defaref
	    else sr=stylechk(line.style) end
	    -- clean up existing transforms
	    if text:match("^{[^}]*\\t") then text=text:gsub(STAG,function(tg) return cleantr(tg) end) end
	    startags=text:match(STAG)
	    tags1=""
	    for tg in transphorm:gmatch("\\[1234]?%a+") do
	      val1=nil
	      if not startags:match(tg.."[%d%-&%(]") then
		if tg=="\\clip" then val1="(0,0,1280,720)" else val1=tag2style(tg,sr) end
		if val1 then tags1=tags1..tg..val1 text=text:gsub("^({\\[^}]-)}","%1"..tg..val1.."}") end
	      else
	      val1=startags:match(tg.."([^\\}]+)")
	      tags1=tags1..tg..val1
	      end
	    end
	    int=res.int
	    tags2=transphorm
	    dur=line.end_time-line.start_time
	    count=math.ceil(dur/int)
	    t=1		tin=0		tout=tin+int
	    if not text:match("^{\\") then text="{\\}"..text end
	    -- main function
	    while t<=math.ceil(count/2) do
		text=text:gsub("^({\\[^}]*)}","%1\\t("..tin..","..tout..","..tags2..")}")
		if tin+int<dur then text=text:gsub("^({\\[^}]*)}","%1\\t("..tin+int..","..tout+int..","..tags1..")}") end
		tin=tin+int+int
		tout=tin+int
		t=t+1
	    end
	    text=text:gsub("\\([\\}])","%1")
	end
	
	-- SPLIT LINE IN 3 PARTS
	if res.spec=="split line in 3 parts" then
		start=line.start_time
		endt=line.end_time
		effect=line.effect
		-- line 3
		line3=line
		line3.start_time=endt-res.trout
		line3.effect=effect.." pt.3"
		if line3.start_time~=line3.end_time then
		subs.insert(i+1,line3) end
		-- line 2
		line2=line
		line2.start_time=start+res.trin
		line2.end_time=endt-res.trout
		line2.effect=effect.." pt.2"
		subs.insert(i+1,line2)
		-- line 1
		line.start_time=start
		line.end_time=start+res.trin
		line.effect=effect.." pt.1"
	end
	
	if res.spec~="create 3D effect from shadow" then
	line.text=text	subs[i]=line
	if res.spec=="split line in 3 parts" and line.start_time==line.end_time then subs.delete(i) end
	end
    end
  end
  return sel
end

function selover(subs,sel)
  local dialogue={}
  for i,line in ipairs(subs) do
    if line.class=="dialogue" then line.i=i table.insert(dialogue,line) end
  end
  table.sort(dialogue,function(a,b) return a.start_time<b.start_time or (a.start_time==b.start_time and a.i<b.i) end)
  local end_time=0
  local overlaps={}
  for i=1,#dialogue do
    local line=dialogue[i]
    if line.start_time>=end_time then
      end_time=line.end_time
    else
      table.insert(overlaps,line.i)
    end
  end
  sel=overlaps
  return sel
end


--	reanimatools	--
function round(num) num=math.floor(num+0.5) return num end

function rnd2dec(num)
num=math.floor((num*100)+0.5)/100
return num
end

function addtag3(tg,txt)
	no_tf=txt:gsub("\\t%b()","")
	tgt=tg:match("(\\%d?%a+)[%d%-&]") val="[%d%-&]"
	if not tgt then tgt=tg:match("(\\%d?%a+)%b()") val="%b()" end
	if not tgt then tgt=tg:match("\\fn") val="" end
	if not tgt then t_error("adding tag '"..tg.."' failed.") end
	if tgt:match("clip") then txt,r=txt:gsub("^({[^}]-)\\i?clip%b()","%1"..tg)
		if r==0 then txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
	elseif no_tf:match("^({[^}]-)"..tgt..val) then txt=txt:gsub("^({[^}]-)"..tgt..val.."[^\\}]*","%1"..tg)
	elseif not txt:match("^{\\") then txt="{"..tg.."}"..txt
	elseif txt:match("^{[^}]-\\t") then txt=txt:gsub("^({[^}]-)\\t","%1"..tg.."\\t")
	else txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
return txt
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function tagmerge(text) repeat text,r=text:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return text end

function tag2style(tg,sr)
	noneg="\\bord\\shad\\xbord\\ybord\\fs\\blur\\be\\fscx\\fscy"
	val=0
	if tg=="\\fs" then val=sr.fontsize end
	if tg=="\\fsp" then val=sr.spacing end
	if tg=="\\fscx" then val=sr.scale_x end
	if tg=="\\fscy" then val=sr.scale_y end
	if tg:match"\\[xy]?bord" then val=sr.outline end
	if tg:match"\\[xy]?shad" then val=sr.shadow end
	if tg=="\\frz" then val=sr.angle end
	if val<0 and noneg:match(tg) then val=0 end
	if tg=="\\c" then val=sr.color1:gsub("H%x%x","H") end
	if tg=="\\2c" then val=sr.color2:gsub("H%x%x","H") end
	if tg=="\\3c" then val=sr.color3:gsub("H%x%x","H") end
	if tg=="\\4c" then val=sr.color4:gsub("H%x%x","H") end
	if tg=="\\1a" then val=sr.color1:match("H%x%x") end
	if tg=="\\2a" then val=sr.color2:match("H%x%x") end
	if tg=="\\3a" then val=sr.color3:match("H%x%x") end
	if tg=="\\4a" then val=sr.color4:match("H%x%x") end
	if tg=="\\alpha" then val="&H00&" end
return val
end

function numgrad(V1,V2,total,l,acc)
	acc=acc or 1
	acc_fac=(l-1)^acc/(total-1)^acc
	VC=rnd2dec(acc_fac*(V2-V1)+V1)
return VC
end

function acgrad(C1,C2,total,l,acc)
	acc=acc or 1
	acc_fac=(l-1)^acc/(total-1)^acc
	B1,G1,R1=C1:match("(%x%x)(%x%x)(%x%x)")
	B2,G2,R2=C2:match("(%x%x)(%x%x)(%x%x)")
	A1=C1:match("(%x%x)") R1=R1 or A1
	A2=C2:match("(%x%x)") R2=R2 or A2
	nR1=(tonumber(R1,16))  nR2=(tonumber(R2,16))
	R=acc_fac*(nR2-nR1)+nR1
	R=tohex(round(R))
	CC="&H"..R.."&"
	if B1 then
	nG1=(tonumber(G1,16))  nG2=(tonumber(G2,16))
	nB1=(tonumber(B1,16))  nB2=(tonumber(B2,16))
	G=acc_fac*(nG2-nG1)+nG1
	B=acc_fac*(nB2-nB1)+nB1
	G=tohex(round(G))
	B=tohex(round(B))
	CC="&H"..B..G..R.."&"
	end
return CC
end

function tohex(num)
n1=math.floor(num/16)
n2=num%16
num=tohex1(n1)..tohex1(n2)
return num
end

function tohex1(num)
HEX={"1","2","3","4","5","6","7","8","9","A","B","C","D","E"}
if num<1 then num="0" elseif num>14 then num="F" else num=HEX[num] end
return num
end

function shortrot(v)
	if tonumber(v)>180 then v=v-360 end
	return v
end

function trem(tags)
	trnsfrm=""
	for t in tags:gmatch("\\t%b()") do trnsfrm=trnsfrm..t end
	tags=tags:gsub("\\t%b()","")
	return tags
end

function cleantr(tags)
	trnsfrm=""
	for t in tags:gmatch("\\t%b()") do trnsfrm=trnsfrm..t end
	tags=tags:gsub("\\t%b()","")
	:gsub("^({[^}]*)}","%1"..trnsfrm.."}")
	return tags
end

tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
tags3={"pos","move","org","fad"}

function duplikill(tagz)
	tagz=tagz:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
	for i=1,#tags1 do
	    tag=tags1[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%2%1") until c==0
	end
	tagz=tagz:gsub("\\1c&","\\c&")
	for i=1,#tags2 do
	    tag=tags2[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1") until c==0
	end
	repeat tagz,c=tagz:gsub("\\fn[^\\}]+([^}]-)(\\fn[^\\}]+)","%2%1") until c==0
	tagz=tagz:gsub("(|i?clip%(%A-%))(.-)(\\i?clip%(%A-%))","%2%3")
	:gsub("(\\i?clip%b())(.-)(\\i?clip%b())",function(a,b,c)
	    if a:match("m") and c:match("m") or not a:match("m") and not c:match("m") then return b..c else return a..b..c end end)
	tagz=tagz:gsub("|","\\"):gsub("\\t%([^\\%)]-%)","")
	return tagz
end

function extrakill(text,o)
	for i=1,#tags3 do
	    tag=tags3[i]
	    if o==2 then
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%3%2") until c==0
	    else
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%1%2") until c==0
	    end
	end
	repeat text,c=text:gsub("(\\pos[^\\}]+)([^}]-)(\\move[^\\}]+)","%1%2") until c==0
	repeat text,c=text:gsub("(\\move[^\\}]+)([^}]-)(\\pos[^\\}]+)","%1%2") until c==0
	return text
end

function textmod(orig,text)
if text=="" then return orig end
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
	vis=text:gsub("%b{}","")
	ltrmatches=re.find(vis,".")
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match(STAG) or ""
	text=text:gsub(STAG,"") :gsub("{[^\\}]-}","")
	count=0
	for seq in orig:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
	count=0
	for seq in text:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
    newline=""
    for i=1,#tk do
	newline=newline..tk[i]
	newt=""
	for n,t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext=stags..newline
    text=newtext:gsub("{}","")
    return text
end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function msgbox(message,h,w)
  pres,rez=ADD({{width=w or 24,height=h or 5,name="msg",class="textbox",value=message}},{"OK","clip bored"},{close='OK'})
  if pres=="clip bored" then clipboard.set(rez.msg) end
end

function styleget(subs)
    styles={}
    for i=1,#subs do
        if subs[i].class=="style" then
	    table.insert(styles,subs[i])
	end
	if subs[i].class=="dialogue" then break end
    end
end

function stylechk(sn)
    for i=1,#styles do
	if sn==styles[i].name then
	    sr=styles[i]
	    if sr.name=="Default" then defaref=styles[i] end
	    break
	end
    end
    if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
    return sr
end

function tf(val)
    if val==true then ret="true"
    elseif val==false then ret="false"
    else ret=val end
    return ret
end

function detf(txt)
    if txt=="true" then ret=true
    elseif txt=="false" then ret=false
    else ret=txt end
    return ret
end

function selcheck()
	SC=0
	for k,v in ipairs(hh_gui) do
	  if v.class=="checkbox" and v.y<10 and res[v.name] then SC=1 end
	  if v.name=="reuse" and res.reuse then SC=1 end
	  if v.name=="moretags" and res.moretags:len()>1 then SC=1 end
	end
	if SC==0 then t_error("No tags selected",1) end
end

--	Config Stuff	--
function saveconfig()
hydraconf="Hydra 4+ Config\n\n"
  for key,v in ipairs(hh_gui) do
    if v.class:match"edit" or v.class=="dropdown" or v.class=="coloralpha" then
      if v.name~="linetext" and v.name~="herp" and not v.name:match"app" then
	hydraconf=hydraconf..v.name..":"..res[v.name].."\n"
      end
    end
    if v.class=="checkbox" and v.name~="save" then
      hydraconf=hydraconf..v.name..":"..tf(res[v.name]).."\n"
    end
  end
file=io.open(hydrakonfig,"w")
file:write(hydraconf)
file:close()
ADD({{class="label",label="Config saved to:\n"..hydrakonfig}},{"OK"},{close='OK'})
end

function loadconfig()
file=io.open(hydrakonfig)
    if file~=nil then
	konf=file:read("*all")
	sm=tonumber(konf:match("smode:(.-)\n"))
	io.close(file)
	for k,v in ipairs(hh1) do
	  if v.class:match"edit" or v.class=="checkbox" or v.class=="coloralpha" then
	    if konf:match(v.name) then v.value=detf(konf:match(v.name..":(.-)\n")) end
	  end
	end
	for k,v in ipairs(hh2) do
	  if v.class:match"edit" or v.class=="checkbox" or v.class=="dropdown" then
	    if konf:match(v.name) then v.value=detf(konf:match(v.name..":(.-)\n")) end
	  end
	end
	for k,v in ipairs(hh3) do
	  if v.class:match"edit" or v.class=="checkbox" or v.class=="dropdown" then
	    if konf:match(v.name) then v.value=detf(konf:match(v.name..":(.-)\n")) end
	    if hydralast then
	      if v.name=="gtype" and res.gtype then v.value=hydralast.gtype end
	      if v.name=="accel" and res.accel then v.value=hydralast.accel end
	      if v.name=="stripe" and res.stripe then v.value=hydralast.stripe end
	      if v.name=="middle" and res.middle then v.value=hydralast.middle end
	    end
	  end
	end
    else sm=1
    end
end

hydraulics={"A multi-headed typesetting tool","Nine heads typeset better than one.","Eliminating the typing part of typesetting","Mass-production of typesetting tags","Hydraulic typesetting machinery","Making sure your subtitles aren't dehydrated","Making typesetting so easy that even you can do it!","A monstrous typesetting tool","A deadly typesetting beast","Building monstrous scripts with ease","For irrational typesetting wizardry","Building a Wall of Tags","The Checkbox Onslaught","HYperactively DRAstic","HYperdimensional DRAma","I can has moar tagz?","Transforming the subtitle landscape"}

function hydra(subs,sel)
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
ATAG="{%*?\\[^}]-}"
STAG="^{\\[^}]-}"
COMM="{[^\\}]-}"
hydrakonfig=ADP("?user").."\\hydra4.conf"
app_lay={"All Layers"}
app_sty={"All Styles"}
app_act={"All Actors"}
app_eff={"All Effects"}
for z,i in ipairs(sel) do
	L=subs[i]
	layr=L.layer
	stl=L.style
	akt=L.actor
	eph=L.effect
	asdf=0
	for a=1,#app_lay do if layr==app_lay[a] then asdf=1 end end
	if asdf==0 then table.insert(app_lay,layr) end
	asdf=0
	for a=1,#app_sty do if stl==app_sty[a] then asdf=1 end end
	if asdf==0 then table.insert(app_sty,stl) end
	asdf=0
	for a=1,#app_act do if akt==app_act[a] then asdf=1 end end
	if asdf==0 then table.insert(app_act,akt) end
	asdf=0
	for a=1,#app_eff do if eph==app_eff[a] then asdf=1 end end
	if asdf==0 then table.insert(app_eff,eph) end
end
hr=math.random(1,#hydraulics)
if #sel==0 then t_error("No selection",1) end
oneline=subs[sel[1]]
linetext=oneline.text:gsub("%b{}","")
alfas={"00","10","20","30","40","50","60","70","80","90","A0","B0","C0","D0","E0","F0","F8","FF"}
hh1={
	{x=0,y=0,width=5,class="label",label="Hydra "..script_version.."  -  "..hydraulics[hr]},
	{x=6,y=0,width=2,class="label",name="info",label="Selected lines: "..#sel},
	
	{x=0,y=1,class="checkbox",name="k1",label="Primary:"},
	{x=1,y=1,class="coloralpha",name="c1"},
	{x=0,y=2,class="checkbox",name="k3",label="Border:"},
	{x=1,y=2,class="coloralpha",name="c3"},
	{x=0,y=3,class="checkbox",name="k4",label="Shadow:"},
	{x=1,y=3,class="coloralpha",name="c4"},
	{x=0,y=4,class="checkbox",name="k2",label="useless... (2c):"},
	{x=1,y=4,class="coloralpha",name="c2"},
	{x=0,y=5,class="checkbox",name="alfas",label="Include alphas",
	hint="Include alphas from colours pickers.\nRequires Aegisub r7993 or higher."},
	{x=1,y=5,class="checkbox",name="aonly",label="only",hint="Use only alphas, not colours"},
	{x=0,y=6,class="checkbox",name="italix",label="Italics"},
	{x=1,y=6,class="checkbox",name="bolt",label="Bold"},
	{x=0,y=7,class="checkbox",name="under",label="Underline"},
	{x=1,y=7,class="checkbox",name="strike",label="Strike"},
	
	{x=2,y=1,class="checkbox",name="bord1",label="\\bord"},
	{x=3,y=1,width=2,class="floatedit",name="bord2",value=0},
	{x=2,y=2,class="checkbox",name="shad1",label="\\shad"},
	{x=3,y=2,width=2,class="floatedit",name="shad2",value=0},
	{x=2,y=3,class="checkbox",name="fs1",label="\\fs"},
	{x=3,y=3,width=2,class="floatedit",name="fs2",value=50},
	{x=2,y=4,class="checkbox",name="spac1",label="\\fsp"},
	{x=3,y=4,width=2,class="floatedit",name="spac2",value=1},
	{x=2,y=5,class="checkbox",name="blur1",label="\\blur"},
	{x=3,y=5,width=2,class="floatedit",name="blur2",value=0.5},
	{x=2,y=6,class="checkbox",name="be1",label="\\be"},
	{x=3,y=6,width=2,class="floatedit",name="be2",value=1},
	{x=2,y=7,class="checkbox",name="fscx1",label="\\fscx"},
	{x=3,y=7,width=2,class="floatedit",name="fscx2",value=100},
	{x=2,y=8,class="checkbox",name="fscy1",label="\\fscy"},
	{x=3,y=8,width=2,class="floatedit",name="fscy2",value=100},
	
	{x=5,y=1,class="checkbox",name="xbord1",label="\\xbord"},
	{x=6,y=1,width=2,class="floatedit",name="xbord2"},
	{x=5,y=2,class="checkbox",name="ybord1",label="\\ybord"},
	{x=6,y=2,width=2,class="floatedit",name="ybord2"},
	{x=5,y=3,class="checkbox",name="xshad1",label="\\xshad"},
	{x=6,y=3,width=2,class="floatedit",name="xshad2"},
	{x=5,y=4,class="checkbox",name="yshad1",label="\\yshad"},
	{x=6,y=4,width=2,class="floatedit",name="yshad2"},
	{x=5,y=5,class="checkbox",name="fax1",label="\\fax"},
	{x=6,y=5,width=2,class="floatedit",name="fax2",value=0.05},
	{x=5,y=6,class="checkbox",name="fay1",label="\\fay"},
	{x=6,y=6,width=2,class="floatedit",name="fay2",value=0.05},
	{x=5,y=7,class="checkbox",name="frx1",label="\\frx"},
	{x=6,y=7,width=2,class="floatedit",name="frx2"},
	{x=5,y=8,class="checkbox",name="fry1",label="\\fry"},
	{x=6,y=8,width=2,class="floatedit",name="fry2"},
	{x=5,y=9,class="checkbox",name="frz1",label="\\frz"},
	{x=6,y=9,width=2,class="floatedit",name="frz2"},
	
	{x=1,y=8,class="checkbox",name="q2",label="\\q2"},
	{x=0,y=8,class="checkbox",name="glo",label="Global fade",hint="global fade - IN on first line, OUT on last line"},
	{x=0,y=9,class="checkbox",name="fade",label="\\fad (in,out)"},
	{x=1,y=9,width=2,class="floatedit",name="fadin",min=0,hint="fade in"},
	{x=3,y=9,width=2,class="floatedit",name="fadout",min=0,hint="fade out"},
}

hh2={
	{x=8,y=0,class="label",name="startmode",label="Start mode"},
	{x=9,y=0,class="dropdown",name="smode",items={"1","2","3"},value="1"},
	{x=8,y=1,class="checkbox",name="layer",label="layer"},
	{x=9,y=1,class="dropdown",name="layers",items={"-5","-4","-3","-2","-1","+1","+2","+3","+4","+5"},value="+1"},
	{x=8,y=2,class="checkbox",name="arfa",label="\\alpha"},
	{x=9,y=2,class="dropdown",name="alpha",items=alfas,value="00"},
	{x=8,y=3,class="checkbox",name="arf1",label="\\1a"},
	{x=9,y=3,class="dropdown",name="alph1",items=alfas,value="00"},
	{x=8,y=4,class="checkbox",name="arf2",label="\\2a"},
	{x=9,y=4,class="dropdown",name="alph2",items=alfas,value="00"},
	{x=8,y=5,class="checkbox",name="arf3",label="\\3a"},
	{x=9,y=5,class="dropdown",name="alph3",items=alfas,value="00"},
	{x=8,y=6,class="checkbox",name="arf4",label="\\4a"},
	{x=9,y=6,class="dropdown",name="alph4",items=alfas,value="00"},
	{x=8,y=7,class="checkbox",name="an1",label="\\an"},
	{x=9,y=7,class="dropdown",name="an2",items={"1","2","3","4","5","6","7","8","9"},value="5"},
	
	{x=8,y=8,width=2,class="label",label="Add with each line:"},
	{x=8,y=9,width=2,class="floatedit",name="add",hint="works with regular tags,\ni.e. the middle two columns"},
	{x=0,y=10,class="label",label="Additional tags:"},
	{x=1,y=10,width=5,class="edit",name="moretags",value="\\"},
	{x=6,y=10,class="checkbox",name="show",label="show  ",hint="Show the tags being applied.\nNote: only transformable tags."},
	{x=7,y=10,class="checkbox",name="reuse",label="reuse  ",hint="Reuse the (transformable) tags from last run.\nCan be used with a different button\nor 'apply to' restriction."},
}

hh3={
	{x=0,y=11,class="label",label="Tag position*:"},
	{x=1,y=11,width=5,class="edit",name="linetext",value=linetext,hint="Place an asterisk where you want the tags."},
	{x=6,y=11,width=2,class="dropdown",name="tagpres",items={"--- presets ---","before last char.","in the middle","1/4 of text","3/4 of text","1/8 of text","3/8 of text","5/8 of text","7/8 of text","custom pattern","section","every char.","every word","text position"},value="--- presets ---",hint="presets/options for tag position"},
	
	{x=0,y=12,class="label",label="Transform t1,t2:"},
	{x=1,y=12,width=2,class="floatedit",name="trin"},
	{x=3,y=12,width=2,class="floatedit",name="trout"},
	{x=5,y=12,width=3,class="checkbox",name="tend",label="Count times from end"},
	
	{x=0,y=13,class="label",label="Transform mode:"},
	{x=1,y=13,width=2,class="dropdown",name="tmode",items={"normal","add2first","add2all","all tag blocks"},value="normal",hint="new \\t  |  add to first \\t  |  add to all \\t  |  add to all {\\tag blocks}"},
	{x=3,y=13,width=2,class="checkbox",name="relative",label="Relative transform",
	hint="Example:\ntag: \\frz30\ninput: 60\nresult: \\t(\\frz90)"},
	{x=5,y=13,class="label",label="       Accel:"},
	
	{x=0,y=14,class="label",label="Shift times/interval:"},
	{x=1,y=14,width=2,class="floatedit",name="int",value=0,hint="'normal' transform: shift \\t times each line\n'all tag blocks': shift \\t times each block\n'back and forth transform': interval"},
	{x=6,y=13,width=2,class="floatedit",name="accel",value=1,min=0,hint="<1 starts fast, >1 starts slow"},
	
	{x=3,y=14,class="label",label="Special functions:"},
	{x=4,y=14,width=4,class="dropdown",name="spec",items={"fscx -> fscy","fscy -> fscx","move colour tag to first block","convert clip <-> iclip","clean up tags","sort tags in set order","back and forth transform","select overlaps","convert clip to drawing","convert drawing to clip","convert strikeout to selected","chequerboard clip","create 3D effect from shadow","split line in 3 parts"},value="convert clip <-> iclip"},
	
	{x=0,y=15,class="label",label="Gradient:"},
	{x=1,y=15,width=2,class="dropdown",name="gtype",items={"vertical","horizontal","by character","by line"},value="by character",
	hint="gradient from current values to selected values\nvertical/horizontal requires clip\nworks with accel"},
	{x=3,y=15,width=2,class="floatedit",name="stripe",value=2,min=0,hint="width of clip stripes for vertical/horizontal gradient"},
	{x=5,y=15,class="label",label="pxl/stripe"},
	{x=6,y=15,width=2,class="checkbox",name="short",label="Shorter rotations",value=true,hint="rotate in shorter direction"},
	{x=8,y=15,width=2,class="checkbox",name="middle",label="Centered gradient",
	hint="selected tags will be in the middle;\nend will be same as beginning"},
	
	{x=8,y=10,width=2,class="label",label="Apply to:"},
	{x=8,y=11,width=2,class="dropdown",name="applay",items=app_lay,value="All Layers"},
	{x=8,y=12,width=2,class="dropdown",name="applst",items=app_sty,value="All Styles"},
	{x=8,y=13,width=2,class="dropdown",name="applac",items=app_act,value="All Actors"},
	{x=8,y=14,width=2,class="dropdown",name="applef",items=app_eff,value="All Effects"},
}
	buttons={{"Apply","Repeat Last","Load Medium","Load Full","Cancel"},
	{"Apply","Repeat Last","Load Full","Cancel"},{"Apply","Transform","Gradient","Repeat Last","Special","Save Config","Help","Cancel"}}
	loadconfig()
	heads=sm*2+1
	hh_gui=hh1	loaded=sm
	progress(string.format("Loading Hydra Heads 1-"..heads))
	if sm==2 then for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end loaded=2 end
	if sm==3 then for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end for i=1,#hh3 do l=hh3[i] table.insert(hh_gui,l) end end
	hh_buttons=buttons[sm]
	P,res=ADD(hh_gui,hh_buttons,{ok='Apply',cancel='Cancel'})
	
	if P=="Load Medium" then progress(string.format("Loading Heads 4-5"))
	    for key,val in ipairs(hh_gui) do val.value=res[val.name] end
	    for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end loaded=2
	    P,res=ADD(hh_gui,buttons[2],{ok='Apply',cancel='Cancel'})
	end
	
	if P=="Load Full" then progress(string.format("Loading Heads "..(loaded+1)*2 .."-7"))
	    for key,val in ipairs(hh_gui) do val.value=res[val.name] end
	    if loaded<2 then  for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end  end
	    for i=1,#hh3 do l=hh3[i] table.insert(hh_gui,l) end loaded=3
	    P,res=ADD(hh_gui,buttons[3],{ok='Apply',cancel='Cancel'})
	end
	
	if P=="Help" then progress(string.format("Loading Head 8"))
	for key,val in ipairs(hh_gui) do val.value=res[val.name] end
	hhh={x=0,y=16,width=10,class="dropdown",name="herp",items={"HELP (scroll/click to read)",
	"Standard mode: check tags, set values, click on 'Apply'.",
	"Transform mode normal: check tags, set values, set t1/t2/accel if needed, click on 'Transform'.",
	"Transform mode add2first: the transforms will be added to the first existing transform in the line.",
	"Transform mode add2all: the transforms will be added to all existing transforms in the line.",
	"Transform mode 'all tag blocks': the transforms will be added to all tag blocks, whether they have transforms or not.",
	"Shift times/interval: 'normal' tf - shift \\t times each line; 'all tag blocks' - shift \\t times each tag block.",
	"Relative transform: If you have frz30 and set transform to frz60, you get \\t(\\frz90), or transform BY 60.",
	"Relative transform: This allows you to keep layers with different frz in sync. (No effect on alpha/colours.)",
	"Additional tags: type any extra tags you want to add.",
	"Add with each line: '2' means that for each line, the value of all checked applicable tags is increased by an extra 2.",
	"Tag position: This shows the text of your first line. Type * where you want your tags to go.",
	"Tag position presets: This places tags in specified positions, proportionally for each selected line.",
	"Gradient: Current state is the start. Given tags are the end. Accel works with this. Vertical/horizontal need a clip.",
	"Centered gradient: 'There and back.' Given state will be in the middle. Last line/character will be the same as the first.",
	"Special functions: select a function, click on 'Special'.",
	"Special functions - back and forth transform: select tags, set 'interval'. Missing initial tags are taken from style.",
	"Special functions - create 3D effect from shadow: creates a 3D effect using layers. Requires xshad/yshad.",
	"Special functions - split line in 3 parts: uses t1 and t2 as time markers.",
	},value="HELP (scroll/click to read)"}
	table.insert(hh_gui,hhh)
	P,res=ADD(hh_gui,{"Apply","Transform","Gradient","Repeat Last","Special","Save Config","Cancel"},{ok='Apply',cancel='Cancel'})
	end
	
	if res.tmode=="normal" then tmode=1 end
	if res.tmode=="add2first" then tmode=2 end
	if res.tmode=="add2all" then tmode=3 end
	if res.tmode=="all tag blocks" then tmode=4 end
	if res.tagpres=="in the middle" then fak=0.5 end
	if loaded==3 and res.tagpres:match("of text") then fa,fb=res.tagpres:match("(%d)/(%d)") fak=fa/fb end
	if res.aonly then res.alfas=true end
	
	if P~="Repeat Last" then hydralast=res Plast=P end
	if P=="Apply" then selcheck() trans=0 hh9(subs,sel) end
	if P=="Transform" then selcheck() trans=1 hh9(subs,sel) end
	if P=="Gradient" then selcheck() hydradient(subs,sel) end
	if P=="Special" then sel=special(subs,sel) end
	if P=="Save Config" then saveconfig() end
	if P=="Repeat Last" then res=hydralast
		if Plast=="Gradient" then hydradient(subs,sel)
		elseif Plast=="Special" then sel=special(subs,sel)
		else hh9(subs,sel) end 
	end
	aegisub.set_undo_point(script_name)
	return sel
end

if haveDepCtrl then depRec:registerMacro(hydra) else aegisub.register_macro(script_name,script_description,hydra) end