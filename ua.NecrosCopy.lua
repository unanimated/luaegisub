-- Manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#necroscopy

-- OPTIONS (true/false)	--
copy_style=true			-- "copy style with tags" checked in the gui
autogradient_clip2fax=true	-- automatically gradient \fax for "fax from clip" with 4-point clip
-- END OF OPTIONS	--

script_name="NecrosCopy"
script_description="Copy and Fax Things"
script_author="unanimated"
script_version="3.0"
script_namespace="ua.NecrosCopy"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="3.0.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

re=require'aegisub.re'

function fucks(subs,sel)
	if res.right then res.fax=0-res.fax end
	for z,i in ipairs(sel) do
	    l=subs[i]
	    t=l.text
	    
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
		sr=stylechk(subs,l.style)
		nontra=t:gsub("\\t%b()","")
		rota=nontra:match("\\frz([%d%.%-]+)") or sr.angle
		scx=nontra:match("\\fscx([%d%.]+)") or sr.scale_x
		scy=nontra:match("\\fscy([%d%.]+)") or sr.scale_y
		scr=scx/scy
		ad=cx1-cx2
		op=cy1-cy2
		tang=(ad/op)
		ang1=math.deg(math.atan(tang))
		ang2=ang1-rota
		tangf=math.tan(math.rad(ang2))
		
		faks=round(tangf/scr*100)/100
		t=addtag("\\fax"..faks,t)
		if cy4~=nil then
		    tang2=((cx3-cx4)/(cy3-cy4))
		    ang3=math.deg(math.atan(tang2))
		    ang4=ang3-rota
		    tangf2=math.tan(math.rad(ang4))
		    faks2=round(tangf2*100)/100
		    endcom=""
		    repeat t=t:gsub("({[^}]-})%s*$",function(ec) endcom=ec..endcom return "" end)
		    until not t:match("}$")
		    t=t:gsub("(.)$","{\\fax"..faks2.."}%1")
		    
		    if autogradient_clip2fax then
			vis=t:gsub("{[^}]-}","")
			orig=t:gsub("^{\\[^}]*}","")
			tg=t:match("^{\\[^}]-}")
			chars={}
			ltrz=re.find(vis,".")
			  for l=1,#ltrz do
			    table.insert(chars,ltrz[l].str)
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
		
		t=t:gsub("\\clip%b()","")
		:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		:gsub("(\\fax[%d%.%-]+)([^}]-)(\\fax[%d%.%-]+)","%3%2")
		:gsub("%**}","}")
	    end	
	    l.text=t
	    subs[i]=l
	end
end

function copystuff(subs,sel)
    -- get stuff from line 1
    rine=subs[sel[1]]
    ftags=rine.text:match("^{(\\[^}]-)}") or ""
    cstext=rine.text:gsub("^{(\\[^}]-)}","")
    vis=rine.text:gsub("%b{}","")
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
	{x=0,y=0,class="checkbox",name="chks",label="[   Start Time   ]   "},
	{x=0,y=1,class="checkbox",name="chke",label="[   End Time   ]"},
	{x=1,y=0,class="checkbox",name="css",label="[   Style   ]   "},
	{x=1,y=1,class="checkbox",name="tkst",label="[   Text   ]"},
	{x=2,y=0,class="label",label="Place * in text below to copy tags there"},
	{x=2,y=1,class="checkbox",name="breaks",label="Copy tags after all linebreaks (all lines)   ",realname=""},
	{x=0,y=2,width=3,class="edit",name="ltxt",value=vis,hint="only works for first selected line"},
	}
    ftw=3
    -- regular tags -> GUI
    for f in ftags:gmatch("\\[^\\]+") do lab=f:gsub("&","&&")
	if f:match("\\i?clip%(m") then lab=f:match("\\i?clip%(m [%d%.%-]+ [%d%.%-]+ %a [%d%.%-]+ [%d%.%-]+ ").."..." end
	if f:match("\\move") then lab=f:gsub("%.%d+","") end
	  cb={x=0,y=ftw,width=2,class="checkbox",name="chk"..ftw,label=lab,realname=f}
	  drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
	  if drept==0 then
	  table.insert(copyshit,cb)	ftw=ftw+1
	  table.insert(rept,f)
	  end
    end
    -- transform tags
    for f in ftra:gmatch("\\t%b()") do
	cb={x=0,y=ftw,width=2,class="checkbox",name="chk"..ftw,label=f}
	  drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
	  if drept==0 then
	  table.insert(copyshit,cb)	ftw=ftw+1
	  table.insert(rept,f)
	  end
    end
    itw=3
    -- inline tags
    if cstext:match("{[^}]-\\[^Ntrk]") then
      for f in cstext:gmatch("\\[^tNhrk][^\\}%)]+") do lab=f:gsub("&","&&")
	if itw==22 then lab="(that's enough...)" f="" end
	if itw==23 then break end
	  cb={x=2,y=itw,class="checkbox",name="chk2"..itw,label=lab,realname=f}
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
	if rez.ltxt:match"%*" then inline=true sn=1 maxx=1
	elseif rez.breaks then inline=true sn=1 maxx=#sel
	else inline=false maxx=#sel end

    -- lines 2+
    if press~="[Un]hide" then
    for z=sn,maxx do
        i=sel[z]
	line=subs[i]
        text=line.text
	text=text:gsub("\\1c","\\c")

	    if not text:match("^{\\") then text="{\\stuff}"..text end
	    ctags=text:match(STAG)
	    -- handle existing transforms
	    if ctags:match("\\t") then
		ctags=trem(ctags)
		if text:match("^{}") then text=text:gsub("^{}","{\\stuff}") end
		text=text:gsub(STAG,ctags)
		trnsfrm=trnsfrm..copytfs
	    elseif copytfs~="" then trnsfrm=copytfs
	    end
	    -- add + clean tags
	    if inline then
		initags=text:match(STAG) or ""
		endcom=""
		repeat
		  ec=text:match("{[^\\}]-}$") text=text:gsub("{[^\\}]-}$","") if ec then endcom=ec..endcom end
		until ec==nil
		orig=text
		if rez.breaks then
		  initags=""
		  text=text:gsub("\\N","\\N{"..kopytags.."}") :gsub("\\N{(\\[^}]-})({\\[^}]-)}","\\N%2%1")
		else
		  text=rez.ltxt:gsub("%*","{"..kopytags.."}")
		  text=textmod(orig,text)
		end
		
		text=initags..text..endcom
	    else
		text=text:gsub("^({\\[^}]-)}","%1"..kopytags.."}")
	    end

	    text=text:gsub(ATAG,function(tg) return duplikill(tg) end)
	    text=extrakill(text,2)
	    -- add transforms
	
	    if trnsfrm then text=text:gsub("^({\\[^}]*)}","%1"..trnsfrm.."}") end
	    trnsfrm=nil
	    text=text:gsub(STAG,function(tags) return cleantr(tags) end)
	    text=text:gsub("\\stuff","") :gsub("{}","")
	
	if rez.css then line.style=csstyle end
	if rez.chks then line.start_time=csst end
	if rez.chke then line.end_time=cset end
	if rez.tkst then text=text:gsub("^({\\[^}]-}).*","%1"..cstext) end
	line.text=text
	subs[i]=line
    end
    else
	txt=rine.text
	    -- unhide
	    if kopytags=="" and copytfs=="" then 
		uncom={}
		wai=0
		for com in txt:gmatch("{//([^}]+)}") do
		    table.insert(uncom,{x=0,y=wai,class="checkbox",label=com,name=com}) wai=wai+1
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

function copytags(subs,sel)
    for z,i in ipairs(sel) do
        line=subs[i]
        text=line.text
	if z==1 then
		tags=text:match(STAG) or ""
		style=line.style
	end
	if z~=1 then
		text=tags..text:gsub(STAG,"")
		if res.cpstyle then line.style=style end
	end
	line.text=text
	subs[i]=line
    end
    return sel
end

function copytext(subs,sel)
    for z,i in ipairs(sel) do
        line=subs[i]
        text=line.text
	if z==1 then tekst=text:gsub(STAG,"") end
	if z~=1 then
		tags=text:match(STAG) or ""
		text=tags..tekst
	end
	line.text=text
	subs[i]=line
    end
    return sel
end

function copyclip(subs,sel)
	xc=res.xlip
	yc=res.ylip
    for z,i in ipairs(sel) do
        line=subs[i]
        text=line.text
	if z==1 then
		klipstart=text:match("\\i?clip%(([^%)]+)%)")
		klip=klipstart
		if not klip then t_error("Error: No clip on line 1.",1) end
	end
	if z~=1 then
		if not text:match("^{\\") then text="{\\klip}"..text end
		if not text:match("\\i?clip") then text=addtag("\\clip()",text) end
		
		-- calculations
		if xc~=0 or yc~=0 then factor=z-1
		    klip=klipstart:gsub("([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		    function(a,b,c,d) return a+xc*factor..","..b+yc*factor..","..c+xc*factor..","..d+yc*factor end)
		    if klipstart:match("m [%d%a%s%-]+") then
		    klip=klipstart:match("m ([%d%a%s%-]+)")
		    klip2=klip:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return a+xc*factor.." "..b+yc*factor end)
		    klip=klip:gsub("%-","%%-")
		    klip=klip:gsub(klip,klip2)
		    klip="m "..klip
		    end
		end
		-- set clip
		text=text:gsub("(\\i?clip)%([^%)]-%)","%1("..klip..")") :gsub("\\klip","")
	end
	line.text=text
	subs[i]=line
    end
    return sel
end

function copycolours(subs,sel)
if not res.c1 and not res.c2 and not res.c3 and not res.c4 then ak() end
    for z,i in ipairs(sel) do
        line=subs[i]
        text=line.text
	sr=stylechk(subs,line.style)
	text=text:gsub("\\1c","\\c")
	nontra=text:gsub("\\t%b()","")
	if z==1 then
		if res.c1 then col1=nontra:match("\\c(&H%x+&)") or sr.color1:gsub("H%x%x","H")
			alf1=nontra:match("\\1a(&H%x+&)") or sr.color1:match("H%x%x") end
		if res.c3 then col3=nontra:match("\\3c(&H%x+&)") or sr.color3:gsub("H%x%x","H")
			alf3=nontra:match("\\3a(&H%x+&)") or sr.color3:match("H%x%x") end
		if res.c4 then col4=nontra:match("\\4c(&H%x+&)") or sr.color4:gsub("H%x%x","H")
			alf4=nontra:match("\\4a(&H%x+&)") or sr.color4:match("H%x%x") end
		if res.c2 then col2=nontra:match("\\2c(&H%x+&)") or sr.color2:gsub("H%x%x","H")
			alf2=nontra:match("\\2a(&H%x+&)") or sr.color2:match("H%x%x") end
	end
	if z~=1 then
		if res.c1 then text=addtag3("\\c"..col1,text) end
		if res.c3 then text=addtag3("\\3c"..col3,text) end
		if res.c4 then text=addtag3("\\4c"..col4,text) end
		if res.c2 then text=addtag3("\\2c"..col2,text) end
	     if res.alfa then
		if res.c1 then text=addtag3("\\1a"..alf1,text) end
		if res.c3 then text=addtag3("\\3a"..alf3,text) end
		if res.c4 then text=addtag3("\\4a"..alf4,text) end
		if res.c2 then text=addtag3("\\2a"..alf2,text) end
	     end
	end
	line.text=text
	subs[i]=line
    end
    return sel
end

function shad3(subs,sel)
    for z=#sel,1,-1 do
        i=sel[z]
	line=subs[i]
        text=line.text
	nontra=text:gsub("\\t%b()","")
	layer=line.layer
	text=text:gsub("^({[^}]-)\\shad([%d%.]+)","%1\\xshad%2\\yshad%2")
	:gsub(STAG,function(tg) return duplikill(tg) end)
	xshad=tonumber(nontra:match("^{[^}]-\\xshad([%d%.%-]+)")) or 0 	ax=math.abs(xshad)
	yshad=tonumber(nontra:match("^{[^}]-\\yshad([%d%.%-]+)")) or 0	ay=math.abs(yshad)
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
	if xshad~=0 and yshad~=0 then subs.delete(i) else line.text=text subs[i]=line end
    end
    return sel
end

function splitbreak(subs,sel)
	nsel={} for z,i in ipairs(sel) do table.insert(nsel,i) end
	for z=#sel,1,-1 do
	    i=sel[z]
	    line=subs[i]
	    text=line.text
	    breakit=true
	    if not text:match("\\N") or res.splitg then
		if not text:match("\\N") then lab="Selection line "..z.." has no \\N. You can split by spaces or by tags."
		else lab="Split by spaces or by tags." end
	      if not applytoall then
		P,rez=ADD({{class="label",label=lab,width=2},
		{y=1,class="checkbox",name="remember",label="Apply to all lines"},
		{x=1,y=1,class="checkbox",name="num",label="Number lines",value=nmbr},
		},{"Spaces","Tags","Skip","Cancel"},{close='Cancel'})
	      end
	      if P=="Cancel" then ak() end
	      if P=="Spaces" then text=textreplace(text," "," \\N") end
	      if P=="Tags" then text=text:gsub("(.)({\\[^}]-})","%1\\N%2") end
	      if rez.remember then applytoall=P end
	      breakit=false nmbr=rez.num
	    end
	  
	  -- split by \N
	  if text:match("\\N")then
	    seg=re.split(text,[[\\N *]])
	    
	    -- positioning with \N (only considers \fs, \fscy, and \an)
	    _,poses=text:gsub("\\N","") poses=poses+1
	    posY=text:match("\\pos%([%d%.%-]+,([%d%.%-]+)%)")
	    if posY and breakit then
		sr=stylechk(subs,line.style)
		fos=text:match("\\fs(%d+)") or sr.fontsize
		scy=text:match("\\fscy([%d%.]+)") or sr.scale_y
		siz=fos*scy/100
		align=text:match("\\an(%d)") or sr.align
		align3=3*align
		postab={}
		if align3>20 then
		    for p=1,poses do table.insert(postab,posY+(p-1)*siz) end
		elseif align3<10 then
		    for p=poses,1,-1 do table.insert(postab,posY-(p-1)*siz) end
		    seg[1]=seg[1]:gsub("(\\pos%([%d%.%-]+,)[%d%.%-]+","%1"..postab[1])
		else
		    posYm=posY-(poses-1)*siz/2
		    for p=1,poses do table.insert(postab,posYm+(p-1)*siz) end
		    seg[1]=seg[1]:gsub("(\\pos%([%d%.%-]+,)[%d%.%-]+","%1"..postab[1])
		end
	    end
		
	    -- pos by spaces/tags (\fs, \fscy, \an)
	    if not breakit then
		vis=text:gsub("%b{}",""):gsub("\\N","")
		nontra=text:gsub("\\t%b()","")
		sr=stylechk(subs,line.style)
		align=tonumber(text:match("\\an(%d)")) or sr.align
		if align>3 then repeat align=align-3 until align<4 end
		scx=nontra:match("^{[^}]-\\fscx([%d%.]+)") or sr.scale_x
		scx=scx/100
		fsize=tonumber(nontra:match("^{[^}]-\\fs(%d+)"))
		sfs=sr.fontsize
		if fsize and fsize~=sfs then sfac=fsize/sfs*scx else sfac=scx end
		w=aegisub.text_extents(sr,vis)*scx
		wtab={} stab={}
		for s=1,#seg do
			seg[s],sp=seg[s]:gsub(" *$","")
			ws=aegisub.text_extents(sr,seg[s]:gsub("%b{}",""))*scx table.insert(wtab,ws)
			table.insert(stab,sp)
		end
		ws=aegisub.text_extents(sr," ")*scx
	    end
		
		line2=line
		tags=""
		for it in seg[1]:gmatch(ATAG) do tags=tags..it end
		tags=tags:gsub("}{","")
		count=0	poscount=2
		for sg=2,#seg do
		    aftern=seg[sg]
		    t2=tags..aftern
		    if posY and breakit then
			t2=t2:gsub("(\\pos%([%d%.%-]+,)[%d%.%-]+","%1"..postab[poscount])
		    else
			t2=findpos(t2,sg)
		    end
		    poscount=poscount+1
		    if aftern~="" then
		        count=count+1
		        t2=t2:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		        :gsub(ATAG,function(tg) return duplikill(tg) end)
			tags=""
		        for it in t2:gmatch(ATAG) do tags=tags..it end
			tags=tags:gsub("}{","")
			line2.text=t2
			if nmbr then
				if sg<10 then ef="0"..sg else ef=sg end
				line2.effect=ef
			end
		        subs.insert(i+count,line2)
			nsel=shiftsel2(nsel,z,1)
		    end
		end
		text=seg[1]
		if not breakit then
			text=text:gsub("(\\pos%()([%d%.%-]+)(,[%d%.%-]+)",function(p,x,y)
			if align==1 then xpos=x end
			if align==2 then xpos=x-w/2+wtab[1]/2 end
			if align==3 then xpos=x-w+wtab[1] end
			return p..round(xpos,1)..y end)
		end
		
	    line.text=text
	    if nmbr then line.effect="01" end
	    subs[i]=line
	  else -- nospace/notag
	  end
	end
	sel=nsel
	applytoall=nil
	nmbr=nil
	return sel
end

function findpos(text,sg)
	text=text:gsub("(\\pos%()([%d%.%-]+)(,[%d%.%-]+)",function(p,x,y)
		if sg==2 then 
			if align==2 then x=x-w/2+wtab[1]/2 end
			if align==3 then x=x-w+wtab[1] end
		end
		space=ws
		if P=="Tags" and stab[sg-1]==1 then space=0 end
		if align==1 then xpos=round(x+wtab[sg-1]+space,2) end
		if align==2 then xpos=round(x+wtab[sg-1]/2+wtab[sg]/2+space,2) end
		if align==3 then xpos=round(x+wtab[sg]+space,2) end
		return p..round(xpos,1)..y end)
	return text
end

--	reanimatools	--
function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end

function addtag2(tag,text)
	local tg=tag:match("\\%d?%a+")
	text=text:gsub("^({\\[^}]-)}","%1"..tag.."}")
	:gsub(tg.."[^\\}]+([^}]-)("..tg.."[^\\}]+)","%2%1")
	return text 
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

function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function logg(m) m=m or "nil" aegisub.log("\n "..m) end

function shiftsel2(sel,z,mode)
	if sel[z]<sel[#sel] then
	for s=1,#sel do if sel[s]>sel[z] then sel[s]=sel[s]+1 end end
	end
	if mode==1 then table.insert(sel,sel[z]+1) end
	table.sort(sel)
return sel
end

function textreplace(txt,r1,r2)
txt=txt:gsub("^([^{]*)",function(t) t=t:gsub(r1,r2) return t end)
txt=txt:gsub("(})([^{]*)",function(b,t) t=t:gsub(r1,r2) return b..t end)
return txt
end

function textmod(orig,text)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
	vis=text:gsub("{[^}]-}","")
	ltrz=re.find(vis,".")
	  for l=1,#ltrz do
	    table.insert(tk,ltrz[l].str)
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
	for n, t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext=stags..newline
    text=newtext:gsub("{}","")
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

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function stylechk(subs,sn)
  for i=1,#subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if sn==st.name then sr=st break end
    end
  end
  if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
  return sr
end

function necroscopy(subs,sel)
ADD=aegisub.dialog.display
ak=aegisub.cancel
ATAG="{%*?\\[^}]-}"
STAG="^{\\[^}]-}"
	GUI={
	{x=0,y=0,class="label",label="\\fax ",},
	{x=1,y=0,width=2,class="floatedit",name="fax",value=lastfax or 0.05},
	{x=0,y=1,width=2,class="checkbox",name="clax",label="from clip   ",value=true},
	{x=2,y=1,class="checkbox",name="right",label="to the right   "},
	
	{x=3,y=0,width=2,class="checkbox",name="cpstyle",label="copy style with tags",value=copy_style},
	
	{x=5,y=0,class="label",label="  copy colours:  ",},
	{x=6,y=0,class="checkbox",name="c1",label="c"},
	{x=7,y=0,class="checkbox",name="c3",label="3c "},
	{x=8,y=0,class="checkbox",name="c4",label="4c  "},
	{x=9,y=0,class="checkbox",name="c2",label="2c"},
	{x=10,y=0,width=2,class="checkbox",name="alfa",label="include alpha"},
	
	{x=3,y=1,class="label",label="shift clip every frame by:",},
	{x=5,y=1,width=2,class="floatedit",name="xlip",value=lastxlip or 0},
	{x=7,y=1,width=3,class="floatedit",name="ylip",value=lastylip or 0},
	
	{x=10,y=1,width=2,class="checkbox",name="splitg",label="split GUI",hint="open GUI to split by spaces/tags instead"},
	{x=12,y=1,width=2,class="label",label=script_name.." v"..script_version},
	} 
	P,res=ADD(GUI,
	{"fax it","copy stuff","copy tags","copy text","copy clip","copy colours","3D shadow","split by \\N","cancel"},{cancel='cancel'})
	
	if P=="cancel" then ak() end
	if P=="fax it" then fucks(subs,sel) end
	if P=="copy stuff" then copystuff(subs,sel) end
	if P=="copy tags" then copytags(subs,sel) end
	if P=="copy text" then copytext(subs,sel) end
	if P=="copy clip" then copyclip(subs,sel) end
	if P=="copy colours" then copycolours(subs,sel) end
	if P=="3D shadow" then shad3(subs,sel) end
	if P=="split by \\N" then sel=splitbreak(subs,sel) end
	lastfax=res.fax
	lastxlip=res.xlip
	lastylip=res.ylip
    aegisub.set_undo_point(script_name)
    return sel
end

if haveDepCtrl then depRec:registerMacro(necroscopy) else aegisub.register_macro(script_name,script_description,necroscopy) end