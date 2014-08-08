-- Hyperdimensional Relocator offers a plethora of functions, focusing primarily on \pos, \move, \org, \clip, and rotations.
-- Check Help (Space Travel Guide) for detailed description of all functions.

script_name="Hyperdimensional Relocator"
script_description="Makes things appear different from before"
script_author="reanimated"
script_url1="http://unanimated.xtreemhost.com/ts/relocator.lua"
script_url2="https://raw.githubusercontent.com/unanimated/luaegisub/master/relocator.lua"
script_version="3.0"

include("utils.lua")
re=require'aegisub.re'

function positron(subs,sel)
    ps=res.post
    shake={} shaker={}
    count=0
    if res.posi=="shadow layer" or res.posi=="space out letters" then table.sort(sel,function(a,b) return a>b end) end
    for x, i in ipairs(sel) do
	progress("Depositing line: "..x.."/"..#sel)
	line=subs[i]
	text=line.text
	
	-- Align X
	if res.posi=="Align X" then
	    if x==1 and not text:match("\\pos") then t_error("Missing \\pos tag.",true) end
	    if x==1 and res.first then pxx=text:match("\\pos%(([%d%.%-]+),") ps=pxx end
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\pos("..ps..",%2)")
	end
	
	-- Align Y
	if res.posi=="Align Y" then
	    if x==1 and not text:match("\\pos") then t_error("Missing \\pos tag.",true) end
	    if x==1 and res.first then pyy=text:match("\\pos%([%d%.%-]+,([%d%.%-]+)") ps=pyy end
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\pos(%1,"..ps..")")
	end
	
	-- Mirrors
	if res.posi:match"mirror" then
	    if not text:match("\\pos") and not text:match("\\move") then t_error("Fail. Some lines are missing \\pos.",true) end
	    info(subs)
	    if not text:match("^{[^}]-\\an%d") then sr=stylechk(subs,line.style) 
		text=text:gsub("^","{\\an"..sr.align.."}") :gsub("({\\an%d)}{\\","%1\\")
	    end
	    if res.post~=0 and res.post~=nil then resx=2*res.post resy=2*res.post end
	    if res.posi=="horizontal mirror" then
	    mirs={"1","4","7","9","6","3"}
	    text2=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(x,y) return "\\pos("..resx-x..","..y..")" end)
	    :gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(x,y,x2,y2) return "\\move("..resx-x..","..y..","..resx-x2..","..y2 end)
	    :gsub("\\an([147369])",function(a) for m=1,6 do if a==mirs[m] then b=mirs[7-m] end end return "\\an"..b end)
	    	if res.rota then 
		    if not text2:match("^{[^}]-\\fry") then text2=addtag("\\fry0",text2) end text2=flip("fry",text2)
		end
	    else
	    mirs={"1","2","3","9","8","7"}
	    text2=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(x,y) return "\\pos("..x..","..resy-y..")" end)
	    :gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(x,y,x2,y2) return "\\move("..x..","..resy-y..","..x2..","..resy-y2 end)
	    :gsub("\\an([123789])",function(a) for m=1,6 do if a==mirs[m] then b=mirs[7-m] end end return "\\an"..b end)
	    	if res.rota then 
		    if not text2:match("^{[^}]-\\frx") then text2=addtag("\\frx0",text2) end text2=flip("frx",text2)
		end
	    end
	    l2=line	l2.text=text2
	    if res.delfbf then
	      text=text2
	    else
	      subs.insert(i+1,l2)
	      for i=x,#sel do sel[i]=sel[i]+1 end
	    end
	end
	
	-- org to fax
	if res.posi=="org to fax" then
	    if text:match("\\move") then t_error("What's \\move doing there??",true) end
	    if not text:match("\\pos") then text=getpos(subs,text) end
	    if not text:match("\\org") then t_error("Missing \\org.",true) end
	    pox,poy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)")
	    orx,ory=text:match("\\org%(([%d%.%-]+),([%d%.%-]+)")
	    rota=text:match("\\frz([%d%.%-]+)")
	    if rota==nil then rota=0 end
	    ad=pox-orx
	    op=poy-ory
	    tang=(ad/op)
	    ang1=math.deg(math.atan(tang))
	    ang2=ang1-rota
	    tangf=math.tan(math.rad(ang2))
	    
	    faks=round(tangf*100)/100
	    text=addtag("\\fax"..faks,text)
	    text=text:gsub("\\org%([^%)]+%)","")
	    text=text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	end
	
	-- clip to fax
	if res.posi=="clip to fax" then
	    if not text:match("\\clip") then t_error("Missing \\clip.",true) end
	    cx1,cy1,cx2,cy2,cx3,cy3,cx4,cy4=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
	    if cx1==nil then cx1,cy1,cx2,cy2=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)") end
	    rota=text:match("\\frz([%d%.%-]+)")
	    if rota==nil then rota=0 end
	    ad=cx1-cx2
	    op=cy1-cy2
	    tang=(ad/op)
	    ang1=math.deg(math.atan(tang))
	    ang2=ang1-rota
	    tangf=math.tan(math.rad(ang2))
	    
	    faks=round(tangf*100)/100
	    text=addtag("\\fax"..faks,text)
	    if cy4~=nil then
		tang2=((cx3-cx4)/(cy3-cy4))
		ang3=math.deg(math.atan(tang2))
		ang4=ang3-rota
		tangf2=math.tan(math.rad(ang4))
		faks2=round(tangf2*100)/100
		endcom=""
		repeat
			text=text:gsub("({[^}]-})%s*$",function(ec) endcom=ec..endcom return "" end)
		until not text:match("}$")
		text=text:gsub("(.)$","{\\fax"..faks2.."}%1")
		
		vis=text:gsub("{[^}]-}","")
		orig=text:gsub("^{\\[^}]*}","")
		tg=text:match("^{\\[^}]-}")
		chars={}
		for char in vis:gmatch(".") do table.insert(chars,char) end
		faxdiff=(faks2-faks)/(#chars-1)
		tt=chars[1]
		for c=2,#chars do
		    if c==#chars then ast="" else ast="*" end
		    if chars[c]==" " then tt=tt.." " else
		    tt=tt.."{"..ast.."\\fax"..round((faks+faxdiff*(c-1))*100)/100 .."}"..chars[c]
		    end
		end
		text=tg..tt
		if orig:match("{%*?\\") then text=textmod(orig,text) end
		
		text=text..endcom
	    end
	    text=text:gsub("\\clip%([^%)]+%)","")
	    :gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	    :gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	end
	
	-- clip to frz
	if res.posi=="clip to frz" then
	    if not text:match("\\clip") then t_error("Missing \\clip.",true) end
	    cx1,cy1,cx2,cy2,cx3,cy3,cx4,cy4=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
	    if cx1==nil then cx1,cy1,cx2,cy2=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)") end
	    ad=cx2-cx1
	    op=cy1-cy2
	    tang=(op/ad)
	    ang1=math.deg(math.atan(tang))
	    rota=round(ang1*100)/100
	    if ad<0 then rota=rota-180 end
	    
	    if cy4~=nil then
		ad2=cx4-cx3
		op2=cy3-cy4
		tang2=(op2/ad2)
		ang2=math.deg(math.atan(tang2))
		rota2=round(ang2*100)/100
		if ad2<0 then rota2=rota2-180 end
	    else rota2=rota
	    end
	    rota3=(rota+rota2)/2
	    
	    text=addtag("\\frz"..rota3,text)
	    text=text:gsub("\\clip%([^%)]+%)","")
	    text=text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	end
	
	-- shake
	if res.posi=="shake" then
	    if text:match("\\move") then t_error("What's \\move doing there??",true) end
	    if not text:match("\\pos") then text=getpos(subs,text) end
	    s=line.start_time
	    diam=res.post
	    scax=res.eks*10+100	scax2=10000/scax
	    scay=res.wai*10+100	scay2=10000/scay
	    if diam==0 and not res.sca then diamx=res.eks diamy=res.wai else diamx=diam diamy=diam end
	    shx=math.random(-100,100)/100*diamx	if res.smo and lshx~=nil then shx=(shx+3*lshx)/4 end
	    shy=math.random(-100,100)/100*diamy	if res.smo and lshy~=nil then shy=(shy+3*lshy)/4 end
	    shr=math.random(-100,100)/100*diam	if res.smo and lshr~=nil then shr=(shr+3*lshr)/4 end
	    shsx=math.random(scax2,scax)/100		if res.smo and lshsx~=nil then shsx=(shsx+3*lshsx)/4 end
	    shsy=math.random(scay2,scay)/100		if res.smo and lshsy~=nil then shsy=(shsy+3*lshsy)/4 end
	    if scax==scay then shsy=shsx end
	    if res.layers then
		ch=0
		for p=1,#shake do sv=shake[p]
		  if sv[1]==s then ch=1 shx=sv[2] shy=sv[3] shr=sv[4] shsx=sv[5] shsy=sv[6] end
		end
		if ch==0 then
		  a={s,shx,shy,shr,shsx,shsy}
		  table.insert(shake,a)
		end
	    end
	    	lshx=shx	lshy=shy	lshr=shr	lshsx=shsx	lshsy=shsy
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(x,y) return "\\pos("..x+shx..","..y+shy..")" end)
	    if res.rota then
		text=text:gsub("\\frz([%d%.%-]+)",function(z) return "\\frz"..z+shr end)
		if not text:match("^{[^}]-\\frz") then text=addtag("\\frz"..shr,text) end
	    end
	    if res.sca then
		text=text:gsub("(\\fscx)([%d%.%-]+)",function(x,y) return x..y*shsx end)
		text=text:gsub("(\\fscy)([%d%.%-]+)",function(x,y) return x..y*shsy end)
		if not text:match("^{[^}]-\\fscx") then text=addtag("\\fscx".. 100*shsx,text) end
		if not text:match("^{[^}]-\\fscy") then text=addtag("\\fscy".. 100*shsy,text) end
	    end
	    text=text:gsub("([%d%.%-]+)([\\}%),])",function(a,b) return round(a*100)/100 ..b end)
	end
	
	-- shake rotation
	if res.posi=="shake rotation" then
	    s=line.start_time
	    ang=res.post
	    angx=res.eks
	    angy=res.wai
	    angl={ang,angx,angy}
	    rots={"\\frz","\\frx","\\fry"}
	    for r=1,3 do ro=rots[r] an=angl[r]
	    if an~=0 then
	      shr=math.random(-100,100)/100*an
	      if res.layers then
		ch=0
		for p=1,#shaker do sv=shaker[p]
		  if sv[1]==s and sv[2]==r then ch=1 shr=sv[3] end
		end
		if ch==0 then rt=r
		  a={s,rt,shr}
		  table.insert(shaker,a)
		end
	      end
	      text=text:gsub(ro.."([%d%.%-]+)",function(z) return ro..z+shr end)
	      if not text:match("^{[^}]-"..ro) then text=addtag(ro..shr,text) end
	    end end
	end
	
	-- shadow layer
	if res.posi=="shadow layer" then
	    sr=stylechk(subs,line.style)
	    text=text:gsub("\\1c","\\c")
	    shadcol=sr.color4:gsub("H%x%x","H")
	    sc=text:match("^{[^}]-\\4c(&H%x+&)")
	    if sc~=nil then shadcol=sc end
	    if res.post~=0 then xsh=res.post ysh=res.post else xsh=res.eks ysh=res.wai end
	    if xsh==0 and ysh==0 then
	     stshad=sr.shadow
	     shad=text:match("^{[^}]-\\shad([%d%.]+)")
	      if shad~=nil then xs=shad ys=shad end
	     xshad=text:match("^{[^}]-\\xshad([%d%.%-]+)")
	      if xshad~=nil then xs=xshad end
	     yshad=text:match("^{[^}]-\\yshad([%d%.%-]+)")
	      if yshad~=nil then ys=yshad end
	     if xs==nil then xs=stshad end
	     if ys==nil then ys=stshad end
	    else xs=xsh ys=ysh
	    end
	    
	    if not text:match("\\pos") and not text:match("\\move") then text=getpos(subs,text) end
	    text=text:gsub("\\[xy]?shad([%d%.%-]+)","")
	    l2=line	text2=text
	    
	    text2=text2
	    :gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return "\\pos("..a+xs..","..b+ys..")" end)
	    :gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d) return "\\pos("..a+xs..","..b+ys..","..c+xs..","..d+ys end)
	    :gsub("{\\[^}]-}",function(tag)
		if tag:match("\\4c&H%x+&") then
		  tag=tag:gsub("\\3?c&H%x+&","") :gsub("\\4c(&H%x+&)","\\c%1\\3c%1")
		else tag=tag:gsub("\\3?c&H%x+&","")
		end
		if tag:match("\\4a&H%x+&") then
		  tag=tag:gsub("\\alpha&H%x+&","") :gsub("\\4a(&H%x+&)","\\alpha%1")
		end
		tag=tag:gsub("\\[13]a&H%x+&","") :gsub("{}","")
		return tag
		end)
	    
	    if not text2:match("^{[^}]-\\c&") then text2=addtag("\\c"..shadcol,text2) end
	    if not text2:match("^{[^}]-\\3c&") then text2=addtag("\\3c"..shadcol,text2) end
	    
	    l2.text=text2
	    subs.insert(i+1,l2)
	    line.layer=line.layer+1
	end

	-- Space out letters
	if res.posi=="space out letters" then
	    sr=stylechk(subs,line.style)
	    acalign=nil
	    text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),.-%)","\\pos(%1,%2)") :gsub("%s?\\[Nn]%s?"," ")
	    if not text:match"\\pos" then text=getpos(subs,text) end
	    tags=text:match("^{\\[^}]-}") or ""
	    after=text:gsub("^{\\[^}]-}","") :gsub("{[^\\}]-}","")
	    local px,py=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	    local x1,width,w,wtotal,let,spacing,avgspac,ltrspac,xpos,lastxpos,spaces,prevlet,scx,k1,k2,k3,bord,off,inwidth,wdiff,pp,tpos
	    scx=text:match("\\fscx([%d%.]+)") or sr.scale_x
	    k1,k2,k3=text:match("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),")
	    bord=text:match("^{[^}]-\\bord([%d%.]+)") or sr.outline
	    visible=text:gsub("{[^}]-}","")
	    letters={}    wtotal=0
	    	ltrmatches=re.find(visible,".")
		  for l=1,#ltrmatches do
		    w=aegisub.text_extents(sr,ltrmatches[l].str)
		    table.insert(letters,{l=ltrmatches[l].str,w=w})
		    wtotal=wtotal+w
		  end
	    intags={}    cnt=0
		for chars,tag in after:gmatch("([^}]+)({\\[^}]+})") do
		    pp=re.find(chars,".")
		    tpos=#pp+1+cnt
		    intags[tpos]=tag
		    cnt=cnt+#pp
		end
	    spacing=ps
	    avgspac=wtotal/#letters
	    off=(letters[1].w-letters[#letters].w)/4*scx/100
	    inwidth=(wtotal-letters[1].w/2-letters[#letters].w/2)*scx/100
	    if spacing==1 then spacing=round(avgspac*scx)/100 end
	    width=(#letters-1)*spacing	--off
	    
	    -- klip-based stuff
	    if k1 then 
		width=(k3-k1)-letters[1].w/2*scx/100-letters[#letters].w/2*scx/100-(2*bord)
		spacing=(width+2*bord)/(#letters-1)
		px=(k1+k3)/2-off
		tags=tags:gsub("\\i?clip%b()","")
	    end
	    
	    -- find starting x point based on alignment
	    if not acalign then acalign=text:match("\\an(%d)") or sr.align end
	    acalign=tostring(acalign)
	    if acalign:match("[147]") then x1=round(px+2*off)
		tags=tags:gsub("\\an%d","") :gsub("^{","{\\an"..acalign+1) 
		if k1 then x1=x1-width/2-2*off end
	    end
	    if acalign:match("[258]") then x1=round(px-width/2) end
	    if acalign:match("[369]") then x1=round(px-width-2*off)
		tags=tags:gsub("\\an%d","") :gsub("^{","{\\an"..acalign-1) 
		if k1 then x1=x1+width/2+2*off end
	    end
	    
	    wdiff=(width-inwidth)/(#letters-1)
	    lastxpos=x1
	    spaces=0
	    -- weird letter-width sorcery starts here
	    for t=1,#letters do
		let=letters[t]
		if t>1 then
		  prevlet=letters[t-1]
		  ltrspac=(let.w+prevlet.w)/2*scx/100+wdiff
		  ltrspac=round(ltrspac*100)/100
		else
		  fact1=spacing/(avgspac*scx/100)
		  fact2=(let.w-letters[#letters].w)/4*scx/100
		  ltrspac=round(fact1*fact2*100)/100
		end
		if intags[t] then tags=tags..intags[t] tags=tags:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") tags=duplikill(tags) end
		t2=tags..let.l
		xpos=lastxpos+ltrspac
		t2=t2:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\pos("..xpos..",%2)")
		lastxpos=xpos
		l2=line
		l2.text=t2
		if t==1 then text=t2 else
		if let.l~=" " then subs.insert(i+t-1-spaces,l2) else count=count-1 spaces=spaces+1 end
		end
	    end
	    count=count+#letters-1
	end

	line.text=text
        subs[i]=line
    end
    table.sort(sel)
    if res.posi=="shadow layer" then for s=1,#sel do sel[s]=sel[s]+s end end
    if res.posi=="space out letters" then last=sel[#sel] for s=1,count do table.insert(sel,last+s) end end
    return sel
end

function bilocator(subs,sel)
    xx=res.eks	yy=res.wai
    for i=#sel,1,-1 do
        progress(string.format("Moving through hyperspace... %d/%d",(#sel-i+1),#sel))
	line=subs[sel[i]]
	text=line.text
	
	    if res.move=="transmove" and sel[i]<#subs then
	    
	    	start=line.start_time		-- start time
		endt=line.end_time		-- end time
		nextline=subs[sel[i]+1]
		text2=nextline.text
		text=text:gsub("\\1c","\\c")
		text2=text2:gsub("\\1c","\\c")
		
		startf=ms2fr(start)		-- startframe
		endf=ms2fr(endt)		-- endframe
		start2=fr2ms(startf)
		endt2=fr2ms(endf-1)
		tim=fr2ms(1)
		movt1=start2-start+tim		-- first timecode in \move
		movt2=endt2-start+tim		-- second timecode in \move
		movt=movt1..","..movt2
		
		-- move
		p1=text:match("\\pos%(([^%)]+)%)")
		p2=text2:match("\\pos%(([^%)]+)%)")
		if p1==nil or p2==nil then t_error("Missing \\pos tag(s).",true) end
		if p2~=p1 then text=text:gsub("\\pos%(([^%)]+)%)","\\move(%1,"..p2..","..movt..")") end
		
		-- transforms
		tf=""
		
		tftags={"fs","fsp","fscx","fscy","blur","bord","shad","fax","fay"}
		for tg=1,#tftags do
		  t=tftags[tg]
		  if text2:match("\\"..t.."[%d%.%-]+") then tag2=text2:match("(\\"..t.."[%d%.%-]+)") 
		    if text:match("\\"..t.."[%d%.%-]+") then tag1=text:match("(\\"..t.."[%d%.%-]+)") else tag1="" end
		    if tag1~=tag2 then tf=tf..tag2 end
		  end
		end
		
		tfctags={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
		for tg=1,#tfctags do
		  t=tfctags[tg]
		  if text2:match("\\"..t.."&H%x+&") then tag2=text2:match("(\\"..t.."&H%x+&)") 
		    if text:match("\\"..t.."&H%x+&") then tag1=text:match("(\\"..t.."&H%x+&)") else tag1="" end
		    if tag1~=tag2 then tf=tf..tag2 end
		  end
		end
		
		tfrtags={"frz","frx","fry"}
		for tg=1,#tfrtags do
		  t=tfrtags[tg]
		  if text2:match("\\"..t.."[%d%.%-]+") then 
		    tag2=text2:match("(\\"..t.."[%d%.%-]+)") rr2=tonumber(text2:match("\\"..t.."([%d%.%-]+)"))
		    if text:match("\\"..t.."[%d%.%-]+") then 
		        tag1=text:match("(\\"..t.."[%d%.%-]+)") rr1=tonumber(text:match("\\"..t.."([%d%.%-]+)"))
		    else tag1="" rr1="0" end
		    if tag1~=tag2 then 
			if res.rotac and math.abs(rr2-rr1)>180 then
			    if rr2>rr1 then rr2=rr2-360 tag2="\\frz"..rr2 else 
			    rr1=rr1-360 text=text:gsub("\\frz[%d%.%-]+","\\frz"..rr1)
			    end
			end
		    tf=tf..tag2 end
		  end
		end
		
		-- apply transform
		if tf~="" then
		    text=text:gsub("^({\\[^}]-)}","%1\\t("..movt..","..tf..")}")
		end
		
		-- delete line 2
		if res.keep==false then subs.delete(sel[i]+1) end
		
	    end -- end of transmove
		
	    if res.move=="horizontal" then
		    text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\move(%1,%2,%3,%2") end
	    if res.move=="vertical" then
		    text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\move(%1,%2,%1,%4") end
	    
	    if res.move=="rvrs. move" then
		text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\move(%3,%4,%1,%2")
	    end
	    
	    if res.move=="shiftmove" then
		text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d) return "\\move("..a..","..b..","..c+xx..","..d+yy end)
		text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)",function(a,b) return "\\move("..a..","..b..","..a+xx..","..b+yy end)
	    end
	    
	    if res.move=="shiftstart" then
		text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d) return "\\move("..a+xx..","..b+yy..","..c..","..d end)
	    end
	    
	    if res.move=="move clip" then
		m1,m2,m3,m4=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
		mt=text:match("\\move%([^,]+,[^,]+,[^,]+,[^,]+,([%d%.,%-]+)")
		if mt==nil then mt="" else mt=mt.."," end
		klip=text:match("\\i?clip%([%d%.,%-]+%)")
		klip=klip:gsub("(\\i?clip%()([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d,e) return a..b+m3-m1..","..c+m4-m2..","..d+m3-m1..","..e+m4-m2 end)
		text=addtag("\\t("..mt..klip..")",text)
	    end
	    
	line.text=text
        subs[sel[i]]=line
    end
end

function multimove(subs,sel)
    for x, i in ipairs(sel) do
        progress(string.format("Synchronizing movement... %d/%d",x,#sel))
	line=subs[i]
        text=subs[i].text
	-- error if first line's missing \move tag
	if x==1 and text:match("\\move")==nil then ADD({{class="label",
		    label="Missing \\move tag on line 1",x=0,y=0,width=1,height=2}},{"OK"})
		    mc=1
	else 
	-- get coordinates from \move on line 1
	    if text:match("\\move") then
	    x1,y1,x2,y2,t,m1,m2=nil
		if text:match("\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.,%-]+%)") then
		x1,y1,x2,y2,t=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.,%-]+)%)")
		else
		x1,y1,x2,y2=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)")
		end
	    m1=x2-x1	m2=y2-y1	-- difference between start/end position
	    end
	-- error if any of lines 2+ don't have \pos tag
	    if x~=1 and text:match("\\pos")==nil then poscheck=1
	    else  
	-- apply move coordinates to lines 2+
		if x~=1 and m2~=nil then
		p1,p2=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		    if t~=nil then
		    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\move%(%1,%2,"..p1+m1..","..p2+m2..","..t.."%)")
		    else
		    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\move(%1,%2,"..p1+m1..","..p2+m2..")")
		    end
		end
	    end
	    
	end
	    line.text=text
	    subs[i]=line
    end
	if poscheck==1 then t_error("Some lines are missing \\pos tags") end
	x1,y1,x2,y2,t,m1,m2=nil
	poscheck=0 
end

function modifier(subs,sel)
    xx=res.eks yy=res.wai
    for x, i in ipairs(sel) do
        progress(string.format("Morphing... %d/%d",x,#sel))
	line=subs[i]
	text=line.text

	    if res.mod=="round numbers" then
		if text:match("\\pos") and res.rnd=="all" or text:match("\\pos") and res.rnd=="pos" then
		px,py=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		px,py=round4(px,py,0,0)
		text=text:gsub("\\pos%([%d%.%-]+,[%d%.%-]+%)","\\pos("..px..","..py..")")
		end
		if text:match("\\org") and res.rnd=="all" or text:match("\\org") and res.rnd=="org" then
		ox,oy=text:match("\\org%(([%d%.%-]+),([%d%.%-]+)%)")
		ox,oy=round4(ox,oy,0,0)
		text=text:gsub("\\org%([%d%.%-]+,[%d%.%-]+%)","\\org("..ox..","..oy..")")
		end
		if text:match("\\move") and res.rnd=="all" or text:match("\\move") and res.rnd=="move" then
		mo1,mo2,mo3,mo4=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
		mo1,mo2,mo3,mo4=round4(mo1,mo2,mo3,mo4)
		text=text:gsub("\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.%-]+","\\move("..mo1..","..mo2..","..mo3..","..mo4)
		end
		if text:match("\\i?clip") and res.rnd=="all" or text:match("\\i?clip") and res.rnd=="clip" then
		 for klip in text:gmatch("\\i?clip%([^%)]+%)") do
		 klip2=klip:gsub("([%d%.%-]+)",function(c) return round(c) end)
		 klip=esc(klip)
		 text=text:gsub(klip,klip2)
		 end
		end
		if text:match("\\p1") and res.rnd=="all" or text:match("\\p1") and res.rnd=="mask" then
		tags=text:match("^{\\[^}]-}")
		text=text:gsub("^{\\[^}]-}","") :gsub("([%d%.%-]+)",function(m) return round(m) end)
		text=tags..text
		end
	    end
	    
	    if res.mod=="fullmovetimes" or res.mod=="fulltranstimes" then
		start=line.start_time		-- start time
		endt=line.end_time		-- end time
		startf=ms2fr(start)		-- startframe
		endf=ms2fr(endt)		-- endframe
		start2=fr2ms(startf)
		endt2=fr2ms(endf-1)
		tim=fr2ms(1)
		movt1=start2-start+tim		-- first timecode in \move
		movt2=endt2-start+tim		-- second timecode in \move
		movt=movt1..","..movt2
	    end
	    
	    if res.mod=="killmovetimes" then
		text=text:gsub("\\move%(([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,%)]+)","\\move(%1,%2,%3,%4")
	    end
	    
	    if res.mod=="fullmovetimes" then
		text=text:gsub("\\move%(([^,]+,[^,]+,[^,]+,[^,]+),([%d%.%-]+),([%d%.%-]+)","\\move(%1,"..movt)
		text=text:gsub("\\move%(([^,]+,[^,]+,[^,]+,[^,]+)%)","\\move(%1,"..movt..")")
	    end
	    
	    if res.mod=="fulltranstimes" then
		text=text:gsub("\\t%([%d,%.]-\\","\\t("..movt..",\\")
		text=text:gsub("\\t%(\\","\\t("..movt..",\\")
	    end
	    
	    if res.mod=="move v. clip" then
		if x==1 then v1,v2=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)") 
			if v1==nil then t_error("Error. No \\pos tag on line 1.",true) end
		end
		if x~=1 and text:match("\\pos") then v3,v4=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		  V1=v3-v1	V2=v4-v2
		aegisub.log("\n V1 "..V1)
		  if text:match("clip%(m [%d%a%s%-%.]+%)") then
		    ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
		    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+V1.." "..b+V2 end)
		    ctext=ctext:gsub("%-","%%-")
		    text=text:gsub("clip%(m "..ctext,"clip(m "..ctext2)
		  end
		  if text:match("clip%(%d+,m [%d%a%s%-%.]+%)") then
		    fac,ctext=text:match("clip%((%d+),m ([%d%a%s%-%.]+)%)")
		    factor=2^(fac-1)
		    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+factor*V1.." "..b+factor*V2 end)
		    ctext=ctext:gsub("%-","%%-")
		    text=text:gsub(",m "..ctext,",m "..ctext2)
		  end
		end
	    end
	    
	    if res.mod=="set origin" then
		text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",
		function(a,b) return "\\pos("..a..","..b..")\\org("..a+res.eks..","..b+res.wai..")" end)
	    end
	    
	    if res.mod=="calculate origin" then
		local c={}
		local c2={}
		x1,y1,x2,y2,x3,y3,x4,y4=text:match("clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
		cor1={x=tonumber(x1),y=tonumber(y1)} table.insert(c,cor1) table.insert(c2,cor1)
		cor2={x=tonumber(x2),y=tonumber(y2)} table.insert(c,cor2) table.insert(c2,cor2)
		cor3={x=tonumber(x3),y=tonumber(y3)} table.insert(c,cor3) table.insert(c2,cor3)
		cor4={x=tonumber(x4),y=tonumber(y4)} table.insert(c,cor4) table.insert(c2,cor4)
		table.sort(c, function(a,b) return tonumber(a.x)<tonumber(b.x) end)	-- sorted by x
		table.sort(c2, function(a,b) return tonumber(a.y)<tonumber(b.y) end)	-- sorted by y
		-- i don't even know myself how all this shit works
		xx1=c[1].x	yy1=c[1].y
		xx2=c[4].x	yy2=c[4].y
		yy3=c2[1].y	xx3=c2[1].x
		yy4=c2[4].y	xx4=c2[4].x
		distx1=c[2].x-c[1].x	disty1=c[2].y-c[1].y
		distx2=c[4].x-c[3].x	disty2=c[4].y-c[3].y
		distx3=c2[2].x-c2[1].x		disty3=c2[2].y-c2[1].y
		distx4=c2[4].x-c2[3].x		disty4=c2[4].y-c2[3].y
		
		-- x/y factor / angle / whatever
		fx1=math.abs(disty1/distx1)
		fx2=math.abs(disty2/distx2)
		fx3=math.abs(distx3/disty3)
		fx4=math.abs(distx4/disty4)
		
		-- determine if y is going up or down
		cy=1
		  if c[2].y>c[1].y then cx1=round(xx1-(yy1-cy)/fx1) else cx1=round(xx1+(yy1-cy)/fx1) end
		  if c[4].y>c[3].y then cx2=round(xx2-(yy2-cy)/fx2) else cx2=round(xx2+(yy2-cy)/fx2) end	
		  top=cx2-cx1
		cy=500
		  if c[2].y>c[1].y then cx1=round(xx1-(yy1-cy)/fx1) else cx1=round(xx1+(yy1-cy)/fx1) end
		  if c[4].y>c[3].y then cx2=round(xx2-(yy2-cy)/fx2) else cx2=round(xx2+(yy2-cy)/fx2) end	
		  bot=cx2-cx1
		if top>bot then cy=c2[4].y ycalc=1 else cy=c2[1].y ycalc=-1 end
		
		-- LOOK FOR ORG X
		repeat
		  if c[2].y>c[1].y then cx1=round(xx1-(yy1-cy)/fx1) else cx1=round(xx1+(yy1-cy)/fx1) end
		  if c[4].y>c[3].y then cx2=round(xx2-(yy2-cy)/fx2) else cx2=round(xx2+(yy2-cy)/fx2) end
		  cy=cy+ycalc
		  -- aegisub.log("\n cx1: "..cx1.."   cx2: "..cx2.."   cy: "..cy)
		until cx1>=cx2 or math.abs(cy)==50000
		org1=cx1
		
		-- determine if x is going left or right
		cx=1
		  if c2[2].x>c2[1].x then cy1=round(yy3-(xx3-cx)/fx3) else cy1=round(yy3+(xx3-cx)/fx3) end
		  if c2[4].x>c2[3].x then cy2=round(yy4-(xx4-cx)/fx4) else cy2=round(yy4+(xx4-cx)/fx4) end
		  left=cy2-cy1
		cx=500
		  if c2[2].x>c2[1].x then cy1=round(yy3-(xx3-cx)/fx3) else cy1=round(yy3+(xx3-cx)/fx3) end
		  if c2[4].x>c2[3].x then cy2=round(yy4-(xx4-cx)/fx4) else cy2=round(yy4+(xx4-cx)/fx4) end
		  rite=cy2-cy1
		if left>rite then cx=c[4].x xcalc=1 else cx=c[1].x xcalc=-1 end
		
		-- LOOK FOR ORG Y
		repeat
		  if c2[2].x>c2[1].x then cy1=round(yy3-(xx3-cx)/fx3) else cy1=round(yy3+(xx3-cx)/fx3) end
		  if c2[4].x>c2[3].x then cy2=round(yy4-(xx4-cx)/fx4) else cy2=round(yy4+(xx4-cx)/fx4) end
		  cx=cx+xcalc
		  -- aegisub.log("\n cy1: "..cy1.."   cy2: "..cy2)
		until cy1>=cy2 or math.abs(cx)==50000
		org2=cy1
		
		text=text:gsub("\\org%([^%)]+%)","") 
		text=addtag("\\org("..org1..","..org2..")",text)
	    end
	       
	    if res.mod=="FReeZe" then
		frz=res.freeze
		if text:match("^{[^}]*\\frz") then
		text=text:gsub("^({[^}]*\\frz)([%d%.%-]+)","%1"..frz)
		else
		text=addtag("\\frz"..frz,text)
		end
	    end
	    
	    if res.mod=="rotate 180" then
		if text:match("\\frz") then text=flip("frz",text) else text=addtag("\\frz180",text) end
	    end
	    
	    if res.mod=="flip hor." then
		if text:match("\\fry") then text=flip("fry",text) else text=addtag("\\fry180",text) end
	    end
	    
	    if res.mod=="flip vert." then
		if text:match("\\frx") then text=flip("frx",text) else text=addtag("\\frx180",text) end
	    end

	    if res.mod=="vector2rect." then
		text=text:gsub("\\(i?)clip%(m%s(%d-)%s(%d-)%sl%s(%d-)%s(%d-)%s(%d-)%s(%d-)%s(%d-)%s(%d-)%)","\\%1clip(%2,%3,%6,%7)") 
	    end

	    if res.mod=="rect.2vector" then
		text=text:gsub("\\(i?)clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(ii,a,b,c,d) 
		a,b,c,d=round4(a,b,c,d) return string.format("\\"..ii.."clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
	    end
	    
	    if res.mod=="find centre" then
		text=text:gsub("\\pos%([^%)]+%)","") t2=text
		text=text:gsub("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d) 
		x=round(a/2+c/2) y=round(b/2+d/2) return "\\pos("..x..","..y..")" end)
		if t2==text then 
		ADD({{class="label",label="Requires rectangular clip"}},{"OK"},{close='OK'})  ak() end
	    end
	    
	    if res.mod=="extend mask" then
		if xx==0 and yy==0 then ADD({{class="label",label="Error. Both given values are 0.\nUse the Teleporter X and Y fields."}},{"OK"},{close='OK'}) ak() end
		draw=text:match("}m ([^{]+)")
		draw2=draw:gsub("([%d%.%-]+) ([%d%.%-]+)",function(a,b) 
		if tonumber(a)>0 then ax=xx elseif tonumber(a)<0 then ax=0-xx else ax=0 end
		if tonumber(b)>0 then by=yy elseif tonumber(b)<0 then by=0-yy else by=0 end
		return a+ax.." "..b+by end)
		draw=esc(draw)
		text=text:gsub("(}m )"..draw,"%1"..draw2)
	    end
	    
	    if res.mod=="flip mask" then
		draw=text:match("}m ([^{]+)")
		draw2=draw:gsub("([%d%.%-]+) ([%d%.%-]+)",function(a,b) return 0-a.." "..b end)
		draw=esc(draw)
		text=text:gsub("(}m )"..draw,"%1"..draw2)
	    end
	    
	    if res.mod=="adjust drawing" then
		if not text:match("\\p%d") then ak() end
		-- drawing 2 clip
		if not text:match("\\i?clip") then
		  klip="\\clip("..text:match("\\p1[^}]-}(m [^{]*)")..")"
		  scx=text:match("\\fscx([%d%.]+)")	if scx==nil then scx=100 end
		  scy=text:match("\\fscy([%d%.]+)")	if scy==nil then scy=100 end
		  if text:match("\\pos") then
		    local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		    xx=round(xx) yy=round(yy)
		    coord=klip:match("\\clip%(m ([^%)]+)%)")
		    coord2=coord:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return round(a*scx/100+xx).." "..round(b*scy/100+yy) end)
		    coord=coord:gsub("%-","%%-")
		    klip=klip:gsub(coord,coord2)
		  end
		  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
		  text=addtag(klip,text)
		-- clip 2 drawing
		else
		  text=text:gsub("\\i?clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d) 
		    a,b,c,d=round4(a,b,c,d) return string.format("\\clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
		  klip=text:match("\\i?clip%((m.-)%)")
		  if text:match("\\pos") then
		  local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		    xx=round(xx) yy=round(yy)
		    coord=klip:match("m ([%d%a%s%-]+)")
		    coord2=coord:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return a-xx.." "..b-yy end)
		    coord=coord:gsub("%-","%%-")
		    klip=klip:gsub(coord,coord2)
		  end
		  text=text:gsub("(\\p1[^}]-})(m [^{]*)","%1"..klip)
		  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
		  if text:match("\\an") then text=text:gsub("\\an%d","\\an7") else text=text:gsub("^{","{\\an7") end
		  if text:match("\\fscx") then text=text:gsub("\\fscx[%d%.]+","\\fscx100") else text=text:gsub("\\p1","\\fscx100\\p1") end
		  if text:match("\\fscy") then text=text:gsub("\\fscy[%d%.]+","\\fscy100") else text=text:gsub("\\p1","\\fscy100\\p1") end
		  text=text:gsub("\\i?clip%(.-%)","")
		end
	    end
	    
	    if res.mod=="randomask" then
		draw=text:match("}m ([^{]+)")
		draw2=draw:gsub("([%d%.%-]+)",function(a) return a+math.random(0-res.post,res.post) end)
		draw=esc(draw)
		text=text:gsub("(}m )"..draw,"%1"..draw2)
	    end
	    
	    if res.mod=="randomize..." then
		if x==1 then
		  randomgui={
		    {x=0,y=0,width=1,height=1,class="label",label="randomization value"},
		    {x=1,y=0,width=1,height=1,class="floatedit",name="random",value=3},
		    {x=0,y=1,width=1,height=1,class="label",label="rounding"},
		    {x=1,y=1,width=1,height=1,class="dropdown",name="dec",items={"1","0.1","0.01","0.001"},value="0.1",},
		    {x=1,y=2,width=1,height=1,class="edit",name="randomtag"},
		    {x=1,y=3,width=1,height=1,class="edit",name="partag1",hint="pos, move, org, clip, (fad)"},
		    {x=1,y=4,width=1,height=1,class="edit",name="partag2",hint="pos, move, org, clip, (fad)"},
		    {x=0,y=2,width=1,height=1,class="checkbox",name="ntag",label="standard type tag - \\",value=true,hint="\\[tag][number]"},
		    {x=0,y=3,width=1,height=1,class="checkbox",name="ptag1",label="parenthesis tag x - \\",value=false,hint="\\tag(X,y)"},
		    {x=0,y=4,width=1,height=1,class="checkbox",name="ptag2",label="parenthesis tag y - \\",value=false,hint="\\tag(x,Y)"},
		  }
		  press,rez=ADD(randomgui,{"Randomize","Disintegrate"},{ok='Randomize',close='Disintegrate'})
		  if press=="Disintegrate" then ak() end
		  rt=rez.randomtag   rtx=rez.partag1   rty=rez.partag2
		  deci=1/tonumber(rez.dec)    rnd=rez.random
		end
		
		-- standard tags
		if rez.ntag then
		 for tag in text:gmatch("\\"..rt.."[%d%.%-]+[\\}].") do
		  tagval,mark=tag:match("([%d%.%-]+)[\\}](.)")
		  tagval1=esc(tagval)
		  rndm=math.random(-100,100)/100*rnd
		    text=text:gsub("\\"..rt..tagval1.."([\\}])"..mark,"\\"..rt..round((tagval+rndm)*deci)/deci.."%1"..mark)
		 end
		end
		
		-- parenthesis tags
		if rez.ptag1 or rez.ptag2 then
		  rndm=math.random(-100,100)/100*rnd
		  if rez.ptag1 then
		    text=text:gsub("\\"..rtx.."%(([%d%.%-]+),([%d%.%-]+)",
			function(x,y) return "\\"..rtx.."("..round((x+rndm)*deci)/deci..","..y end)
		    :gsub("\\"..rtx.."%(([%d%.%-]+,[%d%.%-]+,)([%d%.%-]+),([%d%.%-]+)",
			function(a,x,y) return "\\"..rtx.."("..a..round((x+rndm)*deci)/deci..","..y end)
		  end
		  if rez.ptag2 then
		    text=text:gsub("\\"..rty.."%(([%d%.%-]+),([%d%.%-]+)",
			function(x,y) return "\\"..rty.."("..x..","..round((y+rndm)*deci)/deci end)
		    :gsub("\\"..rty.."%(([%d%.%-]+,[%d%.%-]+,)([%d%.%-]+),([%d%.%-]+)",
			function(a,x,y) return "\\"..rty.."("..a..x..","..round((y+rndm)*deci)/deci end)
		  end
		end
	    end

	    if res.mod=="letterbreak" then
	      if not text:match("^({\\[^}]-})") then
		notag1=text:match("^([^{]+)")
		local notag2=notag1:gsub("([%a%s%d])","%1\\N")
		notag=esc(notag1)
		text=text:gsub(notag1,notag2)
	      end
	      for notag in text:gmatch("{\\[^}]-}([^{]+)") do
		local notag2=notag:gsub("([%a%s%d])","%1\\N")
		notag=esc(notag)
		text=text:gsub(notag,notag2)
	      end
	      text=text:gsub("\\N$","")
	    end
	    
	    if res.mod=="wordbreak" then
	      if not text:match("^({\\[^}]-})") then
		notag1=text:match("^([^{]+)")
		local notag2=notag1:gsub("%s+"," \\N")
		notag=esc(notag1)
		text=text:gsub(notag1,notag2)
	      end
	      for notag in text:gmatch("{\\[^}]-}([^{]+)") do
		local notag2=notag:gsub("%s+"," \\N")
		notag=esc(notag)
		text=text:gsub(notag,notag2)
	      end
	      text=text:gsub("\\N$","")
	    end
	    
	line.text=text
        subs[i]=line
    end
end

function movetofbf(subs,sel)
    fra={}
    for i=#sel,1,-1 do
    progress(string.format("Dissecting line... %d/%d",(#sel-i+1),#sel))
        line=subs[sel[i]]
        text=subs[sel[i]].text
	styleref=stylechk(subs,line.style)
		
	    start=line.start_time
	    endt=line.end_time
	    startf=ms2fr(start)
	    endf=ms2fr(endt)
	    frames=endf-1-startf
	    frnum=frames
	    table.insert(fra,frnum)
	    l2=line
	    
		for frm=endf-1,startf,-1 do
		l2.text=text
			-- move
			if text:match("\\move") then
			    m1,m2,m3,m4=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
			    	mvstart,mvend=text:match("\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.%-]+,([%d%.%-]+),([%d%.%-]+)")
				if mvstart==nil then mvstart=fr2ms(startf)-start end
				if mvend==nil then mvend=fr2ms(endf-1)-start end
				mstartf=ms2fr(start+mvstart)		mendf=ms2fr(start+mvend)
				moffset=mstartf-startf		if moffset<0 then moffset=0 end
				mlimit=mendf-startf
				mpart=frnum-moffset
				mwhole=mlimit-moffset
			    pos1=math.floor((((m3-m1)/mwhole)*mpart+m1)*100)/100
			    pos2=math.floor((((m4-m2)/mwhole)*mpart+m2)*100)/100
				if mpart<0 then pos1=m1 pos2=m2 end
				if mpart>mlimit-moffset then pos1=m3 pos2=m4 end
			    l2.text=text:gsub("\\move%([^%)]*%)","\\pos("..pos1..","..pos2..")")
			end
			--fade
			if text:match("\\fad%(") then
			    f1,f2=text:match("\\fad%(([%d%.]+),([%d%.]+)")
			    	fad_in=ms2fr(start+f1)
				fad_out=ms2fr(endt-f2)
				foffset=fad_out-startf-1
				fendf=fad_in-startf
				fpart=frnum-foffset
				fwhole=endf-fad_out
				faf="&HFF&"	fa0="&H00&"
				  -- existing alpha
				  linealfa=text:match("^{[^}]-\\alpha(&H%x%x&)")
				  if linealfa~=nil then fa0=linealfa l2.text=l2.text:gsub("^({[^}]-)\\alpha&H%x%x&","%1") end
				fa1=interpolate_alpha(1/(fendf+3), faf, fa0)
				fa2=interpolate_alpha(1/(fwhole+3), faf, fa0)
			    val_in=interpolate_alpha(frnum/fendf, fa1, fa0)
			    val_out=interpolate_alpha(fpart/fwhole, fa0, fa2)
				if frnum<fad_in-startf then alfa=val_in
				elseif frnum>fad_out-startf then alfa=val_out
				else alfa=fa0 end
			    l2.text=l2.text:gsub("\\fad%([^%)]*%)","\\alpha"..alfa)
				-- other alphas
				for al=1,4 do
				  alphax=text:match("^{[^}]-\\"..al.."a(&H%x%x&)")
				  if alphax~=nil then
				    val_in=interpolate_alpha(frnum/fendf, fa1, alphax)
				    val_out=interpolate_alpha(fpart/fwhole, alphax, fa2)
					if frnum<fad_in-startf then alfa=val_in
					elseif frnum>fad_out-startf then alfa=val_out
					else alfa=alphax end
				  end
				l2.text=l2.text:gsub("^({[^}]-)\\"..al.."a&H%x%x&","%1\\"..al.."a"..alfa)
				end
			end
		   
		    tags=l2.text:match("^{[^}]*}")
		    if tags==nil then tags="" end
		    -- transforms
		    if tags:match("\\t") then
			l2.text=l2.text:gsub("^({\\[^}]-})",function(tg) return cleantr(tg) end)
			terraform(tags)
			
			l2.text=l2.text
			:gsub("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))","")
			:gsub("(\\t%([^%(%)]-%))","")
			:gsub("^({[^}]*)}","%1"..ftags.."}")
			:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
		    end
		    
		    l2.start_time=fr2ms(frm)
		    l2.end_time=fr2ms(frm+1)
		    subs.insert(sel[i]+1,l2) --table.insert(sel,sel[i]+frnum+1)
		    frnum=frnum-1
		end
		line.end_time=endt
		line.comment=true
	line.text=text
	subs[sel[i]]=line
	--table.sort(sel)
	if res.delfbf then subs.delete(sel[i]) end
    end
    -- selection
    sel2={}
    if res.delfbf then fakt=0 else fakt=1 end
    for s=#sel,1,-1 do
	sfr=fra[#sel-s+1]
	-- shift new sel
	for s2=#sel2,1,-1 do
	    sel2[s2]=sel2[s2]+sfr+fakt
	end
	-- add to new sel
	for f=1,sfr+fakt do
	    table.insert(sel2,sel[s]+f)
	end
	-- add orig line
	if res.delfbf then table.insert(sel2,sel[s]) end
    end
    sel=sel2
    return sel
end

function terraform(tags)
	tra=tags:match("(\\t%([^%(%)]-%))")
	if tra==nil then tra=text:match("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))") end	--aegisub.log("\ntra: "..tra)
	trstart,trend=tra:match("\\t%((%d+),(%d+)")
	--frdiff=(fr2ms(startf+1)-fr2ms(startf))/2
	if trstart==nil or trstart=="0" then trstart=fr2ms(startf)-start end
	if trend==nil or trend=="0" then trend=fr2ms(endf-1)-start end
	tfstartf=ms2fr(start+trstart)		tfendf=ms2fr(start+trend)
	toffset=tfstartf-startf		if toffset<0 then toffset=0 end
	tlimit=tfendf-startf
	tpart=frnum-toffset
	twhole=tlimit-toffset
	nontra=tags:gsub("\\t%b()","")
	ftags=""
	-- most tags
	for tg, valt in tra:gmatch("\\(%a+)([%d%.%-]+)") do
		val1=nil
		if nontra:match(tg) then val1=nontra:match("\\"..tg.."([%d%.%-]+)") end
		if val1==nil then
		if tg=="bord" or tg=="xbord" or tg=="ybord" then val1=styleref.outline end
		if tg=="shad" or tg=="xshad" or tg=="yshad" then val1=styleref.shadow end
		if tg=="fs" then val1=styleref.fontsize end
		if tg=="fsp" then val1=styleref.spacing end
		if tg=="frz" then val1=styleref.angle end
		if tg=="fscx" then val1=styleref.scale_x end
		if tg=="fscy" then val1=styleref.scale_y end
		if tg=="blur" or tg=="be" or tg=="fax" or tg=="fay" or tg=="frx" or tg=="fry" then val1=0 end
		end
		valf=math.floor((((valt-val1)/twhole)*tpart+val1)*100)/100
		if tpart<0 then valf=val1 end
		if tpart>tlimit-toffset then valf=valt end
		ftags=ftags.."\\"..tg..valf
		--aegisub.log("\n val1: "..val1.."  valf: "..valf.."  tpart: "..tpart.."  twhole: "..twhole)
	end
	-- clip
	if tra:match("\\clip") then
	c1,c2,c3,c4=nontra:match("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
	k1,k2,k3,k4=tra:match("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
	tc1=math.floor((((k1-c1)/twhole)*tpart+c1)*100)/100
	tc2=math.floor((((k2-c2)/twhole)*tpart+c2)*100)/100
	tc3=math.floor((((k3-c3)/twhole)*tpart+c3)*100)/100
	tc4=math.floor((((k4-c4)/twhole)*tpart+c4)*100)/100
	if tpart<0 then tc1=c1 tc2=c2 tc3=c3 tc4=c4 end
	if tpart>tlimit-toffset then tc1=k1 tc2=k2 tc3=k3 tc4=k4 end
	ftags=ftags.."\\clip("..tc1..","..tc2..","..tc3..","..tc4..")"
	end
	-- colour/alpha
	tra=tra:gsub("\\1c","\\c")
	nontra=nontra:gsub("\\1c","\\c")
	for tg, valt in tra:gmatch("\\(%w+)(&H%x+&)") do
		val1=nil
		if nontra:match(tg) then val1=nontra:match("\\"..tg.."(&H%x+&)") end
		if val1==nil then
		if tg=="c" then val1=styleref.color1:gsub("H%x%x","H") end
		if tg=="2c" then val1=styleref.color2:gsub("H%x%x","H") end
		if tg=="3c" then val1=styleref.color3:gsub("H%x%x","H") end
		if tg=="4c" then val1=styleref.color4:gsub("H%x%x","H") end
		if tg=="1a" then val1=styleref.color1:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="2a" then val1=styleref.color2:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="3a" then val1=styleref.color3:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="4a" then val1=styleref.color4:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="alpha" then val1="&H00&" end
		end
		if tg:match("c") then valf=interpolate_color(tpart/twhole, val1, valt) end
		if tg:match("a") then valf=interpolate_alpha(tpart/twhole, val1, valt) end
		if tpart<0 then valf=val1 end
		if tpart>tlimit-toffset then valf=valt end
		ftags=ftags.."\\"..tg..valf
	end
end

function joinfbflines(subs,sel)
    -- dialog
	joindialog={
	    {x=0,y=0,width=1,height=1,class="label",label="How many lines?",},
	    {x=0,y=1,width=1,height=1,class="intedit",name="join",value=2,step=1,min=2 },
	}
	P,res=ADD(joindialog,{"OK"},{ok='OK'})
    -- number
    count=1
    for x, i in ipairs(sel) do
        line=subs[i]
	line.effect=count
	if x==1 then line.effect="1" end
        subs[i]=line
	count=count+1
	if count>res.join then count=1 end
    end
    -- delete & time
    total=#sel
    for i=#sel,1,-1 do
	line=subs[sel[i]]
	if line.effect==tostring(res.join) then endtime=line.end_time end
	if i==total then endtime=line.end_time end
	if line.effect=="1" then line.end_time=endtime line.effect="" subs[sel[i]]=line 
	else subs.delete(sel[i]) table.remove(sel,#sel) end
    end
    return sel
end

function negativerot(subs,sel)
	negdialog={
	{x=0,y=0,width=1,height=1,class="checkbox",name="frz",label="frz",value=true},
	{x=1,y=0,width=1,height=1,class="checkbox",name="frx",label="frx"},
	{x=2,y=0,width=1,height=1,class="checkbox",name="fry",label="fry"},
	}
	presst,rez=ADD(negdialog,{"OK","Cancel"},{ok='OK',cancel='Cancel'})
	if presst=="Cancel" then ak() end
    for x, i in ipairs(sel) do
        line=subs[i]
	text=line.text
	if rez.frz then text=text:gsub("\\frz([%d%.]+)",function(r) return "\\frz"..r-360 end) end
	if rez.frx then text=text:gsub("\\frx([%d%.]+)",function(r) return "\\frx"..r-360 end) end
	if rez.fry then text=text:gsub("\\fry([%d%.]+)",function(r) return "\\fry"..r-360 end) end
	line.text=text
	subs[i]=line
    end
end

function transclip(subs,sel,act)
    line=subs[act]
    text=line.text
    if not text:match("\\i?clip%([%d%.%-]+,") then t_error("Error: rectangular clip required on active line.",true) end

    ctype,cc1,cc2,cc3,cc4=text:match("(\\i?clip)%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)")

    clipconfig={
    {x=0,y=0,width=2,height=1,class="label",label="   \\clip(", },
    {x=2,y=0,width=3,height=1,class="edit",name="orclip",value=cc1..","..cc2..","..cc3..","..cc4 },
    {x=5,y=0,width=1,height=1,class="label",label=")", },
    {x=0,y=1,width=2,height=1,class="label",label="\\t(\\clip(", },
    {x=2,y=1,width=3,height=1,class="edit",name="klip",value=cc1..","..cc2..","..cc3..","..cc4 },
    {x=5,y=1,width=1,height=1,class="label",label=")", },
    {x=0,y=2,width=5,height=1,class="label",label="Move x and y for new coordinates by:", },
    {x=0,y=3,width=1,height=1,class="label",label="x:", },
    {x=3,y=3,width=1,height=1,class="label",label="y:", },
    {x=1,y=3,width=2,height=1,class="floatedit",name="eks"},
    {x=4,y=3,width=1,height=1,class="floatedit",name="wai"},
    {x=0,y=4,width=5,height=1,class="label",label="Start / end / accel:", },
    {x=1,y=5,width=2,height=1,class="edit",name="accel",value="0,0,1," },
    {x=4,y=5,width=1,height=1,class="checkbox",name="two",label="use next line's clip",value=false,hint="use clip from the next line (line will be deleted)"},
    }

	buttons={"Transform","Calculate coordinates","Cancel"}
	repeat
	    if P=="Calculate coordinates" then
		xx=res.eks	yy=res.wai
		for key,val in ipairs(clipconfig) do
		    if val.name=="klip" then val.value=cc1+xx..","..cc2+yy..","..cc3+xx..","..cc4+yy end
		    if val.name=="accel" then val.value=res.accel end
		end	
	    end
	P,res=ADD(clipconfig,buttons,{ok='Transform',close='Cancel'})
	if P=="Cancel" then ak() end
	until P~="Calculate coordinates"
	if P=="Transform" then newcoord=res.klip end
	
    if res.two then
	nextline=subs[act+1]
	nextext=nextline.text
      if not nextext:match("\\i?clip%([%d%.%-]+,") then ADD({{class="label",
	label="Error: second line must contain a rectangular clip.",x=0,y=0,width=1,height=2}},{"OK"},{close='OK'}) ak()
	else
	nextclip=nextext:match("\\i?clip%(([%d%.%-,]+)%)")
	text=text:gsub("^({\\[^}]*)}","%1\\t("..res.accel..ctype.."("..nextclip.."))}")
      end
    else
	text=text:gsub("^({\\[^}]*)}","%1\\t("..res.accel..ctype.."("..newcoord.."))}")
    end	
    
    text=text:gsub("0,0,1,\\","\\")
    line.text=text
    subs[act]=line
    if res.two then subs.delete(act+1) end
end

function clone(subs,sel)
    for x, i in ipairs(sel) do
        progress(string.format("Cloning... %d/%d",x,#sel))
	line=subs[i]
        text=subs[i].text
	if not text:match("^{\\") then text=text:gsub("^","{\\}") end

	if res.cpos then
		if x==1 then posi=text:match("\\pos%(([^%)]-)%)") end
		if x>1 and text:match("\\pos") and posi~=nil	 then
		text=text:gsub("\\pos%([^%)]-%)","\\pos%("..posi.."%)")
		end
		if x>1 and not text:match("\\pos") and not text:match("\\move") and posi~=nil and res.cre then
		text=text:gsub("^{\\","{\\pos%("..posi.."%)\\")
		end
	
		if x==1 then move=text:match("\\move%(([^%)]-)%)") end
		if x>1 and text:match("\\move") and move~=nil then
		text=text:gsub("\\move%([^%)]-%)","\\move%("..move.."%)")
		end
		if x>1 and not text:match("\\move") and not text:match("\\pos") and move~=nil and res.cre then
		text=text:gsub("^{\\","{\\move%("..move.."%)\\")
		end
	end
	
	if res.corg then
	    if x==1 then orig=text:match("\\org%(([^%)]-)%)") end
	    if x>1 and orig then
		if text:match("\\org") then text=text:gsub("\\org%([^%)]-%)","\\org%("..orig.."%)")
		elseif res.cre then text=text:gsub("^({\\[^}]*)}","%1\\org%("..orig.."%)}")
		end
	    end
	end
	
	if res.copyrot then
	    if x==1 then rotz=text:match("\\frz([%d%.%-]+)") rotx=text:match("\\frx([%d%.%-]+)") roty=text:match("\\fry([%d%.%-]+)") end

	    if x>1 then
	      if rotz and text:match("\\frz") then text=text:gsub("\\frz[%d%.%-]+","\\frz"..rotz)
	      elseif rotz and not text:match("\\frz") and res.cre then text=addtag("\\frz"..rotz,text) end
	      if rotx and text:match("\\frx") then text=text:gsub("\\frx[%d%.%-]+","\\frx"..rotx)
	      elseif rotx and not text:match("\\frx") and res.cre then text=addtag("\\frx"..rotx,text) end
	      if roty and text:match("\\fry") then text=text:gsub("\\fry[%d%.%-]+","\\fry"..roty)
	      elseif roty and not text:match("\\fry") and res.cre then text=addtag("\\fry"..roty,text) end
	    end
	end
	
	if res.cclip then
	    -- line 1 - copy
	    if x==1 and text:match("\\i?clip") then
		ik,klip=text:match("\\(i?)clip%(([^%)]-)%)")
		if klip:match("m") then type1="vector" else type1="normal" end
	    end
	    -- lines 2+ - paste / replace
	    if x>1 and text:match("\\i?clip") and klip~=nil then
		ik2,klip2=text:match("\\(i?)clip%(([^%)]-)%)")
		if res.klipmatch then kmatch=ik else kmatch=ik2 end
		if klip2:match("m") then type2="vector" klipv=klip2 else type2="normal" end
		if text:match("\\(i?)clip.-\\(i?)clip") then doubleclip=true ikv,klipv=text:match("\\(i?)clip%((%d?,?m[^%)]-)%)")
		else doubleclip=false end
		if res.combine and type1=="vector" and text:match("\\(i?clip)%(%d?,?m[^%)]-%)") then nklip=klipv.." "..klip else nklip=klip end
		-- 1 clip, stack
		if res.stack and type1~=type2 and not doubleclip then 
		  text=text:gsub("^({\\[^}]*)}","%1\\"..ik.."clip%("..nklip.."%)}")
		-- 2 clips -> not stack
		elseif doubleclip then
		  if type1=="normal" then text=text:gsub("\\(i?clip)%([%d%.,%-]-%)","\\%1%("..nklip.."%)") end
		  if type1=="vector" then text=text:gsub("\\(i?clip)%(%d?,?m[^%)]-%)","\\%1%("..nklip.."%)") end
		-- 1 clip, not stack
		elseif type1==type2 and not doubleclip or not res.stack and not doubleclip then
		  text=text:gsub("\\i?clip%([^%)]-%)","\\"..kmatch.."clip%("..nklip.."%)")
		end
	    end
	    -- lines 2+ / paste / create
	    if x>1 and not text:match("\\i?clip") and klip~=nil and res.cre then
		text=text:gsub("^({\\[^}]*)}","%1\\"..ik.."clip%("..klip.."%)}")
	    end
	end
	
	if res.ctclip then
		if x==1 and text:match("\\t%([%d%.,]*\\i?clip") then
		tklip=text:match("\\t%([%d%.,]*\\i?clip%(([^%)]-)%)")
		end
		if x>1 and text:match("\\i?clip") and tklip~=nil then
		text=text:gsub("\\t%(([%d%.,]*)\\(i?clip)%([^%)]-%)","\\t%(%1\\%2%("..tklip.."%)")
		end
		if x>1 and not text:match("\\t%([%d%.,]*\\i?clip") and tklip~=nil and res.cre then
		text=text:gsub("^({\\[^}]*)}","%1\\t%(\\clip%("..tklip.."%)%)}")
		end
	end

	text=text
	:gsub("\\\\","\\")
	:gsub("\\}","}")
	:gsub("{}","")
	
	line.text=text
	subs[i]=line
    end
    posi, move, orig, klip, tklip=nil
end

function teleport(subs,sel)
    tpfx=0    tpfy=0
    if res.tpmod then
	telemod={
	{x=2,y=0,width=2,height=1,class="label",label=" Warped Teleportation"},
	{x=2,y=1,width=3,height=1,class="floatedit",name="eggs",hint="X"},
	{x=2,y=2,width=3,height=1,class="floatedit",name="why",hint="Y"},
	}
	press,rez=ADD(telemod,
	{"Warped Teleport","Disintegrate"},{close='Disintegrate'})
	if press=="Disintegrate" then ak() end
	tpfx=rez.eggs	tpfy=rez.why
    end
    for x, i in ipairs(sel) do
        progress(string.format("Teleporting... %d/%d",x,#sel))
	line=subs[i]
        text=line.text
	style=line.style
	xx=res.eks
	yy=res.wai
	fx=tpfx*(x-1)
	fy=tpfy*(x-1)

	if res.tppos then
	    if res.autopos and not text:match("\\pos") and not text:match("\\move") then text=getpos(subs,text) end
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",
	    function(a,b) return "\\pos("..a+xx+fx..","..b+yy+fy..")" end)
	end

	if res.tporg then
	    text=text:gsub("\\org%(([%d%.%-]+),([%d%.%-]+)%)",
	    function(a,b) return "\\org("..a+xx+fx..","..b+yy+fy..")" end)
	end

	if res.tpmov then
	    text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
	    function(a,b,c,d) return "\\move("..a+xx+fx.. "," ..b+yy+fy.. "," ..c+xx+fx.. "," ..d+yy+fy end)
	end

	if res.tpclip then
	    text=text:gsub("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
	    function(a,b,c,d) return "clip("..a+xx+fx..","..b+yy+fy..","..c+xx+fx..","..d+yy+fy end)
	    
	    if text:match("clip%(m [%d%a%s%-%.]+%)") then
	    ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
	    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+xx+fx.." "..b+yy+fy end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub("clip%(m "..ctext,"clip(m "..ctext2)
	    end
	    
	    if text:match("clip%(%d+,m [%d%a%s%-%.]+%)") then
	    fac,ctext=text:match("clip%((%d+),m ([%d%a%s%-%.]+)%)")
	    factor=2^(fac-1)
	    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+factor*xx+fx.." "..b+factor*yy+fy end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub(",m "..ctext,",m "..ctext2)
	    end
	end

	if res.tpmask then
	    draw=text:match("}m ([^{]+)")
	    draw2=draw:gsub("([%d%.%-]+) ([%d%.%-]+)",function(a,b) return round(a+xx+fx).." "..round(b+yy+fy) end)
	    draw=esc(draw)
	    text=text:gsub("(}m )"..draw,"%1"..draw2)
	end

	line.text=text
	subs[i]=line
    end
end


--	reanimatools	--

function round(a) a=math.floor(a+0.5) return a end

function round4(a,b,c,d)
	a=math.floor(a+0.5)
	b=math.floor(b+0.5)
	c=math.floor(c+0.5)
	d=math.floor(d+0.5)
	return a,b,c,d
end

function getpos(subs, text)
    for g=1, #subs do
        if subs[g].class=="info" then
	    local k=subs[g].key
	    local v=subs[g].value
	    if k=="PlayResX" then resx=v end
	    if k=="PlayResY" then resy=v end
        end
	if resx==nil then resx=0 end
	if resy==nil then resy=0 end
        if subs[g].class=="style" then
            local st=subs[g]
	    if st.name==line.style then
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
	    break
	    end
        end
    end
    if horz>0 and vert>0 then 
	if not text:match("^{\\") then text="{\\rel}"..text end
	text=text:gsub("^({\\[^}]-)}","%1\\pos("..horz..","..vert..")}") :gsub("\\rel","")
    end
    return text
end

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

function cleantr(tags)
	trnsfrm=""
	for t in tags:gmatch("\\t%b()") do trnsfrm=trnsfrm..t end
	tags=tags:gsub("\\t%b()","")

	cleant=""
	for ct in trnsfrm:gmatch("\\t%((\\[^%(%)]-)%)") do cleant=cleant..ct end
	for ct in trnsfrm:gmatch("\\t%((\\[^%(%)]-%b()[^%)]-)%)") do cleant=cleant..ct end
	trnsfrm=trnsfrm:gsub("\\t%(\\[^%(%)]+%)","")
	trnsfrm=trnsfrm:gsub("\\t%((\\[^%(%)]-%b()[^%)]-)%)","")
	trnsfrm="\\t("..cleant..")"..trnsfrm
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

function stylechk(subs,stylename)
  for i=1, #subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if stylename==st.name then styleref=st break end
    end
  end
  return styleref
end

function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end

function flip(rot,text)
    for rotation in text:gmatch("\\"..rot.."([%d%.%-]+)") do
	rotation=tonumber(rotation)
	if rotation<180 then newrot=rotation+180 end
	if rotation>=180 then newrot=rotation-180 end
	text=text:gsub(rot..rotation,rot..newrot)
    end
    return text
end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  aegisub.dialog.display({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then aegisub.cancel() end
end

function logg(m) aegisub.log("\n "..m) end

function info(subs)
    for i=1,#subs do
      if subs[i].class=="info" then
	    local k=subs[i].key
	    local v=subs[i].value
	    if k=="PlayResX" then resx=v end
	    if k=="PlayResY" then resy=v end
      end
      if subs[i].class=="dialogue" then break end
    end
end

-- The Typesetter's Guide to the Hyperdimensional Relocator.
function guide()
intro=[[
Introduction

Hyperdimensional Relocator offers a plethora of functions,
focusing primarily on \pos, \move, \org, \clip, and rotations.
Anything related to positioning, movement, changing shape, etc.,
Relocator aims to make it happen.

]].."Current version: "..script_version.."\n\nUpdate locations:\n"..script_url1.."\n"..script_url2

cannon=[[
'Align X' means all selected \pos tags will have the same given X coordinate. Same with 'Align Y' for Y.
   Useful for multiple signs on screen that need to be aligned horizontally/vertically
   or mocha signs that should move horizontally/vertically.

'align with first' uses X or Y from the first line.

Horizontal Mirror: Duplicates the line and places it horizontally across the screen, mirrored around the middle.
   If you input a number, it will mirror around that coordinate instead,
   so if you have \pos(300,200) and input is 400, the mirrored result will be \pos(500,200).
Vertical Mirror is the logical vertical counetrpart. 'delete orig. line' will delete the original line.

Org to Fax: calculates \fax from the line between \pos and \org coordinates.
Clip to Fax: calculates \fax from the line between the first 2 points of a vectorial clip.
   Both of these work with \frz but not with \frx and \fry. Also, \fscx must be the same as \fscy.
   If the clip has 4 points, points 3-4 are used to calculate fax for the last character (for grad-by-char).
   See blog post for more info - http://unanimated.xtreemhost.com/itw/tsblok.htm#fax

Clip to Frz: calculates \frz from the first 2 points of a vectorial clip. First point is start of text.\n   If the clip has 4 points, the frz is average from 1-2 and 3-4. (Both lines must be in the same direction.)

Shake: Apply to fbf lines with \pos tags to create a shaking effect.
   Input radius for how many pixels the sign may deflect from the original position.

Shake rotation: Adds shaking effect to rotations. Degrees for frz from Repositioning Field, x and y from Teleporter.

Shadow Layer: Creates shadow as a new layer. For offset it uses in this order of priority:
   1. value from Positron or Teleporter (xshad, yshad). 2. shadow value from the line. 3. shadow from style.
   
Space out letters: Set a distance, and line will be split into letters with that distance between them.
   Value 1 = regular distance (only split). You should expect about 1% inaccuracy. \an2/5/8 works best.
   With a rectangular clip, the script tries to fit the text from side to side of the clip.
   fscx is supported, fs isn't, nor are rotations, move, linebreaks, and other things. Inline tags should work.

'rotate' will flip the text accordingly for the mirror functions. It also adds \frz to 'shake'.
'scaling' randomizes fscx/y with 'shake'. Value of 6 gives 0.625 to 1.6 times current value. (Teleporter input.)
'layers' will keep position/rotations the same for all layers with 'shake'. (Same value for same start time.)
'smooth' will make shaking smoother.]]

travel=[[
'Horizontal' move means y2 will be the same as y1 so that the sign moves in a straight horizontal manner. \nSame principle for 'vertical.'

Transmove: Main function: create \move from two lines with \pos.
   Duplicate your line and position the second one where you want the \move the end. 
   Script will create \move from the two positions.
   Second line will be deleted by default; it's there just so you can comfortably set the final position.
   Extra function: to make this a lot more awesome, this can create transforms.
   Not only is the second line used for \move coordinates, but also for transforms.
   Any tag on line 2 that's different from line 1 will be used to create a transform on line 1.
   So for a \move with transforms you can set the initial sign and then the final sign while everything is static.
   You can time line 2 to just the last frame. The script only uses timecodes from line 1.
   Text from line 2 is also ignored (assumed to be same as line 1).
   You can time line 2 to start after line 1 and check 'keep both.'
   That way line 1 transforms into line 2 and the sign stays like that for the duration of line 2.
   'Rotation acceleration' - like with fbf-transform, this ensures that transforms of rotations will go the shortest way,
   thus going only 4 degrees from 358 to 2 and not 356 degrees around.
   If the \pos is the same on both lines, only transforms will be applied.
   Logically, you must NOT select 2 consecutive lines when you want to run this, 
   though you can select every other line.

Multimove: when first line has \move and the other lines have \pos, \move is calculated from the first line for the others.

Shiftmove: like teleporter, but only for the 2nd set of coordinates, ie x2, y2. Uses input from the Teleporter section.

Shiftstart: similarly, this only shifts the initial \move coordinates.

Reverse Move: switches the coordinates, reversing the movement direction.

Move Clip: moves regular clip along with \move using \t\clip.]]

morph=[[
Round Numbers: rounds coordinates for pos, move, org and clip depending on the 'Round' submenu.

Joinfbflines: Select frame-by-frame lines, input numer X when asked, and each X lines will be joined into one.
   (same way as with 'Join (keep first)' from the right-click menu)

KillMoveTimes: nukes the timecodes from a \move tag.
FullMoveTimes: sets the timecodes for \move to the first and last frame.
FullTransTimes: sets the timecodes for \t to the first and last frame.

Move V. Clip: Moves vectorial clip on fbf lines based on \pos tags.
   Note: For decimals on v-clip coordinates: xy-vsfilter OK; libass rounds them; regular vsfilter fails completely.

Set Origin: set \org based off of \pos using teleporter coordinates.

FReeZe: adds \frz with the value from the -frz- menu (the only point being that you get exact, round values).

Rotate/flip: rotates/flips by 180 dgrees from current value.

Negative rot: keeps the same rotation, but changes to negative number, like 350 -> -10, which helps with transforms.

Vector2rect/Rect.2vector: converts between rectangular and vectorial clips.

Find Centre: A useless function that sets \pos in the centre of a rectangular clip.

Randomize: randomizes values of given tags. With \fs50 and value 4 you can get fs 46-54.

Letterbreak: creates vertical text by putting a linebreak after each letter.
Wordbreak: replaces spaces with linebreaks.]]

morph2fbf=[[
Line2fbf:

Splits a line frame by frame, ie. makes a line for each frame.
If there's \move, it calculates \pos tags for each line.
If there are transforms, it calculates values for each line.
Conditions: Only deals with initial block of tags. Works with only one set of transforms.
   Move and transforms can have timecodes. 
   Missing timecodes will be counted as the ones you get with FullMoveTimes/FullTransTimes.
   \fad is now somewhat supported too, but avoid having any alpha transforms at the same time.
   Timecodes must be exact (even for \fad, for precision), or the start of the transform/move may be a frame off.]]

morphorg=[[
Calculate Origin:

This calculates \org from a tetragonal vectorial clip you draw.
Draw a vectorial clip with 4 points, aligned to a surface you need to put your sign on.
The script will calculate the vanishing points for X and Y and give you \org.
Make the clip as large as you can, since on a smaller one any inaccuracies will be more obvious.
If you draw it well enough, the accuracy of the \org point should be pretty decent.
(It won't work when both points on one side are lower than both points on the other side.)
See blog post from 2013-11-27 for more details: http://unanimated.xtreemhost.com/itw/tsblok.htm
]] 

morphclip=[[
Transform Clip:

Go from \clip(x1,y1,x2,y2) to \clip(x1,y1,x2,y2)\t(\clip(x3,y3,x4,y4)).
Coordinates are read from the line.
You can set by how much x and y should change, and new coordinates will be calculated.

'use next line's clip' allows you to use clip from the next line.
   Create a line after your current one (or just duplicate), set the clip you want to transform to on it,
   and check 'use next line's clip'.
   The clip from the next line will be used for the transform, and the line will be deleted.]]

morphmasks=[[
Extend Mask: Use Teleporter X and Y fields to extend a mask in either or both directions.
   This is mainly intended to easily convert something like a rounded square to another rounded rectangle.
   Works optimally with 0,0 coordinate in the centre. May do weird things with curves.
   When all coordinates are to one side from 0,0, then this works like shifting.
   
Flip mask: Flips a mask so that when used with its non-flipped counterpart, they create hollow space.
   For example you have a rounded square. Duplicate it, extend one by 10 pixels in each direction, flip it,
   and then merge them. You'll get a 10 px outline.

Adjust Drawing: (You must not have an unrelated clip in the line.)
   1. Creates a clip that copies the drawing.
   2. You adjust points with clip tool.
   3. Applies new coordinates to the drawing.

Randomask: Moves points in a drawing, each in a random direction, by a factor taken from the positioning field.]]

cloan=[[
This copies specified tags from first line to the others.
Options are position, move, origin point, clip, and rotations.

replicate missing tags: creates tags if they're not present

stack clips: allows stacking of 1 normal and 1 vector clip in one line

match type: if current clip/iclip doesn't match the first line, it will be switched to match

cv (combine vectors): if the first line has a vector clip, then for all other lines with vector clips 
   the vectors will be combined into 1 clip

copyrot: copies all rotations]]

port=[[
Teleport shifts coordinates for selected tags (\pos\move\org\clip) by given X and Y values.
It's a simple but powerful tool that allows you to move whole gradients, mocha-tracked signs, etc.

Note that the Teleporter fields are also used for some other functions, like Shiftstart and Shiftmove.
These functions don't use the 'Teleportation' button but the one for whatever part of HR they belong to.

'mod' allows you to add an extra factor applied line by line.
For example if you set '5' for 'X', things will shift by extra 5 pixels for each new line.]]

stg_top={x=0,y=0,width=1,height=1,class="label",
label="The Typesetter's Guide to the Hyperdimensional Relocator.                                                           "}

stg_toptop={x=1,y=0,width=1,height=1,class="label",label="Choose topic below."}
stg_topos={x=1,y=0,width=1,height=1,class="label",label="  Repositioning Field"}
stg_toptra={x=1,y=0,width=1,height=1,class="label",label="          Soul Bilocator"}
stg_toporph={x=1,y=0,width=1,height=1,class="label",label="   Morphing Grounds"}
stg_topseq={x=1,y=0,width=1,height=1,class="label",label="   Cloning Laboratory"}
stg_toport={x=1,y=0,width=1,height=1,class="label",label="           Teleportation"}

stg_intro={x=0,y=1,width=2,height=9,class="textbox",name="gd",value=intro}
stg_cannon={x=0,y=1,width=2,height=22,class="textbox",name="gd",value=cannon}
stg_travel={x=0,y=1,width=2,height=19,class="textbox",name="gd",value=travel}
stg_morph={x=0,y=1,width=2,height=17,class="textbox",name="gd",value=morph}
stg_morph2fbf={x=0,y=1,width=2,height=8,class="textbox",name="gd",value=morph2fbf}
stg_morphorg={x=0,y=1,width=2,height=8,class="textbox",name="gd",value=morphorg}
stg_morphclip={x=0,y=1,width=2,height=8,class="textbox",name="gd",value=morphclip}
stg_morpmsk={x=0,y=1,width=2,height=10,class="textbox",name="gd",value=morphmasks}
stg_cloan={x=0,y=1,width=2,height=9,class="textbox",name="gd",value=cloan}
stg_port={x=0,y=1,width=2,height=8,class="textbox",name="gd",value=port}

cp_main={"Positron Cannon","Hyperspace Travel","Metamorphosis","Cloning Sequence","Teleportation","Disintegrate"}
cp_back={"Warp Back"}
cp_morph={"Warp Back","Metamorphosis","Line2fbf","Calculate Origin","Transform Clip","Masks/drawings"}
esk1={close='Disintegrate'}
esk2={cancel='Warp Back'}
stg={stg_top,stg_toptop,stg_intro} control_panel=cp_main esk=esk1
repeat
	stg={stg_top,stg_toptop,stg_intro} control_panel=cp_main esk=esk1
	if press=="Positron Cannon" then 	stg={stg_top,stg_topos,stg_cannon} control_panel=cp_back esk=esk2 end
	if press=="Hyperspace Travel" then 	stg={stg_top,stg_toptra,stg_travel} control_panel=cp_back esk=esk2 end
	if press=="Metamorphosis" then 	stg={stg_top,stg_toporph,stg_morph} control_panel=cp_morph esk=esk2 end
	if press=="Cloning Sequence" then 	stg={stg_top,stg_topseq,stg_cloan} control_panel=cp_back esk=esk2 end
	if press=="Teleportation" then 	stg={stg_top,stg_toport,stg_port} control_panel=cp_back esk=esk2 end
	if press=="Line2fbf" then 		stg={stg_top,stg_toporph,stg_morph2fbf} control_panel=cp_morph esk=esk2 end
	if press=="Calculate Origin" then 	stg={stg_top,stg_toporph,stg_morphorg} control_panel=cp_morph esk=esk2 end
	if press=="Transform Clip" then 	stg={stg_top,stg_toporph,stg_morphclip} control_panel=cp_morph esk=esk2 end
	if press=="Masks/drawings" then 		stg={stg_top,stg_toporph,stg_morpmsk} control_panel=cp_morph esk=esk2 end
	if press=="Warp Back" then 		stg={stg_top,stg_toptop,stg_intro} control_panel=cp_main esk=esk1 end
press,rez=ADD(stg,control_panel,esk)
until press=="Disintegrate"
if press=="Disintegrate" then ak() end
end

--	Config Stuff	--
function saveconfig()
hrconf="Hyperconfigator\n\n"
  for key,val in ipairs(hyperconfig) do
    if val.class=="floatedit" or val.class=="dropdown" then
      hrconf=hrconf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="save" then
      hrconf=hrconf..val.name..":"..tf(res[val.name]).."\n"
    end
  end
hyperkonfig=ADP("?user").."\\relocator.conf"
file=io.open(hyperkonfig,"w")
file:write(hrconf)
file:close()
ADD({{class="label",label="Config saved to:\n"..hyperkonfig}},{"OK"},{close='OK'})
end

function loadconfig()
rconfig=ADP("?user").."\\relocator.conf"
file=io.open(rconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	  for key,val in ipairs(hyperconfig) do
	    if val.class=="floatedit" or val.class=="checkbox" or val.class=="dropdown" then
	      if konf:match(val.name) then val.value=detf(konf:match(val.name..":(.-)\n")) end
	    end
	  end
    end
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

function relocator(subs,sel,act)
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
ms2fr=aegisub.frame_from_ms
fr2ms=aegisub.ms_from_frame
keyframes=aegisub.keyframes()
rin=subs[act]	tk=rin.text
if tk:match"\\move" then 
m1,m2,m3,m4=tk:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)") M1=m3-m1 M2=m4-m2 mlbl="mov: "..M1..","..M2
else mlbl="" end
hyperconfig={
    {x=11,y=0,width=2,height=1,class="label",label="Teleportation"},
    {x=11,y=1,width=3,height=1,class="floatedit",name="eks",hint="X"},
    {x=11,y=2,width=3,height=1,class="floatedit",name="wai",hint="Y"},

    {x=0,y=0,width=3,height=1,class="label",label="Repositioning Field",},
    {x=0,y=1,width=2,height=1,class="dropdown",name="posi",value=posdrop,
        items={"Align X","Align Y","org to fax","clip to fax","clip to frz","horizontal mirror","vertical mirror","shake","shake rotation","shadow layer","space out letters"}},
    {x=0,y=2,width=2,height=1,class="floatedit",name="post",value=0},
    {x=0,y=3,width=1,height=1,class="checkbox",name="first",label="by first",value=true,hint="align with first line"},
    {x=1,y=3,width=1,height=1,class="checkbox",name="rota",label="rotate",value=false,},
    {x=0,y=4,width=1,height=1,class="checkbox",name="layers",label="layers",value=true,hint="synchronize shaking for all layers"},
    {x=1,y=4,width=1,height=1,class="checkbox",name="smo",label="smooth",value=false,hint="smoothen shaking"},
    {x=3,y=4,width=1,height=1,class="checkbox",name="sca",label="scaling",value=false,hint="add scaling to shake"},
    {x=0,y=5,width=2,height=1,class="checkbox",name="space",label="space travel guide",value=false,},
    
    {x=3,y=0,width=2,height=1,class="label",label="Soul Bilocator"},
    {x=3,y=1,width=1,height=1,class="dropdown",name="move",value=movedrop,
	items={"transmove","horizontal","vertical","multimove","rvrs. move","shiftstart","shiftmove","move clip"}},
    {x=3,y=2,width=1,height=1,class="checkbox",name="keep",label="keep both",value=false,hint="keeps both lines for transmove"},
    {x=3,y=3,width=3,height=1,class="checkbox",name="rotac",label="rotation acceleration",value=true,hint="transmove option"},
    {x=3,y=5,width=3,height=1,class="label",name="moo",label=mlbl},
    
    {x=5,y=0,width=2,height=1,class="label",label="Morphing Grounds",},
    {x=5,y=1,width=2,height=1,class="dropdown",name="mod",value=morphdrop,
	items={"round numbers","line2fbf","join fbf lines","killmovetimes","fullmovetimes","fulltranstimes","move v. clip","set origin","calculate origin","transform clip","FReeZe","rotate 180","flip hor.","flip vert.","negative rot","vector2rect.","rect.2vector","find centre","extend mask","flip mask","adjust drawing","randomask","randomize...","letterbreak","wordbreak"}},
    {x=5,y=2,width=1,height=1,class="label",label="Round:",},
    {x=6,y=2,width=1,height=1,class="dropdown",name="rnd",items={"all","pos","move","org","clip","mask"},value="all"},
    {x=6,y=3,width=1,height=1,class="dropdown",name="freeze",
	items={"-frz-","30","45","60","90","120","135","150","180","-30","-45","-60","-90","-120","-135","-150"},value="-frz-"},
    {x=5,y=4,width=2,height=1,class="checkbox",name="delfbf",label="delete orig. line",value=true,hint="delete the original line for line2fbf / mirror functions"},
    
    {x=7,y=0,width=3,height=1,class="label",label="Cloning Laboratory",},
    {x=7,y=1,width=2,height=1,class="checkbox",name="cpos",label="\\posimove",value=true },
    {x=9,y=1,width=1,height=1,class="checkbox",name="corg",label="\\org",value=true },
    {x=7,y=2,width=1,height=1,class="checkbox",name="cclip",label="\\[i]clip",value=true },
    {x=8,y=2,width=2,height=1,class="checkbox",name="ctclip",label="\\t(\\[i]clip)",value=true },
    {x=7,y=5,width=4,height=1,class="checkbox",name="cre",label="replicate missing tags",value=true },
    {x=7,y=3,width=2,height=1,class="checkbox",name="stack",label="stack clips",value=false },
    {x=7,y=4,width=1,height=1,class="checkbox",name="copyrot",label="copyrot",value=false,hint="Cloning - copy rotations" },
    {x=9,y=3,width=3,height=1,class="checkbox",name="klipmatch",label="match type    ",value=false },
    {x=9,y=4,width=3,height=1,class="checkbox",name="combine",label="comb. vect.",value=false,hint="Cloning - combine vectors" },
    
    {x=12,y=3,width=1,height=1,class="checkbox",name="tppos",label="pos",value=true },
    {x=12,y=4,width=1,height=1,class="checkbox",name="tpmov",label="move",value=true },
    {x=13,y=3,width=1,height=1,class="checkbox",name="tporg",label="org",value=true },
    {x=13,y=4,width=1,height=1,class="checkbox",name="tpclip",label="clip",value=true },
    {x=12,y=5,width=1,height=1,class="checkbox",name="tpmask",label="mask",value=false },
    {x=13,y=0,width=1,height=1,class="checkbox",name="tpmod",label="mod",value=false },
    {x=11,y=5,width=1,height=1,class="checkbox",name="autopos",label="p",value=true,hint="Teleport position when \\pos tags missing" },
    {x=13,y=5,width=1,height=1,class="label",label="  [v"..script_version.."]",},
    
    {x=6,y=5,width=1,height=1,class="checkbox",name="save",label="Save",value=false,hint="Save current configuration"},
} 

	loadconfig()
	if remember then
	  for key,val in ipairs(hyperconfig) do
	    if val.name=="posi" then val.value=lastpos end
	    if val.name=="move" then val.value=lastmove end
	    if val.name=="mod" then val.value=lastmod end
	  end
	end
	P,res=ADD(hyperconfig,
	{"Positron Cannon","Hyperspace Travel","Metamorphosis","Cloning Sequence","Teleportation","Disintegrate"},{cancel='Disintegrate'})
	if P=="Disintegrate" then ak() end
	
	remember=true
	lastpos=res.posi	lastmove=res.move	lastmod=res.mod
		
	if P=="Positron Cannon" then if res.space then guide(subs,sel) else sel=positron(subs,sel) end end
	if P=="Hyperspace Travel" then
	    if res.move=="multimove" then multimove (subs,sel) else bilocator(subs,sel) end
	end
	if P=="Metamorphosis" then
	    aegisub.progress.title(string.format("Morphing..."))
	    if res.save then saveconfig()
	    elseif res.mod=="line2fbf" then sel=movetofbf(subs,sel) 
	    elseif res.mod=="transform clip" then transclip(subs,sel,act)
	    elseif res.mod=="join fbf lines" then joinfbflines(subs,sel)
	    elseif res.mod=="negative rot" then negativerot(subs,sel)
	    else modifier(subs,sel) end
	end
	if P=="Cloning Sequence" then clone(subs,sel) end
	if P=="Teleportation" then teleport(subs,sel) end
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name,script_description,relocator)