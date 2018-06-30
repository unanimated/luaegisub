script_name="NecrosCopy"
script_description="Copy and fax things in the shadows while lines are splitting and breaking"
script_author="reanimated"
script_version="4.1"
script_namespace="ua.NecrosCopy"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="4.1.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

re=require'aegisub.re'

function fucks(subs,sel)
	for z,i in ipairs(sel) do
		progress("Faxing line "..z.."/"..#sel)
		l=subs[i]
		t=l.text
		
		if not t:match("\\i?clip%(m") and not t:match("//i?clip%(m") then t_error("Missing \\clip on line #"..i-line0..".",1) end
		cx1,cy1,cx2,cy2,cx3,cy3,cx4,cy4=t:match("clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
		if not cx1 then cx1,cy1,cx2,cy2=t:match("clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)") end
		if not cx1 then t_error("Line #"..i-line0..": Not enough clip points. 2 required.",1) end
		sr=stylechk(subs,l.style)
		nontra=t:gsub("\\t%b()","")
		rota=nontra:match("^{[^}]-\\frz([%d.-]+)") or sr.angle
		rota2=nontra:match(".*\\frz([%d.-]+)") or sr.angle
		scx=nontra:match("^{[^}]-\\fscx([%d.]+)") or sr.scale_x
		scy=nontra:match("^{[^}]-\\fscy([%d.]+)") or sr.scale_y
		scr=scx/scy
		ad=cx1-cx2
		op=cy1-cy2
		tang=(ad/op)
		ang1=math.deg(math.atan(tang))
		ang2=ang1-rota
		tangf=math.tan(math.rad(ang2))
		faks=round(tangf/scr*100)/100
		t=addtag("\\fax"..faks,t)
		if cy4 then
			tang2=((cx3-cx4)/(cy3-cy4))
			ang3=math.deg(math.atan(tang2))
			ang4=ang3-rota2
			tangf2=math.tan(math.rad(ang4))
			faks2=round(tangf2*100)/100
			endcom=""
			repeat t=t:gsub("({[^}]-})%s*$",function(ec) endcom=ec..endcom return "" end)
			until not t:match("}$")
			t=t:gsub("(.)$","{\\fax"..faks2.."}%1")
			
			if res.grad then
				vis=nobra(t)
				orig=t:gsub(STAG,"")
				tg=t:match(STAG)
				chars={}
				ltrz=re.find(vis,".")
					for l=1,#ltrz do table.insert(chars,ltrz[l].str) end
				faxdiff=(faks2-faks)/(#chars-1)
				tt=chars[1]
				for c=2,#chars do
					if chars[c]==" " then tt=tt.." " else tt=tt.."{\\fax"..round((faks+faxdiff*(c-1))*100)/100 .."}"..chars[c] end
				end
				t=tg..tt
				if orig:match("{%*?\\") then t=retextmod(orig,t) end
			end
			t=t..endcom
		end
		
		t=tagmerge(t)
		t=t:gsub("\\i?clip%b()",""):gsub("(\\fax[%d%.%-]+)([^}]-)(\\fax[%d%.%-]+)","%3%2"):gsub("%**}","}")
		l.text=t
		subs[i]=l
	end
end

function frozt(subs,sel)
	for z,i in ipairs(sel) do
		progress("Freezing line "..z.."/"..#sel)
		local l=subs[i]
		local text=l.text
		if not text:match("\\i?clip%(m") and not text:match("//i?clip%(m") then t_error("Missing \\clip on line #"..i-line0..".\nAborting.",1) end
		cx1,cy1,cx2,cy2,cx3,cy3,cx4,cy4=text:match("clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
		if not cx1 then cx1,cy1,cx2,cy2=text:match("clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)") end
		if not cx1 then t_error("Line #"..i-line0..": Not enough clip points. 2 required.",1) end
		local ad,op,tang,ang1,rota
		ad=cx2-cx1
		op=cy1-cy2
		tang=(op/ad)
		ang1=math.deg(math.atan(tang))
		rota=round(ang1,2)
		if ad<0 then rota=rota-180 end
		local ad2,op2,tang2,ang2,rota2
		if cy4 then
			ad2=cx4-cx3
			op2=cy3-cy4
			tang2=(op2/ad2)
			ang2=math.deg(math.atan(tang2))
			rota2=round(ang2,2)
			if ad2<0 then rota2=rota2-180 end
		else rota2=rota
		end
		rota3=(rota+rota2)/2
		text=addtag("\\frz"..rota3,text)
		text=text:gsub("\\i?clip%b()",""):gsub(ATAG,function(tg) return duplikill(tg) end)
		l.text=text
		subs[i]=l
	end
end


--	Necroscopy	--	[- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -]
function necrostuff(subs,sel)
	progress("NecrosCopying from line 1...")
	-- get stuff from line 1
	rine=subs[sel[1]]
	ftags=rine.text:match(STAG) or ""
	cstext=rine.text:gsub(STAG,"")
	vis=rine.text:gsub("%b{}","")
	csstyle=rine.style
	csst=rine.start_time
	cset=rine.end_time
	csact=rine.actor
	cseff=rine.effect
	-- detect / save / remove transforms
	ftra=""
	if ftags:match("\\t") then
	for t in ftags:gmatch("\\t%b()") do ftra=ftra..t end
	ftags=ftags:gsub("\\t%b()","")
	end
	rept={"drept"}
	-- build GUI
	copyshit={
	{x=0,y=0,class="checkbox",name="chks",label="[Start Time]"},
	{x=0,y=1,class="checkbox",name="chke",label="[End Time]"},
	{x=1,y=0,class="checkbox",name="css",label="[Style]"},
	{x=1,y=1,class="checkbox",name="tkst",label="[Text]"},
	{x=2,y=0,class="checkbox",name="act",label="[Actor]"},
	{x=2,y=1,class="checkbox",name="eff",label="[Effect]"},
	{x=3,y=0,class="label",label="    Place * in text below to copy tags there"},
	{x=3,y=1,class="checkbox",name="breaks",label="Copy tags after all linebreaks (all lines)",realname=""},
	{x=0,y=2,width=4,class="edit",name="ltxt",value=vis,hint="only works for first selected line"},
	}
	ftw=3
	-- regular tags -> GUI
	for f in ftags:gmatch("\\[^\\}]+") do lab=f:gsub("&","&&")
		if f:match("\\i?clip%(m") then lab=f:match("\\i?clip%(m [%d%.%-]+ [%d%.%-]+ %a [%d%.%-]+ [%d%.%-]+").." ..." end
		if f:match("\\move") then lab=f:gsub("%.%d+","") end
		cb={x=0,y=ftw,width=3,class="checkbox",name="chk"..ftw,label=lab,realname=f}
		drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
		if drept==0 then
			table.insert(copyshit,cb)	ftw=ftw+1
			table.insert(rept,f)
		end
	end
	-- transform tags
	for f in ftra:gmatch("\\t%b()") do
		cb={x=0,y=ftw,width=3,class="checkbox",name="chk"..ftw,label=f}
		drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
		if drept==0 then
			table.insert(copyshit,cb)	ftw=ftw+1
			table.insert(rept,f)
		end
	end
	itw=3
	-- inline tags
	if cstext:match("{[^}]-\\[^Ntrk]") then
		for f in cstext:gmatch("\\[^tNhrk][^\\})]+") do lab=f:gsub("&","&&")
			if itw==22 then lab="(that's enough...)" f="" end
			if itw==23 then break end
			cb={x=3,y=itw,width=2,class="checkbox",name="chk2"..itw,label=lab,realname=f}
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
	progress("Loading necrostuff...")
	press,rez=ADD(copyshit,{"Copy","Check All Tags","Paste Saved","[Un]hide","Cancel"},{ok='Copy',close='Cancel'})
	until press~="Check All Tags"
	if press=="Cancel" then ak() end
	-- save checked tags
	kopytags=""
	copytfs=""
	for key,val in ipairs(copyshit) do
		if rez[val.name]==true and not val.label:match("%[") then
			if not val.label:match("\\t") then kopytags=kopytags..val.realname else copytfs=copytfs..val.label end
		end
	end
	if press=="Paste Saved" then kopytags=savedkopytags copytfs=savedcopytfs sn=1
		csstyle=savedstyle csst=savedt1 cset=savedt2 cstext=savedtext csact=savedactor cseff=savedeffect
		rez.css=savedcss rez.chks=savedchks rez.chke=savedchke rez.tkst=savedtkst
		rez.act=savedact rez.eff=savedeff
	elseif press=="Copy" then sn=2
		savedkopytags=kopytags
		savedcopytfs=copytfs
		savedt1=csst savedt2=cset savedstyle=csstyle savedactor=csact savedeffect=cseff
		savedcss=rez.css savedchks=rez.chks savedchke=rez.chke
		savedact=rez.act savedeff=rez.eff
		savedtext=cstext savedtkst=rez.tkst
	end
	if rez.ltxt:match"%*" then inline=true sn=1 maxx=1
	elseif rez.breaks then inline=true sn=1 maxx=#sel
	else inline=false maxx=#sel end
	
    -- lines 2+
    if press~="[Un]hide" then
	for z=sn,maxx do
		progress("NecroPasting to line "..z.."/"..#sel)
		i=sel[z]
		line=subs[i]
		text=line.text
		text=text:gsub("\\1c","\\c")
		visible=text:gsub("%b{}",""):gsub("\\N","")
		
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
				ec=text:match("{[^\\}]-}$") text=text:gsub("{[^\\}]-}$","")
				if ec then endcom=ec..endcom end
			until ec==nil
			orig=text
			if rez.breaks then
				initags=""
				text=text:gsub("\\N","\\N{"..kopytags.."}"):gsub("\\N{(\\[^}]-})({\\[^}]-)}","\\N%2%1")
			else
				text=rez.ltxt:gsub("%*","{"..kopytags.."}")
				text=retextmod(orig,text)
			end
			text=initags..text..endcom
			visible2=text:gsub("%b{}",""):gsub("\\N","")
			if visible~=visible2 then logg("Line #"..i-line0..": It appears that characters have been lost or added. This is probably a failure of the re module.") end
		else
			text=text:gsub("^({\\[^}]-)}","%1"..kopytags.."}")
		end
		
		text=text:gsub(ATAG,function(tg) return duplikill(tg) end)
		text=extrakill(text,2)
		
		-- add transforms
		if trnsfrm then text=text:gsub("^({\\[^}]*)}","%1"..trnsfrm.."}") end
		trnsfrm=nil
		text=text:gsub(STAG,function(tags) return cleantr(tags) end)
		text=text:gsub("\\stuff",""):gsub("{}","")
		
		if rez.css then line.style=csstyle end
		if rez.act then line.actor=csact end
		if rez.eff then line.effect=cseff end
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
			txt=txt:gsub("^(.*){//([^}]+})","{\\%2%1"):gsub("{(\\[^}]-)}{(\\[^}]-)}","{%2%1}")
		else
			pss,rz=ADD(uncom,{"OK","Cancel"},{ok='OK',close='Cancel'})
			if pss=="Cancel" then ak() end
			for key,val in ipairs(uncom) do
				enam=esc(val.name)
				if rz[val.name]==true then 
					txt=txt:gsub("^(.*){//("..enam..")}","{\\%2}%1"):gsub("{(\\[^}]-)}{(\\[^}]-)}","{%2%1}")
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
	rine.text=txt:gsub("\\1c","\\c")
	subs[sel[1]]=rine
    end
    progress("NecroProcessing complete.")
    trnsfrm=nil
end

function copytags(subs,sel)
	for z,i in ipairs(sel) do
		progress("Copypasting tags... "..z.."/"..#sel)
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
		progress("Copypasting text... "..z.."/"..#sel)
		line=subs[i]
		text=line.text
		if z==1 then
			tekst=text:gsub(STAG,"")
			if res.vis then tekst=tekst:gsub("%b{}","") end
		end
		if z~=1 then
			tags=text:match(STAG) or ""
			text=tags..tekst
		end
		line.text=text
		subs[i]=line
	end
	return sel
end

function copycolours(subs,sel)
	progress("Colours check...")
	if not res.c1 and not res.c2 and not res.c3 and not res.c4 then t_error("No colours selected",1) end
	local col={}
	for n=1,4 do if res['c'..n] then table.insert(col,n) end end
	local C={}
	for z,i in ipairs(sel) do
		progress("Copypasting colours... "..z.."/"..#sel)
		line=subs[i]
		local text=line.text
		if z==1 then
			text=text:gsub("\\1c","\\c")
			local nontra=text:gsub("\\t%b()","")
			sr=stylechk(subs,line.style)
			if res.c1 then C.col1=nontra:match("\\c(&H%x+&)") or sr.color1:gsub("H%x%x","H")
					C.alf1=nontra:match("\\1a(&H%x+&)") or sr.color1:match("&H%x%x").."&" end
			if res.c3 then C.col3=nontra:match("\\3c(&H%x+&)") or sr.color3:gsub("H%x%x","H")
					C.alf3=nontra:match("\\3a(&H%x+&)") or sr.color3:match("&H%x%x").."&" end
			if res.c4 then C.col4=nontra:match("\\4c(&H%x+&)") or sr.color4:gsub("H%x%x","H")
					C.alf4=nontra:match("\\4a(&H%x+&)") or sr.color4:match("&H%x%x").."&" end
			if res.c2 then C.col2=nontra:match("\\2c(&H%x+&)") or sr.color2:gsub("H%x%x","H")
					C.alf2=nontra:match("\\2a(&H%x+&)") or sr.color2:match("&H%x%x").."&" end
		else
			for n=1,#col do
				local cn=col[n]
				local tc=tostring(cn):gsub('1','')
				if res.ccol then text=addtag3("\\"..tc.."c"..C['col'..cn],text) end
				if res.alfa then text=addtag3("\\"..cn.."a"..C['alf'..cn],text) end
			end
		end
		line.text=text
		subs[i]=line
	end
	return sel
end


--	3D shadow	--	[- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -]
function shad3(subs,sel)
    for z=#sel,1,-1 do
        progress("Shadow filling line "..#sel+1-z.."/"..#sel)
	i=sel[z]
	line=subs[i]
        text=line.text
	if not text:match("\\[xy]?shad") then
		sr=stylechk(subs,line.style)
		text="{\\shad"..sr.shadow.."}"..text
		text=text:gsub("^({\\[^}]+)}{\\","%1\\")
	end
	text=text:gsub("^({[^}]-)\\shad([%d%.]+)","%1\\xshad%2\\yshad%2")
	:gsub(STAG,function(tg) return duplikill(tg) end)
	nontra=text:gsub("\\t%b()","")
	layer=line.layer
	xshad=tonumber(nontra:match("^{[^}]-\\xshad([%d%.%-]+)")) or 0 ax=math.abs(xshad)
	yshad=tonumber(nontra:match("^{[^}]-\\yshad([%d%.%-]+)")) or 0	ay=math.abs(yshad)
	if ax>ay then lay=math.floor(ax) else lay=math.floor(ay) end
	
	text2=text:gsub("^({\\[^}]-)}","%1\\3a&HFF&}")	:gsub("\\3a&H%x%x&([^}]-)(\\3a&H%x%x&)","%1%2")
	
	for l=lay,1,-1 do
		line2=line	    f=l/lay
		text2=addtag3('\\1a&HFE&',text2)
		txt=text2	    if l==1 then txt=text end
		line2.text=txt
		:gsub("\\xshad([%d%.%-]+)",function(a) xx=tostring(f*a) xx=xx:gsub("([%d%-]+%.%d%d)%d+","%1") return "\\xshad"..xx end)
		:gsub("\\yshad([%d%.%-]+)",function(a) yy=tostring(f*a) yy=yy:gsub("([%d%-]+%.%d%d)%d+","%1") return "\\yshad"..yy end)
		line2.layer=layer+(lay-l)
		subs.insert(i+1,line2)
	end
	if math.abs(xshad)>=1 or math.abs(yshad)>=1 then
		subs.delete(i)
		for s=z+1,#sel do sel[s]=sel[s]+lay-1 end
	else line.text=text subs[i]=line
	end
    end
    return sel
end


--	Split into Letters	--	[- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -]
function space(subs,sel)
	nsel={} for z,i in ipairs(sel) do table.insert(nsel,i) end
	count=0
	for z=#sel,1,-1 do
		progress("Breaking line "..#sel+1-z.."/"..#sel)
		i=sel[z]
		line=subs[i]
		text=line.text
		visible=text:gsub("%b{}",""):gsub("%s*\\[Nh]%s*"," ")
		letrz=re.find(visible,".")
		if not text:match "\\p1" and letrz and #letrz>1 then
			sr=stylechk(subs,line.style)
			notra=detra(text)
			acalign=nil
			m1,m2,m3,m4=text:match("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)")
			if m1 then
				text=text:gsub("\\move%(([%d.-]+),([%d.-]+)","\\pos(%1,%2)(")
				movX=m3-m1 movY=m4-m2
			end
			text=text:gsub(" *\\[Nh] *"," ")
			if not text:match"\\pos" then text=getpos(subs,text) end
			tags=text:match(STAG) or ""
			after=text:gsub(STAG,""):gsub("{[^\\}]-}","")
			local px,py=text:match("\\pos%(([%d.-]+),([%d.-]+)%)")
			local x1,width,w,wtotal,let,spacing,avgspac,ltrspac,xpos,lastxpos,spaces,prevlet,scx,k1,k2,k3,bord,off,inwidth,wdiff,pp,tpos
			scx=notra:match("^{[^}]-\\fscx([%d%.]+)") or sr.scale_x
			fsp=notra:match("^{[^}]-\\fsp([%d%.]+)")
			if fsp then sr.spacing=tonumber(fsp) end
			fsize=notra:match("^{[^}]-\\fs([%d%.]+)")
			if fsize then sr.fontsize=tonumber(fsize) end
			phont=notra:match("^{[^}]-\\fn([^\\}]+)")
			if phont then sr.fontname=phont end
			bord=notra:match("^{[^}]-\\bord([%d%.]+)") or sr.outline
			k1,k2,k3=text:match("clip%(([%d.-]+),([%d.-]+),([%d.-]+),")
			letters={}	wtotal=0
			for l=1,#letrz do
				local ltr=letrz[l].str
				w=aegisub.text_extents(sr,ltr)
				table.insert(letters,{l=ltr,w=w})
				wtotal=wtotal+w
				leng=re.find(ltr,'.')
				if ltr=="" then
					logg("- Line #"..i-line0..": re module failure: letter lost - #"..l)
				elseif #leng>1 then
					logg("- Line #"..i-line0..": re module failure: multiple letters matched: "..ltr)
				end
			end
			if #letters~=#letrz then
				logg(#letrz.." -> "..#letrz)
			end
			intags={}	cnt=0
			for chars,tag in after:gmatch("([^}]+)({\\[^}]+})") do
				pp=re.find(chars,".")
				tpos=#pp+1+cnt
				intags[tpos]=tag
				cnt=cnt+#pp
			end
			spacing=res.space
			avgspac=wtotal/#letters
			off=(letters[1].w-letters[#letters].w)/4*scx/100
			inwidth=(wtotal-letters[1].w/2-letters[#letters].w/2)*scx/100
			if spacing==1 then spacing=round(avgspac*scx)/100 end
			width=(#letters-1)*spacing	--off
			
			-- klip-based stuff
			if k1 then 
				width=(k3-k1)-letters[1].w/2*(scx/100)-letters[#letters].w/2*(scx/100)-(2*bord)
				spacing=(width+2*bord)/(#letters-1)
				px=(k1+k3)/2-off
				tags=tags:gsub("\\i?clip%b()","")
			end
			
			-- find starting x point based on alignment
			if not acalign then acalign=text:match("\\an(%d)") or sr.align end
			acalign=tostring(acalign)
			if acalign:match("[147]") then
				tags=tags:gsub("\\an%d",""):gsub("^{","{\\an"..acalign+1)
				:gsub("\\pos%(([%d.-]+)",function(p) return "\\pos("..round(p+(wtotal/2)*(scx/100),2) end)
			end
			if acalign:match("[369]") then
				tags=tags:gsub("\\an%d",""):gsub("^{","{\\an"..acalign-1)
				:gsub("\\pos%(([%d.-]+)",function(p) return "\\pos("..round(p-(wtotal/2)*(scx/100),2) end)
			end
			if not k1 then px,py=tags:match("\\pos%(([%d.-]+),([%d.-]+)%)") end
			acalign=tags:match("\\an(%d)")
			x1=round(px-width/2)
			
			wdiff=(width-inwidth)/(#letters-1)
			lastxpos=x1
			spaces=0
			-- weird letter-width sorcery starts here
			for t=1,#letters do
				let=letters[t]
				if t>1 then
					prevlet=letters[t-1]
					ltrspac=(let.w+prevlet.w)/2*scx/100+wdiff
					ltrspac=round(ltrspac,2)
				else
					fact1=spacing/(avgspac*scx/100)
					fact2=(let.w-letters[#letters].w)/4*scx/100
					ltrspac=round(fact1*fact2,2)
				end
				if intags[t] then tags=tags..intags[t] tags=tagmerge(tags) tags=duplikill(tags) end
				t2=tags..let.l
				xpos=lastxpos+ltrspac
				XP=xpos
				notra=detra(t2)
				rota=notra:match("^{[^}]-\\frz([-%d.]+)")
				if rota then
					h=px-xpos
					X=math.cos(math.rad(rota))*h
					Y=math.sin(math.rad(rota))*h
					x=round(px-X,1)
					y=round(py+Y,1)
					t2=t2:gsub("\\pos%b()","\\pos("..x..","..y..")")
				else
					t2=t2:gsub("\\pos%(([%d.-]+),([%d.-]+)%)","\\pos("..XP..",%2)")
				end
				if m1 then
					t2=t2:gsub("\\pos%(([%d.-]+),([%d.-]+)%)%(,[%d.-]+,[%d.-]+",function(a,b) return "\\move("..a..","..b..","..a+movX..","..b+movY end)
				end
				lastxpos=xpos
				l2=line
				l2.text=t2
				if t==1 then text=t2 else
				if let.l~=" " then subs.insert(i+t-1-spaces,l2) nsel=shiftsel(nsel,i,1) else count=count-1 spaces=spaces+1 end
				end
			end
			count=count+#letters-1
			line.text=text
			subs[i]=line
		end
	end
	return nsel
end


--	Split by \N	--	[- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -] [- -]
function splitbreak(subs,sel)
	nsel={} for z,i in ipairs(sel) do table.insert(nsel,i) end
	for z=#sel,1,-1 do
		progress("Breaking line "..#sel+1-z.."/"..#sel)
		i=sel[z]
		line=subs[i]
		text=line.text
		stags=text:match(STAG) or ""
		after=text:gsub(STAG,"")
		breakit=true
		local klipos,kmode
		if not text:match("\\N") or res.splitg then
			if not text:match("\\N") then lab="No \\N in line #"..i-line0..". You can split by spaces, tags, or a marker of your choice."
			else lab="Split by spaces, tags, or any marker." end
			if text:match("clip%(m ([^)]+)%)") then lab=lab..'\n(This line will be split by a clip if it has enough points.)' end
			if not applytoall then
				P,rez=ADD({{class="label",label=lab,width=4},
				{x=3,y=2,class="edit",name="mark",value=mark or "{}"},
				{y=2,class="checkbox",name="remember",label="Apply to all lines"},
				{x=1,y=2,class="checkbox",name="num",label="Number lines",value=nmbr},
				{x=2,y=2,class="label",label="        Marker: "},
				{x=0,y=1,width=4,class="edit",name="txt",value=after,hint="text only for reference"},
				},{"Spaces","Tags","Marker","Skip","Cancel"},{close='Cancel'})
			end
			if P=="Cancel" then ak() end
			text=text:gsub("\\N","")
			if P=="Spaces" then text=textreplace(text," "," \\N") end
			if P=="Tags" then
				repeat text,r=text:gsub("({\\[^}]*)}( +){(\\[^}]*})","%2%1%3") until r==0
				text=text:gsub("({\\[^}]*})( +)","%2%1")
				text=text:gsub("(.)({\\[^}]-})","%1\\N%2")
			end
			if P=="Marker" then
				if mark=="" then t_error("No marker set.",1) end
				after=after:gsub(esc(mark),"\\N")
				text=stags..after
			end
			if rez.remember then applytoall=P end
			breakit=false nmbr=rez.num mark=rez.mark
			text=text:gsub("({\\[^}]*}) *\\N","\\N%1")
		end
	
		-- split by \N
		if text:match("\\N")then
			en=text:gsub("\\N","\n")
			seg={}
			for s in en:gmatch("[^\n]+") do s=s:gsub("( *)(%b{})$","%2%1"):gsub("^ *(.*)$","%1") table.insert(seg,s) end
			
			-- positioning with \N (supports \fs, \fscy, \an, \frz)
			_,poses=text:gsub("\\N","") poses=poses+1
			sr=stylechk(subs,line.style)
			notra=detra(text)
			phont=notra:match("^{[^}]-\\fn([^\\}]+)")
			if phont then sr.fontname=phont end
			posX,posY=text:match("\\pos%(([%d.-]+),([%d.-]+)%)")
			movX,movY=0,0
			m1,m2,m3,m4=text:match("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)")
			if m1 and not posY then posX=m1 posY=m2 movX=m3-m1 movY=m4-m2 end
			if posY and breakit then
				fos=notra:match("^{[^}]-\\fs(%d+)") or sr.fontsize
				scy=notra:match("^{[^}]-\\fscy([%d%.]+)") or sr.scale_y
				rota=notra:match("^{[^}]-\\frz([-%d.]+)")
				d_ver=fos*scy/100
				d_hor=0
				if rota then
					d_hor=round(math.sin(math.rad(rota))*d_ver,2)
					d_ver=round(math.cos(math.rad(rota))*d_ver,2)
				end
				align=text:match("\\an(%d)") or sr.align
				align3=3*align
				postab={}
				if align3>20 then
					for p=1,poses do table.insert(postab,{posX+(p-1)*d_hor,posY+(p-1)*d_ver}) end
				elseif align3<10 then
					for p=poses,1,-1 do table.insert(postab,{posX-(p-1)*d_hor,posY-(p-1)*d_ver}) end
					P1,P2=postab[1][1],postab[1][2]
					seg[1]=seg[1]:gsub("(\\pos%()[%d.-]+,[%d.-]+","%1"..P1..","..P2)
					:gsub("(\\move%()[%d.-]+,[%d.-]+,[%d.-]+,[%d.-]+","%1"..P1..","..P2..","..P1+movX..","..P2+movY)
				else
					posYm=posY-(poses-1)*d_ver/2
					posXm=posX-(poses-1)*d_hor/2
					for p=1,poses do table.insert(postab,{posXm+(p-1)*d_hor,posYm+(p-1)*d_ver}) end
					P1,P2=postab[1][1],postab[1][2]
					seg[1]=seg[1]:gsub("(\\pos%()[%d.-]+,[%d.-]+","%1"..P1..","..P2)
					:gsub("(\\move%()[%d.-]+,[%d.-]+,[%d.-]+,[%d.-]+","%1"..P1..","..P2..","..P1+movX..","..P2+movY)
				end
			end
			
			-- pos by spaces/tags (\fs, \fscx, \fsp, \an, \frz)
			if not breakit then
				vis=text:gsub("%b{}",""):gsub("\\N","")
				align=tonumber(text:match("\\an(%d)")) or sr.align
				valign=math.ceil(align/3)
				align=align%3
				scx=notra:match("^{[^}]-\\fscx([%d%.]+)") or sr.scale_x
				fsp=notra:match("^{[^}]-\\fsp([%d%.]+)")
				if fsp then sr.spacing=tonumber(fsp) end
				scx=scx/100
				fsize=tonumber(notra:match("^{[^}]-\\fs(%d+)"))
				sfs=sr.fontsize
				if fsize and fsize~=sfs then sfac=fsize/sfs*scx else sfac=scx end
				w=aegisub.text_extents(sr,vis)*sfac
				wtab={} stab={}
				for s=1,#seg do
					seg[s],sp=seg[s]:gsub(" *$","")
					ws=aegisub.text_extents(sr,seg[s]:gsub("%b{}",""))*sfac table.insert(wtab,ws)
					table.insert(stab,sp)
				end
				ws=aegisub.text_extents(sr," ")*sfac
				local klip=text:match("clip%(m ([^)]+)%)")
				if klip then
					klipos={}
					for x,y in klip:gmatch("([%-%d%.]+) ([%-%d%.]+)") do
						table.insert(klipos,{x=x,y=y})
					end
					if #klipos<=#seg then klipos=nil end
				end
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
					P1,P2=postab[poscount][1],postab[poscount][2]
					t2=t2:gsub("(\\pos%()[%d.-]+,[%d.-]+","%1"..P1..","..P2)
					:gsub("(\\move%()[%d.-]+,[%d.-]+,[%d.-]+,[%d.-]+","%1"..P1..","..P2..","..P1+movX..","..P2+movY)
				elseif klipos then
					t2=splitbyclip(klipos,sg,t2)
				else
					t2=findpos(t2,sg)
				end
				poscount=poscount+1
				if aftern:gsub("%b{}","")~="" then
					count=count+1
					t2=tagmerge(t2):gsub(ATAG,function(tg) return duplikill(tg) end)
					tags=""
					for it in t2:gmatch(ATAG) do tags=tags..it end
					tags=tags:gsub("}{","")
					line2.text=t2
					if nmbr then
						if sg<10 then ef="0"..sg else ef=sg end
						line2.effect=ef
					end
					subs.insert(i+count,line2)
					nsel=shiftsel(nsel,i,1)
				end
			end
			text=seg[1]
			if not breakit then
				if klipos then
					text=splitbyclip(klipos,1,text)
				else
					text=text:gsub("\\move","\\mpos")
					:gsub("(\\m?pos%()([%d.-]+),([%d.-]+)",function(p,x,y)
					notra=detra(text)
					local rot=notra:match("^{[^}]-\\frz([-%d.]+)")
					if align==1 then xpos=x end
					if align==2 then xpos=x-w/2+wtab[1]/2 end
					if align==0 then xpos=x-w+wtab[1] end
					if rot then xpos,y=rotxy(rot,xpos,y) end
					return p..round(xpos,1)..','..y end)
					:gsub("\\mpos%(([%d.-]+),([%d.-]+),[%d.-]+,[%d.-]+",function(x,y) return "\\move("..x..","..y..","..x+movX..","..y+movY end)
				end
			end
			
			line.text=text
			if nmbr then line.effect="01" end
			subs[i]=line
			xpos2=nil
		end
	end
	sel=nsel
	applytoall=nil
	nmbr=nil
	return sel
end

function splitbyclip(klipos,sg,t)
	px1,py1=klipos[sg].x,klipos[sg].y
	px2,py2=klipos[sg+1].x,klipos[sg+1].y
	px=(px1+px2)/2
	py=(py1+py2)/2
	ad=px2-px1
	op=py1-py2
	tang=(op/ad)
	ang1=math.deg(math.atan(tang))
	rota=round(ang1,2)
	if ad<0 then rota=rota-180 end
	t=t:gsub("\\pos%([%d.-]+,[%d.-]+","\\pos("..px..','..py):gsub("\\i?clip%b()","")
	:gsub("(\\move%()[%d.-]+,[%d.-]+,[%d.-]+,[%d.-]+","%1"..px..","..py..","..px+movX..","..py+movY)
	t=addtag3("\\frz"..rota,t)
	if valign==1 then ann='2' elseif valign==3 then ann='8' else ann='5' end
	t=addtag3("\\an"..ann,t)
	return t
end

function findpos(text,sg)
	notra=detra(text)
	local rot=notra:match("^{[^}]-\\frz([-%d.]+)")
	text=text:gsub("\\move","\\mpos")
	:gsub("(\\m?pos%()([%d.-]+),([%d.-]+)",function(p,x,y)
		if xpos2 then x=xpos2 end
		if sg==2 then 
			if align==2 then x=x-w/2+wtab[1]/2 end
			if align==0 then x=x-w+wtab[1] end
		end
		local space=ws
		if P=="Tags" and stab[sg-1]==1 then space=0 end
		if align==1 then xpos=round(x+wtab[sg-1]+space,2) end
		if align==2 then xpos=round(x+wtab[sg-1]/2+wtab[sg]/2+space,2) end
		if align==0 then xpos=round(x+wtab[sg]+space,2) end
		xpos2=xpos
		if rot then xpos,y=rotxy(rot,xpos,y) end
		return p..round(xpos,1)..','..y end)
	:gsub("\\mpos%(([%d.-]+),([%d.-]+),[%d.-]+,[%d.-]+",function(x,y) return "\\move("..x..","..y..","..x+movX..","..y+movY end)
	return text
end

function rotxy(rot,xpos,y)
	local h,Y,X
	h=posX-xpos
	Y=math.sin(math.rad(rot))*h
	y=round(posY+Y,1)
	X=math.cos(math.rad(rot))*h
	xpos=posX-X
	return xpos,y
end



--	reanimatools	------------------------------------------------------------------------------------------------------------------------------------
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

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function wrap(str) return "{"..str.."}" end
function detra(t) return t:gsub("\\t%b()","") end
function nobra(t) return t:gsub("%b{}","") end
function nobrea(t) return t:gsub("%b{}",""):gsub("\\[Nh]","") end
function nobrea1(t) return t:gsub("%b{}",""):gsub(" *\\[Nh] *"," ") end
function logg(m) m=m or "nil" aegisub.log("\n "..m) end
function logg2(m)
	local lt=type(m)
	aegisub.log("\n >> "..lt)
	if lt=='table' then
		aegisub.log(" (#"..#m..")")
		if not m[1] then
			for k,v in pairs(m) do
				if type(v)=='table' then vvv='[table]' elseif type(v)=='number' then vvv=v..' (n)' elseif type(v)=='boolean' then vvv=tf(v) else vvv=v end
				aegisub.log("\n	"..k..': '..vvv)
			end
		elseif type(m[1])=='table' then aegisub.log("\n nested table")
		else aegisub.log("\n {"..table.concat(m,', ').."}") end
	else
		m=tf(m) or "nil" aegisub.log("\n "..m)
	end
end
function loggtab(m) m=tf(m) or "nil" aegisub.log("\n {"..table.concat(m,';').."}") end
function tagmerge(t) repeat t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return t end
function progress(msg) if aegisub.progress.is_cancelled() then ak() end aegisub.progress.title(msg) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

function tf(val)
	if val==true then ret="true"
	elseif val==false then ret="false"
	else ret=val end
	return ret
end

function shiftsel(sel,i,mode)
	if i<sel[#sel] then
	for s=1,#sel do if sel[s]>i then sel[s]=sel[s]+1 end end
	end
	if mode==1 then table.insert(sel,i+1) end
	table.sort(sel)
	return sel
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

function textreplace(txt,r1,r2)
	txt=txt:gsub("^([^{]*)",function(t) t=t:gsub(r1,r2) return t end)
	txt=txt:gsub("(})([^{]*)",function(b,t) t=t:gsub(r1,r2) return b..t end)
	return txt
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

function getpos(subs,text)
    st=nil defst=nil
    for g=1,#subs do
        if subs[g].class=="info" then
	    local k=subs[g].key
	    local v=subs[g].value
	    if k=="PlayResX" then resx=v end
	    if k=="PlayResY" then resy=v end
        end
	if resx==nil then resx=0 end
	if resy==nil then resy=0 end
        if subs[g].class=="style" then
            local s=subs[g]
	    if s.name==line.style then st=s break end
	    if s.name=="Default" then defst=s end
        end
	if subs[g].class=="dialogue" then
		if defst then st=defst else t_error("Style '"..line.style.."' not found.\nStyle 'Default' not found. ",1) end
		break
	end
    end
    if st then
	acleft=st.margin_l	if line.margin_l>0 then acleft=line.margin_l end
	acright=st.margin_r	if line.margin_r>0 then acright=line.margin_r end
	acvert=st.margin_t	if line.margin_t>0 then acvert=line.margin_t end
	acalign=st.align	if text:match("\\an%d") then acalign=text:match("\\an(%d)") end
	aligntop="789" alignbot="123" aligncent="456"
	alignleft="147" alignright="369" alignmid="258"
	if alignleft:match(acalign) then horz=acleft
	elseif alignright:match(acalign) then horz=resx-acright
	elseif alignmid:match(acalign) then horz=resx/2 end
	if aligntop:match(acalign) then vert=acvert
	elseif alignbot:match(acalign) then vert=resy-acvert
	elseif aligncent:match(acalign) then vert=resy/2 end
    end
    if horz>0 and vert>0 then 
	if not text:match("^{\\") then text="{\\rel}"..text end
	text=text:gsub("^({\\[^}]-)}","%1\\pos("..horz..","..vert..")}") :gsub("\\rel","")
    end
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
	zerotf=""
	for t in tags:gmatch("\\t%b()") do
		if t:match("\\t%(\\") then
			zerotf=zerotf..t:match("\\t%((.*)%)$")
		else
			trnsfrm=trnsfrm..t
		end
	end
	zerotf="\\t("..zerotf..")"
	tags=tags:gsub("\\t%b()",""):gsub("^({[^}]*)}","%1"..zerotf..trnsfrm.."}"):gsub("\\t%(%)","")
	return tags
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

function extrakill(text,o)
	local tags3={"pos","move","org","fad"}
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

function reversel(subs,sel)
	if res.bot then table.sort(sel,function(a,b) return a>b end) end
	return sel
end

faxhelp=[[
clip2fax calculates value for a \fax tag from the first two points of a vector clip.
The clip should be in the vertical direction of the letters.
The point is that however you stretch and rotate (only frz, not x and y) the letters,
they will vertically always align based on the clip's direction.
If the clip has 4 points, points 3-4 are used to calculate fax for the last character.
If 'autogradient' is checked, a gradient by character is made.
\fscx, \fscy, and \frz are supported.

clip2frz switches to \frz mode instead of \fax.
It calculates \frz from the first two points of a vectorial clip.
Direction of text is from point 1 to point 2.
If the clip has 4 points, the frz is average from 1-2 and 3-4.
(Both lines must be in the same direction.)
This helps when the sign is in the middle of a rectangular area
where the top and bottom lines converge.]]
tagsthelp=[[
"copy tags" copies start tags from first selected line to the others.

"copy style with tags" copies the style as well.


"copy text" copies what's after start tags from first selected line to the others.

"only visible text" will exclude any inline tags and comments.


"bottom up" reverses the copying so that the text or tags are taken from the last line and copied upwards.]]
callhelp=[[
"copy colours" copies checked colours from first selected line to the others.

Unlike Necroscopy, this can read the colours from the style when tags are missing.

"copy alphas" will copy alpha values from first selected line to the others.

You can copy one or the other or both.

Both options will copy only the types selected.

"bottom up" reverses the copying so that tags are taken from the last line and copied upwards.]]
shadehelp=[[
"3D shadow" creates a 3D-effect out of a shadow by making multiple layers
with different shadow sizes, using \xshad and \yshad.

Shadow distance is taken from shadow tags.

If there are no tags, it's taken from style.]]
breakhelp=[[
Split by \N: Splits a line at each linebreak.

If there's no linebreak, you can split by tags, spaces, and other things.
If there is one and you want to split by tags or spaces anyway, check "split GUI".

Splitting will try to keep the position of each part.
\pos tag is not added when there isn't one.
Supports \fs, \fscx, \fscy, \fsp, \fn, \frz (but not inline), \move, and \an.

You can always expect some small inaccuracies with the positioning.

You can also split by pretty much any marker you want.
You can split a line|like|this and then set "|" as the marker in the GUI.

Perhaps the most advanced option here is splitting by clip, which works with
spaces, tags, and the marker. For a line with 5 spaces, you need a clip with 6 points.
Each word (or any part between 2 markers) will be aligned to one clip segment.
Check the online manual for more details on this function.]]
splathelp=[[
"split line into letters" makes a new line for each letter of the text.

You can set a distance, and the line will be split into letters with that distance between them.
Value "1" is the normal distance. You can randomly expect about 1% inaccuracy.

With a rectangular clip, the script tries to fit the text from side to side of the clip.

\fscx, \fs, \frz, \fn, and \move are supported.
Other rotations aren't, and line breaks get nuked.
\fax is not a problem; \fay will just apply to each letter but not affect position.
\frz will only work right without \org.
Inline tags should work unless they have impact on the size/position.]]
necrohelp=[[
Necroscopy
This lets you copy almost anything from one line to others.
The primary use is to copy from the first line of your selection to the others.
If you need to copy to a line that's above the source line, you can click Copy
with the selected things, and then use Paste Saved on the target line(s).
Or you can check "bottom up" and copy from the last selected line to the others.

The GUI loads data from the first selected line (not active line).
Check what you want to copy from this line to the other ones in your selection.
The tags on the left are start tags; on the right are inline tags.
Inline tags will only be pasted to the first tag block.

You can also copy Start Time, End Time, Style, Actor, Effect, and Text.
If you select only one line, check some things, and click Copy,
this will be saved in memory.
(It's the script's memory, not clipboard, so reloading automation nukes it.)
You can then select other lines and click Paste Saved,
and the things in memory will be applied.

You can also copy tags inside one line.
So you can type an asterisk before a word, check "\blur0.8",
and the blur tag will be copied there.

"Copy tags after all linebreaks" copies selected tags
after all linebreaks in all selected lines.
This is useful when you have gradient by character and linebreaks,
as it will restart after \N.

[Un]hide lets you hide/unhide checked tags (by making them comments).
Checked tags get hidden. If you don't check anything,
whatever was hidden gets unhidden. Good for clips, for example.]]

function necrohell()
	nekrohelp="http://unanimated.hostfree.pw/ts/scripts-manuals.htm#necroscopy"
	repeat
	if Pr=='clip2fax/frz' then nekrohelp=faxhelp end
	if Pr=='necroscopy' then nekrohelp=necrohelp end
	if Pr=='copy tags/text' then nekrohelp=tagsthelp end
	if Pr=='copy colours' then nekrohelp=callhelp end
	if Pr=='3D shadow' then nekrohelp=shadehelp end
	if Pr=='split letters' then nekrohelp=splathelp end
	if Pr=='split by \\N' then nekrohelp=breakhelp end
	Pr=aegisub.dialog.display({{width=32,height=10,class="textbox",value=nekrohelp},{x=36,height=10,class="label",label="NecrosCopy\nversion "..script_version}},
	{"clip2fax/frz","necroscopy","copy tags/text","copy colours","3D shadow","split letters","split by \\N","cancel"},{close='cancel'})
	until Pr=='cancel'
end

function necroscopy(subs,sel)
ADD=aegisub.dialog.display
ak=aegisub.cancel
ATAG="{[*>]?\\[^}]-}"
STAG="^{>?\\[^}]-}"
for i=1,#subs do
	if subs[i].class=="dialogue" then line0=i-1 break end
end
	res=res or {space=1,ccol=true,cpstyle=true,c1=true,grad=true}
	GUI={
	{x=8,y=1,width=2,class="floatedit",name="space",value=res.space,hint="distance between letters"},
	-- clip 2
	{x=0,y=0,class="label",label="clip2fax /",},
	{x=1,y=0,width=2,class="checkbox",name="frz",label="clip2frz          ",hint="freeze instead of faxing"},
	{x=0,y=1,width=2,class="checkbox",name="grad",label="autogradient",value=res.grad,hint="automatically gradient \\fax"},
	-- copy
	{x=2,y=1,width=2,class="checkbox",name="bot",label="bottom up",value=res.bot,hint="copy from the bottom up [all copy functions]"},
	{x=3,y=0,width=2,class="checkbox",name="cpstyle",label="copy style with tags ",value=res.cpstyle},
	{x=4,y=1,class="checkbox",name="vis",label="only visible text",value=res.vis,hint="no inline tags/comments [copy text]"},
	-- colours
	{x=5,y=0,class="checkbox",name="ccol",label="copy colours:",value=res.ccol},
	{x=5,y=1,class="checkbox",name="alfa",label="copy alphas:",value=res.alfa},
	{x=6,y=0,class="checkbox",name="c1",label="c",value=res.c1},
	{x=7,y=0,class="checkbox",name="c3",label="3c :",value=res.c3},
	{x=6,y=1,class="checkbox",name="c4",label="4c",value=res.c4},
	{x=7,y=1,class="checkbox",name="c2",label="2c :",value=res.c2},
	
	{x=8,y=0,width=2,class="label",label=" split text into letters"},
	{x=10,y=0,width=2,height=2,class="checkbox",name="splitg",label="split\nGUI",hint="open GUI to split by spaces/tags instead"},
	{x=12,y=0,class="label",label=script_name.." v"..script_version},
	{x=12,y=1,class="checkbox",name="help",label="necronomicon",hint="necrohelp"},
	} 
	P,res=ADD(GUI,{"clip2fax/frz","necroscopy","copy tags","copy text","copy colours","3D shadow","split letters","split by \\N","split"},{cancel='split'})
	
	if P=="split" then ak() end
	if res.help then P='' necrohell() end
	if P=="clip2fax/frz" then if res.frz then frozt(subs,sel) else fucks(subs,sel) end end
	if P=="necroscopy" then reversel(subs,sel) necrostuff(subs,sel) end
	if P=="copy tags" then reversel(subs,sel) copytags(subs,sel) end
	if P=="copy text" then reversel(subs,sel) copytext(subs,sel) end
	if P=="copy clip" then reversel(subs,sel) copyclip(subs,sel) end
	if P=="copy colours" then reversel(subs,sel) copycolours(subs,sel) end
	if P=="3D shadow" then shad3(subs,sel) end
	if P=="split letters" then sel=space(subs,sel) end
	if P=="split by \\N" then sel=splitbreak(subs,sel) end
	return sel
end

if haveDepCtrl then
  depRec:registerMacros({
	{script_name,script_description,necroscopy},
	{": HELP : / NecrosCopy",script_description,necrohell},
  },false)
else
	aegisub.register_macro(script_name,script_description,necroscopy)
	aegisub.register_macro(": HELP : / NecrosCopy",script_description,necrohell)
end