script_name="Colorize"
script_description="Does things with colours"
script_author="unanimated"
script_version="4.5"
script_namespace="ua.Colorize"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="4.5.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

info={}
info.colorize=[[
"Colorize letter by letter"
Alternates between 2-5 colours character by character, like 121212, or 123412341234.
Works for primary/border/shadow/secondary (one at a time).
Comments are preserved but all shifted to the end of the line.
 
"Colorize by word"
Colorizes by word instead of by letter.
 
"Don't join with other tags" will keep {initial tags}{colour} separated (ie. won't nuke the "}{").
This allows some other scripts to keep the colour as part of the "text" without initial tags.]]
info.shift=[[
"Shift"
Shift can be used on an already colorized line to shift the colours by one letter.
You have to set the right number of colours for it to work correctly!
If "shift base" is "line", then it takes the colour for the first character from the last character.
  
"Continuous shift line by line"
If you select a bunch of the same colorized lines, this shifts the colours line by line.
This kind of requires that no additional weird crap is done to the lines; otherwise malfunctioning can be expected.]]
info.tunecolours=[[
"Tune colours"
Loads all colours from a line into a GUI and lets you change them from there.
Useful for changing colours in transforms or just tuning lines with multiple colours.

"All selected" loads all 'unique' colours from all selected lines, rather than all from each line.
This is much more useful for tuning/replacing colours in a larger selection.

You can select "all/nontf/transf" to affect colours only from transforms, only those not from transforms, or all.]]
info.setcolours=[[
"Set colours across whole line"
This is like a preparation for a gradient by character. Select number of colours.
For 3 colours, it will place one at the start, one in the middle, and one before the last character.
Works for 2-10 colours and sets them evenly across the line.]]
info.gradient=[[
"Gradient"
Creates a gradient by character. (Uses Colorize button.)
There are two modes: RGB and HSL. RGB is the standard, like lyger's GBC;
HSL interpolates Hue, Saturation, and Lightness separately.
Use the \c, \3c, \4c, \2c checkboxes on the right to choose which colour to gradient.

"Shortest hue" makes sure that hue is interpolated in the shorter direction.
Unchecking it will give you a different gradient in 50% cases.

"Double HSL gradient" will make an extra round through Hue. Note that neither of these 2 options applies to RGB.

"Use asterisks" places asterisks like lyger's GBC so that you can ungradient the line with his script.

You can use acceleration if you type it in Effect, in the following form: "accel1.5"

There are several differences from lyger's GBC:
	- RGB / HSL option
	- You can choose which types of colour you want to gradient
	- Other tags don't interfere with the colour gradients
	- You can use acceleration]]
info.reverse=[[
"Reverse gradient"
On the right, select types of colours to apply this to.
For each colour type, colours from all tags in the line outside transforms are collected
and returned in the opposite direction.
A full gradient gets thus reversed.
(This is separate from the Gradient function, so no need to check that.)]]
info.match=[[
"Match Colours"
This should apply to all colour tags in the line.

c -> 3c: outline colour is changed to match primary
3c -> c: primary colour is changed to match outline
c -> 4c: shadow colour is changed to match primary
3c -> 4c: shadow colour is changed to match outline
c <-> 3c: primary and outline are switched
Invert: all colours are inverted (red->green, yellow->blue, black->white)]]
info.RGBHSL=[[
"Adjust RGB / HSL"
Adjusts Red/Green/Blue or Hue/Saturation/Lightness.
This works for lines with multiple same-type colour tags, including gradient by character.
You can select from -255 to 255.
Check types of colours you want it to apply to.
"Apply to missing" means it will be applied to the colour set in style if there's no tag in the line.
"Randomize" - if you set Lightness (or any RGB/HSL) to 20, the resulting colour will have anywhere between -20 and +20 of the original Lightness.]]
info.general=[[
"Remember last" - Remembers last settings of checkboxes and dropdown menus.

"Repeat last" - Repeat the function with last settings.
 
"Save config" - Saves a config file in your Application Data folder with current settings.

"Colorize" functions: if more selected, the one lowest in the GUI is run.

Full manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#colorize
]]

re=require'aegisub.re'

--	Colour Ice	--
function colors(subs,sel)
    local c={}
    for k=1,5 do
	c[k]=res["c"..k]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
    end
    for z,i in ipairs(sel) do
        progress("Colorizing line "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
	
	if res.kol=="primary" then k="\\c" text=text:gsub("\\1?c&H%x+&","") end
	if res.kol=="border" then k="\\3c" text=text:gsub("\\3c&H%x+&","") end
	if res.kol=="shadow" then k="\\4c" text=text:gsub("\\4c&H%x+&","") end
	if res.kol=="secondary" then k="\\2c" text=text:gsub("\\2c&H%x+&","") end
	
	k1=k..c[1]
	k2=k..c[2]
	k3=k..c[3]
	k4=k..c[4]
	k5=k..c[5]

	tags=text:match(STAG) or ""
	orig=text:gsub(STAG,"")
	comm="" for c in text:gmatch("{[^\\}]*}") do comm=comm..c end
	text=text:gsub("%b{}","") :gsub("%s*$","")

	if res.clrs=="2" then
	    if res.word then
		text=text.." * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 ")
	    else
		text=text:gsub("%s","  ") text=text.."*"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2")
		text=text:gsub("{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s"," ")
	    end
	end
	
	if res.clrs=="3" then
	    if res.word then
		text=text.." * * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 {\\"..k3.."}\\3 ")
	    else
		text=text:gsub("%s","   ") text=text:gsub("\\N","\\N~") text=text.."**"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2{\\"..k3.."}\\3")
		text=text:gsub("{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s"," "):gsub("{\\%d?c&H%x+&}~","")
	    end
	end
	
	if res.clrs=="4" then
	    if res.word then
		text=text.." * * * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 {\\"..k3.."}\\3 {\\"..k4.."}\\4 ")
	    else
		text=text:gsub("%s","    ") text=text:gsub("\\N","\\N\\N") text=text.."***"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2{\\"..k3.."}\\3{\\"..k4.."}\\4")
		text=text:gsub("{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s"," ")
	    end
	end
	
	if res.clrs=="5" then
	    if res.word then
		text=text.." * * * * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 {\\"..k3.."}\\3 {\\"..k4.."}\\4 {\\"..k5.."}\\5 ")
	    else
		text=text:gsub("%s","     ") text=text:gsub("\\N","\\N\\N~") text=text.."****"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2{\\"..k3.."}\\3{\\"..k4.."}\\4{\\"..k5.."}\\5")
		text=text:gsub("{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s{\\%d?c&H%x+&}%s"," "):gsub("{\\%d?c&H%x+&}~","")
	    end
	end

	text=text:gsub("{\\%d?c&H%x+&}%*",""):gsub("[%s%*]+$",""):gsub(" $","")
	:gsub("{\\%d?c&H%x+&}\\{\\%d?c&H%x+&}N","\\N"):gsub("\\N\\N","\\N")
	text=tags..text
	text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
	if not res.join then text=text:gsub("}{","") end
	if orig:match("{%*?\\") then text=textmod(orig) end
	text=text..comm
	line.text=text
        subs[i]=line
    end
end


--	Tune Colours	--
function ctune(subs,sel)
    if res.tuneall then
	tuneallc=""
	for z,i in ipairs(sel) do
	  t=subs[i].text
	  if res.tfmode=="regular" then t=t:gsub("\\t%b()","") end
	  if res.tfmode=="transf" then nt="" for tf in t:gmatch("\\t%b()") do nt=nt..tf end t=nt end
	  for kol in t:gmatch("\\%d?c%b&&") do
	    if not tuneallc:match(kol) then tuneallc=tuneallc..kol end
	  end
	end
	tuneallc=tuneallc:gsub("\\c&","\\1c&")
	tunegui()
	for l=1,4 do
	  if tuneallc:match(l.."c&") then table.insert(colortunegui,lbls[l]) end
	end
	for col in tuneallc:gmatch("(\\[1234]c&H%x%x%x%x%x%x&)") do
	    cType,B,G,R=col:match("\\([1234])c&H(%x%x)(%x%x)(%x%x)&")
	    ctNo=tonumber(cType)
	    C="#"..R..G..B
	    table.insert(colortunegui,{x=cType,y=wai[ctNo],class="color",name=cType..wai[ctNo],value=C})
	    wai[ctNo]=wai[ctNo]+1
	end
	pressed,rez=ADD(colortunegui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pressed=="Cancel" then ak() end
	replcol={}
	for k,v in ipairs(colortunegui) do
		if v.class=="color" then
		c1="\\"..v.x.."c"..v.value:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
		c2="\\"..v.x.."c"..rez[v.name]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
		table.insert(replcol,{c1=c1,c2=c2}) end
	end
    end
    for z=1,#sel do
        i=sel[z]
	progress("Processing... "..z.."/"..#sel)
	line=subs[i]
        text=line.text:gsub("\\c&","\\1c&")
	if res.tuneall then
	  text=alltune(text)
	elseif text:match("c&H%x+&") then
	  tunegui(z)
	  tekst={}
	  ccheck={}
	  text=tunec(text)
	end
	text=text:gsub("\\1c&","\\c&")
	line.text=text
	subs[i]=line
    end
    pressed=nil
end

function tunegui(z)
	wai={1,1,1,1}
	chk={0,0,0,0}
	lbls={{label="primary"},{label="2ndary"},{label="border"},{label="shadow"}}
	for l=1,4 do lbls[l].class="label" lbls[l].x=l end
	if res.tuneall then colortunegui={} else colortunegui={{class="label",label="#"..z}} end
end

function alltune(text)
	segments={}
	text=text:gsub("\\t%([^\\%)]-%)","")
	if text:match("\\t%b()") then
		for seg1,seg2 in text:gmatch("(.-)(\\t%b())") do table.insert(segments,seg1) table.insert(segments,seg2) end
		table.insert(segments,text:match("^.*\\t%b()(.-)$"))
	else table.insert(segments,text)
	end
	nt=""
	for q=1,#segments do
		if segments[q]:match("\\t%b()") and modetf then segments[q]=replicolor(segments[q])
		elseif not segments[q]:match("\\t%b()") and modereg then segments[q]=replicolor(segments[q])
		end
		nt=nt..segments[q]
	end
	return nt
end

function replicolor(t)
	for rc=1,#replcol do t=t:gsub(replcol[rc].c1,replcol[rc].c2) end
	return t
end

function tunec(text)
	segments={}
	text=text:gsub("\\t%([^\\%)]-%)","")
	if text:match("\\t%b()") then
		for seg1,seg2 in text:gmatch("(.-)(\\t%b())") do table.insert(segments,seg1) table.insert(segments,seg2) end
		table.insert(segments,text:match("^.*\\t%b()(.-)$"))
	else table.insert(segments,text)
	end
	for q=1,#segments do
		if segments[q]:match("\\t%b()") and modetf then segments[q]=tune(segments[q])
		elseif not segments[q]:match("\\t%b()") and modereg then segments[q]=tune(segments[q])
		else table.insert(tekst,segments[q]) table.insert(ccheck,0) end
	end
	
	pressed,rez=ADD(colortunegui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pressed=="Cancel" then ak() end
	
	text=""
	rezlt={1,1,1,1}
	for c=1,#tekst do
	  nt=tekst[c]
	  if ccheck[c]==1 then
	    col=nt:match("\\[1234]c&H%x%x%x%x%x%x&")
	    cType,B,G,R=col:match("\\([1234])c&H(%x%x)(%x%x)(%x%x)&")
	    ctNo=tonumber(cType)
	    cor=esc(col)
	    crep="\\"..cType.."c"..rez[cType..rezlt[ctNo]]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
	    text=text..nt:gsub(cor,crep)
	    rezlt[ctNo]=rezlt[ctNo]+1
	  else text=text..nt
	  end
	end
	return text
end

function tune(txt)
	for t,col in txt:gmatch("(.-)(\\[1234]c&H%x%x%x%x%x%x&)") do
	    cType,B,G,R=col:match("\\([1234])c&H(%x%x)(%x%x)(%x%x)&")
	    ctNo=tonumber(cType)
	    C="#"..R..G..B
	    if chk[ctNo]==0 then table.insert(colortunegui,lbls[ctNo]) chk[ctNo]=1 end
	    table.insert(colortunegui,{x=cType,y=wai[ctNo],class="color",name=cType..wai[ctNo],value=C})
	    table.insert(tekst,t..col)
	    table.insert(ccheck,1)
	    wai[ctNo]=wai[ctNo]+1
	end
	final=txt:match(".*\\[1234]c&H%x%x%x%x%x%x&(.-)$")
	if not final then final=txt end
	table.insert(tekst,final)
	table.insert(ccheck,0)
	return txt
end


--	Colours across line	--
function gcolors(subs,sel)
cn=tonumber(res.gclrs)
fn=cn-1
-- factors table
fakt={0}
for f=1,fn do
    fk=f/fn
    table.insert(fakt,fk)
end
-- GUI
gc_config={{x=0,y=0,class="dropdown",name="gctype",items={"\\c","\\3c","\\4c","\\2c"},value="\\c"}}
for c=1,cn do
    cte={x=c,y=0,class="color",name="gc"..c}
    table.insert(gc_config,cte)
end
button={"This is a rather big button","Click this, and something might happen","What is this, I don't even","The do-not-cancel button","I accept the terms of this scam","Is this really the right button?","What do I do with all these colours?!","I sure hope nothing will break if I do this","Yeah, okay. Fine. I'm gonna click on this.","Is this button safe to click?","Anyone else feels like this is a bit random?","We interrupt your typesetting to bring you a button!","I assure you this script actually works (maybe)","No, but seriously, click me!"}
ex=math.random(1,#button)
if not res.rept then press,rez=ADD(gc_config,{button[ex],"Cancel"},{close='Cancel'}) end
if press=="Cancel" then ak() end
kt=rez.gctype
-- colours table
kolors={}
for c=1,cn do
    gcol=rez["gc"..c]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
    gcol=kt..gcol
    table.insert(kolors,gcol)
end

    for z,i in ipairs(sel) do
        progress("Colorizing line "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
	:gsub("\\1c","\\c") :gsub(kt.."&H%x+&","") :gsub("{}","")
	tags=text:match(STAG) or ""
	orig=text:gsub(STAG,"")
	breaks=text:gsub("%b{}","")
	text=breaks:gsub("\\N","")
	clean=text:gsub(" ","")
	len=re.find(clean,".")
	nt=""
	for n=cn,1,-1 do
		lngth=math.ceil((#len-1)*fakt[n])
		kolr=kolors[n]
		seg=re.sub(text,"[\\w[:punct:]\\=\\+\\^\\$]\\s?","",lngth)
		if lngth==0 then seg=text end
		text=text:gsub(esc(seg).."$","")
		seg="{"..kolr.."}"..seg
		nt=seg..nt
	end
	text=nt
	text=tags..textmod(orig)
	text=text:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2")
	:gsub(ATAG,function(tg) repeat tg,r=tg:gsub(kt.."[%d%.%-]+([^}]-)("..kt.."[%d%.%-]+)","%2%1") until r==0 return tg end)
	:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
	
	for breakpos in breaks:gmatch("(.-)\\N") do
		BPL=breakpos:len()
		if LBP then BPL=BPL+LBP+2 end
		if BPL>0 then text=insertxt(text,BPL,"\\N") end
		LBP=BPL or 0
	end
	LBP=nil
	
	line.text=text
        subs[i]=line
    end
end

function insertxt(text,txtpos,thing)
	pos=0
	tcount=0
	for tg,tx in text:gmatch("("..ATAG..")([^{]*)") do
		sl=tx:len() tl=tg:len()
		if sl+pos<txtpos then pos=pos+sl tcount=tcount+tl
		else
			cpos=txtpos-pos
			fullpos=pos+tcount+tl+cpos
			break
		end
	end
	before=text:sub(0,fullpos)
	after=text:sub(fullpos+1)
	text=before..thing..after
	return text
end


--	Shift colours	--
function shift(subs,sel)
	klrs=tonumber(res.clrs)	-- how many colours we're dealing with
	count=1				-- start line counter
	if res.shit=="line" then sline=true else sline=false end
    for z,i in ipairs(sel) do
        progress("Colorizing line "..z.."/"..#sel)
	line=subs[i]
	text=line.text

	    -- check if line looks colorized
	    ccc=re.find(text,"\\{\\\\[1234]?c&H[A-Fa-f0-9]+&\\}[\\w[:punct:]]")
	    if not ccc then t_error("Line "..z.." does not \nappear to be colorized",1) end

	    -- determine which colour has been used to colorize - 1c, 2c, 3c, 4c
	    if sline then 
		matches=re.find(text,"\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\}[^\\{]*$")
		cms=matches[1].str
		ctype,shc=cms:match("{%*?(\\[1234]?c)(&H%x+&)}[^{]*$")
		first="{"..ctype..shc.."}"
	    else
		matches=re.find(text,"\\{\\\\[1234]?c&H[A-Fa-f0-9]+&\\}[\\w[:punct:]]")
		cms=matches[1].str
		ctype=cms:match("\\[1234]?c")

		-- get colours 2, 3, 4, 5, and create sequences for shifting
		matches=re.match(text,"([\\w[:punct:]]\\s?)(\\{\\"..ctype.."&H[A-Fa-f0-9]+&\\})([\\w[:punct:]]\\s?)(\\{\\"..ctype.."&H[A-Fa-f0-9]+&\\})([\\w[:punct:]]\\s?)(\\{\\"..ctype.."&H[A-Fa-f0-9]+&\\})([\\w[:punct:]]\\s?)(\\{\\"..ctype.."&H[A-Fa-f0-9]+&\\})")
		if matches==nil then 
		  matches=re.match(text,"([\\w[:punct:]]\\s?)(\\{\\"..ctype.."&H[A-Fa-f0-9]+&\\})([\\w[:punct:]]\\s?)(\\{\\"..ctype.."&H[A-Fa-f0-9]+&\\})")
		  c2=matches[3].str	c3=matches[5].str
		  else
		  c2=matches[3].str	c3=matches[5].str	c4=matches[7].str	c5=matches[9].str
		end
		
		if klrs==2 then first=c2 end
		if klrs==3 then first=c3 second=c2 end
		if klrs==4 then first=c4 second=c3 third=c2 end
		if klrs==5 then first=c5 second=c4 third=c3 fourth=c2 end
	    end

	    -- don't run for 1st lines in sequences
	    if count>1 or not res.cont then

		-- separate first colour tag from other tags, save initial tags
		tags=""
		if text:match("^{[^}]*"..ctype.."&") then text=text:gsub("^({[^}]*)("..ctype.."&H%x+&)([^}]*})","%1%3{%2}") end
		if not text:match("^{\\%d?c&H%x+&}") then tags=text:match(STAG) or "" text=text:gsub("^{\\[^}]*}","") end

		-- shifting colours happens here
		switch=1
		repeat
		text=re.sub(text,"(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})([\\w[:punct:]])","\\2\\1")
		text=re.sub(text,"(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})(\\s)","\\2\\1")
		text=re.sub(text,"(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})(\\\\N)","\\2\\1")
		text=re.sub(text,"(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})$","")
		text=text:gsub("{}","")
		text=first..text
		switch=switch+1
		if not sline then
		  if switch==2 then first=second end
		  if switch==3 then first=third end
		  if switch==4 then first=fourth end
		else
		  matches=re.find(text,"\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\}[^\\{]*$")
		  cms=matches[1].str
		  ctype,shc=cms:match("{%*?(\\[1234]?c)(&H%x+&)}[^{]*$")
		  first="{"..ctype..shc.."}"
		end
		  for cl1,cl2,cl3 in text:gmatch("({\\[1234]?c&H%x+&})(.)({\\[1234]?c&H%x+&})") do
		    if cl1==cl3 then
		    text=text:gsub(cl1..cl2..cl3,cl1..cl2)
		    end
		  end
		until switch>=count

		text=tags..text
		if res.join==false then text=text:gsub("}{","") end
	    end

	-- line counter
	if res.cont then count=count+1 end
	if not sline and count>klrs then count=1 end
	line.text=text
        subs[i]=line
    end
end


--	Match colours	--
function matchcolors(subs,sel)
	if P=="Match Colours" then _=0
    	  for key,val in ipairs(GUI) do
	    if val.name and val.name:match"match" and res[val.name] then _=_+1 end
	    if val.name and val.name=="invert" and res[val.name] then _=_+1 end
	  end
	if _>1 then t_error("Multiple checkboxes for matching checked.\nResults may be unpredictable.") end
	end
    for z,i in ipairs(sel) do
        progress("Colorizing line "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	if defaref and line.style=="Default" then sr=defaref
	elseif lastref and laststyle==line.style then sr=lastref
	else sr=stylechk(line.style) end
	lastref=sr	laststyle=line.style
	stylecol=stylecolours()
	text=text:gsub("\\1c","\\c")
	if not text:match("^{\\") then text=text:gsub("^","{\\}") end
	tags=text:match(STAG)
	notftags=tags:gsub("\\t%b()","")

	-- 1-->3   match outline to primary
	if P=="Match Colours" and res.match13 then
		if not notftags:match("\\c&") then text=addtag3("\\c"..primary,text) end
		text=macchi(text,"\\c","\\3c")
	end

	-- 3-->1   match primary to outline
	if P=="Match Colours" and res.match31 then
		if not notftags:match("\\3c") then text=addtag3("\\3c"..outline,text) end
		text=macchi(text,"\\3c","\\c")
	end

	-- 1-->4   match shadow to primary
	if P=="Match Colours" and res.match14 then
		if not notftags:match("\\c&") then text=addtag3("\\c"..primary,text) end
		text=macchi(text,"\\c","\\4c")
	end

	-- 3-->4   match shadow to outline
	if P=="Match Colours" and res.match34 then
		if not notftags:match("\\3c") then text=addtag3("\\3c"..outline,text) end
		text=macchi(text,"\\3c","\\4c")
	end

	-- 1<-->3   switch primary and border
	if P=="Match Colours" and res.match131 then
		if not notftags:match("\\c&") then text=addtag3("\\c"..primary,text) end
		if not notftags:match("\\3c") then text=addtag3("\\3c"..outline,text) end
		text=text:gsub("\\c&","\\tempc&"):gsub("\\3c","\\c"):gsub("\\tempc","\\3c")
	end

	-- Invert All Colours  
	if P=="Match Colours" and res.invert then
		for n=1,4 do
		    ctg="\\"..n.."c"
		    ctg=ctg:gsub("1","")
		    if not notftags:match(ctg) and n~=2 then text=addtag3(ctg..stylecol[n],text) end
		end
		for tg,color in text:gmatch("(\\[1234]?c&H)(%x%x%x%x%x%x)&") do
		    icolor=""
		    for kol in color:gmatch("(%x%x)") do
			dkol=tonumber(kol,16)
			idkol=255-dkol
			ikol=tohex(idkol)
			icolor=icolor..ikol
		    end
		    text=text:gsub(tg..color,tg..icolor)
		end
	end

	-- RGB / HSL
	if P=="RGB" or P=="HSL" then
	    lvlr=res.R lvlg=res.G lvlb=res.B
	    hue=res.huehue sat=res.satur brite=res.bright
	    corols={}
	    if res.k1 then table.insert(corols,1) end
	    if res.k2 then table.insert(corols,2) end
	    if res.k3 then table.insert(corols,3) end
	    if res.k4 then table.insert(corols,4) end
	    for i=1,#corols do
		kl="\\"..corols[i].."c"
		kl=kl:gsub("1","")
		if res.mktag and not notftags:match(kl) then text=addtag3(kl..stylecol[corols[i]],text) end
		if P=="RGB" then text=rgbhslmod(text,kl,rgbm) end
		if P=="HSL" then text=rgbhslmod(text,kl,hslm) end
	    end
	end

	text=text:gsub("\\([\\}])","%1") :gsub("\\t%([^\\%)]*%)","") :gsub("{}","")
	line.text=text
        subs[i]=line
    end
end

function macchi(text,c1,c2)
text=text:gsub(ATAG,function(ctags) ctags=ctags:gsub(c2..ACLR,""):gsub(c1.."("..ACLR..")",c1.."%1"..c2.."%1") return ctags end)
return text
end

function rgbhslmod(text,kl,ef)
	segments={}
	if text:match("\\t%b()") then
		for seg1,seg2 in text:gmatch("(.-)(\\t%b())") do table.insert(segments,seg1) table.insert(segments,seg2) end
		table.insert(segments,text:match("^.*\\t%b()(.-)$"))
	else table.insert(segments,text)
	end
	for q=1,#segments do
		if segments[q]:match("\\t%b()") and modetf then segments[q]=ef(segments[q],kl) end
		if not segments[q]:match("\\t%b()") and modereg then segments[q]=ef(segments[q],kl) end
	end
	nt=""
	for q=1,#segments do nt=nt..segments[q] end
	return nt
end

function rgbm(text,kl)
  for kol1,kol2,kol3 in text:gmatch(kl.."&H(%x%x)(%x%x)(%x%x)&") do
    kol1n=brightness(kol1,lvlb)
    kol2n=brightness(kol2,lvlg)
    kol3n=brightness(kol3,lvlr)
  text=text:gsub(kl.."&H"..kol1..kol2..kol3,kl.."&H"..kol1n..kol2n..kol3n)
  end
  return text
end

function hslm(text,kl)
  for kol1,kol2,kol3 in text:gmatch(kl.."&H(%x%x)(%x%x)(%x%x)&") do
  H1,S1,L1=RGB_to_HSL(kol3,kol2,kol1)
  H=H1+hue/255
  S=S1+sat/255
  L=L1+brite/255
  if randomize then
    H2=H1-hue/255
    S2=S1-sat/255
    L2=L1-brite/255
    H=math.random(H*1000,H2*1000)/1000
    S=math.random(S*1000,S2*1000)/1000
    L=math.random(L*1000,L2*1000)/1000
  end
  H,S,L=HSLround(H,S,L)
  kol3n,kol2n,kol1n=HSL_to_RGB(H,S,L)
  kol3n=tohex(round(kol3n))
  kol2n=tohex(round(kol2n))
  kol1n=tohex(round(kol1n))
  text=text:gsub(kl.."&H"..kol1..kol2..kol3,kl.."&H"..kol1n..kol2n..kol3n)
  end
  return text
end


--	GRADIENT	--
function gradient(subs,sel)
    styleget(subs)
    if res.grtype=="RGB" then GRGB=true else GRGB=false end
    if res.ast then ast="*" else ast="" end
    for z,i in ipairs(sel) do
        progress("Colorizing line "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	acc=line.effect:match("accel ?(%d+%.?%d*)")
	text=text:gsub("\\c&","\\1c&") :gsub(" *\\N *","{\\N}") :gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
	after=text:gsub(STAG,"")
	nc=text:gsub(COMM,"")
	if text:match(ATAG.."$") then text=text.."wtfwhywouldyoudothis" end
	
	-- colours from style
	sr=stylechk(line.style)
	stylecol=stylecolours()
	-- which types will be used
	applycol={}
	if res.k1 and after:match("\\1c") then table.insert(applycol,1) end
	if res.k2 and after:match("\\2c") then table.insert(applycol,2) end
	if res.k3 and after:match("\\3c") then table.insert(applycol,3) end
	if res.k4 and after:match("\\4c") then table.insert(applycol,4) end
	
	for g=1,#applycol do
	  ac=applycol[g]
	  sc=stylecol[ac]
	  tags=text:match(STAG) or ""
	  -- linebreak adjustment
	  if res.gradn then
	    startc=tags:match("\\"..ac.."c&H%x+&") or "\\"..ac.."c"..sc
	    endc=nc:match("(\\"..ac.."c&H%x+&)[^}]-}%S+$") or ""
	    text=text:gsub("([%S])%s*{\\N","{"..endc.."}%1{\\N}{"..startc)
	  end
	  -- back up original
	  orig=text
	  -- leave only releavant colour tags, nuke all other ones, add colour from style if missing at the start
	  ctext=text:gsub("\\N","") :gsub("\\[^1234][^c][^\\}]+","") :gsub("\\[^"..ac.."]c[^\\}]+","") :gsub("{%**}","")
	  if not ctext:match("^{\\") then ctext="{\\kolor}"..ctext end
	  if not ctext:match("^{[^}]-\\"..ac.."c") then 
		ctext=ctext:gsub("^({\\[^}]-)}","%1\\"..ac.."c"..sc.."}") end
	  -- make tables of colour tags and text after them
	  linecol={}
	  posi={}
	  coltext={}
	  pos=0
	  for k,t in ctext:gmatch("{[^}]-\\"..ac.."c&H(%x+)&[^}]-}([^{]+)") do
	    table.insert(posi,pos)
	    table.insert(linecol,k)
	    table.insert(coltext,t)
	    ps=re.find(t,".")
	    pos=#ps
	  end
	
	  -- text for each colour
	  gradtext=""
	
	  -- sequence for each colour tag / text
	  for c=1,#linecol-1 do
	    -- get RBG and HSL if needed
	    B1,G1,R1=linecol[c]:match("(%x%x)(%x%x)(%x%x)")
	    B2,G2,R2=linecol[c+1]:match("(%x%x)(%x%x)(%x%x)")
	    if not GRGB then
	      H1,S1,L1=RGB_to_HSL(R1,G1,B1)
	      H2,S2,L2=RGB_to_HSL(R2,G2,B2)
	      if res.hueshort then
	        if H2>H1 and H2-H1>0.5 then H1=H1+1 end
	        if H2<H1 and H1-H2>0.5 then H2=H2+1 end
	      end
	      if res.double then
	        if H2>H1 then H2=H2+1 else H1=H1+1 end
	        if H1>2 or H2>2 then H2=H2-1 H1=H1-1 end
	      end
	    end
	    -- letters of this sequence
	    textseq={}
	    ltrmatches=re.find(coltext[c],".")
		for l=1,#ltrmatches do
		    table.insert(textseq,ltrmatches[l].str)
		end
	    -- new text starting with original colour tag and first letter
	    ntxt="{\\"..ac.."c&H"..linecol[c].."&}"..textseq[1]
	    -- calculate colours for the other letters in sequence
	    for l=2,posi[c+1] do
	      if textseq[l]~=" " then
		if GRGB then	-- RGB
		  NC=acgrad(linecol[c],linecol[c+1],posi[c+1]+1,l,acc)
		else		-- HSL
		  Hdiff=(H2-H1)/(posi[c+1]+1)	H=H1+Hdiff*l
		  Sdiff=(S2-S1)/(posi[c+1]+1)	S=S1+Sdiff*l
		  Ldiff=(L2-L1)/(posi[c+1]+1)	L=L1+Ldiff*l
		  R,G,B=HSL_to_RGB(H,S,L)
		  R=tohex(round(R))
		  G=tohex(round(G))
		  B=tohex(round(B))
		  NC="&H"..B..G..R.."&"
		end
		ncol="{"..ast.."\\"..ac.."c"..NC.."}"
		-- colour + letter
		ntxt=ntxt..ncol..textseq[l]
	      else
	        -- spaces (no tags)
		ntxt=ntxt..textseq[l]
	      end
	    end
	    gradtext=gradtext..ntxt
	  end
	  -- add final tag + text
	  gradtext=gradtext.."{\\"..ac.."c&H"..linecol[#linecol].."&}"..coltext[#coltext]
	  text=tags..gradtext
	  -- merge with original
	  text=textmod(orig)
	end
	
	text=text:gsub("({%*?\\[^}]-})",function(tg) return colkill(tg) end)
	text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
	:gsub("wtfwhywouldyoudothis","")
	:gsub("{([^}]-)\\N([^}]-)}","\\N{%1%2}")
	:gsub("{%**}","")
	:gsub("([^{])%*\\","%1\\")
	line.text=text
        subs[i]=line
    end
end


--	Reverse Gradient	--
function rvrsgrad(subs,sel)
    for z,i in ipairs(sel) do
        progress("Colorizing line "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end) :gsub("\\c&","\\1c&")
	after=text:gsub(STAG,"")
	applycol={}
	if res.k1 and after:match("\\1c") then table.insert(applycol,1) end
	if res.k2 and after:match("\\2c") then table.insert(applycol,2) end
	if res.k3 and after:match("\\3c") then table.insert(applycol,3) end
	if res.k4 and after:match("\\4c") then table.insert(applycol,4) end
	
	for g=1,#applycol do
	  ac=applycol[g]
	  tagtab={}
	  coltab={}
	  for tt,cc in text:gmatch("(.-)(\\"..ac.."c&H%x+&)") do table.insert(tagtab,tt..cc) table.insert(coltab,cc) end
	  END=text:match("^.*\\"..ac.."c&H%x+&(.-)$")
	  for t=1,#tagtab do o=#tagtab-t+1
	    tagtab[t]=tagtab[t]:gsub("\\"..ac.."c&H%x+&",coltab[o])
	  end
	  nt=END
	  for a=#tagtab,1,-1 do nt=tagtab[a]..nt end
	  text=nt
	end
	
	text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end) :gsub("\\1c&","\\c&")
	line.text=text
        subs[i]=line
    end
end

function stylecolours()
stylecol={}	notf=text:gsub("\\t%b()","")
table.insert(stylecol,(sr.color1:gsub("H%x%x","H")))	primary=notf:match("^{[^}]-\\c(&H%x+&)") or stylecol[1]
table.insert(stylecol,(sr.color2:gsub("H%x%x","H")))	secondary=notf:match("^{[^}]-\\3c(&H%x+&)") or stylecol[2]
table.insert(stylecol,(sr.color3:gsub("H%x%x","H")))	outline=notf:match("^{[^}]-\\3c(&H%x+&)") or stylecol[3]
table.insert(stylecol,(sr.color4:gsub("H%x%x","H")))	shadow=notf:match("^{[^}]-\\c(&H%x+&)")or stylecol[4]
return stylecol
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

function textmod(orig)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
	vis=text:gsub("{[^}]-}","")
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

function colkill(tagz)
	tagz=tagz:gsub("\\1c&","\\c&")
	tags2={"c","2c","3c","4c"}
	for i=1,#tags2 do
	    tag=tags2[i]
	    tagz=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1")
	end
	return tagz
end

function RGB_to_HSL(Red,Green,Blue)
    R=(tonumber(Red,16)/255)
    G=(tonumber(Green,16)/255)
    B=(tonumber(Blue,16)/255)
    
    Min=math.min(R,G,B)
    Max=math.max(R,G,B)
    del_Max=Max-Min
    
    L=(Max+Min)/2
    
    if del_Max==0 then H=0 S=0
    else
      if L<0.5 then S=del_Max/(Max+Min)
      else S=del_Max/(2-Max-Min)
      end
      
      del_R=(((Max-R)/6)+(del_Max/2))/del_Max
      del_G=(((Max-G)/6)+(del_Max/2))/del_Max
      del_B=(((Max-B)/6)+(del_Max/2))/del_Max
      
      if R==Max then H=del_B-del_G
      elseif G==Max then H=(1/3)+del_R-del_B
      elseif B==Max then H=(2/3)+del_G-del_R
      end
      
      if H<0 then H=H+1 end
      if H>1 then H=H-1 end
    end
    return H,S,L
end

function HSL_to_RGB(H,S,L)
    if S==0 then
	R=L*255
	G=L*255
	B=L*255
    else
	if L<0.5 then var_2=L*(1+S)
	else var_2=(L+S)-(S*L)
	end
	var_1=2*L-var_2
	R=255*Hue_to_RGB(var_1,var_2,H+(1/3))
	G=255*Hue_to_RGB(var_1,var_2,H)
	B=255*Hue_to_RGB(var_1,var_2,H-(1/3))
    end
    return R,G,B
end

function Hue_to_RGB(v1,v2,vH)
    if vH<0 then vH=vH+1 end
    if vH>1 then vH=vH-1 end
    if (6*vH)<1 then return(v1+(v2-v1)*6*vH) end
    if (2*vH)<1 then return(v2) end
    if (3*vH)<2 then return(v1+(v2-v1)*((2/3)-vH)*6) end
    return(v1)
end

function HSLround(H,S,L)
  if H>1 then H=H-1 end
  if H<0 then H=H+1 end
  if S>1 then S=1 end
  if S<0 then S=0 end
  if L>1 then L=1 end
  if L<0 then L=0 end
  return H,S,L
end

function brightness(klr,lvl)
    klr=tonumber(klr,16)
    if randomize then
	rAn=math.random(klr-lvl,klr+lvl)
	klr=round(rAn)
    else
	klr=klr+lvl
    end
    if klr<0 then klr=0 end
    if klr<10 then klr="0"..klr else klr=tohex(klr) end
return klr
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
	    if styles[i].name=="Default" then defaref=styles[i] end
	    break
	end
    end
    if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
    return sr
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end

function round(num) num=math.floor(num+0.5) return num end

function addtag3(tg,txt)
	no_tf=txt:gsub("\\t%b()","")
	tgt=tg:match("(\\%d?%a+)[%d%-&]")	if not tgt then t_error("Adding tag '"..tg.."' failed.") end
	if no_tf:match("^({[^}]-)"..tgt.."[%d%-&]") then txt=txt:gsub("^({[^}]-)"..tgt.."[%d%-&][^\\}]*","%1"..tg)
	elseif not txt:match("^{\\") then txt="{"..tg.."}"..txt
	elseif txt:match("^{[^}]-\\t") then txt=txt:gsub("^({[^}]-)\\t","%1"..tg.."\\t")
	else txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
return txt
end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function repetition()
    if lastres and res.rept then res=lastres end
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

function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end

function saveconfig()
colconf="Colorize Configutation\n\n"
for key,val in ipairs(GUI) do
    if val.class=="checkbox" and val.name~="save" then colconf=colconf..val.name..":"..tf(res[val.name]).."\n" end
    if val.class=="dropdown" then colconf=colconf..val.name..":"..res[val.name].."\n" end
end
colorconfig=ADP("?user").."\\colorize.conf"
file=io.open(colorconfig,"w")
file:write(colconf)
file:close()
ADD({{class="label",label="Config Saved to:\n"..colorconfig}},{"OK"},{close='OK'})
end

function loadconfig()
colorconfig=ADP("?user").."\\colorize.conf"
file=io.open(colorconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	  for key,val in ipairs(GUI) do
	    if val.class=="checkbox" or val.class=="dropdown" then
	      if konf:match(val.name) then val.value=detf(konf:match(val.name..":(.-)\n")) end
	    end
	  end
    end
end

function colorize(subs,sel)
STAG="^{\\[^}]-}"
ATAG="{%*?\\[^}]-}"
COMM="{[^\\}]-}"
ACLR="&H%x+&"
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
	GUI={
	{x=0,y=0,class="label",label="Colours"},
	{x=1,y=0,width=2,class="dropdown",name="clrs",items={"2","3","4","5"},value="2",hint="number of colours for\n'colorize letter by letter'"},
	
	{x=0,y=1,class="label",label="Apply to:  "},
	{x=1,y=1,width=2,class="dropdown",name="kol",items={"primary","border","shadow","secondary"},value="primary"},
	
	{x=0,y=2,class="label",label="Shift base:"},
	{x=1,y=2,width=2,class="dropdown",name="shit",items={"# of colours","line"},value="# of colours",hint="shift by the number of colours the line had been colorized with,\nor shift the whole line (last colour becomes first)"},
	
	{x=4,y=0,class="label",label="  1 "},
	{x=4,y=1,class="label",label="  2 "},
	{x=4,y=2,class="label",label="  3 "},
	{x=4,y=3,class="label",label="  4 "},
	{x=4,y=4,class="label",label="  5 "},
	
	{x=5,y=0,class="color",name="c1"},
	{x=5,y=1,class="color",name="c2"},
	{x=5,y=2,class="color",name="c3"},
	{x=5,y=3,class="color",name="c4"},
	{x=5,y=4,class="color",name="c5"},
	
	{x=5,y=6,class="dropdown",name="tfmode",items={"all","regular","transf"},value="all",hint="all tags / regular tags / tags in transforms\napplies to 'Tune colours' and RGB/HSL"},
	
	{x=0,y=3,width=3,class="checkbox",name="word",label="Colorize by word"},
	{x=0,y=4,width=3,class="checkbox",name="join",label="Don't join with other tags"},
	{x=0,y=5,width=4,class="checkbox",name="cont",label="Continuous shift line by line"},
	{x=0,y=6,width=2,class="checkbox",name="tune",label="Tune colours"},
	{x=2,y=6,width=3,class="checkbox",name="tuneall",label="All selected",hint="load from / apply to all selected lines\nrather than one by one"},
	{x=0,y=7,width=5,class="checkbox",name="gcl",label="Set colours across whole line:"},
	{x=5,y=7,class="dropdown",name="gclrs",items={"2","3","4","5","6","7","8","9","10"},value="3"},
	
	{x=6,y=0,class="label",label=" "},
	
	{x=7,y=2,class="label",label="Red: "},
	{x=8,y=2,width=3,class="intedit",name="R",value=0,min=-255,max=255},
	{x=7,y=3,class="label",label="Green: "},
	{x=8,y=3,width=3,class="intedit",name="G",value=0,min=-255,max=255},
	{x=7,y=4,class="label",label="Blue: "},
	{x=8,y=4,width=3,class="intedit",name="B",value=0,min=-255,max=255},
	
	{x=7,y=5,class="label",label="Hue:"},
	{x=8,y=5,width=3,class="intedit",name="huehue",value=0,min=-255,max=255},
	{x=7,y=6,class="label",label="Saturation:"},
	{x=8,y=6,width=3,class="intedit",name="satur",value=0,min=-255,max=255},
	{x=7,y=7,class="label",label="Lightness:"},
	{x=8,y=7,width=3,class="intedit",name="bright",value=0,min=-255,max=255},
	
	{x=7,y=8,class="checkbox",name="k1",label="\\c       ",value=true},
	{x=8,y=8,class="checkbox",name="k3",label="\\3c      "},
	{x=9,y=8,class="checkbox",name="k4",label="\\4c      "},
	{x=10,y=8,class="checkbox",name="k2",label="\\2c"},
	{x=7,y=9,width=2,class="checkbox",name="mktag",label="Apply to missing",hint="Apply even to colours without tags in line"},
	{x=9,y=9,width=2,class="checkbox",name="randoom",label="Randomize",hint="randomize RGB/HSL within the\nspecified range in each direction"},
	
	{x=7,y=0,class="label",label="Match col.:"},
	{x=8,y=0,class="checkbox",name="match13",label="c->3c  ",hint="copy primary to outline"},
	{x=9,y=0,class="checkbox",name="match31",label="3c->c",hint="copy outline to primary"},
	{x=7,y=1,class="checkbox",name="match14",label="c->4c",hint="copy primary to shadow"},
	{x=8,y=1,class="checkbox",name="match34",label="3c->4c",hint="copy outline to shadow"},
	{x=9,y=1,class="checkbox",name="match131",label="c<->3c",hint="switch primary and outline"},
	{x=10,y=1,class="checkbox",name="invert",label="Invert",hint="invert colours"},
	
	{x=10,y=0,class="label",label="[ver. "..script_version.."]"},
	
	{x=0,y=8,width=2,class="checkbox",name="grad",label="Gradient  "},
	{x=2,y=8,width=3,class="checkbox",name="hueshort",label="Shortest hue",value=true},
	{x=5,y=8,class="dropdown",name="grtype",items={"RGB","HSL"},value="HSL"},
	{x=0,y=9,width=3,class="checkbox",name="double",label="Double HSL gradient"},
	{x=3,y=9,width=3,class="checkbox",name="ast",label="Use asterisks"},
	
	{x=0,y=10,width=3,class="checkbox",name="gradn",label="Restart after each \\N",hint="Restart gradient after each linebreak"},
	{x=0,y=11,width=3,class="checkbox",name="reverse",label="Reverse gradient",
	hint="Reverse the direction of \nnon-transform colours across the line"},
	
	{x=7,y=10,width=2,class="checkbox",name="rem",label="Remember last",hint="Remember last settings"},
	{x=9,y=10,width=2,class="checkbox",name="rept",label="Repeat last",hint="Repeat with last settings"},
	{x=7,y=11,class="checkbox",name="help",label="Help",
	hint="Loads Help. Topic menu is on the left.\nUse any button that's not 'Cancel'."},
	{x=9,y=11,width=2,class="checkbox",name="save",label="Save config",hint="Saves current configuration\n(for most things)"},
	
	{x=4,y=11,width=2,class="dropdown",name="hmenu",value="colorize",hint="Help menu",
	items={"colorize","shift","tunecolours","setcolours","gradient","reverse","match","RGBHSL","general"}}
	}
	loadconfig()
	if colourblind and res.rem then
	  for key,val in ipairs(GUI) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="color" then val.value=res[val.name] end
	    if val.name=="save" then val.value=false end
	  end
	end
	HELP=false
	NOHELP=true
	repeat
	if HELP then
	  if NOHELP then table.insert(GUI,{x=0,y=12,width=11,height=7,class="textbox",name="helpbox"}) end
	  for key,val in ipairs(GUI) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="color" then val.value=res[val.name] end
	    if val.name=="save" then val.value=false end
	    if val.name=="helpbox" then val.value=info[res.hmenu] end
	  end
	  NOHELP=false
	end
	P,res=ADD(GUI,{"Colorize","Shift","Match Colours","RGB","HSL","Cancel"},{ok='Colorize',close='Cancel'})
	HELP=res.help
	until P=="Cancel" or not res.help
	if P=="Cancel" then ak() end
	if res.save then saveconfig() ak() end
	
	randomize=res.randoom
	if res.tfmode=="all" or res.tfmode=="regular" then modereg=true else modereg=false end
	if res.tfmode=="all" or res.tfmode=="transf" then modetf=true else modetf=false end
	if P=="Colorize" then repetition()
	    if res.reverse then rvrsgrad(subs,sel)
	    elseif res.grad then gradient(subs,sel)
	    elseif res.gcl then gcolors(subs,sel)
	    elseif res.tune then ctune(subs,sel)
	    else colors(subs,sel) end
	end
	if P=="Shift" then repetition() shift(subs,sel) end
	if P=="Match Colours" or P=="RGB" or P=="HSL" then repetition() styleget(subs) matchcolors(subs,sel) end
	
	lastres=res
	colourblind=true
	aegisub.set_undo_point(script_name)
	return sel
end

if haveDepCtrl then depRec:registerMacro(colorize) else aegisub.register_macro(script_name,script_description,colorize) end