-- Example: Set to 120%, check fscx and fscy, and all values for fscx/y will be increased by 20% for selected lines.
-- With "multiply/add more with each line" and fscx100 you'll get 120, 140, 160, 180 for consecutive lines.
-- Alternative 2nd value allows for a different value for all Y things (fscY, Ybord, Yshad, frY, faY, all Y coordinates) + fad2, t2.
--   It will be used as Multiply or Add depending on the button you press.
-- Mirror: intended for mirroring mocha data. Applied to fbf lines with pos going from 200 to 260, it will go from 200 to 140.
--   Works with position, origin, rotations, and rectangular clip. If clip changes size/shape, results will be weird.
--   Also works with move (though that makes pretty much no sense to use) and fax/fay.
-- Regradient: if you check a tag that appears at least 3 times in the line, the middle values are calculated as gradient from the first and last.
--   That means that if you have an existing gradient and change the values on either end, the gradient is recalculated from those.
--   Works for the first 3 rows of tags except kara and for alpha/colours.
-- Manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#recalculator

script_name="Recalculator"
script_description="recalculates things"
script_author="unanimated"
script_version="3.0"
script_namespace="ua.Recalculator"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="3.0.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

-- SETTINGS: type the names of checkboxes you want checked by default as you see them in the GUI, separated by commas.

checked="fscx,fscy,anchor clip"
default_rounding=2

-- END OF SETTINGS

re=require'aegisub.re'

function calc(num)
    if P=="Multiply" then num=round(num+num*count,rnd) end
    if P=="Add" then num=round(num+(res.add*linec),rnd)end
    if neg==0 and num<0 then num=0 end
    return num
end

function calc2(num)
    if P=="Multiply" then num=round(num+num*altcount,rnd) end
    if P=="Add" then num=round(num+(alt*linec),rnd)end
    if neg==0 and num<0 then num=0 end
    return num
end

function recalc(text,tg,c)
	if not res.regtag and not res.tftag then
		t_error("For "..tg..", you must select 'regular tags' or 'tags in transforms' or both.",1) end
	if c==1 then kalk=calc else kalk=calc2 end
	if neg==1 then val="([%d%.%-]+)" else val="([%d%.]+)" end
	-- split into non-tf/tf segments if there are transforms
	seg={}
	if text:match("\\t%b()") then
		for seg1,seg2 in text:gmatch("(.-)(\\t%b())") do table.insert(seg,seg1) table.insert(seg,seg2) end
		table.insert(seg,text:match("^.*\\t%b()(.-)$"))
	else table.insert(seg,text)
	end
	-- change non-tf/tf/all segments
	for q=1,#seg do
		if res.regtag and not seg[q]:match("\\t%b()") then
			seg[q]=seg[q]:gsub(tg.."("..val..")",function(a) return tg..kalk(tonumber(a)) end)
		end
		if res.tftag and seg[q]:match("\\t%b()") then
			seg[q]=seg[q]:gsub(tg.."("..val..")",function(a) return tg..kalk(tonumber(a)) end)
		end
	end
	nt=""
	for q=1,#seg do nt=nt..seg[q] end
	return nt
end

function recalc2(text,tg,c)
	if neg==1 then val="([%d%.%-]+)" else val="([%d%.]+)" end
	if c==1 then
	  text=text:gsub(tg.."%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return tg.."("..calc(tonumber(a))..","..b..")" end)
	else
	  text=text:gsub(tg.."%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return tg.."("..a..","..calc2(tonumber(b))..")" end)
	end
	return text
end

function multiply(subs,sel)
    c=(res.pc-100)/100
    oc=res.pc/100
    rnd=res.rnd
    if res.alt then ac=res.altval/100 else ac=oc end
    if P=="Multiply" then alt=(res.altval-100)/100 else alt=res.altval end
    if res.mov1 or res.mov2 or res.mov3 or res.mov4 then move=1 else move=0 end
    if res.clipx or res.clipy then clip=1 else clip=0 end
    for z,i in ipairs(sel) do
	progress("Processing line: "..z.."/"..#sel)
        if res.byline then count=z*c linec=z altcount=z*alt else count=c linec=1 altcount=alt end
	if not res.alt then altcount=count alt=res.add end
	line=subs[i]
	text=line.text
	sr=stylechk(line.style)
	if not text:match("^{\\") then text="{\\rec}"..text end

	notf=text:gsub("\\t%b()","")
	spac=sr.spacing		if res.fsp and not notf:match("\\fsp") and spac~=0 then text=addtag3("\\fsp"..spac,text) end
	fsize=sr.fontsize	if res.fs and not notf:match("\\fs%d") then text=addtag3("\\fs"..fsize,text) end
	scy=sr.scale_y		if res.fscy and not notf:match("\\fscy") then text=addtag3("\\fscy"..scy,text) end
	scx=sr.scale_x		if res.fscx and not notf:match("\\fscx") then text=addtag3("\\fscx"..scx,text) end
	shdw=sr.shadow		if res.shad and not notf:match("\\shad") and shdw~=0 then text=addtag3("\\shad"..shdw,text) end
	brdr=sr.outline		if res.bord and not notf:match("\\bord") and brdr~=0 then text=addtag3("\\bord"..brdr,text) end

	if res.fscx then	neg=0 text=recalc(text,"\\fscx",1) end
	if res.fscy then	neg=0 text=recalc(text,"\\fscy",2) end
	if res.fs then		neg=0 text=recalc(text,"\\fs",1) end
	if res.fsp then	neg=1 text=recalc(text,"\\fsp",1) end
	if res.bord then	neg=0 text=recalc(text,"\\bord",1) end
	if res.shad then	neg=0 text=recalc(text,"\\shad",1) end
	if res.blur then	neg=0 text=recalc(text,"\\blur",1) end
	if res.be then		neg=0 text=recalc(text,"\\be",1) end
	if res.xbord then	neg=0 text=recalc(text,"\\xbord",1) end
	if res.ybord then	neg=0 text=recalc(text,"\\ybord",2) end
	if res.xshad then	neg=1 text=recalc(text,"\\xshad",1) end
	if res.yshad then	neg=1 text=recalc(text,"\\yshad",2) end
	if res.frx then	neg=1 text=recalc(text,"\\frx",1) end
	if res.fry then	neg=1 text=recalc(text,"\\fry",2) end
	if res.frz then	neg=1 text=recalc(text,"\\frz",1) end
	if res.fax then	neg=1 text=recalc(text,"\\fax",1) end
	if res.fay then	neg=1 text=recalc(text,"\\fay",2) end

	if res.kara then neg=0 text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		:gsub("^({[^}]-\\[Kk][fo]?)([%d%.]+)",function(a,b) return a..calc(tonumber(b)) end) end

	if res.posx then neg=1 text=recalc2(text,"\\pos",1) end
	if res.posy then neg=1 text=recalc2(text,"\\pos",2) end

	if res.orgx then neg=1 text=recalc2(text,"\\org",1) end
	if res.orgy then neg=1 text=recalc2(text,"\\org",2) end

	if res.fad1 then neg=0 text=recalc2(text,"\\fad",1) end
	if res.fad2 then neg=0 text=recalc2(text,"\\fad",2) end

	if move==1 then neg=1 text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d)
		if res.mov1 then a=calc(tonumber(a)) end
		if res.mov2 then b=calc2(tonumber(b)) end
		if res.mov3 then c=calc(tonumber(c)) end
		if res.mov4 then d=calc2(tonumber(d)) end
	return "\\move("..a..","..b..","..c..","..d end) end

	if clip==1 then neg=1
		if not res.regtag and not res.tftag then t_error("You must select 'regular tags' or 'tags in transforms' or both.",true) end
		orig=text
		if res.anchor and P=="Multiply" then m=1/oc m2=1/ac
		  text=text:gsub("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		    function(a,b,c,d) x=0 y=0
		      if res.clipx then x=(a+c)/2-((a+c)/2)*m end
		      if res.clipy then y=(b+d)/2-((b+d)/2)*m2 end
		    return "clip("..a-x..","..b-y..","..c-x..","..d-y end)
		  if text:match("clip%(m [%d%a%s%-%.]+%)") then
		    ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
		    c1,c2=ctext:match("([%d%-%.]+)%s([%d%-%.]+)")
		    x=0 y=0
		    if res.clipx then x=c1-c1*m end
		    if res.clipy then y=c2-c2*m2 end
		    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a-x.." "..b-y end)
		    ctext=ctext:gsub("%-","%%-")
		    text=text:gsub("clip%(m "..ctext,"clip(m "..ctext2)
	          end
		end
	      text=text:gsub("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d)
		if res.clipx then a=calc(tonumber(a)) c=calc(tonumber(c)) end
		if res.clipy then b=calc2(tonumber(b)) d=calc2(tonumber(d)) end
	      return "clip("..a..","..b..","..c..","..d..")" end)
	      if text:match("clip%(m [%d%a%s%-%.]+%)") then
		ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
		ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b)
		  if res.clipx then a=calc(tonumber(a)) end
		  if res.clipy then b=calc2(tonumber(b)) end
		return a.." "..b end)
		ctext=ctext:gsub("%-","%%-")
		text=text:gsub(ctext,ctext2)
	      end
		-- regular vs transforms: shitty, slow workaround because fuck if i'm gonna figure out what's going on above
		origami={}
		hybrid={}
		textn=""
	      if text:match("\\t%b()") then
		-- transforms present
		if not res.regtag or not res.tftag then
			for seg1,seg2 in orig:gmatch("(.-)(\\t%b())") do table.insert(origami,seg1) table.insert(origami,seg2) end
			table.insert(origami,orig:match("^.*\\t%b()(.-)$"))
			for seg1,seg2 in text:gmatch("(.-)(\\t%b())") do table.insert(hybrid,seg1) table.insert(hybrid,seg2) end
			table.insert(hybrid,text:match("^.*\\t%b()(.-)$"))
			for q=1,#hybrid do
				if hybrid[q]:match("\\t") then
					if res.regtag then textn=textn..origami[q] else textn=textn..hybrid[q] end
				else
					if res.tftag then textn=textn..origami[q] else textn=textn..hybrid[q] end
				end
			end
			text=textn
		end
	      else
		-- no transforms present - only regular clips recalculated
		if not res.regtag then text=orig end	-- yep, it was all for nothing
	      end
	end

	if res.drawx or res.drawy then neg=1
	      if text:match("\\p[1-9]") and text:match("}m [%d%a%s%-%.]+") then
	      dtext=text:match("}m ([%d%a%s%-%.]+)")
	      dtext2=dtext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b)
		if res.drawx then xx=math.floor(calc(tonumber(a))+0.5) else xx=a end
		if res.drawy then yy=math.floor(calc2(tonumber(b))+0.5) else yy=b end
		return xx.." "..yy end)
	      dtext=dtext:gsub("%-","%%-")
	      text=text:gsub(dtext,dtext2)
	      end
	end

	if res.ttim1 then neg=1 text=text:gsub("\\t%(([%d%.%-]+),([%d%.%-]+),",function(a,b)
	return "\\t("..calc(tonumber(a))..","..b.."," end) end
	if res.ttim2 then neg=1 text=text:gsub("\\t%(([%d%.%-]+),([%d%.%-]+),",function(a,b)
	return "\\t("..a..","..calc2(tonumber(b)).."," end) end

	text=text:gsub("\\rec","")
	line.text=text
        subs[i]=line
    end
end

function regrad(subs,sel)
    gradlist={"bord","shad","blur","be","fs","fscx","fscy","fsp","frx","fry","frz","fax","fay","xshad","xbord","yshad","ybord"}
    acol={"alpha","1a","2a","3a","4a","1c","2c","3c","4c"}
    rnd=res.rnd
    for z=1,#sel do
	i=sel[z]
	progress("Processing line: "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	-- regular tags
	for x=1,#gradlist do
	  tag=gradlist[x]
	  _,c=text:gsub("\\"..tag.."%-?%d","")
	  if res[tag] and c>2 then
	    text=text:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
	    tagtab={}
	    for tt in text:gmatch(".-\\"..tag.."[%d%.%-]+") do table.insert(tagtab,tt) end
	    count=#tagtab
	    if res.space then spaceworks("{\\"..tag.."0fake} ","[%d%.%-]+") end
	    END=text:match("^.*\\"..tag.."[%d%.%-]+(.-)$")
	    val1=tonumber(tagtab[1]:match("\\"..tag.."([%d%.%-]+)"))
	    val2=tonumber(tagtab[count]:match("\\"..tag.."([%d%.%-]+)"))
	    for t=2,count-1 do
	      valc=currentval(val1,val2,t)
	      valc=round(valc,rnd)
	      tagtab[t]=tagtab[t]:gsub("(\\"..tag..")([%d%.%-]+)","%1"..valc)
	    end
	    nt=END
	    for a=count,1,-1 do nt=tagtab[a]..nt end
	    nt=nt:gsub("{\\%a%a+[%d%.%-]+fake}","")
	    text=nt:gsub("|t%b()",function(t) return t:gsub("|","\\") end)
	  end
	end
	-- colours
	text=text:gsub("\\c&","\\1c&")
	for x=1,#acol do
	  tag=acol[x]
	  _,c=text:gsub("\\"..tag.."&","")
	  if res[tag] and c>2 then
	    text=text:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
	    tagtab={}
	    for tt in text:gmatch(".-\\"..tag.."&H%x+&") do table.insert(tagtab,tt) end
	    count=#tagtab
	    if res.space and tag:match("a") then spaceworks("{\\"..tag.."&H00&fake} ","&H%x+&") end
	    if res.space and tag:match("c") then spaceworks("{\\"..tag.."&H000000&fake} ","&H%x+&") end
	    END=text:match("^.*\\"..tag.."&H%x+&(.-)$")
	    val1=tagtab[1]:match("\\"..tag.."(&H%x+&)")
	    val2=tagtab[count]:match("\\"..tag.."(&H%x+&)")
	    B1,G1,R1=val1:match("(%x%x)(%x%x)(%x%x)")
	    B2,G2,R2=val2:match("(%x%x)(%x%x)(%x%x)")
	    A1=val1:match("&H(%x%x)&")
	    A2=val2:match("&H(%x%x)&")
	    for t=2,count-1 do
	      if A1 then
		nA1=(tonumber(A1,16))  nA2=(tonumber(A2,16))
		nAC=currentval(nA1,nA2,t)
		valc=tohex(round(nAC))
	      else
		nR1=(tonumber(R1,16))  nR2=(tonumber(R2,16))
		nG1=(tonumber(G1,16))  nG2=(tonumber(G2,16))
		nB1=(tonumber(B1,16))  nB2=(tonumber(B2,16))
		nRC=currentval(nR1,nR2,t)
		nGC=currentval(nG1,nG2,t)
		nBC=currentval(nB1,nB2,t)
		RC=tohex(round(nRC))
		GC=tohex(round(nGC))
		BC=tohex(round(nBC))
		valc=BC..GC..RC
	      end
	      tagtab[t]=tagtab[t]:gsub("(\\"..tag..")(&H%x+&)","%1&H"..valc.."&")
	    end
	    nt=END
	    for a=count,1,-1 do nt=tagtab[a]..nt end
	    nt=nt:gsub("{\\%d?%a+&H%x+&fake}","")
	    text=nt:gsub("|t%b()",function(t) return t:gsub("|","\\") end)
	  end
	end
	text=text:gsub("\\1c&","\\c&") :gsub("_s_"," ")
	line.text=text
        subs[i]=line
    end
end

function currentval(val1,val2,t) return (val2-val1)/(count-1)*(t-1)+val1 end

function spaceworks(faketag,value)
	nocom=text:gsub("%b{}","")
	letrz=nocom:gsub(" ","")
	lcount=re.find(letrz,".")
	if count==#lcount and nocom:match(" ") then
		text=text:gsub("{[^\\}]-}",function(com) return com:gsub(" ","_s_") end)
		:gsub(" ",faketag)
		tagtab={}
		for tt in text:gmatch(".-\\"..tag..value) do table.insert(tagtab,tt) end
		count=#tagtab
	end
end

function mirror(subs,sel)
    taglist={"frz","frx","fry","fax","fay","posx","posy","orgx","orgy","mov1","mov2","mov3","mov4","clipx","clipy"}
    tagval={}
    line=subs[sel[1]]
    text=line.text
    tags=text:match(STAG)
    if not tags then t_error("No tags on line 1.",true) end
    tags=tags:gsub("\\t%b()","")
    for x=1,#taglist do
	tag=taglist[x]
	val=getval(tags,val)
	tagval[x]=val
    end
    for z=2,#sel do
	i=sel[z]
	progress("Processing line: "..z-1 .."/"..#sel-1)
	line=subs[i]
	text=line.text
	tags=text:match(STAG) or ""
	text=text:gsub(STAG,"")
	for x=1,#taglist do
	  tag=taglist[x]
	  if res[tag] then
	    val1=tonumber(tagval[x])
	    val2=tonumber(getval(tags,val2))
	    if val1 and val2 then tags=replaceval(tags) end
	  end
	end
	line.text=tags..text
        subs[i]=line
    end
end

function getval(tags,val)
	val=tags:match("\\"..tag.."([^\\}]+)")
	if tag=="posx" then val=tags:match("\\pos%(([%d%.%-]+)") end
	if tag=="posy" then val=tags:match("\\pos%([%d%.%-]+,([%d%.%-]+)") end
	if tag=="orgx" then val=tags:match("\\org%(([%d%.%-]+)") end
	if tag=="orgy" then val=tags:match("\\org%([%d%.%-]+,([%d%.%-]+)") end
	if tag=="mov1" then val=tags:match("\\move%(([%d%.%-]+)") end
	if tag=="mov2" then val=tags:match("\\move%([%d%.%-]+,([%d%.%-]+)") end
	if tag=="mov3" then val=tags:match("\\move%([%d%.%-]+,[%d%.%-]+,([%d%.%-]+)") end
	if tag=="mov4" then val=tags:match("\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,([%d%.%-]+)") end
	if tag=="clipx" then val=tags:match("\\clip%(([%d%.%-]+)") end
	if tag=="clipy" then val=tags:match("\\clip%([%d%.%-]+,([%d%.%-]+)") end
	return val
end

function replaceval(tags)
	val3=val1+(val1-val2)
	tags=tags:gsub("\\"..tag..val2,"\\"..tag..val3)
	if tag=="posx" then tags=tags:gsub("(\\pos%()([%d%.%-]+)","%1"..val3) end
	if tag=="posy" then tags=tags:gsub("(\\pos%([%d%.%-]+,)([%d%.%-]+)","%1"..val3) end
	if tag=="orgx" then tags=tags:gsub("(\\org%()([%d%.%-]+)","%1"..val3) end
	if tag=="orgy" then tags=tags:gsub("(\\org%([%d%.%-]+,)([%d%.%-]+)","%1"..val3) end
	if tag=="mov1" then tags=tags:gsub("(\\move%()([%d%.%-]+)","%1"..val3) end
	if tag=="mov2" then tags=tags:gsub("(\\move%([%d%.%-]+,)([%d%.%-]+)","%1"..val3) end
	if tag=="mov3" then tags=tags:gsub("(\\move%([%d%.%-]+,[%d%.%-]+,)([%d%.%-]+)","%1"..val3) end
	if tag=="mov4" then tags=tags:gsub("(\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,)([%d%.%-]+)","%1"..val3) end
	if tag=="clipx" then
	  tags=tags:gsub("(\\clip%()([%d%.%-]+)(,[%d%.%-]+,)([%d%.%-]+)",function(a,b,c,d) return a..val3..c..d-(b-val3) end)
	end
	if tag=="clipy" then
	  tags=tags:gsub("(\\clip%([%d%.%-]+,)([%d%.%-]+)(,[%d%.%-]+,)([%d%.%-]+)",function(a,b,c,d) return a..val3..c..d-(b-val3) end)
	end
	return tags
end

--	reanimatools	--
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end

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

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function logg(m) m=m or "nil" aegisub.log("\n "..m) end

function recalculator(subs,sel)
ADD=aegisub.dialog.display
ak=aegisub.cancel
ATAG="{%*?\\[^}]-}"
STAG="^{\\[^}]-}"
	GUI={
	{x=2,y=0,width=3,class="floatedit",name="pc",value=100,min=0,hint="Multiply"},
	{x=2,y=1,width=3,class="floatedit",name="add",value=0,hint="Add (use negative to subtract)"},
	{x=2,y=2,width=3,class="floatedit",name="altval",value=0,hint="Multiply/Add based on button P"},
	{x=2,y=3,width=3,class="intedit",name="rnd",value=default_rounding,min=0,max=4,hint="How many decimal places should be allowed"},
	
	{x=0,y=0,width=2,class="label",label="Change values to:"},
	{x=0,y=1,width=2,class="label",label="Increase values by:"},
	{x=0,y=2,width=2,class="checkbox",name="alt",label="Alternative 2nd value",value=false,hint="Affects fscy, ybord, yshad, fry, fay, all Y coordinates, fad2, t2"},
	{x=0,y=3,width=2,class="label",label="Rounding:"},
	
	{x=5,y=0,width=3,class="label",label="%            Recalculator v"..script_version},
	
	{x=0,y=4,class="checkbox",name="fscx",label="fscx"},
	{x=1,y=4,class="checkbox",name="fscy",label="fscy"},
	{x=2,y=4,class="checkbox",name="fs",label="fs"},
	{x=3,y=4,class="checkbox",name="fsp",label="fsp"},
	{x=4,y=4,class="checkbox",name="blur",label="blur"},
	{x=5,y=4,class="checkbox",name="be",label="be"},

	{x=0,y=5,class="checkbox",name="bord",label="bord"},
	{x=1,y=5,class="checkbox",name="shad",label="shad"},
	{x=2,y=5,class="checkbox",name="xbord",label="xbord"},
	{x=3,y=5,class="checkbox",name="ybord",label="ybord"},
	{x=4,y=5,class="checkbox",name="xshad",label="xshad   "},
	{x=5,y=5,class="checkbox",name="yshad",label="yshad"},

	{x=0,y=6,class="checkbox",name="frz",label="frz"},
	{x=1,y=6,class="checkbox",name="frx",label="frx"},
	{x=2,y=6,class="checkbox",name="fry",label="fry"},
	{x=3,y=6,class="checkbox",name="fax",label="fax"},
	{x=4,y=6,class="checkbox",name="fay",label="fay"},
	{x=5,y=6,class="checkbox",name="kara",label="kara",hint="k/kf/ko. only the first one in the line."},

	{x=0,y=7,class="checkbox",name="posx",label="pos x"},
	{x=1,y=7,class="checkbox",name="posy",label="pos y"},
	{x=2,y=7,class="checkbox",name="orgx",label="org x"},
	{x=3,y=7,class="checkbox",name="orgy",label="org y"},
	{x=4,y=7,class="checkbox",name="fad1",label="fad 1"},
	{x=5,y=7,class="checkbox",name="fad2",label="fad 2"},

	{x=4,y=8,width=2,class="checkbox",name="allpos",label="all pos/move/org      ",
	hint="same as all 8 checkboxes. \naffects only existing tags."},
	{x=6,y=8,width=2,class="label",label="---------------------------"},

	{x=0,y=9,class="checkbox",name="clipx",label="clip x"},
	{x=1,y=9,class="checkbox",name="clipy",label="clip y"},
	{x=2,y=9,class="checkbox",name="drawx",label="draw x"},
	{x=3,y=9,class="checkbox",name="drawy",label="draw y"},
	{x=4,y=9,class="checkbox",name="ttim1",label="\\t 1",hint="\\t timecode 1"},
	{x=5,y=9,class="checkbox",name="ttim2",label="\\t 2",hint="\\t timecode 2"},
	{x=6,y=9,width=2,class="checkbox",name="anchor",label="anchor clip",hint="anchor clip with Multiply"},
	
	{x=6,y=2,width=2,class="label",label="-v- Regradient -v-"},
	{x=6,y=3,class="checkbox",name="alpha",label="alpha"},
	{x=7,y=3,class="checkbox",name="space",label="[  ]",value=true,hint="workaround for spaces with full-line GBC"},

	{x=0,y=10,width=3,class="checkbox",name="byline",label="multiply/add more with each line"},

	{x=3,y=10,width=2,class="checkbox",name="regtag",label="regular tags",value=true},
	{x=5,y=10,width=2,class="checkbox",name="tftag",label="tags in transforms",value=true},
	{x=6,y=1,width=2,class="checkbox",name="rpt",label="repeat last"},
	}
	for z=1,4 do
	  table.insert(GUI,{x=z-1,y=8,class="checkbox",name="mov"..z,label="move"..z.."  "})
	  table.insert(GUI,{x=6,y=z+3,class="checkbox",name=z.."a",label=z.."a"})
	  table.insert(GUI,{x=7,y=z+3,class="checkbox",name=z.."c",label=z.."c"})
	end
	chk=","..checked..","
	chk=chk:gsub(" *, *",",") :gsub("\t","\\t")
	for key,val in ipairs(GUI) do
		if val.class=="checkbox" and chk:match(","..val.label:gsub(" *$","")..",") then val.value=true end
	end
	repeat
	  if P=="Clear" then
	    for key,val in ipairs(GUI) do
		if val.class=="checkbox" and val.name~="anchor" then val.value=false end
		if val.name=="anchor" then val.value=res.anchor end
		if val.name=="alt" then val.value=res.alt end
		if val.name=="regtag" then val.value=res.regtag end
		if val.name=="tftag" then val.value=res.tftag end
		if val.name=="space" then val.value=res.space end
		if val.class:match("edit") then val.value=res[val.name] end
	    end
	  end
	P,res=ADD(GUI,{"Multiply","Add","Mirror","Regradient","Clear","Cancel"},{ok='Multiply',cancel='Cancel'})
	until P~="Clear"
	if P=="Cancel" then ak() end
	if res.rpt and lastres then res=lastres end
	if res.allpos then
		res.posx=true res.posy=true res.orgx=true res.orgy=true
		res.mov1=true res.mov2=true res.mov3=true res.mov4=true
	end
	if P=="Multiply" or P=="Add" then styleget(subs) multiply(subs,sel) end
	if P=="Regradient" then regrad(subs,sel) end
	if P=="Mirror" then mirror(subs,sel) end
	lastres=res
	aegisub.set_undo_point(script_name)
	return sel
end

if haveDepCtrl then depRec:registerMacro(recalculator) else aegisub.register_macro(script_name,script_description,recalculator) end