-- Example: Set to 120%, check fscx and fscy, and all values for fscx/y will be increased by 20% for selected lines.
-- With "multiply/add more with each line" and fscx100 you'll get 120, 140, 160, 180 for consecutive lines.
-- Alternative 2nd value allows for a different value for all Y things (fscY, Ybord, Yshad, frY, faY, all Y coordinates) + fad2, t2.
--   It will be used as Multiply or Add depending on the button you press.
-- Mirror: intended for mirroring mocha data. Applied to fbf lines with pos going from 200 to 260, it will go from 200 to 140.
--   Works with position, origin, rotations, and rectangular clip. If clip changes size/shape, results will be weird.
--   Also works with move (though that makes pretty much no sense to use) and fax/fay.
-- Manuals for all my scripts: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm

script_name="Recalculator"
script_description="recalculates things"
script_author="unanimated"
script_version="2.3"

-- SETTINGS: type the names of checkboxes you want checked by default as you see them in the GUI, separated by commas

checked="fscx,fscy,anchor clip"
default_rounding=2

-- SETTINGS END

function calc(num)
    if P=="Multiply" then num=round(num+num*count) end
    if P=="Add" then num=round(num+(res.add*linec))end
    if neg==0 and num<0 then num=0 end
    return num
end

function calc2(num)
    if P=="Multiply" then num=round(num+num*altcount) end
    if P=="Add" then num=round(num+(alt*linec))end
    if neg==0 and num<0 then num=0 end
    return num
end

function recalc(text,tg,c)
	if not res.regtag and not res.tftag then
		t_error("For "..tg..", you must select 'regular tags' or 'tags in transforms' or both.",true) end
	if c==1 then kalk=calc else kalk=calc2 end
	if neg==0 then val="([%d%.%-]+)" else val="([%d%.]+)" end
	-- split into non-tf/tf segments if there are transforms
	segments={}
	if text:match("\\t%b()") then
		for seg1,seg2 in text:gmatch("(.-)(\\t%b())") do table.insert(segments,seg1) table.insert(segments,seg2) end
		table.insert(segments,text:match("^.*\\t%b()(.-)$"))
	else table.insert(segments,text)
	end
	-- change non-tf/tf/all segments
	for q=1,#segments do
		if res.regtag and not segments[q]:match("\\t%b()") then
			segments[q]=segments[q]:gsub(tg.."("..val..")",function(a) return tg..kalk(tonumber(a)) end)
		end
		if res.tftag and segments[q]:match("\\t%b()") then
			segments[q]=segments[q]:gsub(tg.."("..val..")",function(a) return tg..kalk(tonumber(a)) end)
		end
	end
	nt=""
	for q=1,#segments do nt=nt..segments[q] end
	return nt
end

function recalc2(text,tg,c)
	if neg==0 then val="([%d%.%-]+)" else val="([%d%.]+)" end
	if c==1 then
	  text=text:gsub(tg.."%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return tg.."("..calc(tonumber(a))..","..b..")" end)
	else
	  text=text:gsub(tg.."%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return tg.."("..a..","..calc2(tonumber(b))..")" end)
	end
	return text
end

function addtag(tag,text) text=text:gsub("^{(\\[^}]-})","{"..tag.."%1") return text end

function multiply(subs,sel)
    c=(res.pc-100)/100
    oc=res.pc/100
    rnd=10^res.rnd
    if res.alt then ac=res.altval/100 else ac=oc end
    if P=="Multiply" then alt=(res.altval-100)/100 else alt=res.altval end
    if res.mov1 or res.mov2 or res.mov3 or res.mov4 then move=1 else move=0 end
    if res.clipx or res.clipy then clip=1 else clip=0 end
    for x,i in ipairs(sel) do
	progress("Processing line: "..x.."/"..#sel)
        if res.byline then count=x*c linec=x altcount=x*alt else count=c linec=1 altcount=alt end
	if not res.alt then altcount=count alt=res.add end
	line=subs[i]
	text=line.text
	styleref=stylechk(line.style)
	if not text:match("^{\\") then text="{\\rec}"..text end

	notf=text:gsub("\\t%b()","")
	scx=styleref.scale_x	if res.fscx and not notf:match("\\fscx") then text=addtag("\\fscx"..scx,text) end
	scy=styleref.scale_y	if res.fscy and not notf:match("\\fscy") then text=addtag("\\fscy"..scy,text) end
	fsize=styleref.fontsize	if res.fs and not notf:match("\\fs%d") then text=addtag("\\fs"..fsize,text) end
	brdr=styleref.outline	if res.bord and not notf:match("\\bord") and brdr~=0 then text=addtag("\\bord"..brdr,text) end
	shdw=styleref.shadow	if res.shad and not notf:match("\\shad") and shdw~=0 then text=addtag("\\shad"..shdw,text) end
	spac=styleref.spacing	if res.fsp and not notf:match("\\fsp") and spac~=0 then text=addtag("\\fsp"..spac,text) end

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

function mirror(subs,sel)
    taglist={"frz","frx","fry","fax","fay","posx","posy","orgx","orgy","mov1","mov2","mov3","mov4","clipx","clipy"}
    tagval={}
    line=subs[sel[1]]
    text=line.text
    tags=text:match("^{\\[^}]-}")
    if not tags then t_error("No tags on line 1.",true) end
    tags=tags:gsub("\\t%b()","")
    for x=1,#taglist do
	tag=taglist[x]
	val=getval(tags,val)
	tagval[x]=val
    end
    for i=2,#sel do
	progress("Processing line: "..i-1 .."/"..#sel-1)
	line=subs[sel[i]]
	text=line.text
	tags=text:match("^{\\[^}]-}") or ""
	text=text:gsub("^{\\[^}]-}","")
	for x=1,#taglist do
	  tag=taglist[x]
	  if res[tag] then
	    val1=tonumber(tagval[x])
	    val2=tonumber(getval(tags,val2))
	    if val1 and val2 then tags=replaceval(tags) end
	  end
	end
	line.text=tags..text
        subs[sel[i]]=line
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
function round(num) num=math.floor(num*rnd+0.5)/rnd return num end

function styleget(subs)
    styles={}
    for i=1,#subs do
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

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  aegisub.dialog.display({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function logg(m) if m==nil then m="Nil" end aegisub.log("\n "..m) end

function recalculator(subs,sel)
	ak=aegisub.cancel
	GUI={
	{x=0,y=0,width=2,height=1,class="label",label="Change values to:",},
	{x=2,y=0,width=3,height=1,class="floatedit",name="pc",value=100,min=0,hint="Multiply"},
	{x=5,y=0,class="label",label="%",},
	
	{x=0,y=1,width=2,height=1,class="label",label="Increase values by:",},
	{x=2,y=1,width=3,height=1,class="floatedit",name="add",value=0,hint="Add (use negative to subtract)"},
	
	{x=2,y=2,width=3,height=1,class="floatedit",name="altval",value=0,hint="Multiply/Add based on button P"},
	{x=0,y=2,width=2,height=1,class="checkbox",name="alt",label="Alternative 2nd value",value=false,hint="Affects fscy, ybord, yshad, fry, fay, all Y coordinates, fad2, t2"},
	
	{x=0,y=3,width=2,height=1,class="label",label="Rounding:",},
	{x=2,y=3,width=3,height=1,class="intedit",name="rnd",value=default_rounding,min=0,hint="How many decimals should be allowed"},
	
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

	{x=0,y=8,class="checkbox",name="mov1",label="move1  "},
	{x=1,y=8,class="checkbox",name="mov2",label="move2  "},
	{x=2,y=8,class="checkbox",name="mov3",label="move3  "},
	{x=3,y=8,class="checkbox",name="mov4",label="move4  "},

	{x=4,y=8,width=2,height=1,class="checkbox",name="allpos",label="all pos/move/org",hint="same as all 8 checkboxes. \naffects only existing tags."},

	{x=0,y=9,class="checkbox",name="clipx",label="clip x"},
	{x=1,y=9,class="checkbox",name="clipy",label="clip y"},
	{x=2,y=9,class="checkbox",name="drawx",label="draw x"},
	{x=3,y=9,class="checkbox",name="drawy",label="draw y"},
	{x=4,y=9,class="checkbox",name="ttim1",label="\\t 1",hint="\\t timecode 1"},
	{x=5,y=9,class="checkbox",name="ttim2",label="\\t 2",hint="\\t timecode 2"},

	{x=0,y=10,width=4,height=1,class="checkbox",name="byline",label="multiply/add more with each line"},
	{x=4,y=10,width=2,height=1,class="checkbox",name="anchor",label="anchor clip",hint="anchor clip with Multiply"},

	{x=0,y=11,width=2,height=1,class="checkbox",name="regtag",label="regular tags",value=true},
	{x=2,y=11,width=3,height=1,class="checkbox",name="tftag",label="tags in transforms",value=true},
	}
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
		if val.class:match("edit") then val.value=res[val.name] end
	    end
	  end
	P, res=aegisub.dialog.display(GUI,{"Multiply","Add","Mirror","Clear","Cancel"},{ok='Multiply',cancel='Cancel'})
	until P~="Clear"
	if P=="Cancel" then ak() end
	if res.allpos then
		res.posx=true res.posy=true res.orgx=true res.orgy=true
		res.mov1=true res.mov2=true res.mov3=true res.mov4=true
	end
	if P=="Multiply" or P=="Add" then styleget(subs) multiply(subs,sel) end
	if P=="Mirror" then mirror(subs,sel) end
	aegisub.set_undo_point(script_name)
	return sel
end

aegisub.register_macro(script_name, script_description, recalculator)