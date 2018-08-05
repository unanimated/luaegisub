-- Manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#selectrix

script_name="Selectricks"
script_description="Selectricks and Sortricks"
script_author="unanimated"
script_version="3.4"
script_namespace="ua.Selectrix"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="3.4.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

re=require'aegisub.re'
unicode=require'aegisub.unicode'
clipboard=require("aegisub.clipboard")
ulower=unicode.to_lower_case


--	SELECTRIX GUI		--
function konfig(subs,sel)
	for i=1,#subs do if subs[i].class=="dialogue" then line0=i-1 break end end
	edtr=0
	main_mode=
	{"--------text--------","0 text","1 style","2 actor","3 effect","text|actor|effect","text|act|eff|style","visible text (no tags)","------numbers------","layer","duration","word count","character count","char. per second","blur","left margin","right margin","vertical margin","start time","end time","line #","------sorting only------","sort by time","reverse","width of text","dialogue first","dialogue last","ts/dialogue/oped","dialogue/oped/ts","{TS} to the top","masks to the bottom","by comments"}
	presetses={"Default style - All","nonDefault - All","OP in style","ED in style","layer 0","lines w/ comments 1","same text (contin.)","same text (all lines)","same style","same actor","same effect","skiddiks, your their?","its/id/ill/were/wont","any/more+some/time","range of lines","----from selection----","no-blur signs","commented lines","lines w/ comments 2","odd line #","even line #","move sel. up","move sel. down","------sorting------","move sel. to the top","move sel. to bottom","sel: first to bottom","sel: last to top"}
	GUI={
	{x=2,y=0,class="label",label="Text:  "},

	-- MAIN MODE
	{x=0,y=4,class="label",label="Match &this:"},
	{x=1,y=4,width=4,class="edit",name="match",value=lastmatch or ""},
	{x=0,y=5,class="label",label="&History:"},
	{x=1,y=5,width=4,class="dropdown",name="srch",value="",items={""}},
	{x=0,y=6,class="label",label="&Filter:"},
	{x=1,y=6,width=4,class="edit",name="filt",value=filter or ""},

	{x=0,y=0,class="label",label="&Select/sort:"},
	{x=1,y=0,class="dropdown",name="mode",value="0 text",items=main_mode},
	{x=0,y=1,class="label",label="Used &area:"},
	{x=1,y=1,class="dropdown",name="selection",value="current selection",items={"current selection","all lines","add to selection"}},
	{x=0,y=2,class="label",label="&Numbers:"},
	{x=1,y=2,class="dropdown",name="equal",value="==",items={"==",">=","<=","<= [non-zero]"},hint="options for layer/duration"},
	{x=1,y=3,class="dropdown",name="nomatch",value="matches",items={"matches","doesn't match"}},
	{x=3,y=0,width=2,class="checkbox",name="case",label="&Case sensitive"},
	{x=3,y=1,width=2,class="checkbox",name="exact",label="&Exact match"},
	{x=2,y=1,class="checkbox",name="regexp",label="&Regexp   "},
	{x=2,y=2,width=3,class="checkbox",name="nocom",label="E&xclude commented lines",value=true},
	{x=2,y=3,class="checkbox",name="sep",label="Sep. &words",hint="match all words separately\n(disabled by regexp / exact match)"},
	{x=3,y=3,width=2,class="checkbox",name="rev",label="Re&versed sorting"},
	
	{x=0,y=7,class="label",label="Limitations:"},
	{x=1,y=7,class="checkbox",name="onlyfirst",label="&Only 1st result",hint="not applicable with 'doesn't match'\n(switches to 'matches')"},
	{x=2,y=7,width=2,class="checkbox",name="beg",label="&Beginning of line",hint="pattern must be at the beginning of line\n(relevant only without regexp)"},

	-- PRESETS
	{x=0,y=8,class="label",label="&Preset:"},
	{x=1,y=8,class="dropdown",name="pres","Default style - All",items=presetses},
	{x=2,y=8,class="checkbox",name="mod",label="&mod"},
	{x=3,y=8,width=2,class="checkbox",name="editor",label="&Load in editor"},
	
	{x=1,y=9,class="checkbox",name="rem1",label="Remember &dropdowns"},
	{x=2,y=9,width=2,class="checkbox",name="rem2",label="Remember chec&kboxes   "},
	{x=4,y=9,class="checkbox",name="yr",label="yr",hint="your retarded (4 skiddiks)"},
	{x=0,y=9,class="label",label="v. "..script_version},
	}
	buttons={"Set Selection","Preset","Sort","Save","Cancel"}
	loadconfig()
	P,res=ADD(GUI,buttons,{ok='Set Selection',close='Cancel'})
	if P=="Cancel" then aegisub.cancel() end

	-- search list / history
	if res.srch~="" then res.match=res.srch end
	if res.match~="" and res.match:len()<51 then
		for i=#searches,1,-1 do
			if searches[i]==res.match then table.remove(searches,i) end
		end
		table.insert(searches,2,res.match)
	end

	if res.yr then your_retarded=true end
	beg=res.beg	filter=res.filt
	-- res.mode=res.mode:gsub('^%d ','')
	if filter~="" then F1=true else F1=false end

	if P=="Preset" then 
		if res.pres=="no-blur signs" or res.pres=="commented lines" or res.pres=="lines w/ comments 2" 
		    or res.pres:match"move sel." or res.pres:match"sel:" or res.pres:match"line #"
		then sel=presel(subs,sel)
		else edtr=1 preset(subs,sel) end
	end
	if P=="Sort" and res.selection=="current selection" then sorting(subs,sel) end
	if P=="Sort" and res.selection=="all lines" then sel=selectall(subs,sel) sorting(subs,sel) end

	if P=="Set Selection" and res.selection=="current selection" then edtr=1 slct(subs,sel) end
	if P=="Set Selection" and res.selection=="all lines" then edtr=1 sel=selectall(subs,sel) slct(subs,sel) end
	if P=="Set Selection" and res.selection=="add to selection" then edtr=1 sel3={} for z=1,#sel do table.insert(sel3,sel[z]) end sel=selectall(subs,sel) slct(subs,sel) end
	if P=="Save" then saveconfig() end
	lastmatch=res.match
	return sel
end


--	Analyse Line
function analyse(l)
	text=l.text
	style=l.style
	dur=l.end_time-l.start_time
	dura=dur/1000
	txt=text:gsub("{[^}]-}","") :gsub("\\N","")
	visible=text:gsub("{\\alpha&HFF&}[^{}]-{[^{}]-}","")	:gsub("{\\alpha&HFF&}[^{}]*$","")	:gsub("{[^{}]-}","")
			:gsub("\\[Nn]","*")	:gsub("%s?%*+%s?"," ")	:gsub("^%s+","")	:gsub("%s+$","")
	wrd=0	for word in txt:gmatch("([%a\']+)") do wrd=wrd+1 end
	chars=visible:gsub(" ","")	:gsub("[%.,%?!'\"—]","")
	char=chars:len()
	cps=math.ceil(char/dura)
	if dur==0 then cps=0 end
	blur=text:match("\\blur([%d%.]+)")	blur=tonumber(blur)	if blur==nil then blur=0 end
	comment=""
	for com in text:gmatch("{[^\\}]-}") do comment=comment..com end
end

--	Check Style
function stylechk(subs,sn)
  for i=1,#subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if sn==st.name then sr=st end
      if subs[i].name=="Default" then dstyleref=subs[i] end
    end
  end
  if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
  return sr
end

--	SELECT
function slct(subs,sel)
    sel2={}
    eq=res.equal
    SEP={}
    progress('Selecting...')
    for i=#sel,1,-1 do
	local line=subs[sel[i]]
	analyse(line)
	local a=sel[i]

	local nums=0
	local search_area, numb, numbers
	if res.mode=="0 text" then search_area=text if res.mod then search_area=comment end end
	if res.mode=="1 style" then search_area=style end
	if res.mode=="2 actor" then search_area=line.actor end
	if res.mode=="3 effect" then search_area=line.effect end
	if res.mode=="text|actor|effect" then search_area=text..'\n'..line.actor..'\n'..line.effect end
	if res.mode=="text|act|eff|style" then search_area=text..'\n'..line.actor..'\n'..line.effect..'\n'..style end
	if res.mode=="visible text (no tags)" then search_area=text:gsub("{[^}]-}",""):gsub(" *\\N *"," ") end
	if res.mode=="layer" then numb=line.layer nums=1 end
	if res.mode=="duration" then numb=dur nums=1 end
	if res.mode=="word count" then numb=wrd nums=1 end
	if res.mode=="character count" then numb=char nums=1 end
	if res.mode=="char. per second" then numb=cps nums=1 end
	if res.mode=="blur" then numb=blur nums=1 end
	if res.mode=="left margin" then numb=line.margin_l nums=1 end
	if res.mode=="right margin" then numb=line.margin_r nums=1 end
	if res.mode=="vertical margin" then numb=line.margin_t nums=1 end
	if res.mode=="start time" then numb=line.start_time nums=1 end
	if res.mode=="end time" then numb=line.end_time nums=1 end
	if res.mode=="line #" then numb=i nums=1 end
	
	if not search_area and nums==0 then t_error("'"..res.mode.."' is not applicable for selection. Try 'Sort'.",1) end
	if nums==1 then numbers=true else numbers=false end
	if not numbers then s_area_lower=ulower(search_area) end
	
	local nonregexp,nonregexplower,Fnonregexp,Fnonregexplower,M
	
	nonregexp=esc(res.match)		nonregexplower=ulower(nonregexp)	-- reg.search
	if res.sep then
		for s in res.match:gmatch("%S+") do table.insert(SEP,esc(s)) end
	end
	
	Fnonregexp=esc(filter)			Fnonregexplower=ulower(Fnonregexp)	-- filter
	
	if numbers then
		NUM=res.match
		if res.mode:match"time" then
			num1,num2=res.match:match("^(.-)%-(.*)")
			if num1 then num1=taim(num1) num2=taim(num2) else NUM=taim(NUM) end
		else
			num1,num2=res.match:match("([%d%.]+)%-([%d%.]+)")
		end
		
		if num2==nil then num1=NUM num2=NUM end
		
		if eq=="==" and numb<tonumber(num1) then table.remove(sel,i) end
		if eq=="==" and numb>tonumber(num2) then table.remove(sel,i) end
		if eq==">=" and numb<tonumber(NUM) then table.remove(sel,i) end
		if eq=="<=" and numb>tonumber(NUM) then table.remove(sel,i) end
		if eq=="<= [non-zero]" and numb>tonumber(NUM) or eq=="<= [non-zero]" and numb==0 then table.remove(sel,i) end
	end
	
	-- Text Search
      if not numbers then
	if res.case then
	  if res.exact then if search_area~=res.match then table.remove(sel,i) end
	  else
	    if res.regexp then
		matches=re.match(search_area,res.match)
		if F1 then local Fmatches=re.match(search_area,filter) end
		if matches==nil or Fmatches then table.remove(sel,i) end
	    else 
		if beg then M="^"..nonregexp else M=nonregexp end
		local MATCH=true
		if res.sep then
			for s=1,#SEP do
				ms=SEP[s]
				if not search_area:match(ms) then MATCH=false break end
			end
		else MATCH=search_area:match(M)
		end
		if not MATCH or F1 and search_area:match(Fnonregexp) then table.remove(sel,i) end
	    end
	  end
	end
	
	if not res.case then
	  if res.exact then if s_area_lower~=ulower(res.match) then table.remove(sel,i) end
	  else
	    if res.regexp then
		matches=re.match(search_area,res.match,re.ICASE)
		if F1 then local Fmatches=re.match(search_area,filter,re.ICASE) end
		if matches==nil or Fmatches then table.remove(sel,i) end
	    else	-- default search
		if beg then M="^"..nonregexplower else M=nonregexplower end
		local MATCH=true
		if res.sep then
			for s=1,#SEP do
				ms=ulower(SEP[s])
				if not s_area_lower:match(ms) then MATCH=false break end
			end
		else MATCH=s_area_lower:match(M)
		end
		if not MATCH or F1 and s_area_lower:match(Fnonregexplower) then table.remove(sel,i) end
	    end
	  end
	end
      end
	
	if res.nocom and line.comment and sel[i]==a then table.remove(sel,i) end
	
	if sel[i]~=a then
		if res.nocom and line.comment then
		else
		table.insert(sel2,a)
		end
	end
    end
    
    if res.selection=="add to selection" then
	for z=1,#sel3 do table.insert(sel,sel3[z]) end
    end

    if res.onlyfirst then res.nomatch="matches" for s=#sel,2,-1 do table.remove(sel,s) end return sel end
    if res.nomatch=="doesn't match" then return sel2 else return sel end
end

function taim(T)
	crap=tonumber(T:match("%.(%d+)")) or 0
	if crap<10 then crap=100*crap end
	if crap<100 then crap=10*crap end
	if T:match(":") and T:match("[%a]") then t_error("Wrong timecode: "..T,1) end
	if T:match(":") then
		T=T
		:gsub("%.%d+","")
		:gsub(":(%d%d):(%d%d)","h%1m%2s")
		:gsub("(%d+):(%d%d)","0h%1m%2s")
	else
		T=T
		:gsub(" ","")
		:gsub("min","m")
		:gsub("sec","s")
		:gsub("h(%d+)s","h00m%1s")
		:gsub("h(%d+)$","h%1m00s")
		:gsub("m(%d%d)$","m%1s")
		:gsub("h$","h00m00s")
		:gsub("m$","m00s")
		:gsub("^(%d+)m","0h%1m")
		:gsub("^(%d+)s","0h0m%1s")
	end
	H,M,S=T:match("(%d*%.?%d+)h(%d+)m(%d+)s")
	if not H then t_error("Wrong timecode: "..res.match,1) end
	TC=H*3600000+M*60000+S*1000+crap
	return TC
end

--	PRESET All
function preset(subs,sel)
	progress('Selecting...')
	act=sel[1]
	if res.pres:match("same text") then
		marks={}  lm=nil
		for x,i in ipairs(sel) do
			rine=subs[i]
			mark=rine.text:gsub("{[^}]-}","")
			if mark=="" then mark="_empty_" end
			if mark~=lm then table.insert(marks,mark) end
			lm=mark
		end
	end
	if res.pres=="same style" then
		smarks={}  lm=nil
		for x,i in ipairs(sel) do
			rine=subs[i]
			mark=rine.style
			if mark=="" then mark="_empty_" end
			if mark~=lm then table.insert(smarks,mark) end
			lm=mark
		end
	end
	if res.pres=="same actor" then
		amarks={}  lm=nil
		for x,i in ipairs(sel) do
			rine=subs[i]
			mark=rine.actor
			if mark=="" then mark="_empty_" end
			if mark~=lm then table.insert(amarks,mark) end
			lm=mark
		end
	end
	if res.pres=="same effect" then
		emarks={}  lm=nil
		for x,i in ipairs(sel) do
			rine=subs[i]
			mark=rine.effect
			if mark=="" then mark="_empty_" end
			if mark~=lm then table.insert(emarks,mark) end
			lm=mark
		end
	end
	if res.pres=="range of lines" then
		range_st,range_end=res.match:match("(%d+)%-(%d+)")
		if range_st==nil then range_st=res.match:match("%d+") range_end=range_st end
		if range_st==nil then ADD({{class="label",label="Error: No numbers given."}},{"OK"},{close='OK'})
			if cancel then aegisub.cancel() end
		end
	end
	for i=#sel,1,-1 do	table.remove(sel,i) end
	opst=10000000	opet=0
	edst=10000000	edet=0
    for i=1,#subs do
	if subs[i].class=="dialogue" then
	local line=subs[i]
	local text=line.text
	local st=line.style
	local actr=line.actor
	local eff=line.effect
	local start=line.start_time
	local endt=line.end_time
	local nc=text:gsub("{[^\\}]-}","")
	    if res.pres=="Default style - All" then
		if st:match("Defa") or st:match("Alt") then table.insert(sel,i) end
	    end
	    if res.pres=="nonDefault - All" then
		if not st:match("Defa") and not st:match("Alt") then table.insert(sel,i) end
	    end
	    if res.pres=="OP in style" then
		if st:match("OP") then table.insert(sel,i)
		    if start<opst then opst=start end
		    if endt>opet then opet=endt end
		end
	    end
	    if res.pres=="ED in style" then
		if st:match("ED") then table.insert(sel,i)
		    if start<edst then edst=start end
		    if endt>edet then edet=endt end
		end
	    end
	    if res.pres=="layer 0" then
		if line.layer==0 then table.insert(sel,i) end
	    end
	    if res.pres=="lines w/ comments 1" then
		if not res.nocom or not line.comment then
		  if text:match("{[^\\}]-}") then table.insert(sel,i) end
		end
	    end
	    if res.pres=="same text (contin.)" then
		if i==act then table.insert(sel,i) end
		if i>act then ct=text:gsub("{[^}]-}","")	ch=0
		    for m=1,#marks do if marks[m]==ct then ch=1 end end
		    if ch==1 then table.insert(sel,i) else break end
		end
	    end
	    if res.pres=="same text (all lines)" then
		ct=text:gsub("{[^}]-}","")	ch=0
		for m=1,#marks do if marks[m]==ct then ch=1 end end
		if ch==1 then table.insert(sel,i) end
	    end
	    if res.pres=="same style" then
		ch=0
		for m=1,#smarks do if smarks[m]==st or res.mod and st:match(esc(smarks[m])) then ch=1 end end
		if ch==1 then table.insert(sel,i) end
	    end
	    if res.pres=="same actor" then
		ch=0
		for m=1,#amarks do if amarks[m]==actr then ch=1 end end
		if ch==1 then table.insert(sel,i) end
	    end
	    if res.pres=="same effect" then
		ch=0
		for m=1,#emarks do if emarks[m]==eff then ch=1 end end
		if ch==1 then table.insert(sel,i) end
	    end
	    if res.pres=="skiddiks, your their?" then
	      if st:match("Defa") or st:match("Alt") then
		if nc:match("[Yy]ou\'?re?%s")
		or nc:match("[Tt]hey?\'?re")
		or nc:match("[Tt]heir")
		then table.insert(sel,i)
		if your_retarded then line.effect=line.effect.." your retarded" subs[i]=line end
		end
	      end
	    end
	    if res.pres=="its/id/ill/were/wont" then
	      if st:match("Defa") or st:match("Alt") then
		nc=" "..nc:lower().." "
		nc=nc:gsub(" *\\n *"," ")
		if nc:match(" its ")
		or nc:match(" id ")
		or nc:match(" ill ")
		or nc:match(" wont ")
		then table.insert(sel,i)
		end
		if nc:match(" were ") then
			if not nc:match(" we were ") and not nc:match(" you were ") and not nc:match(" they were ") then table.insert(sel,i)
		end
		end
	      end
	    end
	    if res.pres=="any/more+some/time" then
		nc=" "..nc:lower().." "
		if nc:match(" any ?more")
		or nc:match("some ?time")
		then table.insert(sel,i)
		end
	    end
	    if res.pres=="range of lines" then
	      if startline==nil then startline=i end
	      ind=i-startline+1
	      if ind>=tonumber(range_st) and ind<=tonumber(range_end) then table.insert(sel,i) end
	    end
	end
    end
    -- OP/ED mod
    if res.mod and res.pres:match("in style") then
      for i=1,#subs do
	if subs[i].class=="dialogue" then
	local line=subs[i]
	local text=line.text
	local st=line.style
	local start=line.start_time
	local endt=line.end_time
	    if res.pres=="OP in style" then
		if not st:match("OP") and start>opst and endt<opet then table.insert(sel,i) end
	    end
	    if res.pres=="ED in style" then
		if not st:match("ED") and start>edst and endt<edet then table.insert(sel,i) end
	    end
	end
      end
    end
    startline=nil
    return sel
end

--	PRESET From Selection
function presel(subs,sel)
	progress('Selecting...')
	sorttab={}
	if res.pres=="move sel. up" then table.sort(sel,function(a,b) return a>b end) end
	if res.match:match("^%d+$") then moveby=res.match:match("^(%d+)$") else moveby=1 end
	edtr=0
	for i=#sel,1,-1 do
		local line=subs[sel[i]]
		local text=line.text
		local st=line.style
		if res.pres=="no-blur signs" then edtr=1
			blur=text:match("\\blur([%d%.]+)")
			if st:match("Defa") or st:match("Alt") or st:match("OP") or st:match("ED") or blur~=nil then table.remove(sel,i) end
		end
		if res.pres=="commented lines" and not line.comment then edtr=1 table.remove(sel,i) end
		if res.pres=="lines w/ comments 2" then edtr=1
			if res.nocom and line.comment or not text:match("{[^\\}]-}") then table.remove(sel,i) end
		end
		if res.pres=="move sel. to the top" or res.pres=="move sel. to bottom" then  line.ind=i
			table.insert(sorttab,subs[sel[i]])
			subs.delete(sel[i])
		end
		if res.pres=="move sel. up" then
			sel[i]=sel[i]-moveby
		end
		if res.pres=="move sel. down" then
			sel[i]=sel[i]+moveby
		end
		if res.pres=="odd line #" then
			ln=sel[i]-line0
			if ln%2==0 then table.remove(sel,i) end
		end
		if res.pres=="even line #" then
			ln=sel[i]-line0
			if ln%2==1 then table.remove(sel,i) end
		end
	end
	if res.pres=="move sel. to the top" then    cs=1
		repeat   if subs[cs].class~="dialogue" then cs=cs+1 end   until subs[cs].class=="dialogue"
		for s=1,#sorttab do  subs.insert(cs,sorttab[s]) end
		if not res.mod then
			sel={}
			for sl=cs,cs+#sorttab-1 do table.insert(sel,sl) end
		end
	end
	if res.pres=="move sel. to bottom" then
		for s=#sorttab,1,-1 do  subs.append(sorttab[s]) end
		if not res.mod then
			sel={}
			for sl=#subs,#subs-#sorttab+1,-1 do table.insert(sel,sl) end
		end
	end
	if res.pres=="sel: last to top" then
		sell={}
		for i=1,#sel do
			l=subs[sel[i]]
			table.insert(sell,l)
		end
		for i=1,#sel do
			l=subs[sel[i]]
			if i==1 then subs[sel[i]]=sell[#sel]
			else subs[sel[i]]=sell[i-1]
			end
		end
	end
	if res.pres=="sel: first to bottom" then
		sell={}
		for i=1,#sel do
			l=subs[sel[i]]
			table.insert(sell,l)
		end
		for i=1,#sel do
			l=subs[sel[i]]
			if i==#sel then subs[sel[i]]=sell[1]
			else subs[sel[i]]=sell[i+1]
			end
		end
	end
	    
	return sel
end

--	SORTING
function sorting(subs,sel)
    subtable={}
    -- lines into table
    for x, i in ipairs(sel) do
	local l=subs[i]
	analyse(l)
	l.i=x
	l.wrd=wrd
	l.ch=char
	l.cps=cps
	l.ml=l.margin_l
	l.mr=l.margin_r
	l.mv=l.margin_t
	nocomment=l.text:gsub("{[^}]-}","") :gsub("%s?\\N%s?"," ")
	if style:match("Defa") or style:match("Alt") then l.st=1 else l.st=2 end
	l.sdo=1	l.does=3
	if style:match("Defa") or style:match("Alt") then l.sdo=2 l.does=1 end
	if style:match("OP") or style:match("ED") then l.sdo=3 l.does=2 end
	if l.text:match("{TS") then l.ts=1 else l.ts=2 end
	if l.text:match("{[^\\}]-}") then l.com=l.text:match("{[^\\}]-}") else l.com="" end
	blur=text:match("\\blur([%d%.]+)")	blur=tonumber(blur)	if blur==nil then blur=0 end	l.bl=blur
	if text:match("\\p1") then l.mask=1 else l.mask=0 end
	if res.mode=="width of text" then
	  if l.style=="Default" and dstyleref~=nil then styleref=dstyleref
	  else styleref=stylechk(subs,l.style) end
	  l.width=aegisub.text_extents(styleref,nocomment)
	end
	table.insert(subtable,l)
    end
    
    -- sort lines
    if res.mode=="layer" then table.sort(subtable,function(a,b) return a.layer<b.layer or (a.layer==b.layer and a.i<b.i) end) end
    if res.mode=="duration" then table.sort(subtable,function(a,b) 
	return a.end_time-a.start_time<b.end_time-b.start_time or (a.end_time-a.start_time==b.end_time-b.start_time and a.i<b.i) end) end
    if res.mode=="0 text" then table.sort(subtable,function(a,b) 
	return a.text:lower()<b.text:lower() or (a.text:lower()==b.text:lower() and a.i<b.i) end) end
    if res.mode=="1 style" then table.sort(subtable,function(a,b) return a.style<b.style or (a.style==b.style and a.i<b.i) end) end
    if res.mode=="2 actor" then table.sort(subtable, function(a,b) return a.actor<b.actor or (a.actor==b.actor and a.i<b.i) end) end
    if res.mode=="3 effect" then table.sort(subtable,function(a,b) return a.effect<b.effect or (a.effect==b.effect and a.i<b.i) end) end
    if res.mode=="visible text (no tags)" then table.sort(subtable,function(a,b) 
	return a.text:lower():gsub("{[^}]-}","")<b.text:lower():gsub("{[^}]-}","") 
	or (a.text:lower():gsub("{[^}]-}","")==b.text:lower():gsub("{[^}]-}","") and a.i<b.i) end) end
    if res.mode=="word count" then table.sort(subtable,function(a,b) return a.wrd<b.wrd or (a.wrd==b.wrd and a.i<b.i) end) end
    if res.mode=="character count" then table.sort(subtable,function(a,b) return a.ch<b.ch or (a.ch==b.ch and a.i<b.i) end) end
    if res.mode=="char. per second" then table.sort(subtable,function(a,b) return a.cps<b.cps or (a.cps==b.cps and a.i<b.i) end) end
    if res.mode=="blur" then table.sort(subtable,function(a,b) return a.bl<b.bl or (a.bl==b.bl and a.i<b.i) end) end
    if res.mode=="left margin" then table.sort(subtable,function(a,b) return a.ml<b.ml or (a.ml==b.ml and a.i<b.i) end) end
    if res.mode=="right margin" then table.sort(subtable,function(a,b) return a.mr<b.mr or (a.mr==b.mr and a.i<b.i) end) end
    if res.mode=="vertical margin" then table.sort(subtable,function(a,b) return a.mv<b.mv or (a.mv==b.mv and a.i<b.i) end) end
    if res.mode=="sort by time" and not res.mod then table.sort(subtable,function(a,b)
	return a.start_time<b.start_time or (a.start_time==b.start_time and a.end_time<b.end_time)
	or (a.start_time==b.start_time and a.end_time==b.end_time and a.i<b.i) end) end
    if res.mode=="sort by time" and res.mod then table.sort(subtable,function(a,b)
	return a.end_time<b.end_time or (a.end_time==b.end_time and a.start_time<b.start_time)
	or (a.end_time==b.end_time and a.start_time==b.start_time and a.i<b.i) end) end
    if res.mode=="reverse" then table.sort(subtable,function(a,b) return a.i>b.i end) end
    if res.mode=="width of text" then table.sort(subtable,function(a,b) return a.width<b.width or (a.width==b.width and a.i<b.i) end) end
    if res.mode=="dialogue first" then table.sort(subtable,function(a,b) return a.st<b.st or (a.st==b.st and a.i<b.i) end) end
    if res.mode=="dialogue last" then table.sort(subtable,function(a,b) return a.st>b.st or (a.st==b.st and a.i<b.i) end) end
    if res.mode=="ts/dialogue/oped" then table.sort(subtable,function(a,b) return a.sdo<b.sdo or (a.sdo==b.sdo and a.i<b.i) end) end
    if res.mode=="dialogue/oped/ts" then table.sort(subtable,function(a,b) return a.does<b.does or (a.sdo==b.sdo and a.start_time<b.start_time 
	or a.sdo==b.sdo and a.start_time==b.start_time and a.i<b.i) end) end
    if res.mode=="{TS} to the top" then table.sort(subtable,function(a,b) return a.ts<b.ts or (a.ts==b.ts and a.i<b.i) end) end
    if res.mode=="masks to the bottom" then table.sort(subtable,function(a,b) return a.mask<b.mask or (a.mask==b.mask and a.i<b.i) end) end
    if res.mode=="by comments" then table.sort(subtable,function(a,b) return a.com<b.com or (a.com==b.com and a.i<b.i) end) end
    
    -- lines back
    for x, i in ipairs(sel) do
	local l=subtable[x]
	local r=subtable[#subtable-x+1]
	if res.rev then subs[i]=r else subs[i]=l end
    end
end

--	Select All
function selectall(subs,sel)
sel={}
    for i=1, #subs do
	if subs[i].class=="dialogue" then table.insert(sel,i) end
    end
    return sel
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then aegisub.cancel() end
end

--	EDITOR
function editlines(subs,sel)
	editext=""
	dura=""
    for x, i in ipairs(sel) do
	if aegisub.progress.is_cancelled() then aegisub.cancel() end
    	aegisub.progress.title(string.format("Reading line: %d/%d",x,#sel))
        line=subs[i]
	text=line.text
	dur=line.end_time-line.start_time
	dur=dur/1000
	char=text:gsub("{[^}]-}","")	:gsub("\\[Nn]","*")	:gsub("%s?%*+%s?"," ")	:gsub(" ","")	:gsub("[%.,%?!'\"—]","")
	linelen=char:len()
	cps=math.ceil(linelen/dur)
	if tostring(dur):match("%.%d$") then dur=dur.."0" end
	if not tostring(dur):match("%.") then dur=dur..".00" end
	if cps<10 then cps="  "..cps end
	if dur=="0.00" then cps="n/a" end
	
	      if x~=#sel then editext=editext..text.."\n" dura=dura..dur.." .. "..cps.." .. "..linelen.."\n" end
	      if x==#sel then editext=editext..text dura=dura..dur.." .. "..cps.." .. "..linelen end
    end
    editbox(subs,sel)
    if failt==1 then editext=res.dat editbox(subs,sel) end
    return sel
end

--	EDITOR GUI
function editbox(subs,sel)
aegisub.progress.title("Loading Editor...")
	if #sel<=4 then boxheight=7 end
	if #sel>=5 and #sel<9 then boxheight=8 end
	if #sel>=9 and #sel<15 then boxheight=math.ceil(#sel*0.8) end
	if #sel>=15 and #sel<18 then boxheight=12 end
	if #sel>=18 then boxheight=15 end
	if editext:len()>1500 and boxheight==7 then boxheight=8 end
	if editext:len()>1800 and boxheight==8 then boxheight=9 end
	nocom=editext:gsub("{[^}]-}","")
	words=0
	plaintxt=nocom:gsub("%p","")
	for wrd in plaintxt:gmatch("%S+") do
	words=words+1
	end
	if lastrep1==nil then lastrep1="" end
	if lastrep2==nil then lastrep2="" end
	GUI=
	{
	    {x=0,y=0,width=52,height=1,class="label",label="Text"},
	    {x=52,y=0,width=5,height=1,class="label",label="Duration | CPS | chrctrs"},
	    
	    {x=0,y=boxheight+1,class="label",label="Replace:"},
	    {x=1,y=boxheight+1,width=15,height=1,class="edit",name="rep1",value=lastrep1},
	    {x=16,y=boxheight+1,class="label",label="with"},
	    {x=17,y=boxheight+1,width=15,height=1,class="edit",name="rep2",value=lastrep2},
	    
	    {x=0,y=1,width=52,height=boxheight,class="textbox",name="dat",value=editext},
	    {x=52,y=1,width=5,height=boxheight,class="textbox",name="durr",value=dura,hint="This is informative only. \nCPS=Characters Per Second"},
	    
	    {x=32,y=boxheight+1,width=20,height=1,class="edit",name="info",value="Lines loaded: "..#sel..", Characters: "..editext:len()..", Words: "..words },
	    {x=52,y=boxheight+1,width=5,height=1,class="label",label="Multi-Line Editor v1.33"},
	}
	buttons={"Save","Replace","Remove tags","Rm. comments","Remove \"- \"","Remove \\N","Add italics","Add \\an8","Reload text","Taller GUI","Cancel"}
	repeat
	if P=="Replace" or P=="Add italics" or P=="Add \\an8" or P=="Remove \\N" or P=="Reload text"
		or P=="Remove tags" or P=="Rm. comments" or P=="Remove \"- \"" or P=="Taller GUI" then
		
		if P=="Add italics" then
		res.dat=res.dat	:gsub("$","\n") :gsub("(.-)\n","{\\i1}%1\n") :gsub("{\\i1}{\\","{\\i1\\") :gsub("\n$","") end
		if P=="Add \\an8" then
		res.dat=res.dat	:gsub("$","\n") :gsub("(.-)\n","{\\an8}%1\n") :gsub("{\\an8}{\\","{\\an8\\") :gsub("\n$","") end
		if P=="Remove \\N" then res.dat=res.dat	:gsub("%s?\\N%s?"," ") end
		if P=="Remove tags" then res.dat=res.dat:gsub("{%*?\\[^}]-}","") end
		if P=="Rm. comments" then res.dat=res.dat:gsub("{[^\\}]-}","") :gsub("{[^\\}]-\\N[^\\}]-}","") end
		if P=="Remove \"- \"" then res.dat=res.dat:gsub("%- ","") end
		if P=="Replace" then rep1=esc(res.rep1)
		res.dat=res.dat:gsub(rep1,res.rep2)
		end
		if P=="Taller GUI" then boxheight=boxheight+1 
		  for key,val in ipairs(GUI) do
		    if val.y==1 then val.height=val.height+1 end
		    if val.y>1 then val.y=val.y+1 end
		  end
		end
		
		for key,val in ipairs(GUI) do
		  if P~="Reload text" then
		    if val.name=="dat" then val.value=res.dat end
		    if val.name=="durr" then val.value=res.durr end
		    if val.name=="info" then val.value=res.info end
		    if val.name=="oneline" then val.value=res.oneline end
		    if val.name=="rep1" then val.value=res.rep1 end
		    if val.name=="rep2" then val.value=res.rep2 end
		  else
		    if val.name=="dat" then val.value=editext end
		  end
		end
	end
	P, res=ADD(GUI,buttons,{save='Save',close='Cancel'})
	until P=="Save" or P=="Cancel"

	if P=="Cancel" then aegisub.cancel() end
	if P=="Save" then savelines(subs,sel) end
	lastrep1=res.rep1
	lastrep2=res.rep2
	return sel
end

--	EDITOR SAVE
function savelines(subs,sel)
aegisub.progress.title("Saving...")
    local data={}	raw=res.dat.."\n"
    if #sel==1 then raw=raw:gsub("\n(.)","\\N%1") raw=raw:gsub("\\N "," \\N") end
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    failt=0    
    if #sel~=#data and #sel>1 then failt=1 else
	for x, i in ipairs(sel) do
        line=subs[i]
	line.text=data[x]
	subs[i]=line
	end
    end
    if failt==1 then ADD({{class="label",
		    label="Line count of edited text does not \nmatch the number of selected lines.",x=0,y=0,width=1,height=2}},{"OK"})
		    clipboard.set(res.dat) end
	aegisub.set_undo_point(script_name)
	return sel
end

function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end


--	Config Stuff	--
function saveconfig()
selconf="Selectrix 3.0 Config\n\n"
  for key,v in ipairs(GUI) do
    if v.class=="dropdown" then
	selconf=selconf..v.name..":"..res[v.name].."\n"
    end
    if v.class=="checkbox" then
	selconf=selconf..v.name..":"..tf(res[v.name]).."\n"
    end
  end
file=io.open(selkonfig,"w")
file:write(selconf)
file:close()
ADD({{class="label",label="Config saved to:\n"..selkonfig}},{"OK"},{close='OK'})
end

function loadconfig()
  file=io.open(matchlist)
    searches={}
    if file~=nil then
	slist=file:read("*all")
	io.close(file)
	for l in slist:gmatch("(.-)\n") do
		table.insert(searches,l)
	end
    else searches={""}
    end
  file=io.open(selkonfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	for k,v in ipairs(GUI) do
	  if v.class:match"dropdown" or v.class=="checkbox" then
	    if konf:match(v.name) then v.value=detf(konf:match(v.name..":(.-)\n")) end
	    if res and res.rem1 and v.class:match"dropdown" then v.value=res[v.name] end
	    if res and res.rem1 and v.name=="rem1" then v.value=true end
	    if res and res.rem2 and v.class:match"checkbox" then v.value=res[v.name] end
	    if v.name=="srch" then v.items=searches v.value="" end
	  end
	end
    end
end

function savesearch()
	file=io.open(matchlist,"w")
	list=""
	for i=1,#searches do
		list=list..searches[i].."\n"
		if i==30 then break end	-- history list limit
	end
	file:write(list)
	file:close()
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

function string2time(timecode)
	timecode=timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)",function(a,b,c,d) return d*10+c*1000+b*60000+a*3600000 end)
	return timecode
end

function chkbx()
	errM="No matches found.\n\nSearch string: \""..res.match.."\""
	if res.case then errM=errM.."\n • Case sensitive" end
	if res.exact then errM=errM.."\n • Exact match" end
	if res.sep then errM=errM.."\n • Sep. words" end
	if res.beg then errM=errM.."\n • Beginning of line" end
	if res.mod and res.mode=='0 text' then errM=errM.."\n • Mod (Search in {comments})" end
	errM=errM:gsub("\"\n","\"\n\nOptions checked:\n")
	return errM
end

function progress(msg)
	if aegisub.progress.is_cancelled() then ak() end
	aegisub.progress.title(msg)
end

function selector(subs,sel,act)
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ak=aegisub.cancel
	selkonfig=ADP("?user").."\\selectrix.conf"
	matchlist=ADP("?user").."\\selectrixmatches.list"
	sel=konfig(subs,sel,act)
	savesearch()
	if edtr==1 and res.editor then editlines(subs,sel,act) end
	if P=="Set Selection" then
		if res.nomatch=="matches" and #sel==0 then act=nil errM=chkbx() t_error(errM) end
		if res.nomatch=="doesn't match" and #sel2==0 then act=nil t_error("No matches found.") end
	end
	aegisub.set_undo_point(script_name)
	if res.nomatch=="doesn't match" and P=="Set Selection" then return sel2,act else return sel,act end
end

if haveDepCtrl then depRec:registerMacro(selector) else aegisub.register_macro(script_name,script_description,selector) end