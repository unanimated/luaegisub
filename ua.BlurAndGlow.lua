--[[	"Blur / Layers" creates layers with blur. Supports 2 borders, xbord, ybord, xshad, and yshad. Basic support for transforms and \r.
	"Blur + Glow" - Same as above but with an extra layer for glow. Set blur amount and alpha for the glow.
	The "double border" option additionally lets you change the size and colour of the 2nd border.
	If blur is missing, default blur is added.
	"Bottom blur" allows you to use different blur for the lowest non-glow layer than for top layer(s).
	"fix \\1a for layers with border and fade" - Uses \1a&HFF& for the duration of a fade on layers with border.
		"transition" - for \fad(500,0) with transition 80ms you get \1a&HFF&\t(420,500,\1a&H00&).
	"only add glow" - will add glow to a line with a border, without messing with the primary / border. (Blur + Glow)
	"only add 2nd border" - will add 2nd border, without messing with the primary / first border. (Blur / Layers)
	"Fix fades" - Recalculates those \1a fades mentioned above. 
		Use this when you shift something like an episode title to a new episode and the duration of the sign is different.
	"Change layer" - raises or lowers layer for all selected lines by the same amount. [This is separate from the other functions.]
	
	Full manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#blurglow
]]

script_name="Blur and Glow"
script_description="Add blur and/or glow to signs"
script_author="unanimated"
script_url="http://unanimated.xtreemhost.com/ts/blur-and-glow.lua"
script_version="2.5"
script_namespace="ua.BlurAndGlow"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="2.5.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end


function glow(subs,sel)
    if not res.rep then al=res.alfa bl=res.blur end
    if res.glowcol then glowc=res.glc:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&") end
    if res.autod then if res.clr or res.bsize then res.double=true end end
    for z=#sel,1,-1 do
	i=sel[z]
	progress("Glowing line: "..(#sel-z+1).."/"..#sel)
	line=subs[i]
	text=line.text
	if defaref and line.style=="Default" then sr=defaref
	elseif lastref and laststyle==line.style then sr=lastref
	else sr=stylechk(line.style) end
	lastref=sr	laststyle=line.style
	duration=line.end_time-line.start_time

	-- get colors, border, shadow from style
	stylinfo(text)
	text=preprocess(text)
	line.text=text

	if border~="0" or text:match("\\[xy]bord") then

	    -- WITH TWO BORDERS
	    if res.double then

		-- second border
		line1=line
		line1.text=text
		line1.text=borderline2(line1.text)
		line1.layer=line1.layer+1
		subs.insert(i+1,line1)

		-- first border
		line2=line
		line2.text=text
		line2.text=borderline(line2.text)
		if shadow~="0" then line2.text=line2.text:gsub("^({\\[^}]+)}","%1\\shad"..shadow.."}") end
		if not res.s_mid then line2.text=line2.text:gsub("^({\\[^}]-)}","%1\\4a&HFF&}") end
		line2.layer=line2.layer+1
		subs.insert(i+2,line2)

		-- top line
		line3=line
		line3.text=text
		line3.text=topline(line3.text)
		line3.layer=line3.layer+1
		subs.insert(i+3,line3)

		-- bottom / glow
		text=borderline2(text)
		text=glowlayer(text,"3c","3")
		if res.botalpha and line.text:match("\\fad%(") then text=botalfa(text) end
		line.layer=line.layer-3
		line.text=text
		sls=3

	    else
		-- WITH ONE BORDER

		-- border
		line2=line
		if not res.onlyg then
		line2.text=text
		line2.text=borderline(line2.text)
		end
		line2.layer=line2.layer+1
		subs.insert(i+1,line2)

		-- top line
		line3=line
		line3.layer=line3.layer+1
		if not res.onlyg then
		line3.text=text
		line3.text=topline(line3.text)
		subs.insert(i+2,line3)
		end

		-- bottom / glow
		text=glowlayer(text,"3c","3")
		if res.botalpha and line.text:match("\\fad%(") then text=botalfa(text) end
		line.layer=line.layer-2
		line.text=text
		sls=2

	    end

	else
		-- WITHOUT BORDER

		line2=line
		line2.layer=line2.layer+1
		subs.insert(i+1,line2)
		text=glowlayer(text,"c","1")
		line.layer=line.layer-1
		line.text=text
		sls=1

	end
	subs[i]=line
	for s=z,#sel do sel[s]=sel[s]+sls end
    end
    progress("Blur & Glow: DONE")
    return sel
end

function layerblur(subs,sel)
    if res.autod then if res.clr or res.bsize then res.double=true end end
    for z=#sel,1,-1 do
	i=sel[z]
	progress("Blurring line: "..(#sel-z+1).."/"..#sel)
	line=subs[i]
	text=line.text
	if defaref~=nil and line.style=="Default" then sr=defaref
	elseif lastref~=nil and laststyle==line.style then sr=lastref
	else sr=stylechk(line.style) end
	lastref=sr	laststyle=line.style
	duration=line.end_time-line.start_time

	-- get colors, border, shadow from style
	stylinfo(text)
	text=preprocess(text)
	line.text=text

	-- TWO BORDERS
	if res.double then

		-- first border
		line2=line
		if not res.onlyb then
		line2.text=text
		line2.text=borderline(line2.text)
		if not res.s_mid then line2.text=line2.text:gsub("^({\\[^}]-)}","%1\\4a&HFF&}") end
		end
		line2.layer=line2.layer+1
		subs.insert(i+1,line2)

		-- top line
		line3=line
		line3.layer=line3.layer+1
		if not res.onlyb then
		line3.text=text
		line3.text=topline(line3.text)
		subs.insert(i+2,line3)
		end

		-- second border
		text=borderline2(text)
		line.layer=line.layer-2
		line.text=text
		sls=2

	-- ONE BORDER
	else

		-- top line
		line3=line
		line3.text=text
		line3.text=topline(line3.text)
		line3.layer=line3.layer+1
		subs.insert(i+1,line3)

		-- bottom line
		text=borderline(text)
		line.layer=line.layer-1
		line.text=text
		sls=1
	end

	subs[i]=line
	for s=z,#sel do sel[s]=sel[s]+sls end
    end
    progress("Blur: DONE")
end

function topline(txt)
	txt=txt
	:gsub("(\\t%([^%)]*)\\bord[%d%.]+","%1")
	:gsub("(\\t%([^%)]*)\\shad[%d%.]+","%1")
	:gsub("\\t%([^\\]*%)","")
	if not txt:match("^{[^}]-\\bord") then txt=txt:gsub("^{\\","{\\bord0\\") end
	txt=txt
	:gsub("\\bord[%d%.]+","\\bord0")
	:gsub("(\\r[^}]-)}","%1\\bord0}")
	txt=txt:gsub("(\\[xy]bord)[%d%.]+","")	:gsub("\\3c&H%x+&","")
	if shadow~="0" then txt=txt:gsub("^({\\[^}]+)}","%1\\shad"..shadow.."}") end
	txt=txt
	:gsub("^({\\[^}]-)}","%1\\4a&HFF&}")
	:gsub("(\\r[^}]-)}","%1\\shad"..shadow.."\\4a&HFF&}")
	:gsub("\\bord[%d%.%-]+([^}]-)(\\bord[%d%.%-]+)","%1%2")
	:gsub("\\shad[%d%.%-]+([^}]-)(\\shad[%d%.%-]+)","%1%2")
	if res.s_top then txt=txt:gsub("\\4a&HFF&","") end
	txt=txt:gsub("{}","")
	return txt
end

function borderline(txt)
	txt=txt:gsub("\\c&H%x+&","")
	-- transform check
	if txt:match("^{[^}]-\\t%([^%)]-\\3c") then
		pretrans=text:match("^{(\\[^}]-)\\t")
		if not pretrans:match("^{[^}]-\\3c") then txt=txt:gsub("^{\\","{\\c"..soutline.."\\") end
	end
	if not txt:match("^{[^}]-\\3c&[^}]-}") then
		txt=txt:gsub("^({\\[^}]+)}","%1\\c"..soutline.."}")
		:gsub("(\\r[^}]-)}","%1\\c"..routline.."}")
	end
	txt=txt:gsub("(\\3c)(&H%x+&)","%1%2\\c%2")
	:gsub("(\\r[^}]-)}","%1\\c"..routline.."}")
	:gsub("(\\r[^}]-\\3c)(&H%x+&)([^}]-)}","%1%2\\c%2%3")
	:gsub("\\c&H%x+&([^}]-)(\\c&H%x+&)",function(a,b) if not a:match("\\t") then return a..b end end)
	:gsub("{%*?}","")
	if res.bbl and not res.double then txt=txt:gsub("\\blur[%d%.]+","\\blur"..res.bblur) end
	if res.botalpha and txt:match("\\fad%(") then txt=botalfa(txt) end
	return txt
end

function borderline2(txt)
	outlinetwo=primary
	if res.clr then col3=res.c3:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&") outlinetwo=col3 rimary=col3 end
	bordertwo=border
	if res.bsize then bordertwo=res.secbord end
	-- transform check
	if txt:match("^{[^}]-\\t%([^%)]-\\bord") then
		pretrans=text:match("^{(\\[^}]-)\\t")
		if not pretrans:match("^{[^}]-\\bord") then txt=txt:gsub("^{\\","{\\bord"..border.."\\") end
	end
	if not txt:match("^{[^}]-\\bord") then txt=txt:gsub("^{\\","{\\bord"..border.."\\") end
	txt=txt:gsub("(\\r[^\\}]-)([\\}])","%1\\bord"..rbord.."%2")
	:gsub("(\\r[^\\}]-)\\bord[%d%.%-]+([^}]-)(\\bord[%d%.%-]+)","%1%2%3")
	:gsub("(\\bord)([%d%.]+)",function(a,b) if res.bsize then brd=bordertwo else brd=b end return a..b+brd end)
	:gsub("(\\[xy]bord)([%d%.]+)",function(a,b) return a..b+b end)
	:gsub("\\3c&H%x+&","")
	:gsub("^({\\[^}]+)}","%1\\3c"..outlinetwo.."}")
	:gsub("(\\3c)(&H%x+&)","%1"..outlinetwo)
	if res.clr then txt=txt:gsub("\\c&H%x+&([^}]-)}","\\c"..rimary.."\\3c"..outlinetwo.."%1}")
		else txt=txt:gsub("(\\c)(&H%x+&)([^}]-)}","%1%2%3\\3c%2}") end
	txt=txt:gsub("(\\r[^}]+)}","%1\\3c"..rimary.."}")
	:gsub("\\c&H%x+&([^}]-)(\\c&H%x+&)",function(a,b) if not a:match("\\t") then return a..b end end)
	:gsub("\\3c&H%x+&([^}]-)(\\3c&H%x+&)",function(a,b) if not a:match("\\t") then return a..b end end)
	:gsub("{%*?}","")
	if res.bbl and res.double then txt=txt:gsub("\\blur[%d%.]+","\\blur"..res.bblur) end
	if res.botalpha and txt:match("\\fad%(") then txt=botalfa(txt) end
	return txt
end

function glowlayer(txt,kol,alf)
	txt=txt:gsub("\\alpha&H(%x%x)&",function(a) if a>al then return "\\alpha&H"..a.."&" else return "\\alpha&H"..al.."&" end end)
	:gsub("\\"..alf.."a&H(%x%x)&",function(a) if a>al then return "\\"..alf.."a&H"..a.."&" else return "\\"..alf.."a&H"..al.."&" end end)
	:gsub("(\\blur)[%d%.]*([\\}])","%1"..bl.."%2")
	:gsub("(\\r[^}]-)}","%1\\alpha&H"..al.."&}")
	if not txt:match("^{[^}]-\\alpha") then txt=txt:gsub("^({\\[^}]-)}","%1\\alpha&H"..al.."&}") end
	if res.alfa=="00" then txt=txt:gsub("^({\\[^}]-)\\alpha&H00&","%1") end
	txt=txt:gsub("{%*?}","")
	if res.glowcol then
		if txt:match("^{\\[^}]-\\"..kol.."&") then txt=txt:gsub("\\"..kol.."&H%x+&","\\"..kol..glowc)
		else txt=txt:gsub("\\"..kol.."&H%x+&","\\"..kol..glowc) txt=txt:gsub("^({\\[^}]-)}","%1\\"..kol..glowc.."}")
		end
	end
	return txt
end

function botalfa(txt)
	fadin,fadout=txt:match("\\fad%((%d+)%,(%d+)")
	alfadin=res.alphade	alfadout=res.alphade
	if res.alphade=="max" then alfadin=fadin alfadout=fadout end
	if fadin==nil or fadout==nil then aegisub.log("\n ERROR: Failed to capture fade times from line:\n "..text) end
        if fadin~="0" then
	    txt=txt:gsub("^({\\[^}]-)}","%1\\1a&HFF&\\t("..fadin-alfadin..","..fadin..",\\1a&H00&)}")
        end
        if fadout~="0" then
	    txt=txt:gsub("^({\\[^}]-)}","%1\\t("..duration-fadout..","..duration-fadout+alfadout..",\\1a&HFF&)}")
        end
    return txt
end

function stylinfo(text)
    	startags=text:match("^{\\[^}]-}") or ""
    	startags=startags:gsub("\\t%b()","")
    	
    	primary=startags:match("^{[^}]-\\c(&H%x+&)") or sr.color1:gsub("H%x%x","H")
    	soutline=sr.color3:gsub("H%x%x","H")
    	outline=startags:match("^{[^}]-\\3c(&H%x+&)") or soutline
    	border=startags:match("^{[^}]-\\bord([%d%.]+)") or tostring(sr.outline)
    	shadow=startags:match("^{[^}]-\\shad([%d%.]+)") or tostring(sr.shadow)
    	
    	if text:match("\\r%a") then
    	rstyle=text:match("\\r([^\\}]+)")
    	reref=stylechk(rstyle)
    	rimary=reref.color1:gsub("H%x%x","H")
    	routline=reref.color3:gsub("H%x%x","H")
    	rbord=tostring(reref.outline)
    	else routline=soutline rimary=primary rbord=border
    	end
end

function preprocess(text)
	if not text:match("^{\\") then text="{\\blur"..bdef.."}"..text			-- default blur if no tags
		text=text:gsub("(\\r[^}]-)}","%1\\blur"..bdef.."}")
	end
	if not text:match("\\blur") then text=text:gsub("^{\\","{\\blur"..bdef.."\\")	-- default blur if missing in tags
		text=text:gsub("(\\r[^}]-)}","%1\\blur"..bdef.."}")
	end
	if text:match("\\blur") and not text:match("^{[^}]*blur[^}]*}") then			-- add blur if missing in first tag block
		text=text:gsub("^{\\","{\\blur"..bdef.."\\")
	end
	if text:match("^{[^}]-\\t[^}]-}") and not text:match("^{[^}]-\\3c[^}]-\\t") then	-- \t workaround
		text=text:gsub("^{\\","{\\3c"..soutline.."\\")
	end
	text=text:gsub("\\1c","\\c")
	return text
end

function fixfade(subs,sel)
    for z=#sel,1,-1 do
	i=sel[z]
	line=subs[i]
	text=line.text
	sr=stylechk(line.style)
	duration=line.end_time-line.start_time
	border=tostring(sr.outline)
	bord=text:match("^{[^}]-\\bord([%d%.]+)")
	if bord then border=bord end
	
	if border~="0" and line.text:match("\\fad%(") then
	text=text:gsub("\\1a&H%x+&","") :gsub("\\t%([^\\%(%)]-%)","")
	text=botalfa(text)
	end
	line.text=text
	subs[i]=line
    end
end

function layeraise(subs,sel)
    for z=#sel,1,-1 do
	i=sel[z]
	line=subs[i]
	if line.layer+res["layer"]>=0 then line.layer=line.layer+res["layer"] else t_error("You're dumb. Layers can't go below 0.",1) end
	subs[i]=line
    end
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
    for s=1,#styles do
	if sn==styles[s].name then
	    sr=styles[s]
	    if styles[s].name=="Default" then defaref=styles[s] end
	end
    end
    if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
    return sr
end

function saveconfig()
bgconf="Blur & Glow config\n\n"
  for key,val in ipairs(GUI) do
    if val.class=="floatedit" or val.class=="dropdown" or val.class=="color" then
      bgconf=bgconf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="save" then
      bgconf=bgconf..val.name..":"..tf(res[val.name]).."\n"
    end
  end
blurkonfig=ADP("?user").."\\blurandglow.conf"
file=io.open(blurkonfig,"w")
file:write(bgconf)
file:close()
ADD({{class="label",label="Config saved to:\n"..blurkonfig}},{"OK"},{close='OK'})
end

function loadconfig()
blurkonfig=ADP("?user").."\\blurandglow.conf"
file=io.open(blurkonfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	for key,val in ipairs(GUI) do
	  if val.class=="floatedit" or val.class=="checkbox" or val.class=="dropdown" or val.class=="color" then
	    if konf:match(val.name) then val.value=detf(konf:match(val.name..":(.-)\n")) end
	  end
	end
    end
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

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function blurandglow(subs,sel)
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
GUI={
	--left
	{x=0,y=0,width=2,class="label",label="  =   Blur and Glow version "..script_version.."   ="},
	{x=0,y=1,class="label",label="Glow blur:"},
	{x=0,y=2,class="label",label="Glow alpha:"},
	
	{x=1,y=1,width=2,class="floatedit",name="blur",value=3},
	{x=1,y=2,width=2,class="dropdown",name="alfa",items={"00","20","30","40","50","60","70","80","90","A0","B0","C0","D0","F0"},value="80"},
	
	{x=0,y=3,class="checkbox",name="glowcol",label="glow c.:",hint="glow colour"},
	{x=1,y=3,width=2,class="color",name="glc"},
	
	{x=0,y=4,width=2,class="checkbox",name="s_top",label="keep shadow on top layer"},
	
	{x=0,y=5,width=5,class="checkbox",name="botalpha",label="fix \\1a for layers with border and fade --> transition:",value=true,
	hint="uses \\1a&HFF& for bottom layer during fade"},
	{x=5,y=5,class="dropdown",name="alphade",items={0,45,80,120,160,200,"max"},value=45},
	{x=6,y=5,width=2,class="label",label="ms"},
	
	{x=0,y=6,width=4,class="checkbox",name="onlyg",label="only add glow (layers w/ border)"},
	
	-- right
	{x=4,y=0,class="checkbox",name="double",label="double border"},
	{x=5,y=0,width=2,class="checkbox",name="onlyb",label="only add 2nd border"},
	
	{x=4,y=1,class="checkbox",name="bbl",label="bottom blur:",
	hint="Blur for bottom layer \n[not the glow layer] \nif different from top layer."},
	{x=5,y=1,width=2,class="floatedit",name="bblur",value=1},
	
	{x=4,y=2,class="checkbox",name="bsize",label="2nd b. size:",
	hint="Size for 2nd border \n[counts from first border out] \nif different from the current border."},
	{x=5,y=2,width=2,class="floatedit",name="secbord",value=2},
	
	{x=4,y=3,class="checkbox",name="clr",label="2nd b. colour:",hint="Colour for 2nd border \nif different from primary."},
	{x=5,y=3,width=2,class="color",name="c3"},
	
	{x=4,y=4,width=4,class="checkbox",name="s_mid",label="keep shadow on middle layer"},
	
	{x=4,y=6,class="label",label="    Change layer:"},
	{x=5,y=6,class="dropdown",name="layer",items={"-5","-4","-3","-2","-1","+1","+2","+3","+4","+5"},value="+1"},
	
	
	{x=0,y=7,width=2,class="checkbox",name="rep",label="repeat with last settings"},
	{x=4,y=7,class="checkbox",name="autod",label="auto double",value=true,
	hint="automatically use double border\nif 2nd colour or 2nd border size is checked"},
	{x=6,y=6,class="dropdown",name="def",items={"0.3","0.4","0.5","0.6","0.7","0.8","0.9","1"},value="0.6",hint="config: default blur"},
	{x=5,y=7,width=2,class="checkbox",name="save",label="save configuration"},
}
	loadconfig()
	buttons={"Blur / Layers","Blur + Glow","Fix fades","Change layer","cancel"}
	pressed,res=ADD(GUI,buttons,{ok='Blur / Layers',close='cancel'})
	if pressed=="cancel" then ak() end
	bdef=res.def
	if res.onlyg then res.double=false end
	if res.onlyb then res.double=true end
	if res.save then saveconfig()
	else
	 if res.rep then res=lastres end
	 styleget(subs)
	 if pressed=="Blur / Layers" then layerblur(subs,sel) end
	 if pressed=="Blur + Glow" then sel=glow(subs,sel) end
	 if pressed=="Fix fades" then fixfade(subs,sel) end
	 if pressed=="Change layer" then layeraise(subs,sel) end
	end
	if res.rep==false then lastres=res end
	aegisub.set_undo_point(script_name)
	return sel
end

if haveDepCtrl then depRec:registerMacro(blurandglow) else aegisub.register_macro(script_name,script_description,blurandglow) end