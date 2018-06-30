script_name="Colourise"
script_description="RGB Magic and HSL Sorcery"
script_author="unanimated"
script_version="5.0"
script_namespace="ua.Colourise"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="5.0.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

info={}
info.colourise=[[
"Colourise letter by letter"
Alternates between 2-6 colours character by character, like 121212, or 123412341234.
Works for all colour types (one at a time), based on the 'Apply to' menu.
Handles inline tags and comments.
 
"Colourise by word"
Colourises by word instead of by letter.

"Bounce Back" will create a sequence like 123432123432 instead of 12341234.]]
info.shift=[[
"Shift"
Shift can be used on an already colourised line to shift the colours by one letter.
You have to set the right number of colours for it to work correctly.
You'll be shitfing the colour type in the 'Apply to' menu.
If "shift base" is "line", then it takes the colour for the first character from the last one.
This way it can shift colours no matter how few/many tags there are and where.
  
"Shift line by line"
If you select a bunch of the same colourised lines, this shifts the colours line by line.
First line is shifted by one letter, second one by two, etc.]]
info.tunecolours=[[
"Tune colours"
Loads all colours from a line into a GUI and lets you change them from there.
Useful for changing colours in transforms or just tuning lines with multiple colours.

"All selected" loads all 'unique' colours from all selected lines, rather than all from each line.
This is much more useful for tuning/replacing colours in a larger selection.

You can select "all/nontf/transf" to affect colours only from transforms, only those not from transforms, or all.]]
info.setcolours=[[
"Set colours across whole line"
This is like a preparation for a gradient by character.
Select number of colours, and choose the colours to be used.
For 3 colours, it will place one tag at the start, one in the middle, and one before the last character.
For 2 colours, it'll be the first and last characters.
Works for 2-10 colours and sets them evenly across the line.]]
info.gradient=[[
"Gradient"
Creates a gradient by character. (Uses Colourise button.)
There are two modes: RGB and HSL. RGB is the standard, like lyger's GBC;
HSL interpolates Hue, Saturation, and Lightness separately.
Use the \c, \3c, \4c, \2c checkboxes on the right to choose which colours to gradient.

"Short hue" makes sure that hue is interpolated in the shorter direction.
Unchecking it will give you a different gradient in 50% cases.

"Double HSL gradient" will make an extra round through Hue. Note that neither of these two options applies to RGB.

"Use asterisks" places asterisks like lyger's GBC so that you can ungradient the line with his script.

"Restart after each \N" will create the full gradient for each line if there are linebreaks.

The edit box below that is for acceleration. You can still type accel in Effect, the old way,
in the form: accel1.5, and this will override the GUI setting, ensuring you can have
different accel for different lines.

There are several differences from lyger's GBC:
	- RGB / HSL option
	- You can choose which types of colour you want to gradient
	- Other tags don't interfere with the colour gradients
	- You can use acceleration

The hotkeyable macros run with \c and \3c checked, and 'short hue' for HSL.]]
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

c -> 3c: primary colour is copied to outline
3c -> c: outline colour is copied to primary
c -> 4c: primary colour is copied to shadow
3c -> 4c: outline colour is copied to shadow
c <-> 3c: primary and outline are switched
Invert: all colours are inverted (red->green, yellow->blue, black->white)]]
info.RGBHSL=[[
"Adjust RGB / HSL"
Adjusts Red/Green/Blue or Hue/Saturation/Lightness.
This works for lines with multiple same-type colour tags, including gradient by character.
You can select from -255 to 255.
Check types of colours you want it to apply to.
"Apply to missing" means it will be applied to the colour set in style if there's no tag in the line.
"Randomise" - if you set Lightness (or any RGB/HSL) to 20, the resulting colour will have anywhere between -20 and +20 of the original Lightness.]]
info.general=[[
"Remember last" - Remembers last settings of checkboxes and dropdown menus.

"Repeat last" - Repeat the function with last settings.
 
"Save config" - Saves a config file in your Application Data folder with current settings.

"Colourise" functions: if more selected, the one lowest in the GUI is run.

Full manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#colourise
]]

re=require'aegisub.re'

function cuts(subs)
STAG="^{>?\\[^}]-}"
ATAG="{[*>]?\\[^}]-}"
COMM="{[^\\}]-}"
ACLR="&H%x+&"
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
for i=1,#subs do	if subs[i].class=="dialogue" then line0=i-1 break end		end
end

function colourise(subs,sel)
	cuts(subs)
	validateCol(subs,sel)
	GUI={
	{x=0,y=0,class="label",label="Colours"},
	{x=1,y=0,width=3,class="dropdown",name="clrs",items={"2","3","4","5","6","7"},value="2",hint="number of colours for\n'colourise letter by letter'"},
	
	{x=0,y=1,class="label",label="Apply to:  "},
	{x=1,y=1,width=3,class="dropdown",name="kol",items={"\\c","\\3c","\\4c","\\2c"},value="\\c",hint="relevant for colourisng by letter, shifting, set across"},
	
	{x=0,y=2,class="label",label="Shift base:"},
	{x=1,y=2,width=3,class="dropdown",name="shit",items={"# of colours","line","1st2start","last2start","all2start"},value="# of colours",hint="shift by the number of colours the line had been colourised with,\nor shift the whole line (last colour becomes first)"},
	
	{x=4,y=0,class="label",label="壹"},
	{x=4,y=1,class="label",label="貳"},
	{x=4,y=2,class="label",label="參"},
	{x=4,y=3,class="label",label="肆"},
	{x=4,y=4,class="label",label="伍"},
	{x=4,y=5,class="label",label="陸"},
	{x=4,y=6,class="label",label="漆"},
	
	{x=5,y=0,class="color",name="c1"},
	{x=5,y=1,class="color",name="c2"},
	{x=5,y=2,class="color",name="c3"},
	{x=5,y=3,class="color",name="c4"},
	{x=5,y=4,class="color",name="c5"},
	{x=5,y=5,class="color",name="c6"},
	{x=5,y=6,class="color",name="c7"},
	
	{x=0,y=3,width=3,class="checkbox",name="word",label="Colourise by word"},
	{x=0,y=4,width=4,class="checkbox",name="bounce",label="Bounce back (123454321)",hint="colourise: sequence 1234321 instead of 12341234"},
	{x=0,y=5,width=4,class="checkbox",name="cont",label="Shift line by line",hint="shift more with each line"},
	{x=0,y=6,width=4,class="checkbox",name="across",label="Set colours across line"},
	
	{x=6,y=0,class="label",label=" "},
	
	{x=7,y=2,class="label",label="Red "},
	{x=8,y=2,width=3,class="intedit",name="R",value=0,min=-255,max=255},
	{x=7,y=3,class="label",label="Green "},
	{x=8,y=3,width=3,class="intedit",name="G",value=0,min=-255,max=255},
	{x=7,y=4,class="label",label="Blue "},
	{x=8,y=4,width=3,class="intedit",name="B",value=0,min=-255,max=255},
	
	{x=7,y=5,class="label",label="Hue"},
	{x=8,y=5,width=3,class="intedit",name="huehue",value=0,min=-255,max=255},
	{x=7,y=6,class="label",label="Saturation"},
	{x=8,y=6,width=3,class="intedit",name="satur",value=0,min=-255,max=255},
	{x=7,y=7,class="label",label="Lightness"},
	{x=8,y=7,width=3,class="intedit",name="light",value=0,min=-255,max=255},
	
	{x=7,y=8,class="checkbox",name="k1",label="\\c",value=true},
	{x=8,y=8,class="checkbox",name="k3",label="\\3c"},
	{x=9,y=8,class="checkbox",name="k4",label="\\4c"},
	{x=10,y=8,class="checkbox",name="k2",label="\\2c"},
	{x=7,y=9,width=2,class="checkbox",name="mktag",label="Apply to missing",hint="Apply even to colours without tags in line"},
	{x=9,y=9,width=2,class="checkbox",name="randoom",label="Randomise",hint="randomise RGB/HSL within the\nspecified range in each direction"},
	
	-- Match
	{x=7,y=0,height=2,class="label",label="Match\ncolours:"},
	{x=8,y=0,class="checkbox",name="match13",label="c->3c",hint="copy primary to outline"},
	{x=9,y=0,class="checkbox",name="match31",label="3c->c",hint="copy outline to primary"},
	{x=8,y=1,class="checkbox",name="match14",label="c->4c",hint="copy primary to shadow"},
	{x=9,y=1,class="checkbox",name="match34",label="3c->4c",hint="copy outline to shadow"},
	{x=10,y=0,class="checkbox",name="match131",label="c<->3c",hint="switch primary and outline"},
	{x=10,y=1,class="checkbox",name="invert",label="Invert",hint="invert colours (applies to the types chacked below)"},
	
	-- Gradient
	{x=0,y=7,width=2,class="checkbox",name="grad",label="Gradient  "},
	{x=2,y=7,width=3,class="checkbox",name="hueshort",label="Shorter hue",value=true},
	{x=5,y=7,class="dropdown",name="grtype",items={"RGB","HSL"},value="HSL"},
	{x=0,y=8,width=4,class="checkbox",name="gradn",label="Restart after each \\N",hint="Restart gradient after each linebreak"},
	{x=0,y=9,width=3,class="checkbox",name="double",label="Double HSL gradient"},
	{x=0,y=10,width=3,class="checkbox",name="ast",label="Use asterisks"},
	{x=0,y=11,width=3,class="floatedit",name="acc",value=1,min=0,hint="Acceleration for gradients"},
	
	-- Tune/Reverse
	{x=3,y=9,width=3,class="checkbox",name="tuneall",label="Tune all selected",hint="load from / apply to all selected lines\nrather than one by one"},
	{x=5,y=8,class="dropdown",name="tfmode",items={"all tags","regular","transf"},value="all tags",
	hint="all tags / regular tags / tags in transforms\napplies to 'Tune colours' and RGB/HSL"},
	{x=3,y=10,width=3,class="checkbox",name="reverse",label="Reverse colours",
	hint="Reverse the direction of non-transform colours across the line \nfor the types checked on the right"},
	
	{x=7,y=10,width=2,class="checkbox",name="rem",label="Remember last",hint="Remember last settings"},
	{x=9,y=10,width=2,class="checkbox",name="rept",label="Repeat last",hint="Repeat with last settings"},
	{x=7,y=11,width=2,class="checkbox",name="save",label="Save config",hint="Saves current configuration\n(for most things)"},
	{x=9,y=11,width=2,class="label",label="Colourise version "..script_version..""},
	
	{x=3,y=11,width=3,class="dropdown",name="help",value=": Help Menu :",hint="Choose a topic. Use any button that's not 'Cancel'.",
	items={": Help Menu :","colourise","shift","setcolours","gradient","tunecolours","reverse","match","RGBHSL","general"}}
	}
	loadconfig()
	if colourblind and res.rem then
		for key,val in ipairs(GUI) do
			if val.class=="checkbox" or val.class=="dropdown" or val.class=="color" or val.class:match"edit" then val.value=res[val.name] end
			if val.name=="save" then val.value=false end
			if val.name=="help" then val.value=": Help Menu :" end
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
			if val.name=="rept" then val.value=false end
			if val.name=="helpbox" then val.value=info[res.help] end
			if val.name=="help" then val.value=": Help Menu :" end
		end
		NOHELP=false
	end
	P,res=ADD(GUI,{"Colourise","Shift","Tune/Rvrs","Match Colours","RGB/HSL","Black Out"},{ok='Colourise',close='Black Out'})
	if res.help~=": Help Menu :" then HELP=true else HELP=false end
	until P=="Black Out" or res.help==": Help Menu :"
	if P=="Black Out" then ak() end
	if res.save then saveconfig() ak() end
	
	randomise=res.randoom
	if res.tfmode=="all tags" or res.tfmode=="regular" then modereg=true else modereg=false end
	if res.tfmode=="all tags" or res.tfmode=="transf" then modetf=true else modetf=false end
	if P=="Colourise" then repetition()
		if res.grad then gradient(subs,sel)
		elseif res.across then gcolours(subs,sel)
		else colors(subs,sel) end
	end
	if P=="Tune/Rvrs" then repetition()
		if res.reverse then rvrsgrad(subs,sel) else ctune(subs,sel) end
	end
	if P=="Shift" then repetition() if res.shit:match'start' then shift2(subs,sel) else shift(subs,sel) end end
	if P=="Match Colours" or P=="RGB/HSL" then repetition() styleget(subs) match_col(subs,sel) end
	
	lastres=res
	colourblind=true
	return sel
end


--	Colour Ice	--
function colors(subs,sel)
    local c={}
    for k=1,7 do
	c[k]=res["c"..k]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
    end
    for z,i in ipairs(sel) do
        progress("Colourising line #"..i-line0.." ["..z.."/"..#sel.."]")
	line=subs[i]
	text=line.text
	tags=text:match(STAG) or ""
	if not tags:match("\\p1") then
		text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
		visible=nobrea(text)
	
		local kl=res.kol
		if kl=="\\c" then text=text:gsub("\\1?c[^l\\})]*([\\}])","%1") end
		if kl=="\\3c" then text=text:gsub("\\3c[^\\})]*","") end
		if kl=="\\4c" then text=text:gsub("\\4c[^\\})]*","") end
		if kl=="\\2c" then text=text:gsub("\\2c[^\\})]*","") end
		text=text:gsub("{}","") 
		
		local col={}	-- table with colours to use
		for t=1,res.clrs do table.insert(col,wrap(kl..c[t])) end
		if res.bounce and tonumber(res.clrs)>2 then
			for t=res.clrs-1,2,-1 do table.insert(col,wrap(kl..c[t])) end
		end
	
		orig=text:gsub(STAG,""):gsub("\\N","{\\N}")
		-- save positions for inline tags and comments
		inTags=inline_pos(orig)
		if not res.word then
			-- by letter
			local letrz=re.find(visible,".") or {}
			letrz=re_test(letrz,visible)
			nt=""
			local p=1
			for k=2,#letrz do
				local ltr=letrz[k].str
				-- add colour tag positions to table
				if ltr~=" " then
					p=p%#col+1	-- cycle colours
					table.insert(inTags,{n=k-1,t=col[p]})
				end
			end
			table.sort(inTags,function(a,b) return a.n<b.n end)
			-- put back all inline tags
			local _=0
			repeat
				t2=inline_ret(visible,inTags)
				local vis=t2:gsub("%b{}","")
				_=_+1
			until vis==visible or _==666
			
			tags=tags..col[1]
			text=tags..t2
		else
			-- by word
			orig=orig:gsub("(%b{})",function(com) return com:gsub(" ","_SP_") end)
			local n=0
			t2=orig:gsub("%S+%s*",function(a) n=n%#col+1 b=col[n]..a return b end)
			text=tags..t2
			text=text:gsub("_SP_"," "):gsub("(%b{})(\\N)(%b{})","%2%3%1"):gsub("(%b{})(\\N)","%2%1")
		end
		
		text=text:gsub("{\\N","\\N{"):gsub("\\N}","}\\N"):gsub("{}","")
		text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
		text=tagmerge(text)
		text=text:gsub(ATAG,function(tg) return duplikill(tg) end)
		visible2=nobrea(text)
		txt_check(visible,visible2,i)
		line.text=text
		subs[i]=line
	end
    end
end


--	Tune Colours	--
function ctune(subs,sel)
    if res.tuneall then
	local tuneallc=""
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
	  if tuneallc:match(l.."c&") then table.insert(coltunegui,lbls[l]) end
	end
	for col in tuneallc:gmatch("(\\[1234]c&H%x%x%x%x%x%x&)") do
	    cType,B,G,R=col:match("\\([1234])c&H(%x%x)(%x%x)(%x%x)&")
	    ctNo=tonumber(cType)
	    C="#"..R..G..B
	    table.insert(coltunegui,{x=cType,y=wai[ctNo],class="color",name=cType..wai[ctNo],value=C})
	    wai[ctNo]=wai[ctNo]+1
	end
	pressed,rez=ADD(coltunegui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pressed=="Cancel" then ak() end
	replcol={}
	for k,v in ipairs(coltunegui) do
		if v.class=="color" then
		c1="\\"..v.x.."c"..v.value:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
		c2="\\"..v.x.."c"..rez[v.name]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
		table.insert(replcol,{c1=c1,c2=c2}) end
	end
    end
    for z=1,#sel do
        i=sel[z]
	progress("Processing... #"..i-line0.." ["..z.."/"..#sel.."]")
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
	if res.tuneall then coltunegui={} else coltunegui={{class="label",label="#"..z}} end
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
		if segments[q]:match("\\t%b()") and modetf then segments[q]=replicolour(segments[q])
		elseif not segments[q]:match("\\t%b()") and modereg then segments[q]=replicolour(segments[q])
		end
		nt=nt..segments[q]
	end
	return nt
end

function replicolour(t)
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
	
	pressed,rez=ADD(coltunegui,{"OK","Cancel"},{ok='OK',close='Cancel'})
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
	    if chk[ctNo]==0 then table.insert(coltunegui,lbls[ctNo]) chk[ctNo]=1 end
	    table.insert(coltunegui,{x=cType,y=wai[ctNo],class="color",name=cType..wai[ctNo],value=C})
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
function gcolours(subs,sel)
	local cn=tonumber(res.clrs)
	local fn=cn-1
	-- factors table
	fakt={0}
	for f=1,fn do table.insert(fakt,f/fn) end
	kt=res.kol
	-- colours table
	local kolors={}
	for c=1,cn do
	    gcol=res["c"..c]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
	    gcol=kt..gcol
	    table.insert(kolors,gcol)
	end

    for z,i in ipairs(sel) do
        progress("Colourising line #"..i-line0.." ["..z.."/"..#sel.."]")
	line=subs[i]
	text=line.text
	visible=nobrea(text):gsub("^ *(.-) *$","%1")
	text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
	:gsub("\\1c","\\c") :gsub(kt.."&H%x+&","") :gsub("{}","")
	tags=text:match(STAG) or ""
	orig=text:gsub(STAG,""):gsub("\\N",""):gsub("^ *(.-) *$","%1")
	breaks=text:gsub("%b{}",""):gsub("^ *(.-) *$","%1")
	text=breaks:gsub("\\N","")
	clean=text:gsub(" ","")
	back=text
	if clean~="" and not tags:match("\\p1") then
		local c=0
		repeat
		text=back
		len=re.find(clean,".") or {}
		nt=""
		for n=cn,1,-1 do
			lngth=math.ceil((#len-1)*fakt[n])
			kolr=kolors[n]
			seg=re.sub(text,"\\S\\s*","",lngth)
			if lngth==0 then seg=text end
			text=text:gsub(esc(seg).."$","")
			seg="{"..kolr.."}"..seg
			nt=seg..nt
		end
		text=nt
		text=tags..textmod(orig,text)
		text=text:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2")
		:gsub(ATAG,function(tg) repeat tg,r=tg:gsub(kt.."%b&&([^}]-)("..kt.."%b&&)","%2%1") until r==0 return tg end)
		:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
		
		for breakpos in breaks:gmatch("(.-)\\N") do
			BPL=breakpos:len()
			if LBP then BPL=BPL+LBP+2 end
			if BPL>0 then text=insertxt(text,BPL,"\\N") end
			LBP=BPL or 0
		end
		LBP=nil
		visible2=nobrea(text)
		c=c+1
		until visible==visible2 or c==666
		txt_check(visible,visible2,i)
		line.text=text
		subs[i]=line
	end
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
	count=1			-- start line counter
	local sline
	if res.shit=="line" then sline=true end
	local kl=res.kol
	
    for z,i in ipairs(sel) do
        progress("Colourising line #"..i-line0.." ["..z.."/"..#sel.."]")
	line=subs[i]
	text=line.text
	text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
	
	local last
	local n=0
	repeat
		-- get last colour
		if not sline then
			local b=text:gsub(kl.."%b&&","",klrs-1)
			last=b:match(kl.."%b&&")
			if not last then t_error("Line #"..i-line0.." does not have "..klrs.." colours of the "..kl.." type.\nAborting.",1) end
		else
			last=text:match(".*("..kl.."%b&&)")
			if not last then t_error("Line #"..i-line0.." does not have any colours of the "..kl.." type.\nAborting.",1) end
		end
		local col={last}
		
		-- this fucking line does the whole thing
		text=text:gsub("(.-)("..kl.."%b&&)",function(t,c) table.insert(col,1,c) return t..col[2] end)
		n=n+1
	until n==count

	-- line counter
	if res.cont then count=count+1 end
	if not sline and count>klrs then count=1 end
	
	text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
	line.text=text
        subs[i]=line
    end
end

function shift2(subs,sel)
	local k=res.kol
	for z,i in ipairs(sel) do
		progress("Processing line #"..i-line0.." ["..z.."/"..#sel.."]")
		line=subs[i]
		text=line.text
		tags=text:match(STAG) or ""
		inline=text:gsub(STAG,"")
		local kol
		if res.shit:match"1st" then kol=inline:match(k.."%b&&") inline=inline:gsub(k.."%b&&","",1)
		else kol=inline:match(".*("..k.."%b&&)") end
		if res.shit:match'last' then inline=inline:gsub("(.*)"..k.."%b&&","%1") end
		if res.shit:match'all' then inline=inline:gsub(k.."%b&&","") end
		inline=inline:gsub("{}","")
		if kol then
			if tags=="" then tags=wrap(kol) else tags=addtag3(kol,tags) end
			text=tags..inline
			line.text=text
			subs[i]=line
		end
	end
end

--	Match colours	--
function match_col(subs,sel)
	local MC
	if P=="Match Colours" then _=0 MC=1
    	  for key,val in ipairs(GUI) do
	    if val.name and val.name:match"match" and res[val.name] then _=_+1 end
	    if val.name and val.name=="invert" and res[val.name] then _=_+1 end
	  end
	  if _>1 then t_error("Multiple checkboxes for matching checked.\nResults may be unpredictable.") end
	end
	local RGB, HSL
	lvlr=res.R lvlg=res.G lvlb=res.B
	hue=res.huehue sat=res.satur lite=res.light
	if lvlr~=0 or lvlg~=0 or lvlb~=0 then RGB=true end
	if hue~=0 or sat~=0 or lite~=0 then HSL=true end
	
    for z,i in ipairs(sel) do
        progress("Colourising line #"..i-line0.." ["..z.."/"..#sel.."]")
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

	-- Matching
	if MC then
		if res.match13 then text=macchi(text,"\\c","\\3c",primary) end
		if res.match31 then text=macchi(text,"\\3c","\\c",outline) end
		if res.match14 then text=macchi(text,"\\c","\\4c",primary) end
		if res.match34 then text=macchi(text,"\\3c","\\4c",outline) end
	end

	-- switch primary and border
	if MC and res.match131 then
		if not notftags:match("\\c&") then text=addtag3("\\c"..primary,text) end
		if not notftags:match("\\3c") then text=addtag3("\\3c"..outline,text) end
		text=text:gsub("\\c&","\\tempc&"):gsub("\\3c","\\c"):gsub("\\tempc","\\3c")
	end

	-- Invert All Colours  
	if MC and res.invert then
		match="["
		for n=1,4 do
		    ctg="\\"..n.."c"
		    ctg=ctg:gsub("1","")
		    if not notftags:match(ctg) and n~=2 then text=addtag3(ctg..stylecol[n],text) end
		    if n>1 and res['k'..n] then match=match..n end
		end
		match=match..']'
		if res.k1 then match=match..'?' end
		match=match:gsub("%[%]%?","")
		text=text:gsub("(\\"..match.."c&H)(%x%x%x%x%x%x)&",function(tg,col)
			invcol=""
			for kol in col:gmatch("(%x%x)") do
				dkol=tonumber(kol,16)
				idkol=255-dkol
				ikol=tohex(idkol)
				invcol=invcol..ikol
			end
			return tg..invcol.."&"
			end)
	end

	-- RGB / HSL
	if P=="RGB/HSL" then
	    corols={}
	    if res.k1 then table.insert(corols,1) end
	    if res.k2 then table.insert(corols,2) end
	    if res.k3 then table.insert(corols,3) end
	    if res.k4 then table.insert(corols,4) end
	    for i=1,#corols do
		kl="\\"..corols[i].."c"
		kl=kl:gsub("1","")
		if res.mktag and not notftags:match(kl) then text=addtag3(kl..stylecol[corols[i]],text) end
		if RGB then text=rgbhslmod(text,kl,rgbm) end
		if HSL then text=rgbhslmod(text,kl,hslm) end
	    end
	end

	text=text:gsub("\\([\\}])","%1") :gsub("\\t%([^\\%)]*%)","") :gsub("{}","")
	line.text=text
        subs[i]=line
    end
end

function macchi(text,c1,c2,kv)
if not notftags:match(c1.."&") then text=addtag3(c1..kv,text) end
text=text:gsub(ATAG,function(ctags) ctags=ctags:gsub(c2..ACLR,""):gsub(c1.."("..ACLR..")",c1.."%1"..c2.."%1") return ctags end)
return text
end

function rgbhslmod(text,kl,ef)
	local segments={}
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
	text=text:gsub(kl.."&H(%x%x)(%x%x)(%x%x)&",function(kol1,kol2,kol3) 
		kol1n=brightness(kol1,lvlb)
		kol2n=brightness(kol2,lvlg)
		kol3n=brightness(kol3,lvlr)
		return kl.."&H"..kol1n..kol2n..kol3n.."&"
		end)
	return text
end

function hslm(text,kl)
	text=text:gsub(kl.."&H(%x%x)(%x%x)(%x%x)&",function(kol1,kol2,kol3) 
		H1,S1,L1=RGB_to_HSL(kol3,kol2,kol1)
		H1,S1,L1=RGB_to_HSL(kol3,kol2,kol1)
		H=H1+hue/255
		S=S1+sat/255
		L=L1+lite/255
		if randomise then
			H2=H1-hue/255
			S2=S1-sat/255
			L2=L1-lite/255
			H=math.random(H*1000,H2*1000)/1000
			S=math.random(S*1000,S2*1000)/1000
			L=math.random(L*1000,L2*1000)/1000
		end
		H,S,L=HSLround(H,S,L)
		kol3n,kol2n,kol1n=HSL_to_RGB(H,S,L)
		kol3n=tohex(round(kol3n))
		kol2n=tohex(round(kol2n))
		kol1n=tohex(round(kol1n))
		return kl.."&H"..kol1n..kol2n..kol3n.."&"
		end)
	return text
end


--	GRADIENT	--
function gradient(subs,sel)
    styleget(subs)
    if res.grtype=="RGB" then GRGB=true else GRGB=false end
    if res.ast then ast="*" else ast="" end
    for z,i in ipairs(sel) do
        progress("Colourising line #"..i-line0.." ["..z.."/"..#sel.."]")
	line=subs[i]
	re_check=0
	repeat
		text=line.text
		if text:match '\\p1' then break end
		text=text:gsub("\\N (%w)","\\N%1"):gsub(" +\\N"," \\N"):gsub("{%*\\[^}]+}",""):gsub("{}","")
		visible=nobrea1(text)
		-- comments
		local komments=''
		for cm in text:gmatch("{[^\\{}]-}") do komments=komments..cm end
		-- something to [try to] deal with spaces and linebreaks because dumb renderer inconsistency
		breaks={}
		for br in text:gmatch(" ?\\[Nh]") do
			table.insert(breaks,br)
		end
		acc=line.effect:match("accel ?(%d+%.?%d*)") or res.acc
		text=text:gsub("\\c&","\\1c&"):gsub("\\c([}\\])","\\1c%1") :gsub(" *(\\[Nh]) *","{%1}")
		:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
		text=tagmerge(text)
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
		    text=text:gsub("([%S])%s*({\\N.-})","{"..endc.."}%1%2{"..startc.."}"):gsub("{}","")
		  end
		  -- set style colour to reset c tags
		  text=text:gsub("(\\"..ac.."c)([}\\])","%1"..sc.."%2")
		  -- back up original
		  orig=text
		  text=text:gsub("{[^\\}]-}","")
		  -- leave only releavant colour tags, nuke all other ones, add colour from style if missing at the start
		  ctext=text:gsub("\\N","") --:gsub("\\[ibusaqk]%d?([\\}])","%1") :gsub("\\[^1234][^c][^\\}]*","") :gsub("\\[^"..ac.."]c[^\\}]*","") :gsub("{%**}","")
		  ctext=ctext:gsub("\\[^\\}]+",function(tag) if tag:match("\\"..ac.."c%b&&") then return tag else return "" end end) :gsub("{%**}","")
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
		    -- get RBG [and HSL if needed]
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
			  NC=acgrad(linecol[c],linecol[c+1],posi[c+1],l,acc)
			else		-- HSL
			  local acc_fac=(l-1)^acc/(posi[c+1])^acc
			  H=acc_fac*(H2-H1)+H1
			  S=acc_fac*(S2-S1)+S1
			  L=acc_fac*(L2-L1)+L1
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
		  gradtext=gradtext.."{\\"..ac.."c&H"..
			linecol[#linecol].."&}"..
			coltext[#coltext]
		  text=tags..gradtext
		  -- merge with original
		  text=textmod(orig,text)
		end
		text=text:gsub(ATAG,function(tg) return colkill(tg) end)
		text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
		:gsub("wtfwhywouldyoudothis","")
		repeat text,r=text:gsub("{([^}]-)(\\[Nh])([^}]-)}","%2{%1%3}") until r==0
		text=text:gsub("{%**}",""):gsub("(%S)(\\[Nh])","%1 %2")
		:gsub("([^{])%*\\","%1\\")
		local b=0
		text=text:gsub(" \\[Nh]",function() b=b+1 return breaks[b] end)..komments
		visible2=nobrea1(text)
		if visible~=visible2 then re_check=re_check+1 end
	until visible==visible2 or re_check==256
	txt_check(visible,visible2,i)
	line.text=text
        subs[i]=line
    end
end


--	Reverse Colours		--
function rvrsgrad(subs,sel)
    for z,i in ipairs(sel) do
        progress("Colourising line #"..i-line0.." ["..z.."/"..#sel.."]")
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
	local acc_fac=(l-1)^acc/(total)^acc
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

--	reamnimatools	---------------------------------------------
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function round(num) num=math.floor(num+0.5) return num end
function tagmerge(t) repeat t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return t end
function wrap(str) return "{"..str.."}" end
function nobra(t) return t:gsub("%b{}","") end
function nobrea(t) return t:gsub("%b{}",""):gsub("\\N","") end
function nobrea1(t) return t:gsub("%b{}",""):gsub(" *\\N *"," ") end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function logg2(m)
	local lt=type(m)
	aegisub.log("\n >> "..lt)
	if lt=='table' then
		aegisub.log(" (#"..#m..")")
		if not m[1] then
			for k,v in pairs(m) do
				if type(v)=='table' then vvv='[table]' elseif type(v)=='number' then vvv=v..' (n)' else vvv=v end
				aegisub.log("\n	"..k..': '..vvv)
			end
		elseif type(m[1])=='table' then aegisub.log("\n nested table")
		else aegisub.log("\n {"..table.concat(m,', ').."}") end
	else
		m=tf(m) or "nil" aegisub.log("\n "..m)
	end
end
function loggtab(m) m=tf(m) or "nil" aegisub.log("\n {"..table.concat(m,';').."}") end
function progress(msg) if aegisub.progress.is_cancelled() then ak() end aegisub.progress.title(msg) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

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

function addtag3(tg,txt)
	no_tf=txt:gsub("\\t%b()","")
	tgt=tg:match("(\\%d?%a+)[%d%-&]")	if not tgt then t_error("Adding tag '"..tg.."' failed.") end
	if no_tf:match("^({[^}]-)"..tgt.."[%d%-&]") then txt=txt:gsub("^({[^}]-)"..tgt.."[%d%-&][^\\}]*","%1"..tg)
	elseif not txt:match("^{\\") then txt="{"..tg.."}"..txt
	elseif txt:match("^{[^}]-\\t") then txt=txt:gsub("^({[^}]-)\\t","%1"..tg.."\\t")
	else txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
	return txt
end

-- save inline tags
function inline_pos(t)
	inTags={}
	tl=t:len()
	if tl==0 then return {} end
	p=0
	t1=''
	repeat
		seg=t:match("^(%b{})") -- try to match tags/comments
		if seg then
			table.insert(inTags,{n=p,t=seg})
		else
			seg=t:match("^([^{]+)") -- or match text
			if not seg then t_error("Error: There appears to be a problem with the brackets here...\n"..t1..t,1) end
			SL=re.find(seg,".")
			p=p+#SL -- position of next '{' [or end]
		end
		t1=t1..seg
		t=t:gsub("^"..esc(seg),"")
		tl=t:len()
	until tl==0
	return inTags
end

-- rebuild inline tags
function inline_ret(t,tab)
	tl=t:len()
	nt=''
	kill='_Z#W_' -- this is supposed to never match
	for k,v in ipairs(tab) do
		N=tonumber(v.n)
		if N==0 then nt=nt..v.t
		else
			m='.'
			-- match how many chars at the start
			m=m:rep(N)
			RS=re.find(t,m)
			seg=RS[1].str
			seg=re.sub(seg,'^'..kill,'')
			nt=nt..seg..v.t
			kill=m -- how many matched in the last round
		end
	end
	-- the rest
	seg=re.sub(t,'^'..kill,'')
	nt=nt..seg
	return nt
end

function retextmod(orig,text)
	local v1,v2,c,t2
	v1=nobrea(orig)
	c=0
	repeat
		t2=textmod(orig,text)
		v2=nobrea(text)
		c=c+1
	until v1==v2 or c==666
	if v1~=v2 then logg("Something went wrong with the text...") logg(v1) logg(v2) end
	return t2
end

function textmod(orig,text)
if text=="" then return orig end
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	text=tagmerge(text)
	vis=nobra(text)
	ltrmatches=re.find(vis,".")
	if not ltrmatches then logg("text: "..text..'\nvisible: '..vis)
		logg("If you're seeing this, something really weird is happening with the re module.\nTry this again or rescan Autoload.")
	end
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match(STAG) or ""
	text=text:gsub(STAG,"") :gsub("{[^\\}]-}","")
	orig=orig:gsub("{([^\\}]+)}",function(c) return wrap("\\\\"..c.."|||") end)
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
    newtext=stags..newline:gsub("(|||)(\\\\)","%1}{%2"):gsub("({[^}]-)\\\\([^\\}]-)|||","{%2}%1")
    text=newtext:gsub("{}","")
    return text
end


function duplikill(tagz)
	local tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
	local tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
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
	repeat tagz,c=tagz:gsub("(\\[ibusq])%d(.-)(%1%d)","%2%3") until c==0
	repeat tagz,c=tagz:gsub("(\\an)%d(.-)(%1%d)","%3%2") until c==0
	tagz=tagz:gsub("(|i?clip%(%A-%))(.-)(\\i?clip%(%A-%))","%2%3")
	:gsub("(\\i?clip%b())(.-)(\\i?clip%b())",function(a,b,c)
	    if a:match("m") and c:match("m") or not a:match("m") and not c:match("m") then return b..c else return a..b..c end end)
	tagz=tagz:gsub("|","\\"):gsub("\\t%([^\\%)]-%)","")
	return tagz
end

function colkill(tagz)
	tagz=tagz:gsub("\\1c&","\\c&")
	local tags2={"c","2c","3c","4c"}
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
	if randomise and S>1 then S=1-S end
	if S>1 then S=1 end
	if randomise then S=math.abs(S) end
	if S<0 then S=0 end
	if randomise and L>1 then L=1-L end
	if L>1 then L=1 end
	if randomise then L=math.abs(L) end
	if L<0 then L=0 end
	return H,S,L
end

function brightness(klr,lvl)
    klr=tonumber(klr,16)
    if randomise then
	rAn=math.random(klr-lvl,klr+lvl)
	klr=round(rAn)
	if klr<0 then klr=math.abs(klr) end
	if klr>255 then klr=255-(klr-255) end
    else
	klr=klr+lvl
    end
    if klr<0 then klr=0 end
    if klr<10 then klr="0"..klr else klr=tohex(klr) end
return klr
end

function tohex(num)
	n1=math.floor(num/16)
	n2=math.floor(num%16)
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

function txt_check(t1,t2,i)
	if t1~=t2 then
		local bad
		for s=1,#badsel do
			if badsel[s]==i then bad=1 end
		end
		if bad then
		logg("Line #"..i-line0..": Operation failed, probably because of malformed tags. Undo (Ctrl+Z) and fix the line before trying again.\n")
		else
		logg("Line #"..i-line0..": It appears that characters have been lost or added. \n If the problem isn't obvious from the two lines below, it's probably a failure of the re module.\n Undo (Ctrl+Z) and try again (Repeat Last might work). If the problem persists, rescan Autoload Dir.\n If you keep getting the SAME strange results, then it may be a bug in Colourise.\n>> "..t1.."\n--> "..t2.."\n")
		end
	end
end

function re_test(letrz,visible)
	local count=0
	repeat
		local nt=''
		for l=1,#letrz do
			local ltr=letrz[l].str
			nt=nt..ltr
		end
		count=count+1
		if nt~=visible then letrz=re.find(visible,".") or {} end
	until nt==visible or count==100
	return letrz
end
	
function validateCol(subs,sel)
	local err
	badsel={}
	for z,i in ipairs(sel) do
		local line=subs[i]
		tx=line.text
		for c in tx:gmatch("\\[1234]?c[^l\\})]+") do
			if not c:match("c&H%x%x%x%x%x%x&") then logg("Line #"..i-line0..": "..c) err=1 table.insert(badsel,i) end
		end
	end
	if err==1 then t_error("Some malformed colour tags have been found in selected lines.\nThis means the values don't match the standard format of\n&&HFFFFFF&&. Some things are likely to break.\nSee the log for a list of errors found.") end
end

function repetition()
	if lastres and res.rept then res=lastres end
end

function saveconfig()
colconf="Colourise Configutation\n\n"
for key,val in ipairs(GUI) do
    if val.class=="checkbox" and val.name~="save" then colconf=colconf..val.name..":"..tf(res[val.name]).."\n" end
    if val.class=="dropdown" and val.name~=": Help Menu :" or val.class=="color" then colconf=colconf..val.name..":"..res[val.name].."\n" end
end
colourconfig=ADP("?user").."\\colourise.conf"
file=io.open(colourconfig,"w")
file:write(colconf)
file:close()
ADD({{class="label",label="Config Saved to:\n"..colourconfig}},{"OK"},{close='OK'})
end

function loadconfig()
colourconfig=ADP("?user").."\\colourise.conf"
file=io.open(colourconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	  for key,val in ipairs(GUI) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="color" then
	      if konf:match(val.name) and val.name~="help" then val.value=detf(konf:match(val.name..":(.-)\n")) end
	    end
	  end
    end
end

function grad_rgb(subs,sel)
	cuts(subs)
	validateCol(subs,sel)
	res={grtype="RGB",acc=1,k1=true,k3=true}
	gradient(subs,sel)
	return sel
end

function grad_hsl(subs,sel)
	cuts(subs)
	validateCol(subs,sel)
	res={grtype="HSL",acc=1,k1=true,k3=true,hueshort=true}
	gradient(subs,sel)
	return sel
end

if haveDepCtrl then
  depRec:registerMacros({
	{script_name,script_description,colourise},
	{": Non-GUI macros :/Colourise: Gradient by Character, RGB","GBC RGB",grad_rgb},
	{": Non-GUI macros :/Colourise: Gradient by Character, HSL","GBC HSL",grad_hsl},
  },false)
else
	aegisub.register_macro(script_name,script_description,colourise)
	aegisub.register_macro(": Non-GUI macros :/Colourise: Gradient by Character, RGB","GBC RGB",grad_rgb)
	aegisub.register_macro(": Non-GUI macros :/Colourise: Gradient by Character, HSL","GBC HSL",grad_hsl)
end