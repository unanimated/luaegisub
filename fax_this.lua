script_name="Copyfax This"
script_description="Copyfax This"
script_author="unanimated"
script_version="2.71"

-- all the "copy" things copy things from first selected line and paste them to the other lines
-- clip shift coordinates will shift the clip by that amount each line

--[[

Fax It
	Adds a \fax tag. "to the right" just adds a "-". (Yes, that's pretty useless.)
	"from clip" calculates the fax value from the first two points of a vector clip.
	  if the clip has 4 points, points 3-4 are used to calculate fax for the last character (for grad-by-char).

Copy Stuff
	This lets you copy almost anything from one line to others.
	The primary use is to copy from the first line of your selection to the others.
	If you need to copy to a line that's above the source like in the grid, just click Copy with the selected things
	and then use Paste Saved on the line(s) you want to copy to.
	You can copy inline tags too, but they will only be pasted to the first tag block.
	By placing * in the text in the GUI, selected tags will be copied to that position (first selected line only).
	[Un]hide lets you hide/unhide checked tags (by making them comments). Nothing checked = unhide. Good for clips, for example.

Copy Tags
	Copies the first block of tags in its entirety from first selected line to the others.

Copy Text
	Copies what's after the first block of tags from first selected line to the others (including inline tags).

Copy Clip
	Copies clip from first selected line to the others.
	Clip shift coordinates will shift the clip by that amount each line.

Copy Colours
	Copies checked colours from first selected line to the others.
	Unlike Copy Stuff, this can read the colours from the style when tags are missing.
	You can also include alpha for the checked colours.

Split by \N
	Splits a line at each linebreak.
	If there's no linebreak, you can split by tags or spaces.
	Splitting by linebreak will try to keep the position of each part, but it only supports \fs, \fscy, and \an.


-- OPTIONS (true/false)													]]
copy_style=true			-- "copy style with tags" checked in the gui
autogradient_clip2fax=true	-- automatically gradient \fax for "fax from clip" with 4-point clip

re=require'aegisub.re'

function fucks(subs, sel)
	if res.right then res.fax=0-res.fax end
	for z, i in ipairs(sel) do
	    local l=subs[i]
	    local t=l.text
	    if not res.clax then
		t=t:gsub("^({[^}]-\\fax)[%d%.%-]+","%1"..res.fax)
		if not t:match("^{[^}]-\\fax") then 
		t="{\\fax"..res.fax.."}"..t
		t=t:gsub("^({\\[^}]-)}{\\","%1\\")
		end
	    else
		if not t:match("\\clip") then t_error("Missing \\clip.",true) end
		cx1,cy1,cx2,cy2,cx3,cy3,cx4,cy4=t:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
		if cx1==nil then cx1,cy1,cx2,cy2=t:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)") end
		rota=t:match("\\frz([%d%.%-]+)") or 0
		ad=cx1-cx2
		op=cy1-cy2
		tang=(ad/op)
		ang1=math.deg(math.atan(tang))
		ang2=ang1-rota
		tangf=math.tan(math.rad(ang2))
		
		faks=round(tangf*100)/100
		t=addtag("\\fax"..faks,t)
		if cy4~=nil then
		    tang2=((cx3-cx4)/(cy3-cy4))
		    ang3=math.deg(math.atan(tang2))
		    ang4=ang3-rota
		    tangf2=math.tan(math.rad(ang4))
		    faks2=round(tangf2*100)/100
		    endcom=""
		    repeat
			t=t:gsub("({[^}]-})%s*$",function(ec) endcom=ec..endcom return "" end)
		    until not t:match("}$")
		    t=t:gsub("(.)$","{\\fax"..faks2.."}%1")
		    
		    if autogradient_clip2fax then
			vis=t:gsub("{[^}]-}","")
			orig=t:gsub("^{\\[^}]*}","")
			tg=t:match("^{\\[^}]-}")
			chars={}
			ltrmatches=re.find(vis,".")
			  for l=1,#ltrmatches do
			    table.insert(chars,ltrmatches[l].str)
			  end
			faxdiff=(faks2-faks)/(#chars-1)
			tt=chars[1]
			for c=2,#chars do
			    if c==#chars then ast="" else ast="*" end
			    if chars[c]==" " then tt=tt.." " else
			    tt=tt.."{"..ast.."\\fax"..round((faks+faxdiff*(c-1))*100)/100 .."}"..chars[c]
			    end
			end
			t=tg..tt
			
			if orig:match("{%*?\\") then t=textmod(orig,t) end
		    end
		    
		    t=t..endcom
		end
		
		t=t:gsub("\\clip%([^%)]+%)","")
		:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		:gsub("(\\fax[%d%.%-]+)([^}]-)(\\fax[%d%.%-]+)","%3%2")
		:gsub("%**}","}")
	    end	
	    l.text=t
	    subs[i]=l
	end
end

function copystuff(subs, sel)
    -- get stuff from line 1
    rine=subs[sel[1]]
    ftags=(rine.text:match("^{(\\[^}]-)}") or "")
    cstext=rine.text:gsub("^{(\\[^}]-)}","")
    vis=rine.text:gsub("{([^}]-)}","")
    csstyle=rine.style
    csst=rine.start_time
    cset=rine.end_time
    -- detect / save / remove transforms
    ftra=""
    if ftags:match("\\t") then
	for t in ftags:gmatch("\\t%b()") do ftra=ftra..t end
	ftags=ftags:gsub("\\t%b()","")
    end
    rept={"drept"}
    -- build GUI
    copyshit={
	{x=0,y=0,width=1,height=1,class="checkbox",name="chks",label="[   Start Time   ]   ",value=false},
	{x=0,y=1,width=1,height=1,class="checkbox",name="chke",label="[   End Tim   ]",value=false},
	{x=1,y=0,width=1,height=1,class="checkbox",name="css",label="[   Style   ]   ",value=false},
	{x=1,y=1,width=1,height=1,class="checkbox",name="tkst",label="[   Text   ]",value=false},
	{x=2,y=0,width=1,height=1,class="label",label="Place * in text below to copy tags there"},
	{x=0,y=2,width=3,height=1,class="edit",name="ltxt",value=vis,hint="only works for first selected line"},
	}
    ftw=3
    -- regular tags -> GUI
    for f in ftags:gmatch("\\[^\\]+") do lab=f
	if f:match("\\i?clip%(m") then lab=f:match("\\i?clip%(m [%d%.%-]+ [%d%.%-]+ %a [%d%.%-]+ [%d%.%-]+ ").."..." end
	if f:match("\\move") then lab=f:gsub("%.%d+","") end
	  cb={x=0,y=ftw,width=2,height=1,class="checkbox",name="chk"..ftw,label=lab,value=false,realname=f}
	  drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
	  if drept==0 then
	  table.insert(copyshit,cb)	ftw=ftw+1
	  table.insert(rept,f)
	  end
    end
    -- transform tags
    for f in ftra:gmatch("\\t%b()") do
	cb={x=0,y=ftw,width=2,height=1,class="checkbox",name="chk"..ftw,label=f,value=false}
	  drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
	  if drept==0 then
	  table.insert(copyshit,cb)	ftw=ftw+1
	  table.insert(rept,f)
	  end
    end
    itw=3
    -- inline tags
    if cstext:match("{[^}]-\\[^Ntrk]") then
      cb={x=2,y=1,width=1,height=1,class="label",label="inline tags (will only be added to 1st block)"} table.insert(copyshit,cb)
      for f in cstext:gmatch("\\[^tNhrk][^\\}%)]+") do lab=f
	if itw==22 then lab="(that's enough...)" f="" end
	if itw==23 then break end
	  cb={x=2,y=itw,width=1,height=1,class="checkbox",name="chk2"..itw,label=lab,value=false,realname=f}
	  drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
	  if drept==0 then
	  table.insert(copyshit,cb)	itw=itw+1
	  table.insert(rept,f)
	  end
      end
    end
	repeat
	    if press=="Check All Tags" then
		for key,val in ipairs(copyshit) do
		    if val.class=="checkbox" and not val.label:match("%[ ") and val.x==0 then val.value=true end
		end
	    end
	press,rez=ADD(copyshit,{"Copy","Check All Tags","Paste Saved","[Un]hide","Cancel"},{ok='Copy',close='Cancel'})
	until press~="Check All Tags"
	if press=="Cancel" then ak() end
	-- save checked tags
	kopytags=""
	copytfs=""
	for key,val in ipairs(copyshit) do
	    if rez[val.name]==true and not val.label:match("%[ ") then 
		if not val.label:match("\\t") then kopytags=kopytags..val.realname else copytfs=copytfs..val.label end
	    end
	end
	if press=="Paste Saved" then kopytags=savedkopytags copytfs=savedcopytfs sn=1
	csstyle=savedstyle csst=savedt1 cset=savedt2 cstext=savedtext
	rez.css=savedcss rez.chks=savedchks rez.chke=savedchke rez.tkst=savedtkst
	elseif press=="Copy" then sn=2 
	savedkopytags=kopytags
	savedcopytfs=copytfs
	savedt1=csst savedt2=cset savedstyle=csstyle
	savedcss=rez.css savedchks=rez.chks savedchke=rez.chke
	savedtext=cstext savedtkst=rez.tkst
	end
	if rez.ltxt:match"%*" then inline=true sn=1 maxx=1 else inline=false maxx=#sel end

    -- lines 2+
    if press~="[Un]hide" then
    for i=sn,maxx do
        line=subs[sel[i]]
        text=subs[sel[i]].text
	text=text:gsub("\\1c","\\c")

	    if not text:match("^{\\") then text="{\\stuff}"..text end
	    ctags=text:match("^{\\[^}]-}")
	    -- handle existing transforms
	    if ctags:match("\\t") then
		ctags=trem(ctags)
		if text:match("^{}") then text=text:gsub("^{}","{\\stuff}") end
		text=text:gsub("^{\\[^}]-}",ctags)
		trnsfrm=trnsfrm..copytfs
	    elseif copytfs~="" then trnsfrm=copytfs
	    end
	    -- add + clean tags
	    if inline then
		initags=text:match("^{\\[^}]-}") if initags==nil then initags="" end
		endcom=""
		repeat
		  ec=text:match("{[^\\}]-}$") text=text:gsub("{[^\\}]-}$","") if ec~=nil then endcom=ec..endcom end
		until ec==nil
		orig=text
		text=rez.ltxt:gsub("%*","{"..kopytags.."}")
		text=textmod(orig,text)
		text=initags..text..endcom
	    else
		text=text:gsub("^({\\[^}]-)}","%1"..kopytags.."}")
	    end

	    text=text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	    text=extrakill(text)
	    -- add transforms
	
	    if trnsfrm then text=text:gsub("^({\\[^}]*)}","%1"..trnsfrm.."}") end
	    trnsfrm=nil
	    text=text:gsub("^({\\[^}]-})",function(tags) return cleantr(tags) end)
	    text=text:gsub("\\stuff","") :gsub("{}","")
	
	if rez.css then line.style=csstyle end
	if rez.chks then line.start_time=csst end
	if rez.chke then line.end_time=cset end
	if rez.tkst then text=text:gsub("^({\\[^}]-}).*","%1"..cstext) end
	line.text=text
	subs[sel[i]]=line
    end
    else
	txt=rine.text
	    -- unhide
	    if kopytags=="" and copytfs=="" then 
		uncom={}
		wai=0
		for com in txt:gmatch("{//([^}]+)}") do
		    table.insert(uncom,{x=0,y=wai,class="checkbox",label=com,name=com,value=false}) wai=wai+1
		end
		if #uncom<=1 then 
		    txt=txt:gsub("^(.*){//([^}]+})","{\\%2%1")
		    txt=txt:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%2%1}")
		else
		    pss,rz=ADD(uncom,{"OK","Cancel"},{ok='OK',close='Cancel'})
		    if pss=="Cancel" then ak() end
		    for key,val in ipairs(uncom) do
			enam=esc(val.name)
			if rz[val.name]==true then 
			    txt=txt:gsub("^(.*){//("..enam..")}","{\\%2}%1")
			    txt=txt:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%2%1}")
			end
		    end
		end
	    -- hide
	    else
		ekopytags=esc(kopytags)
		ecopytfs=esc(copytfs)
		for tg in ekopytags:gmatch("\\[^\\}]+") do txt=txt:gsub(tg,"") end
		for tg in kopytags:gmatch("\\([^\\}]+)") do txt=txt.."{//"..tg.."}" end
		for tg in ecopytfs:gmatch("\\t%%%b()") do txt=txt:gsub(tg,"") end
		for tg in copytfs:gmatch("\\(t%b())") do txt=txt.."{//"..tg.."}" end
		txt=txt:gsub("{}","")
	    end
	rine.text=txt
	subs[sel[1]]=rine
    end
    trnsfrm=nil
end

function copytags(subs, sel)
    for x, i in ipairs(sel) do
        line=subs[i]
        text=subs[i].text
	    if x==1  then
	      tags=text:match("^({\\[^}]*})")
	      if res.cpstyle then style=line.style end
	    end
	    if x~=1 then
	      if text:match("^({\\[^}]*})") then
	      text=text:gsub("^{\\[^}]*}",tags) else
	      text=tags..text
	      end
	      if res.cpstyle then line.style=style end
	    end
	    line.text=text
	    subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function copytext(subs, sel)
    for x, i in ipairs(sel) do
        line=subs[i]
        text=subs[i].text
	    if x==1  then
	      tekst=text:gsub("^{\\[^}]*}","")
	    end
	    if x~=1 then
	      if text:match("^{\\[^}]*}") then
	      text=text:gsub("^({\\[^}]*}).*","%1"..tekst) else
	      text=tekst
	      end
	    end
	    line.text=text
	    subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function copyclip(subs, sel)
	xc=res.xlip
	yc=res.ylip
    for x, i in ipairs(sel) do
        line=subs[i]
        text=subs[i].text
	    if x==1  then
	      if text:match("\\i?clip") then -- read clip
	      klipstart=text:match("\\i?clip%(([^%)]+)%)")
	      klip=klipstart
	      end
	    end
	    
	    if x~=1 then
	      if not text:match("^{\\") then text="{\\klip}"..text end
	      if not text:match("\\i?clip") then text=addtag("\\clip()",text) end
	      
		-- calculations
		if xc~=0 or yc~=0 then factor=x-1
		    klip=klipstart:gsub("([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		    function(a,b,c,d) return a+xc*factor.. "," ..b+yc*factor.. "," ..c+xc*factor.. "," ..d+yc*factor end)
		    if klipstart:match("m [%d%a%s%-]+") then
		    klip=klipstart:match("m ([%d%a%s%-]+)")
		    klip2=klip:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return a+xc*factor.." "..b+yc*factor end)
		    klip=klip:gsub("%-","%%-")
		    klip=klip:gsub(klip,klip2)
		    klip="m "..klip
		    end
		end
	      -- set clip
	      text=text:gsub("(\\i?clip)%([^%)]-%)","%1("..klip..")")
	      text=text:gsub("\\klip","")
	    end
	line.text=text
	subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function copycolours(subs, sel)
if not res.c1 and not res.c2 and not res.c3 and not res.c4 then ak() end
    for x, i in ipairs(sel) do
        line=subs[i]
        text=subs[i].text
	sr=stylechk(subs,line.style)
	text=text:gsub("\\1c","\\c")
	
	    -- copy from line 1
	    if x==1  then
	      if res.c1 then
	        if text:match("^{[^}]-\\c&") then col1=text:match("\\c(&H%x+&)") else col1=sr.color1:gsub("H%x%x","H") end
	        if text:match("^{[^}]-\\1a&") then alf1=text:match("\\a(&H%x+&)") else alf1=sr.color1:match("H%x%x") end
	      end
	      if res.c3 then
	        if text:match("^{[^}]-\\3c&") then col3=text:match("\\3c(&H%x+&)") else col3=sr.color3:gsub("H%x%x","H") end
	        if text:match("^{[^}]-\\3a&") then alf3=text:match("\\3a(&H%x+&)") else alf3=sr.color3:match("H%x%x") end
	      end
	      if res.c4 then
	        if text:match("^{[^}]-\\4c&") then col4=text:match("\\4c(&H%x+&)") else col4=sr.color4:gsub("H%x%x","H") end
	        if text:match("^{[^}]-\\4a&") then alf4=text:match("\\4a(&H%x+&)") else alf4=sr.color4:match("H%x%x") end
	      end
	      if res.c2 then
	        if text:match("^{[^}]-\\2c&") then col2=text:match("\\2c(&H%x+&)") else col2=sr.color2:gsub("H%x%x","H") end
	        if text:match("^{[^}]-\\2a&") then alf2=text:match("\\2a(&H%x+&)") else alf2=sr.color2:match("H%x%x") end
	      end
	    end

	    -- paste to other lines
	    if x~=1 then if not text:match("^{\\") then text=text:gsub("^","{\\kol}") end
	      if res.c1 then text=addtag2("\\c"..col1,text) end
	      if res.c3 then text=addtag2("\\3c"..col3,text) end
	      if res.c4 then text=addtag2("\\4c"..col4,text) end
	      if res.c2 then text=addtag2("\\2c"..col2,text) end
	     -- alpha
	     if res.alfa then
	      if res.c1 then text=addtag2("\\1a"..alf1,text) end
	      if res.c3 then text=addtag2("\\3a"..alf3,text) end
	      if res.c4 then text=addtag2("\\4a"..alf4,text) end
	      if res.c2 then text=addtag2("\\2a"..alf2,text) end
	     end
	    end
	    
	text=text:gsub("\\kol","")
	line.text=text
	subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function splitbreak(subs, sel)		-- 1.6
	for i=#sel,1,-1 do
	  line=subs[sel[i]]
	  text=subs[sel[i]].text
	    text=text:gsub("({[^}]-})",function (a) return debreak(a) end)
	    
	    if not text:match("\\N") then
	    P=ADD({{class="label",
	    label="Selection line "..i.." has no \\N. \nYou can split by spaces or by tags.",x=0,y=0,width=1,height=2}},{"Spaces","Tags","Skip","Cancel"})
	      if P=="Cancel" then ak() end
	      if P=="Spaces" then text=text:gsub(" "," \\N") end
	      if P=="Tags" then text=text:gsub("(.)({\\[^}]-})","%1\\N%2") end
	    end
	  
	    -- split by \N
	    if text:match("\\N")then
	    -- positioning (only considers \fs, \fscy, and \an)
	    poses=1 for en in text:gmatch("\\N") do poses=poses+1 end
	    posY=text:match("\\pos%([%d%.%-]+,([%d%.%-]+)%)")
	    if posY~=nil then
		styleref=stylechk(subs,line.style)
		fos=styleref.fontsize
		l_fos=text:match("\\fs(%d+)")		if l_fos~=nil then fos=l_fos end
		scy=styleref.scale_y
		l_scy=text:match("\\fscy([%d%.]+)")		if l_scy~=nil then scy=l_scy end
		siz=fos*scy/100
		align=tostring(styleref.align)
		l_align=text:match("\\an(%d)")		if l_align~=nil then align=l_align end
		if align:match("[123]") then posbase="low"
		elseif align:match("[456]") then posbase="mid"
		else posbase="high" end
		postab={}
		if posbase=="high" then
		    for p=1,poses do table.insert(postab,posY+(p-1)*siz) end
		end
		if posbase=="low" then
		    for p=poses,1,-1 do table.insert(postab,posY-(p-1)*siz) end
		    text=text:gsub("(\\pos%([%d%.%-]+,)[%d%.%-]+","%1"..postab[1])
		end
		if posbase=="mid" then
		    posYm=posY-(poses-1)*siz/2
		    for p=1,poses do table.insert(postab,posYm+(p-1)*siz) end
		    text=text:gsub("(\\pos%([%d%.%-]+,)[%d%.%-]+","%1"..postab[1])
		end
	    end
	    
	    line2=line
		if text:match("%*")then text=text:gsub("%*","_asterisk_") end
		if text:match("^{\\") then				-- lines 2+, with initial tags
		    tags=text:match("^({\\[^}]*})")			-- initial tags
		    tags2=""
		    count=0	poscount=2
		    text=text:gsub("\\N","*")				-- switch \N for *
		    for aftern in text:gmatch("%*%s*([^%*]*)") do	-- part after \N [*]
		      aftern=aftern:gsub("_break_","\\N")	:gsub("%s*$","")	:gsub("_asterisk_","*")
		        line2.text=tags..aftern				-- every new line=initial tags + part after one \N
			if posY~=nil then
			    line2.text=line2.text:gsub("(\\pos%([%d%.%-]+,)[%d%.%-]+","%1"..postab[poscount])
			end
			poscount=poscount+1
		      if aftern~="" then
		        count=count+1
		        line2.text=line2.text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		        line2.text=line2.text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
		        tags=line2.text:match("^({\\[^}]*})")
		        subs.insert(sel[i]+count,line2)		-- insert each match one line further 
		      end
		    end
		else							-- lines 2+, without initial tags
		    count=0
		    text=text:gsub("\\N","*")
		    for aftern in text:gmatch("%*%s*([^%*]*)") do
		      aftern=aftern:gsub("_break_","\\N")	:gsub("%s*$","")	:gsub("_asterisk_","*")
		      if aftern~="" then
		        count=count+1
		        line2.text=aftern
		        subs.insert(sel[i]+count,line2)
		      end
		    end
		end
		if text:match("^{\\") then				-- line 1, with initial tags
		    text=text:gsub("^({\\[^}]-})(.-)%*(.*)","%1%2")
		    text=text:gsub("_break_","\\N")	:gsub("%s*$","")
		else							-- line 1, without initial tags
		    text=text:gsub("^(.-)%*(.*)","%1")
		    text=text:gsub("_break_","\\N")	:gsub("%s*$","")
		end
		text=text:gsub("_asterisk_","*")
		
	    line.text=text
	    subs[sel[i]]=line
	    end
	end
	aegisub.set_undo_point(script_name)
end

--	reanimatools	--
function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end

function addtag2(tag,text) 
	local tg=tag:match("\\%d?%a+")
	text=text:gsub("^({\\[^}]-)}","%1"..tag.."}")
	:gsub(tg.."[^\\}]+([^}]-)("..tg.."[^\\}]+)","%2%1")
	return text 
end

function despace(txt) txt=txt:gsub("%s","_sp_") return txt end

function debreak(txt) txt=txt:gsub("\\N","_break_") return txt end

function round(num)  num=math.floor(num+0.5)  return num  end

function textmod(orig,text)
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
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext="{"..stags.."}"..newline
    text=newtext
    return text
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

	cleant=""
	for ct in trnsfrm:gmatch("\\t%((\\[^%(%)]-)%)") do cleant=cleant..ct end
	for ct in trnsfrm:gmatch("\\t%((\\[^%(%)]-%b()[^%)]-)%)") do cleant=cleant..ct end
	trnsfrm=trnsfrm:gsub("\\t%(\\[^%(%)]+%)","")
	trnsfrm=trnsfrm:gsub("\\t%((\\[^%(%)]-%b()[^%)]-)%)","")
	if cleant~="" then trnsfrm="\\t("..cleant..")"..trnsfrm end	
	tags=tags:gsub("^({\\[^}]*)}","%1"..trnsfrm.."}")
	return tags
end

function duplikill(tagz)
	tf=""
	for t in tagz:gmatch("\\t%b()") do tf=tf..t end
	tagz=tagz:gsub("\\t%b()","")
	tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
	for i=1,#tags1 do
	    tag=tags1[i]
	    tagz=tagz:gsub("\\"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%2%1")
	end
	tagz=tagz:gsub("\\1c&","\\c&")
	tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
	for i=1,#tags2 do
	    tag=tags2[i]
	    tagz=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1")
	end
	tagz=tagz:gsub("({\\[^}]-)}","%1"..tf.."}")
	return tagz
end

function extrakill(text)
	tags3={"pos","move","org","clip","iclip","fad"}
	for i=1,#tags3 do
	    tag=tags3[i]
	    text=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%3%2")
	end
	text=text:gsub("(\\pos[^\\}]+)([^}]-)(\\move[^\\}]+)","%3%2")
	text=text:gsub("(\\move[^\\}]+)([^}]-)(\\pos[^\\}]+)","%3%2")
	return text
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

function t_error(message,cancel)
  aegisub.dialog.display({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then aegisub.cancel() end
end

function stylechk(subs,stylename)
  for i=1, #subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if stylename==st.name then styleref=st break end
      
    end
  end
  return styleref
end

function konfig(subs, sel)
	if lastfax==nil then lastfax=0.05 end
	if lastxlip==nil then lastxlip=0 end
	if lastylip==nil then lastylip=0 end
	GUI=
	{
	    {x=0,y=0,width=1,height=1,class="label",label="\\fax ",},
	    {x=1,y=0,width=2,height=1,class="floatedit",name="fax",value=lastfax},
	    {x=0,y=1,width=2,height=1,class="checkbox",name="clax",label="from clip   ",value=true},
	    {x=2,y=1,width=1,height=1,class="checkbox",name="right",label="to the right   ",value=false},
	    
	    {x=3,y=0,width=2,height=1,class="checkbox",name="cpstyle",label="copy style with tags",value=copy_style},
	    
	    {x=5,y=0,width=1,height=1,class="label",label="  copy colours:  ",},
	    {x=6,y=0,width=1,height=1,class="checkbox",name="c1",label="c",value=false},
	    {x=7,y=0,width=1,height=1,class="checkbox",name="c3",label="3c ",value=false},
	    {x=8,y=0,width=1,height=1,class="checkbox",name="c4",label="4c  ",value=false},
	    {x=9,y=0,width=1,height=1,class="checkbox",name="c2",label="2c",value=false},
	    {x=10,y=0,width=2,height=1,class="checkbox",name="alfa",label="include alpha",value=false},
	    
	    {x=3,y=1,width=1,height=1,class="label",label="shift clip every frame by:",},
	    {x=5,y=1,width=2,height=1,class="floatedit",name="xlip",value=lastxlip},
	    {x=7,y=1,width=3,height=1,class="floatedit",name="ylip",value=lastylip},
	    
	    {x=10,y=1,width=2,height=1,class="label",label="   Copyfax This v"..script_version},
	} 	
	P, res=ADD(GUI,
	{"fax it","copy stuff","copy tags","copy text","copy clip","copy colours","split by \\N","cancel"},{cancel='cancel'})
	
	if P=="cancel" then ak() end
	if P=="fax it" then fucks(subs, sel) end
	if P=="copy stuff" then copystuff(subs, sel) end
	if P=="copy tags" then copytags(subs, sel) end
	if P=="copy text" then copytext(subs, sel) end
	if P=="copy clip" then copyclip(subs, sel) end
	if P=="copy colours" then copycolours(subs, sel) end
	if P=="split by \\N" then splitbreak(subs, sel) end
	lastfax=res.fax
	lastxlip=res.xlip
	lastylip=res.ylip
end

function fax_this(subs, sel)
    ADD=aegisub.dialog.display
    ak=aegisub.cancel
    konfig(subs, sel)
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, fax_this)