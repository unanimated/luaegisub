--[[	alternative to aegisub's select tool. unlike that one, this can also select by layer.
	version 2.0 includes sorting of selected/all lines, by the same markers as the selecting uses.

D	'Select/sort' 	This is what the search string is compared against. There are 4 'numbers' items and 4 'text' items. 
E	'Used area' 	'current selection' - only lines in the current selection will be scanned. 
S	'Numbers.' 	For 'numbers' items, you can select lines with higher or lower layer/duration instead of just exact match.
C		With "==", you can specify a range, like 2-4, to select for example lines with layers 2-4.
R	'Match this' 	Only numbers for 'numbers' items. Duration is in milliseconds. 
I	'case sensitive' Obviously applies only to 'text' items. 
P	'exact match' 	Same. 
T	'use regexp' 	Not sure how well this is working, but it should work. Only for 'text' items.
I	'mod'		Modifies some functions:
O		-> "sort by time" - sorts by end time
N		-> "OP/ED in style" - includes any lines timed between the first and last lines of OP/ED (for including signs in OP/ED)
		-> "move sel. to top/bottom" - selection doesn't follow the moved lines
	Presets:
	same text (contin.) - reads texts of selected lines and selects all following lines with the same texts until it reaches new text
	same text (all lines) - selects all lines in the script with the same texts as the current selection (clean text - no tags/comments)
	move sel. up/down - moves the selection by 1 unless given a different number in the match field
--]]

script_name="Selectricks"
script_description="Selectricks and Sortricks"
script_author="unanimated"
script_version="2.71"

-- SETTINGS --				you can choose from the options below to change the default settings

search_sort="text"			-- "layer","style","actor","effect","text"
select_from="current selection"		-- "current selection","all lines"
matches_or_not="matches"		-- "matches","doesn't match"
numbers_option="=="			-- "==",">=","<="
case_sensitive=false			-- true/false
exact_match=false			-- true/false
use_regexp=false			-- true/false
exclude_commented=true			-- true/false
load_in_editor=false			-- true/false
remember_last_search=true		-- true/false [will remember last search string]
remember_select_sort=true		-- true/false [will remember last select/sort mode]
remember_case=false			-- true/false [will remember case sensitive option]
remember_regexp=false			-- true/false [will remember regexp option]
remember_exact=false			-- true/false [will remember exact match option]
your_retarded=false			-- set to true if your skiddiks

-- end of settings --

require "clipboard"
re=require'aegisub.re'

--	Analyze Line
function analyze(l)
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
function stylechk(subs,stylename)
  for i=1, #subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if stylename==st.name then styleref=st end
      if subs[i].name=="Default" then dstyleref=subs[i] end
    end
  end
  return styleref
end

--	SELECT
function slct(subs, sel)
    sel2={}
    eq=res.equal
    for i=#sel,1,-1 do
	local line=subs[sel[i]]
	analyze(line)
	a=sel[i]

	nums=0
	if res.mode=="style" then search_area=style end
	if res.mode=="actor" then search_area=line.actor end
	if res.mode=="effect" then search_area=line.effect end
	if res.mode=="text" then search_area=text if res.mod then search_area=comment end end
	if res.mode=="visible text (no tags)" then search_area=text:gsub("{[^}]-}","") end
	if res.mode=="layer" then numb=line.layer nums=1 end
	if res.mode=="duration" then numb=dur nums=1 end
	if res.mode=="word count" then numb=wrd nums=1 end
	if res.mode=="character count" then numb=char nums=1 end
	if res.mode=="char. per second" then numb=cps nums=1 end
	if res.mode=="blur" then numb=blur nums=1 end
	if res.mode=="left margin" then numb=line.margin_l nums=1 end
	if res.mode=="right margin" then numb=line.margin_r nums=1 end
	if res.mode=="vertical margin" then numb=line.margin_t nums=1 end
	
	if nums==1 then numbers=true else numbers=false end
	
	nonregexp=esc(res.match)
	nonregexplower=nonregexp:lower()
	regexplower=res.match:lower()
	
	if not numbers then s_area_lower=search_area:lower() end
	
	if numbers then
	num1,num2=res.match:match("([%d%.]+)%-([%d%.]+)")
	if num2~=nil then nmbrs={} 
	    for n=num1,num2 do table.insert(nmbrs,n) end 
	else nmbrs={res.match}
	end
	if eq=="==" then
	    numatch=0
	    for n=1,#nmbrs do
	    if numb==tonumber(nmbrs[n]) then numatch=1  end
	    end
	    if numatch==0 then table.remove(sel,i) end
	end
	if eq==">=" and numb<tonumber(res.match) then table.remove(sel,i) end
	if eq=="<=" and numb>tonumber(res.match) then table.remove(sel,i) end
	end
	
      if not numbers then
	if res.case then
	  if res.exact then if search_area~=res.match then table.remove(sel,i) end
	  else
	    if res.regexp then
		matches=re.find(search_area,res.match)
		if matches==nil then  table.remove(sel,i) end
	    else 
		if not search_area:match(nonregexp) then  table.remove(sel,i) end
	    end
	  end
	end
	
	if not res.case then
	  if res.exact then if s_area_lower~=res.match:lower() then table.remove(sel,i) end
	  else
	    if res.regexp then
		matches=re.find(search_area,res.match,re.ICASE)
		if matches==nil then  table.remove(sel,i) end
	    else
		if not s_area_lower:match(nonregexplower) then  table.remove(sel,i) end
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
  
    if res.nomatch=="doesn't match" then return sel2 else return sel end
end

--	PRESET All
function preset(subs, sel)
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
for i=#sel,1,-1 do	table.remove(sel,i) end
opst=10000000	opet=0
edst=10000000	edet=0
    for i=1,#subs do
	if subs[i].class=="dialogue" then
	local line=subs[i]
	local text=line.text
	local st=line.style
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
		if nc:match(" its ")
		or nc:match(" id ")
		or nc:match(" ill ")
		or nc:match(" were ")
		or nc:match(" wont ")
		then table.insert(sel,i)
		end
	      end
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
    return sel
end

--	PRESET From Selection
function presel(subs, sel)
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
    end
    if res.pres=="move sel. to the top" then    cs=1
      repeat   if subs[cs].class~="dialogue" then cs=cs+1 end   until subs[cs].class=="dialogue"
      for s=1,#sorttab do  subs.insert(cs,sorttab[s])  end
      if not res.mod then
	sel={}
	for sl=cs,cs+#sorttab-1 do table.insert(sel,sl) end
      end
    end
    if res.pres=="move sel. to bottom" then
      for s=#sorttab,1,-1 do  subs.append(sorttab[s])  end
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

--	SELECTRIX GUI
function konfig(subs, sel)
	if lastmatch==nil then lastmatch="" end
	if lastmode==nil then lastmode=search_sort end
	if lastcase==nil then lastcase=case_sensitive end
	if lastregexp==nil then lastregexp=use_regexp end
	if lastexact==nil then lastexact=exact_match end
	edtr=0
	GUI=
	{
	    {x=0,y=0,width=1,height=1,class="label",label="Select/sort:"},
	    {x=0,y=1,width=1,height=1,class="label",label="Used area:"},
	    {x=0,y=2,width=1,height=1,class="label",label="Numbers:"},
	    -- MAIN MODE
	    {x=1,y=0,width=1,height=1,class="dropdown",name="mode",value=lastmode,
		items={"--------text--------","style","actor","effect","text","visible text (no tags)","------numbers------","layer","duration","word count","character count","char. per second","blur","left margin","right margin","vertical margin","------sorting only------","sort by time","reverse","width of text","dialogue first","dialogue last","ts/dialogue/oped","{TS} to the top","masks to the bottom","by comments"}},
	    {x=1,y=1,width=1,height=1,class="dropdown",name="selection",value=select_from,items={"current selection","all lines"}},
	    {x=1,y=2,width=1,height=1,class="dropdown",name="equal",value=numbers_option,items={"==",">=","<="},
							hint="options for layer/duration"},
	    {x=1,y=3,width=1,height=1,class="dropdown",name="nomatch",value=matches_or_not,items={"matches","doesn't match"}},
	    
	    {x=0,y=4,width=1,height=1,class="label",label="Match this:"},
	    {x=1,y=4,width=3,height=1,class="edit",name="match",value=lastmatch},
	    
	    -- PRESETS
	    {x=0,y=5,width=1,height=1,class="label",label="Sel. preset:"},
	    {x=1,y=5,width=1,height=1,class="dropdown",name="pres",value="Default style - All",
	    items={"Default style - All","nonDefault - All","OP in style","ED in style","layer 0","lines w/ comments 1","same text (contin.)","same text (all lines)","skiddiks, your their?","its/id/ill/were/wont","----from selection----","no-blur signs","commented lines","lines w/ comments 2","move sel. up","move sel. down","------sorting------","move sel. to the top","move sel. to bottom","sel: first to bottom","sel: last to top"}},
	    
	    {x=2,y=0,width=1,height=1,class="label",label="Text:  "},
	    {x=3,y=0,width=1,height=1,class="checkbox",name="case",label="case sensitive",value=lastcase},
	    {x=3,y=1,width=1,height=1,class="checkbox",name="exact",label="exact match",value=lastexact},
	    {x=2,y=1,width=1,height=1,class="checkbox",name="regexp",label="regexp",value=lastregexp},
	    {x=2,y=2,width=2,height=1,class="checkbox",name="nocom",label="exclude commented lines",value=exclude_commented},
	    
	    {x=2,y=3,width=1,height=1,class="label",label="Sorting:"},
	    {x=3,y=3,width=1,height=1,class="checkbox",name="rev",label="reversed",value=false},
	    
	    {x=2,y=5,width=1,height=1,class="checkbox",name="mod",label="mod",value=false},
	    {x=3,y=5,width=1,height=1,class="checkbox",name="editor",label="load in editor",value=load_in_editor},
	    
	}
	buttons={"Set Selection","Preset","Sort","Cancel"}
	pressed, res=aegisub.dialog.display(GUI,buttons,{ok='Set Selection',close='Cancel'})
	if pressed=="Cancel" then aegisub.cancel() end
	if pressed=="Preset" then 
		if res.pres=="no-blur signs" or res.pres=="commented lines" or res.pres=="lines w/ comments 2" 
		    or res.pres:match"move sel." or res.pres:match"sel:"
		then sel=presel(subs, sel)
		else edtr=1 preset(subs, sel) end
	end
	if pressed=="Sort" and res.selection=="current selection" then sorting(subs, sel) end
	if pressed=="Sort" and res.selection=="all lines" then sel=selectall(subs, sel) sorting(subs, sel) end

	if pressed=="Set Selection" and res.selection=="current selection" then edtr=1 slct(subs, sel) end
	if pressed=="Set Selection" and res.selection=="all lines" then edtr=1 sel=selectall(subs, sel) slct(subs, sel) end
	if remember_last_search then lastmatch=res.match end
	if remember_select_sort then lastmode=res.mode end
	if remember_case then lastcase=res.case end
	if remember_regexp then lastregexp=res.regexp end
	if remember_exact then lastexact=res.exact end
	return sel
end

--	SORTING
function sorting(subs,sel)
    subtable={}
    -- lines into table
    for x, i in ipairs(sel) do
	local l=subs[i]
	analyze(l)
	l.i=x
	l.wrd=wrd
	l.ch=char
	l.cps=cps
	l.ml=l.margin_l
	l.mr=l.margin_r
	l.mv=l.margin_t
	nocomment=l.text:gsub("{[^}]-}","") :gsub("%s?\\N%s?"," ")
	if style:match("Defa") or style:match("Alt") then l.st=1 else l.st=2 end
	l.sdo=1
	if style:match("Defa") or style:match("Alt") then l.sdo=2 end
	if style:match("OP") or style:match("ED") then l.sdo=3 end
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
    if res.mode=="actor" then table.sort(subtable, function(a,b) return a.actor<b.actor or (a.actor==b.actor and a.i<b.i) end) end
    if res.mode=="effect" then table.sort(subtable,function(a,b) return a.effect<b.effect or (a.effect==b.effect and a.i<b.i) end) end
    if res.mode=="style" then table.sort(subtable,function(a,b) return a.style<b.style or (a.style==b.style and a.i<b.i) end) end
    if res.mode=="text" then table.sort(subtable,function(a,b) 
	return a.text:lower()<b.text:lower() or (a.text:lower()==b.text:lower() and a.i<b.i) end) end
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
    if res.mode=="sort by time" and not res.mod then table.sort(subtable,function(a,b) return a.start_time<b.start_time or (a.start_time==b.start_time and a.end_time<b.end_time) end) end
    if res.mode=="sort by time" and res.mod then table.sort(subtable,function(a,b) return a.end_time<b.end_time or (a.end_time==b.end_time and a.start_time<b.start_time) end) end
    if res.mode=="reverse" then table.sort(subtable,function(a,b) return a.i>b.i end) end
    if res.mode=="width of text" then table.sort(subtable,function(a,b) return a.width<b.width or (a.width==b.width and a.i<b.i) end) end
    if res.mode=="dialogue first" then table.sort(subtable,function(a,b) return a.st<b.st or (a.st==b.st and a.i<b.i) end) end
    if res.mode=="dialogue last" then table.sort(subtable,function(a,b) return a.st>b.st or (a.st==b.st and a.i<b.i) end) end
    if res.mode=="ts/dialogue/oped" then table.sort(subtable,function(a,b) return a.sdo<b.sdo or (a.sdo==b.sdo and a.i<b.i) end) end
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
function selectall(subs, sel)
sel={}
    for i=1, #subs do
	if subs[i].class=="dialogue" then table.insert(sel,i) end
    end
    return sel
end

function esc(str)
str=str
:gsub("%%","%%%%")
:gsub("%(","%%%(")
:gsub("%)","%%%)")
:gsub("%[","%%%[")
:gsub("%]","%%%]")
:gsub("%.","%%%.")
:gsub("%*","%%%*")
:gsub("%-","%%%-")
:gsub("%+","%%%+")
:gsub("%?","%%%?")
return str
end

--	EDITOR
function editlines(subs, sel)
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
    editbox(subs, sel)
    if failt==1 then editext=res.dat editbox(subs, sel) end
    return sel
end

--	EDITOR GUI
function editbox(subs, sel)
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
	for wrd in plaintxt:gmatch("%w+") do
	words=words+1
	end
	if lastrep1==nil then lastrep1="" end
	if lastrep2==nil then lastrep2="" end
	GUI=
	{
	    {x=0,y=0,width=52,height=1,class="label",label="Text"},
	    {x=52,y=0,width=5,height=1,class="label",label="Duration | CPS | chrctrs"},
	    
	    {x=0,y=boxheight+1,width=1,height=1,class="label",label="Replace:"},
	    {x=1,y=boxheight+1,width=15,height=1,class="edit",name="rep1",value=lastrep1},
	    {x=16,y=boxheight+1,width=1,height=1,class="label",label="with"},
	    {x=17,y=boxheight+1,width=15,height=1,class="edit",name="rep2",value=lastrep2},
	    
	    {x=0,y=1,width=52,height=boxheight,class="textbox",name="dat",value=editext},
	    {x=52,y=1,width=5,height=boxheight,class="textbox",name="durr",value=dura,hint="This is informative only. \nCPS=Characters Per Second"},
	    
	    {x=32,y=boxheight+1,width=20,height=1,class="edit",name="info",value="Lines loaded: "..#sel..", Characters: "..editext:len()..", Words: "..words },
	    {x=52,y=boxheight+1,width=5,height=1,class="label",label="Multi-Line Editor v1.33"},
	}
	buttons={"Save","Replace","Remove tags","Rm. comments","Remove \"- \"","Remove \\N","Add italics","Add \\an8","Reload text","Taller GUI","Cancel"}
	repeat
	if pressed=="Replace" or pressed=="Add italics" or pressed=="Add \\an8" or pressed=="Remove \\N" or pressed=="Reload text"
		or pressed=="Remove tags" or pressed=="Rm. comments" or pressed=="Remove \"- \"" or pressed=="Taller GUI" then
		
		if pressed=="Add italics" then
		res.dat=res.dat	:gsub("$","\n") :gsub("(.-)\n","{\\i1}%1\n") :gsub("{\\i1}{\\","{\\i1\\") :gsub("\n$","") end
		if pressed=="Add \\an8" then
		res.dat=res.dat	:gsub("$","\n") :gsub("(.-)\n","{\\an8}%1\n") :gsub("{\\an8}{\\","{\\an8\\") :gsub("\n$","") end
		if pressed=="Remove \\N" then res.dat=res.dat	:gsub("%s?\\N%s?"," ") end
		if pressed=="Remove tags" then res.dat=res.dat:gsub("{%*?\\[^}]-}","") end
		if pressed=="Rm. comments" then res.dat=res.dat:gsub("{[^\\}]-}","") :gsub("{[^\\}]-\\N[^\\}]-}","") end
		if pressed=="Remove \"- \"" then res.dat=res.dat:gsub("%- ","") end
		if pressed=="Replace" then rep1=esc(res.rep1)
		res.dat=res.dat:gsub(rep1,res.rep2)
		end
		if pressed=="Taller GUI" then boxheight=boxheight+1 
		  for key,val in ipairs(GUI) do
		    if val.y==1 then val.height=val.height+1 end
		    if val.y>1 then val.y=val.y+1 end
		  end
		end
		
		for key,val in ipairs(GUI) do
		  if pressed~="Reload text" then
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
	pressed, res=aegisub.dialog.display(GUI,buttons,{save='Save',close='Cancel'})
	until pressed=="Save" or pressed=="Cancel"

	if pressed=="Cancel" then aegisub.cancel() end
	if pressed=="Save" then savelines(subs, sel) end
	lastrep1=res.rep1
	lastrep2=res.rep2
	return sel
end

--	EDITOR SAVE
function savelines(subs, sel)
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
    if failt==1 then aegisub.dialog.display({{class="label",
		    label="Line count of edited text does not \nmatch the number of selected lines.",x=0,y=0,width=1,height=2}},{"OK"})  
		    clipboard.set(res.dat) end
	aegisub.set_undo_point(script_name)
	return sel
end

function selector(subs,sel,act)
    sel=konfig(subs,sel,act)
    if edtr==1 and res.editor then editlines(subs,sel,act) end
    aegisub.set_undo_point(script_name)
    if res.nomatch=="doesn't match" and pressed=="Set Selection" then return sel2, act else return sel, act end
end

aegisub.register_macro(script_name, script_description, selector)