script_name="Colorize"
script_description="Does things with colours"
script_author="unanimated"
script_version="4.3"

--[[

 Bottom dropdown menu chooses mode:
	Colorize letter by letter:
 Alternates between 2-5 colours character by character, like 121212, 123123123, or 123412341234.
 Works for primary/border/shadow/secondary (only one of those).
 Nukes all comments and inline tags. Only first block of tags is kept.
	Shift:
 Shift can be used on an already colorized line to shift the colours by one letter.
 You have to set the right number of colours for it to work correctly!
 If shift base is "line", then it takes the colour for the first character from the last character.
 
   "Colorize by word"
 Colorizes by word instead of by letter.
 
   "Don't join with other tags" will keep {initial tags}{colour} separated (ie won't nuke the "}{"). 
 This helps some other scripts to keep the colour as part of the "text" without initial tags.
 
   "Continuous shift line by line" - If you select a bunch of the same colorized lines, this shifts the colours line by line.
 This kind of requires that no additional weird crap is done to the lines, otherwise malfunctioning can be expected.
 
   "Tune colours"
 Loads all colours from a line into a GUI and lets you change them from there.
 
   "Set colours across whole line"
 This is like a preparation for gradient-by-character. Select number of colours.
 For 3 colours, it will place one at the start, one in the middle, and one before the last character.
 Works for 2-10 colours and sets them evenly across the line. (Then you can run grad-by-char.)
 
	Gradient:
 Creates a gradient by character. (Uses Colorize button.)
 There are two modes: RGB and HSL. RGB is the standard, like lyger's GBC; HSL interpolates Hue, Saturation, and Lightness separately.
 Use the \c, \3c, \4c, \2c checkboxes on the right to choose which colour to gradient.
 "Shortest hue" makes sure that hue is interpolated in the shorter direction. Unchecking it will give you a different gradient in 50% cases.
 "Double HSL gradient" will make an extra round through Hue. Note that neither of these 2 options applies to RGB.
 "Use asterisks" places asterisks like GBC so that you can ungradient the line with lyger's script.
 There are several differences from lyger's GBC:
	- RGB / HSL option
	- You can choose which types of colour you want to gradient
	- Other tags don't interfere with the colour gradients
 
	Match/switch/invert \c, \3c, 4c:
 This should be obvious from the names and should apply to all new colour tags in the line.
 
	Adjust RGB / HSL
 Adjusting Red/Green/Blue or Hue/Saturation/Lightness
 This works for lines with multiple same-type colour tags, including gradient by character.
 You can select from -255 to 255.
 Check types of colours you want it to apply to.
 "Apply to missing" means it will be applied to the colour set in style if there's no tag in the line.
 "Randomize" - if you set Lightness (any RGB/HSL) to 20, the resulting colour will have anywhere between -20 and +20 of the original Lightness.
 
   "Remember last"
 Remembers last settings of checkboxes and dropdowns.
 
   "Save config"
 Saves a config file in your Application Data folder with current settings.

--]]

re=require'aegisub.re'

--	Colorize	--
function colors(subs,sel)
    local c={}
    for k=1,5 do
	c[k]=res["c"..k]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
    end
    for x, i in ipairs(sel) do
        progress(string.format("Colorizing line %d/%d",x,#sel))
	line=subs[i]
	text=line.text
	
	    if res.kol=="primary" then k="\\c" text=text:gsub("\\1?c&H%x+&","") end
	    if res.kol=="border" then k="\\3c" text=text:gsub("\\3c&H%x+&","") end
	    if res.kol=="shadow" then k="\\4c" text=text:gsub("\\4c&H%x+&","") end
	    if res.kol=="secondary" then k="\\2c" text=text:gsub("\\2c&H%x+&","") end
	    
	    k1=k..c[1]
	    k2=k..c[2]
	    k3=k..c[3]
	    k4=k..c[4]
	    k5=k..c[5]

	    tags=text:match("^{\\[^}]-}") or ""
	    orig=text:gsub("^({\\[^}]*})","")
	    comm="" for c in text:gmatch("{[^\\}]*}") do comm=comm..c end
	    text=text:gsub("{[^}]*}","") :gsub("%s*$","")

	    if res.clrs=="2" then
	      if res.word then
		text=text.." * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 ")
	      else
		text=text:gsub("%s","  ") text=text.."*"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2")
		text=text:gsub("{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s"," ")
	      end
	    end
	    
	    if res.clrs=="3" then
	      if res.word then
		text=text.." * * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 {\\"..k3.."}\\3 ")
	      else
		text=text:gsub("%s","   ") text=text:gsub("\\N","\\N~") text=text.."**"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2{\\"..k3.."}\\3")
		text=text:gsub("{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s"," ")
		text=text:gsub("{\\[1234]?c&H%x+&}~","")
	      end
	    end
	    
	    if res.clrs=="4" then
	      if res.word then
		text=text.." * * * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 {\\"..k3.."}\\3 {\\"..k4.."}\\4 ")
	      else
		text=text:gsub("%s","    ") text=text:gsub("\\N","\\N\\N") text=text.."***"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2{\\"..k3.."}\\3{\\"..k4.."}\\4")
		text=text:gsub("{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s"," ")
	      end
	    end
	    
	    if res.clrs=="5" then
	      if res.word then
		text=text.." * * * * "
		text=re.sub(text,"([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ([\\w[:punct:]]+) ","{\\"..k1.."}\\1 {\\"..k2.."}\\2 {\\"..k3.."}\\3 {\\"..k4.."}\\4 {\\"..k5.."}\\5 ")
	      else
		text=text:gsub("%s","     ") text=text:gsub("\\N","\\N\\N~") text=text.."****"
		text=re.sub(text,"([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])([\\w[:punct:]\\s])","{\\"..k1.."}\\1{\\"..k2.."}\\2{\\"..k3.."}\\3{\\"..k4.."}\\4{\\"..k5.."}\\5")
		text=text:gsub("{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s{\\[1234]?c&H%x+&}%s"," ")
		text=text:gsub("{\\[1234]?c&H%x+&}~","")
	      end
	    end

	    text=text:gsub("{\\[1234]?c&H%x+&}%*","")
	    text=text:gsub("[%s%*]+$","")
	    text=text:gsub(" $","")

	text=text:gsub("{\\[1234]?c&H%x+&}\\{\\[1234]?c&H%x+&}N","\\N")
	text=text:gsub("\\N\\N","\\N")
	text=tags..text
	if res.join==false then text=text:gsub("}{","") end
	if orig:match("{%*?\\") then text=textmod(orig) end
	text=text..comm
	line.text=text
        subs[i]=line
    end
end


--	Tune Colours	--
function ctune(subs,sel)
    for i=1,#sel do
        progress("Processing... "..i.."/"..#sel)
	line=subs[sel[i]]
        text=line.text
	if text:match("c&H%x+&") then
	  text=text:gsub("\\c&","\\1c&")
	  wai={1,1,1,1}
	  chk={0,0,0,0}
	  lbls={{label="primary"},{label="2ndary"},{label="border"},{label="shadow"}}
	  for l=1,4 do lbls[l].class="label" lbls[l].x=l end
	  tekst={}
	  colortunegui={{class="label",label="#"..i}}
	  for t,col in text:gmatch("(.-)(\\[1234]c&H%x%x%x%x%x%x&)") do
	    cType,B,G,R=col:match("\\([1234])c&H(%x%x)(%x%x)(%x%x)&")
	    ctNo=tonumber(cType)
	    C="#"..R..G..B
	    if chk[ctNo]==0 then table.insert(colortunegui,lbls[ctNo]) chk[ctNo]=1 end
	    table.insert(colortunegui,{x=cType,y=wai[ctNo],class="color",name=cType..wai[ctNo],value=C})
	    table.insert(tekst,t..col)
	    wai[ctNo]=wai[ctNo]+1
	  end
	  final=text:match(".*\\[1234]c&H%x%x%x%x%x%x&(.-)$")
	  
  	  pressed,rez=ADD(colortunegui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	  if pressed=="Cancel" then ak() end
	  
	  text=""
	  rezlt={1,1,1,1}
	  for c=1,#tekst do
	    nt=tekst[c]
	    col=tekst[c]:match("\\[1234]c&H%x%x%x%x%x%x&")
	    cType,B,G,R=col:match("\\([1234])c&H(%x%x)(%x%x)(%x%x)&")
	    ctNo=tonumber(cType)
	    cor=esc(col)
	    crep="\\"..cType.."c"..rez[cType..rezlt[ctNo]]:gsub("#(%x%x)(%x%x)(%x%x)","&H%3%2%1&")
	    text=text..nt:gsub(cor,crep)
	    rezlt[ctNo]=rezlt[ctNo]+1
	  end
	  text=text..final
	  text=text:gsub("\\1c&","\\c&")
	end
	line.text=text
	subs[sel[i]]=line
    end
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
gc_config={{x=0,y=0,width=1,height=1,class="dropdown",name="gctype",items={"\\c","\\3c","\\4c","\\2c"},value="\\c"}}
for c=1,cn do
    cte={x=c,y=0,width=1,height=1,class="color",name="gc"..c}
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

    for x, i in ipairs(sel) do
        progress(string.format("Colorizing line %d/%d",x,#sel))
	line=subs[i]
	text=line.text
	text=text:gsub("\\1c","\\c") :gsub(kt.."&H%x+&","")
	if not text:match("^{\\") then text=text:gsub("^","{\\clrs}") end
	
	clean=text:gsub("{[^}]-}","") :gsub("%s?\\[Nn]%s?"," ")
	text=text:gsub("%*","_ast_")
	
	for n=cn,1,-1 do
		lngth=math.floor(clean:len()*fakt[n])
		text="*"..text
		text=text:gsub("%*({\\[^}]-})","%1*")
		tags=kolors[n]
		m=0
		if lngth>0 then
		  repeat text=text:gsub("%*({[^}]-})","%1*") :gsub("%*(.)","%1*") :gsub("%*(%s?\\[Nn]%s?)","%1*") m=m+1
		  until m==lngth
		end
		if n==cn then text=text:gsub("([^}])%*$","*%1") :gsub("([^}])%*({[^\\}]-})$","*%1%2") end
		text=text:gsub("%*","{"..tags.."}") :gsub("({"..tags.."})({[^}]-})","%2%1") 
		:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") :gsub("("..kt.."&H%x+&)"..kt.."&H%x+&","%1")
	end
	
	text=text:gsub("\\clrs","") :gsub("_ast_","*") :gsub("{}","")
	line.text=text
        subs[i]=line
    end
end


--	Shift colours	--
function shift(subs,sel)
	klrs=tonumber(res.clrs)	-- how many colours we're dealing with
	count=1				-- start line counter
	if res.shit=="line" then sline=true else sline=false end
    for x, i in ipairs(sel) do
        progress(string.format("Colorizing line %d/%d",x,#sel))
	line=subs[i]
	text=line.text

	    -- check if line looks colorized
	    if not text:match("{(\\[1234]?c)&H%x+&}[%w%p]") then ADD({{class="label",
		label="Line "..x.." does not \nappear to be colorized",x=0,y=0,width=1,height=2}},{"OK"}) ak()
	    end

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
		if not text:match("^{\\[1234]?c&H%x+&}") then tags=text:match("^({\\[^}]*})") text=text:gsub("^{\\[^}]*}","") end

		-- shifting colours happens here
		switch=1
		repeat 
		text=re.sub(text, "(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})([\\w[:punct:]])", "\\2\\1")
		text=re.sub(text, "(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})(\\s)", "\\2\\1")
		text=re.sub(text, "(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})(\\\\N)", "\\2\\1")
		text=re.sub(text, "(\\{\\*?\\\\[1234]?c&H[A-Fa-f0-9]+&\\})$", "")
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
		  for cl1,cl2,cl3 in text:gmatch("({\\[1234]?c&H%x+&})([%w%p%s])({\\[1234]?c&H%x+&})") do
		    if cl1==cl3 then 
		    text=text:gsub(cl1..cl2..cl3,cl1..cl2)
		    end
		  end
		until switch>=count

		if tags then text=tags..text end
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
    for x, i in ipairs(sel) do
        progress(string.format("Colorizing line %d/%d",x,#sel))
	line=subs[i]
	text=line.text
	if defaref and line.style=="Default" then styleref=defaref
	elseif lastref and laststyle==line.style then styleref=lastref
	else styleref=stylechk(line.style) end
	lastref=styleref	laststyle=line.style
	
	stylecol=stylecolours()
	
	    if res.kol=="primary" then k="\\c" end
	    if res.kol=="border" then k="\\3c" end
	    if res.kol=="shadow" then k="\\4c" end
	    if res.kol=="secondary" then k="\\2c" end
	    text=text:gsub("\\1c","\\c")
	    if not text:match("^{\\") then text=text:gsub("^","{\\}") end

	-- 1-->3   match outline to primary
	if pressed=="Match Colours" and res.match13 then
	    for ctags in text:gmatch("({\\[^}]-})") do
		ctags2=nil
		if ctags:match("\\3c") and not ctags:match("\\c&") then ctags2=ctags:gsub("\\3c&H%w+&","\\3c"..primary) end
		if ctags:match("\\c&") and ctags:match("\\3c") then 
		  tempc=ctags:match("\\c(&H%w+&)") ctags2=ctags:gsub("\\3c&H%w+&","\\3c"..tempc) end
		if ctags:match("\\c&") and not ctags:match("\\3c") then
		  ctags2=ctags:gsub("\\c(&H%w+&)","\\c%1\\3c%1") end
		if ctags==text:match("^({\\[^}]-})") and not ctags:match("\\3c") and not ctags:match("\\c&") then
		  ctags2=ctags:gsub("^({\\[^}]-)}","%1\\3c"..primary.."}") end
		if ctags2 then ctags=esc(ctags) text=text:gsub(ctags,ctags2) end
	    end
	end

	-- 3-->1   match primary to outline
	if pressed=="Match Colours" and res.match31 then
	    for ctags in text:gmatch("({\\[^}]-})") do
		ctags2=nil
		if ctags:match("\\c&") and not ctags:match("\\3c") then ctags2=ctags:gsub("\\c&H%w+&","\\c"..outline) end
		if ctags:match("\\c&") and ctags:match("\\3c") then 
		  tempc=ctags:match("\\3c(&H%w+&)") ctags2=ctags:gsub("\\c&H%w+&","\\c"..tempc) end
		if ctags:match("\\3c") and not ctags:match("\\c&") then
		  ctags2=ctags:gsub("\\3c(&H%w+&)","\\c%1\\3c%1") end
		if ctags==text:match("^({\\[^}]-})") and not ctags:match("\\c&") and not ctags:match("\\3c") then
		  ctags2=ctags:gsub("^({\\[^}]-)}","%1\\c"..outline.."}") end
		if ctags2 then ctags=esc(ctags) text=text:gsub(ctags,ctags2) end
	    end
	end
	
	-- 1-->4   match shadow to primary
	if pressed=="Match Colours" and res.match14 then
	    for ctags in text:gmatch("({\\[^}]-})") do
		ctags2=nil
		if ctags:match("\\4c") and not ctags:match("\\c") then ctags2=ctags:gsub("\\4c&H%w+&","\\4c"..primary) end
		if ctags:match("\\4c") and ctags:match("\\c") then 
		  tempc=ctags:match("\\c(&H%w+&)") ctags2=ctags:gsub("\\4c&H%w+&","\\4c"..tempc) end
		if ctags:match("\\c") and not ctags:match("\\4c") then
		  ctags2=ctags:gsub("\\c(&H%w+&)","\\c%1\\4c%1") end
		if ctags==text:match("^({\\[^}]-})") and not ctags:match("\\4c") and not ctags:match("\\c") then
		  ctags2=ctags:gsub("^({\\[^}]-)}","%1\\4c"..primary.."}") end
		if ctags2 then ctags=esc(ctags) text=text:gsub(ctags,ctags2) end
	    end
	end
	
	-- 3-->4   match shadow to outline
	if pressed=="Match Colours" and res.match34 then
	    for ctags in text:gmatch("({\\[^}]-})") do
		ctags2=nil
		if ctags:match("\\4c") and not ctags:match("\\3c") then ctags2=ctags:gsub("\\4c&H%w+&","\\4c"..outline) end
		if ctags:match("\\4c") and ctags:match("\\3c") then 
		  tempc=ctags:match("\\3c(&H%w+&)") ctags2=ctags:gsub("\\4c&H%w+&","\\4c"..tempc) end
		if ctags:match("\\3c") and not ctags:match("\\4c") then
		  ctags2=ctags:gsub("\\3c(&H%w+&)","\\3c%1\\4c%1") end
		if ctags==text:match("^({\\[^}]-})") and not ctags:match("\\4c") and not ctags:match("\\3c") then
		  ctags2=ctags:gsub("^({\\[^}]-)}","%1\\4c"..outline.."}") end
		if ctags2 then ctags=esc(ctags) text=text:gsub(ctags,ctags2) end
	    end
	end

	-- 1<-->3   switch primary and border
	if pressed=="Match Colours" and res.match131 then
	    if text:match("^{\\") then
		tags=text:match("^({\\[^}]-})")
		if tags:match("\\c&") then tags=tags:gsub("\\c&","\\tempc")
		else tags=tags:gsub("({\\[^}]-)}","%1\\tempc"..primary.."}") end
		if tags:match("\\3c") then tags=tags:gsub("\\3c","\\c")
		else tags=tags:gsub("({\\[^}]-)}","%1\\c"..outline.."}") end
		tags=tags:gsub("\\tempc","\\3c")
		after=text:match("^{\\[^}]-}(.*)")
		after=after:gsub("\\c&","\\tempc")
		after=after:gsub("\\3c","\\c")
		after=after:gsub("\\tempc","\\3c")
		text=tags..after
	    else
		tags="{\\c"..outline.."\\3c"..primary.."}"
		after=text
		after=after:gsub("\\c&","\\tempc")
		after=after:gsub("\\3c","\\c")
		after=after:gsub("\\tempc","\\3c")
		text=tags..after
	    end
	end

	-- Invert All Colours  
	if pressed=="Match Colours" and res.invert then
	    if not text:match("^{\\") then text="{\\what}"..text end
		tags=text:match("^({\\[^}]-})")
		for n=1,4 do
		    ctg="\\"..n.."c"
		    ctg=ctg:gsub("1","")
		    if not tags:match(ctg) and n~=2 then text=text:gsub("^({\\[^}]-)}","%1"..ctg..stylecol[n].."}") end
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
	    text=text:gsub("\\what","")
	end

	-- RGB / HSL
	if pressed=="RGB" or pressed=="HSL" then
	    lvlr=res.R lvlg=res.G lvlb=res.B
	    hue=res.huehue
	    sat=res.satur
	    brite=res.bright
	    corols={}
	    if res.k1 then table.insert(corols,"1") end
	    if res.k2 then table.insert(corols,"2") end
	    if res.k3 then table.insert(corols,"3") end
	    if res.k4 then table.insert(corols,"4") end
	    tagz=text:match("^({\\[^}]-})")
	    
	    for i=1,#corols do
		n=tonumber(corols[i])
		local kl="\\"..n.."c"
		kl=kl:gsub("\\1c","\\c")
		
		if res.mktag and not tagz:match(kl) then
		    text=text:gsub("^({\\[^}]-)}","%1"..kl..stylecol[n].."}")
		end 
	      
		-- R G B --
		if pressed=="RGB" then
		  for kol1,kol2,kol3 in text:gmatch(kl.."&H(%x%x)(%x%x)(%x%x)&") do
		    kol1n=brightness(kol1,lvlb)
		    kol2n=brightness(kol2,lvlg)
		    kol3n=brightness(kol3,lvlr)
		  text=text:gsub(kl.."&H"..kol1..kol2..kol3,kl.."&H"..kol1n..kol2n..kol3n)
		  end
		end
		
		-- H S B --
		if pressed=="HSL" then
		  for kol1,kol2,kol3 in text:gmatch(kl.."&H(%x%x)(%x%x)(%x%x)&") do
		  H1,S1,L1=RGB_to_HSL(kol3,kol2,kol1)
		  H=H1+hue/255
		  S=S1+sat/255
		  L=L1+brite/255
		  H,S,L=HSLround(H,S,L)
		  if randomize then
		    H2=H1-hue/255
		    S2=S1-sat/255
		    L2=L1-brite/255
		    H2,S2,L2=HSLround(H2,S2,L2)
		    H=math.random(H*1000,H2*1000)/1000
		    S=math.random(S*1000,S2*1000)/1000
		    L=math.random(L*1000,L2*1000)/1000
		  end
		  kol3n,kol2n,kol1n=HSL_to_RGB(H,S,L)
		  kol3n=tohex(round(kol3n))
		  kol2n=tohex(round(kol2n))
		  kol1n=tohex(round(kol1n))
		  text=text:gsub(kl.."&H"..kol1..kol2..kol3,kl.."&H"..kol1n..kol2n..kol3n)
		  end
		end
	    end
	end

	text=text:gsub("\\\\","\\") :gsub("\\}","}") :gsub("{}","")
	line.text=text
        subs[i]=line
    end
end


--	GRADIENT	--
function gradient(subs,sel)
    styleget(subs)
    if res.grtype=="RGB" then GRGB=true else GRGB=false end
    if res.ast then ast="*" else ast="" end
    for x, i in ipairs(sel) do
        progress(string.format("Colorizing line %d/%d",x,#sel))
	line=subs[i]
	text=line.text
	text=text:gsub("\\c&","\\1c&") :gsub("\\N","{\\N}") :gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	after=text:gsub("^{\\[^}]-}","")
	nc=text:gsub("{[^\\}]-}","")
	if text:match("{\\[^}]-}$") then text=text.."wtfwhywouldyoudothis" end
	
	-- colours from style
	styleref=stylechk(line.style)
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
	  -- save tags
	  tags=text:match("^{\\[^}]-}") or ""
	  -- linebreak adjustment
	  if res.gradn then
	    startc=tags:match("\\"..ac.."c&H%x+&") or "\\"..ac.."c"..sc
	    endc=nc:match("(\\"..ac.."c&H%x+&)[^}]-}%w+$") or ""
	    text=text:gsub("([%w%p])%s*{\\N","{"..endc.."}%1{\\N}{"..startc)
	  end
	  -- back up original
	  orig=text
	  -- leave only releavant colour tags, nuke all other ones, add colour from style if missing at the start
	  ctext=text:gsub("\\N","") :gsub("\\[^1234][^c][^\\}]+","") :gsub("\\[^"..ac.."]c[^\\}]+","") :gsub("{%*?}","")
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
		  nR1=(tonumber(R1,16))  nR2=(tonumber(R2,16))
		  nG1=(tonumber(G1,16))  nG2=(tonumber(G2,16))
		  nB1=(tonumber(B1,16))  nB2=(tonumber(B2,16))
		  Rdiff=(nR2-nR1)/posi[c+1]	R=nR1+Rdiff*l
		  Gdiff=(nG2-nG1)/posi[c+1]	G=nG1+Gdiff*l
		  Bdiff=(nB2-nB1)/posi[c+1]	B=nB1+Bdiff*l
		else		-- HSL
		  Hdiff=(H2-H1)/posi[c+1]	H=H1+Hdiff*l
		  Sdiff=(S2-S1)/posi[c+1]	S=S1+Sdiff*l
		  Ldiff=(L2-L1)/posi[c+1]	L=L1+Ldiff*l
		  R,G,B=HSL_to_RGB(H,S,L)
		end
		R=tohex(round(R))
		G=tohex(round(G))
		B=tohex(round(B))
		-- colour + letter
		ncol="{"..ast.."\\"..ac.."c&H"..B..G..R.."&}"
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
	:gsub("wtfwhywouldyoudothis","")
	:gsub("{\\N\\","\\N{\\")
	:gsub("{\\N}","\\N")
	:gsub("\\N}","}\\N")
	:gsub("([^{])%*\\","%1\\")
	
	line.text=text
        subs[i]=line
    end
end

function stylecolours()
	stylecol={}
	primary=styleref.color1:gsub("H%x%x","H")	sc1=primary	table.insert(stylecol,sc1)
	pri=text:match("^{[^}]-\\c(&H%x+&)")		if pri~=nil then primary=pri end
	secondary=styleref.color2:gsub("H%x%x","H")	sc2=secondary	table.insert(stylecol,sc2)
	sec=text:match("^{[^}]-\\3c(&H%x+&)")		if sec~=nil then secondary=sec end
	outline=styleref.color3:gsub("H%x%x","H")	sc3=outline	table.insert(stylecol,sc3)
	out=text:match("^{[^}]-\\3c(&H%x+&)")		if out~=nil then outline=out end
	shadow=styleref.color4:gsub("H%x%x","H")	sc4=shadow	table.insert(stylecol,sc4)
	sha=text:match("^{[^}]-\\c(&H%x+&)")		if sha~=nil then shadow=sha end
	return stylecol
end

function textmod(orig)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	    until not text:match("{(\\[^}]-)}{(\\[^}]-)}")
	vis=text:gsub("{[^}]-}","")
	ltrmatches=re.find(vis,".")
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match("^{(\\[^}]-)}")
	if stags==nil then stags="" end
	text=text:gsub("^{\\[^}]-}","") :gsub("{[^\\}]-}","")
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
	for n, t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..newt.."}" end
    end
    newtext="{"..stags.."}"..newline
    text=newtext
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
    if num<1 then num="0"
    elseif num>14 then num="F"
    elseif num==10 then num="A"
    elseif num==11 then num="B"
    elseif num==12 then num="C"
    elseif num==13 then num="D"
    elseif num==14 then num="E" end
return num
end

function styleget(subs)
    styles={}
    for i=1, #subs do
        if subs[i].class=="style" then
	    table.insert(styles,subs[i])
	end
	if subs[i].class=="dialogue" then break end
    end
end

function stylechk(stylename)
    for i=1,#styles do
	if stylename==styles[i].name then
	    styleref=styles[i]
	    if styles[i].name=="Default" then defaref=styles[i] end
	    break
	end
    end
    return styleref
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

function round(num) num=math.floor(num+0.5) return num end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function repetition()
    if lastres and res.rept then res=lastres end
end

function tf(val)
    if val==true then ret="true" else ret="false" end
    return ret
end

function detf(txt)
    if txt=="true" then ret=true
    elseif txt=="false" then ret=false
    else ret=txt end
    return ret
end

function logg(m) aegisub.log("\n "..m) end

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
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
	GUI=
	{
	{x=0,y=0,class="label",label="Colours"},
	{x=1,y=0,width=2,class="dropdown",name="clrs",items={"2","3","4","5"},value="2"},
	
	{x=0,y=1,class="label",label="Shift base:"},
	{x=1,y=1,width=2,class="dropdown",name="shit",items={"# of colours","line"},value="# of colours"},
	
	{x=0,y=2,class="label",label="Apply to:  "},
	{x=1,y=2,width=2,class="dropdown",name="kol",items={"primary","border","shadow","secondary"},value="primary"},
	    
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
	
	{x=0,y=3,width=3,class="checkbox",name="word",label="Colorize by word"},
	{x=0,y=4,width=3,class="checkbox",name="join",label="Don't join with other tags"},
	{x=0,y=5,width=4,class="checkbox",name="cont",label="Continuous shift line by line"},
	{x=0,y=6,width=3,class="checkbox",name="tune",label="Tune colours"},
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
	{x=9,y=9,width=2,class="checkbox",name="randoom",label="Randomize",hint=""},
	
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
	{x=3,y=10,width=3,class="checkbox",name="rem",label="Remember last",hint="Remember last settings"},
	{x=7,y=10,width=2,class="checkbox",name="rept",label="Repeat last",hint="Repeat with last settings"},
	{x=9,y=10,width=2,class="checkbox",name="save",label="Save config",hint="Saves current configuration\n(for most things)"},
	
	}
	loadconfig()
	if colourblind and res.rem then
	  for key,val in ipairs(GUI) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="color" then val.value=res[val.name] end
	    if val.name=="save" then val.value=false end
	  end
	end
	pressed,res=ADD(GUI,{"Colorize","Shift","Match Colours","RGB","HSL","Cancel"},{ok='Colorize',close='Cancel'})
	if pressed=="Cancel" then ak() end
	randomize=res.randoom
	if pressed=="Colorize" then repetition() 
	    if res.save then saveconfig()
	    elseif res.gcl then gcolors(subs,sel)
	    elseif res.grad then gradient(subs,sel)
	    elseif res.tune then ctune(subs,sel)
	    else colors(subs,sel) end
	end
	if pressed=="Shift" then repetition() shift(subs,sel) end
	if pressed=="Match Colours" or pressed=="RGB" or pressed=="HSL" then repetition() styleget(subs) matchcolors(subs,sel) end
	
	colourblind=true
	lastres=res
	
	aegisub.set_undo_point(script_name)
	return sel
end

aegisub.register_macro(script_name, script_description, colorize)