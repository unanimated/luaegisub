script_name="MultiCopy"
script_description="Copy and paste just about anything from/to multiple lines"
script_author="unanimated"
script_version="3.01"

-- Use the Help button for info

require "clipboard"
re=require'aegisub.re'

-- COPY PART

function copy(subs,sel)	-- tags
    copytags=""
    for x,i in ipairs(sel) do
    	progress("Copying from line: "..x.."/"..#sel)
	text=subs[i].text
	tags=text:match("^{\\[^}]*}") or ""
	copytags=copytags..tags.."\n"
	if x==#sel then copytags=copytags:gsub("\n$","") end
    end
    copydialog[2].label=""
    copydialog[3].value=copytags
    P,res=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copytags) end
end

function copyt(subs,sel)	-- text
    copytekst=""
    for x,i in ipairs(sel) do
    	progress("Copying from line: "..x.."/"..#sel)
	text=subs[i].text
	text=text:gsub("^{\\[^}]-}","")
	copytekst=copytekst..text.."\n"
	if x==#sel then copytekst=copytekst:gsub("\n$","") end
    end
    words=0 for t in copytekst:gmatch("%S+") do words=words+1 end
    copydialog[2].label="("..copytekst:len().." characters, "..words.." words)"
    copydialog[3].value=copytekst
    P,res=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copytekst) end
end

function kopi(this)
  if this~=nil then cc=cc..this end
end

function copyc(subs,sel)	-- any tags; layeractoreffectetc.
    cc=""
    tagg=res.dat:gsub("\n","")
    for x,i in ipairs(sel) do
	progress("Copying from line: "..x.."/"..#sel)
	line=subs[i]
	text=subs[i].text
	vis=text:gsub("%b{}","")
	nospace=vis:gsub(" ","")
	comments=""
	for com in text:gmatch("{[^\\}]-}") do comments=comments..com end
	tagst=text:match("^{\\[^}]-}") or ""
	tags=tagst:gsub("\\t%b()","")
	
	if CM=="clip" then kopi(tags:match("\\i?clip%b()")) end
	if CM=="position" then kopi(tags:match("\\pos%b()")) end
	if CM=="blur" then kopi(tags:match("\\blur[%d%.]+")) end
	if CM=="border" then kopi(tags:match("\\bord[%d%.]+")) end
	if CM=="colour(s)" and res.c1 then kopi(tags:match("\\1?c&H%w+&")) end
	if CM=="colour(s)" and res.c2 then kopi(tags:match("\\2c&H%w+&")) end
	if CM=="colour(s)" and res.c3 then kopi(tags:match("\\3c&H%w+&")) end
	if CM=="colour(s)" and res.c4 then kopi(tags:match("\\4c&H%w+&")) end
	if CM=="alpha" and res.alf then kopi(tags:match("\\alpha&H%w+&")) end
	if CM=="alpha" and res.a1 then kopi(tags:match("\\1a&H%w+&")) end
	if CM=="alpha" and res.a2 then kopi(tags:match("\\2a&H%w+&")) end
	if CM=="alpha" and res.a3 then kopi(tags:match("\\3a&H%w+&")) end
	if CM=="alpha" and res.a4 then kopi(tags:match("\\4a&H%w+&")) end
	if CM=="fscx" then kopi(tags:match("\\fscx[%d%.]+")) end
	if CM=="fscy" then kopi(tags:match("\\fscy[%d%.]+")) end
	
	if CM=="any tag" then for tag in tagg:gmatch("[^,]+") do
	 tag=tag:gsub(" ","")
	 tak=nil
	 if tag=="t" then
	  if tagst:match("\\t") then tak=""
	    for t in tagst:gmatch("\\t%b()") do tak=tak..t end
	  end
	 elseif tag:match("^[abikps]$") then tak=tags:match("(\\"..tag.."%d*)[\\}]")
	 elseif tag=="fs" then tak=tags:match("(\\fs%d*)[\\}]")
	 elseif tag=="c" then tak=tags:match("(\\c&[^\\}]*)")
	 elseif tag=="fad" then tak=tags:match("\\fad%b()")
	 else
	  tak=tags:match("(\\"..tag.."[^\\}]*)")
	 end
	 kopi(tak)
	end end
	
	if CM=="layer" then cc=cc..line.layer end
	if CM=="actor" then cc=cc..line.actor end
	if CM=="effect" then cc=cc..line.effect end
	if CM=="style" then cc=cc..line.style end
	if CM=="duration" then cc=cc..line.end_time-line.start_time end
	if CM=="comments" then cc=cc..comments end
	if CM=="# of characters" then cc=cc..vis:len() end
	if CM=="# of chars (no space)" then cc=cc..nospace:len() end
	
	if x~=#sel then cc=cc.."\n" end
    end
    copydialog[1].label="Data to export:"
    copydialog[2].label=""
    copydialog[3].value=cc
    P,res=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(cc) end
end

function copyall(subs,sel)	-- all
	copylines=""
    for x,i in ipairs(sel) do
    	progress("Copying from line: "..x.."/"..#sel)
	text=subs[i].text
	copylines=copylines..text.."\n"
	if x==#sel then copylines=copylines:gsub("\n$","") end
    end
    words=0 for t in copylines:gmatch("%S+") do words=words+1 end
    copydialog[2].label="("..copylines:len().." characters, "..words.." words)"
    copydialog[3].value=copylines
    P,res=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copylines) end
end

-- CR Export for Pad

function crmod(subs,sel)
    for i=1,#subs do
    	progress("Crunching line: "..i.."/"..#subs)
        if subs[i].class=="dialogue" then
        line=subs[i]
        text=subs[i].text
	style=line.style
	text=text
	:gsub("^%s*","")
	:gsub("%s%s+"," ")
	:gsub("{\\i0}$","")
	
	-- change main style to Default
	style=style:gsub("[Ii]nternal","Italics")
	if style:match("[Ii]talics") and not style:match("[Ff]lashback") and not text:match("\\i1") then text="{\\i1}"..text end
	if style:match("[Mm]ain") or style:match("[Oo]verlap") or style:match("[Ii]talics")
	or style:match("[Ii]nternal") or style:match("[Ff]lashback") or style:match("[Nn]arrat")
	then style="Default" end

	-- nuke tags from signs, set actor to "Sign", add timecode
	if not style:match("Defa") then
	text=text:gsub("{[^\\}]*}","")
	actor="Sign"
	timecode=math.floor(line.start_time/1000)
	tc1=math.floor(timecode/60)
	tc2=timecode%60+1
	if tc2==60 then tc2=0 tc1=tc1+1 end
	if tc1<10 then tc1="0"..tc1 end
	if tc2<10 then tc2="0"..tc2 end
	text="{TS "..tc1..":"..tc2.."}"..text
	if style:match("[Tt]itle") then text=text:gsub("({TS %d%d:%d%d)}","%1 Title}") end

	else
	text=text:gsub("%s?\\[Nn]%s?"," ") :gsub("\\a6","\\an8")
	line.text=text
	end
	line.actor=""
	line.style=style
	line.text=text
        subs[i]=line
        end
    end
    -- move signs to the top of the script
    aegisub.progress.title("Sorting")
    i=1	moved=0
    while i<=(#subs-moved) do
	line=subs[i]
	if line.class=="dialogue" and line.style=="Default" then
	  subs.delete(i)
	  moved=moved+1
	  subs.append(line)
	else
	    i=i+1
	end
    end
    -- copy text from all lines
    copylines=""
    for i=1,#subs do
	progress("Copying from line: "..i.."/"..#subs)
        if subs[i].class == "dialogue" then
        line=subs[i]
	text=subs[i].text
	copylines=copylines..text.."\n"
	if x==#sel then copylines=copylines:gsub("\n$","") end
	subs[i]=line
	end
    end
    words=0 for t in copylines:gmatch("%S+") do words=words+1 end
    copydialog[2].label="("..copylines:len().." characters, "..words.." words)"
    copydialog[3].value=copylines
    P,res=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copylines) end
end

-- COPY BETWEEN COLUMNS

function copycol(subs,sel)
    for x,i in ipairs(sel) do
	line=subs[i]
	source=line[res.copyfrom]
	target=line[res.copyto]
	if type(target)=="number" then data=tonumber(source) else data=source end
	if data then line[res.copyto]=data end
	if res.switch then
	  if type(source)=="number" then data2=tonumber(target) else data2=target end
	  if data2 then line[res.copyfrom]=data2 end
	end
	subs[i]=line
    end
end


-- PASTE PART

function paste(subs,sel)	-- tags
    data={}	raw=res.dat.."\n"	loop=nil	over=nil
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    if #data~=#sel then mispaste(sel) end
    overloop(sel)
    for x,i in ipairs(sel) do
      if data[x] then
	line=subs[i]
	text=subs[i].text
	text=text:gsub("^({\\[^}]*})","")
	text=data[x]..text
	line.text=text
	subs[i]=line
      end
    end
end

function pastet(subs,sel)	-- text
    data={}	raw=res.dat.."\n"	loop=nil	over=nil
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    if #data~=#sel then mispaste(sel) end
    overloop(sel)
    for x,i in ipairs(sel) do
      if data[x] then
	line=subs[i]
	text=subs[i].text
	tags=text:match("^{\\[^}]*}") or ""
	text=tags..data[x]
	line.text=text
	subs[i]=line
      end
    end
end

function gbctext(text,text2)
    stags=text:match("^{\\[^}]-}") or ""
    lastag=text:match("({\\[^}]-}).$")
    stags=stags:gsub("\\c&","\\1c&")
    lastag=lastag:gsub("\\c&","\\1c&")
    ntext=text2:gsub("(.)$",lastag.."%1")
    if lastag:match("\\[1234]c") then
      textseq={}
      ltrs=re.find(text2,".")
	for l=1,#ltrs do
	  table.insert(textseq,ltrs[l].str)
	end
      tagfirst={}
      taglast={}
      sc1="\\c"..styleref.color1:gsub("H%x%x","H")
      sc2="\\2c"..styleref.color2:gsub("H%x%x","H")
      sc3="\\3c"..styleref.color3:gsub("H%x%x","H")
      sc4="\\4c"..styleref.color4:gsub("H%x%x","H")
      stylecol={sc1,sc2,sc3,sc4}
      for c=1,4 do
	cfirst=stags:match("\\"..c.."c&H%x+&")
	clast=lastag:match("\\"..c.."c&H%x+&")
	if cfirst==nil and clast~=nil then cfirst=stylecol[c] end
	if cfirst~=nil and clast~=nil then table.insert(tagfirst,cfirst) table.insert(taglast,clast) end
      end
      grtext=textseq[1]
      tsn=#textseq
      for c=2,tsn-1 do
	coltag=""
	if textseq[c]~=" " then
	  for t=1,#taglast do
	    col1=tagfirst[t]
	    col2=taglast[t]
	    B1,G1,R1=col1:match("(%x%x)(%x%x)(%x%x)")
	    B2,G2,R2=col2:match("(%x%x)(%x%x)(%x%x)")
	    nR1=(tonumber(R1,16)) nR2=(tonumber(R2,16))
	    nG1=(tonumber(G1,16)) nG2=(tonumber(G2,16))
	    nB1=(tonumber(B1,16)) nB2=(tonumber(B2,16))
	    Rdiff=(nR2-nR1)/tsn		R=nR1+Rdiff*(c-1)
	    Gdiff=(nG2-nG1)/tsn		G=nG1+Gdiff*(c-1)
	    Bdiff=(nB2-nB1)/tsn		B=nB1+Bdiff*(c-1)
	    R=tohex(round(R))
	    G=tohex(round(G))
	    B=tohex(round(B))
	    coltag=coltag..col1:gsub("(%x%x)(%x%x)(%x%x)",B..G..R)
	  end
	grtext=grtext.."{*"..coltag.."}"..textseq[c]
	else grtext=grtext.." "
	end
      end
      ntext=grtext..lastag..textseq[tsn]
    end
    text=stags..ntext
    return text
end

--	pasted data / selection mismatch
function mispaste(sel)
	if raw=="\n" or raw=="" then t_error("No data provided.",true) end
	mispastegui={{class="label",label="Selected lines: "..#sel.." ... Pasted lines: "..#data}}
	if #data<#sel then
	  B1="Loop paste"
	  B2="Paste only "..#data.." lines"
	else
	  B1="Paste only "..#sel.." lines"
	  B2="Paste all "..#data.." lines"
	end
	B1=B1:gsub(" 1 lines"," 1 line")
	B2=B2:gsub(" 1 lines"," 1 line")
	P,res=ADD(mispastegui,{B1,B2,"Cancel"},{close='Cancel'})
	if P=="Cancel" then ak() end
	if P=="Loop paste" then loop=true end
	if P=="Paste all "..#data.." lines" then over=true end
end

function overloop(sel)
	if over then
	  ldiff=#data-#sel
	  last=#sel
	  for a=1,ldiff do table.insert(sel,sel[last]+a)end
	end
	if loop then
	  y=1
	  maxd=#data
	  repeat
	    table.insert(data,data[y])
	    y=y+1	if y==maxd+1 then y=1 end
	  until #data>=#sel
	end
end


--	MAIN PASTE PART		--

function pastec(subs,sel)
    pasteover=0	podetails=""	loop=nil	over=nil
    data={}	raw=res.dat.."\n" raw=raw:gsub("\n\n$","\n")
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    if PM=="superpasta" or PM=="all" then special=true else special=false end
    if #data~=#sel and not special then mispaste(sel) end
    
    -- PASTE OVER WITH CHECK
    if PM=="all" then pasteover=1 pasterep="" pnum=""	m100=0 m0=0 mtotal=0 om=0 omtotal=0 alter="Default"
    for i=1,#subs do 
        if subs[i].class=="style" and subs[i].name:match("Alt") then alter=subs[i].name end
	if subs[i].class=="dialogue" then z=i-1 break end
    end
    susp=""	suspL=0	suspT=0	sustab={}
      for x,i in ipairs(sel) do
	line=subs[i]
	T1l=subs[i].text				T2l=data[x] or ""	T2l=T2l:gsub("^%w+:([^%s])","%1")
	T1=T1l:gsub("%b{}","") :gsub(" ?\\N"," ")	T2=T2l:gsub("%b{}","") :gsub(" ?\\N"," ")
	L1=T1:len()					L2=T2:len()
	ln=i-z	if ln<10 then ln="00"..ln elseif ln<100 then ln="0"..ln end
	
	-- comparing words between current and pasted
	TC=T1:gsub("[%.,%?!\":;%—]","") TD=T2:gsub("[%.,%?!\":;%—]","")	ml=""
	for c in TC:gmatch("[%w']+") do
	    for d in TD:gmatch("[%w']+") do
		if c:lower()==d:lower() then
		    TD=TD:gsub("^.-"..d,"")
		    ml=ml..c.." "
		    break
		end
	    end
	end
	ml=ml:gsub(" $","")
	M1=ml:len()
	M2=TC:len()	if M2==0 then M2=1 end
	match1=math.floor((M1*100/M2+0.5))
	if M1==0 and M2==1 then match1=100 end
	
	-- other direction
	TC=T1:gsub("[%.,%?!\":;%—]","") TD=T2:gsub("[%.,%?!\":;%—]","")	mr=""
	for c in TD:gmatch("[%w']+") do
	    for d in TC:gmatch("[%w']+") do
		if c:lower()==d:lower() then
		    TC=TC:gsub("^.-"..d,"")
		    mr=mr..c.." "
		    break
		end
	    end
	end
	mr=mr:gsub(" $","")
	M1=mr:len()
	M2=TD:len()	if M2==0 then M2=1 end
	match2=math.floor((M1*100/M2+0.5))
	if M1==0 and M2==1 then match2=100 end
	
	if match1>match2 then match=match1 othermatch=match2 ma=ml else match=match2 othermatch=match1 ma=mr end
	pasterep=pasterep..ln.."	"..match.."%	"..ma.."\n"
	if match==100 then m100=m100+1 if othermatch==100 then om=om+1 end end
	if match==0 then m0=m0+1 end
	mtotal=mtotal+match
	omtotal=omtotal+othermatch
	line.effect=line.effect.."["..othermatch.."%]"
	line.text=T2l
	if T2l:match("{%*ALT%*}") then line.style=alter end
	if T2l:match("^%#") then line.comment=true end
	subs[i]=line
      end
	
	if #sel~=#data then
		for s=1,#sustab do susp=susp..sustab[s] ..", " end
		susp=susp:gsub(", $","")
		ldiff=#sel-#data
		if math.abs(ldiff)==1 then es="" else es="s" end
		if ldiff>0 then LD="The pasted data is "..ldiff.." line"..es.." shorter than your selection" else
		LD="The pasted data is ".. 0-ldiff.." line"..es.." longer than your selection" end
		podetails="Line count of the selection doesn't match pasted data.\n"..LD.."\nIf you're pasting over edited text from a pad,\nwhere you start getting too many 0% is where it's probably a line off."
	else
		fullm=math.floor(m100*100/#sel+0.5)	zerom=math.floor(m0*100/#sel+0.5)	totalm=math.floor(mtotal*10/#sel+0.5)/10
		otherm=math.floor(om*100/#sel+0.5)	totalom=math.floor(omtotal*10/#sel+0.5)/10
		podetails="Line count of the selection matched pasted data. ("..#sel.." lines)\nFull match: "..m100.."/"..#sel.." ("..fullm.."%)   Both ways: "..om.."/"..#sel.." ("..otherm.."%, ie. "..#sel-om.." lines changed - ".. 100-otherm.."%)\nZero match: "..m0.."/"..#sel.." ("..zerom.."%)\nOverall match: "..totalm.."% (".. 100-totalm.."% change / ".. 100-totalom.."% both ways)"
	end
    end -- of paste over with check
    
    
    -- SUPER PASTA - advanced paste over
    if PM=="superpasta" then
      styles=""
      warningstyles=""
      for i=1,#subs do
        if subs[i].class=="style" then
	styles=styles..","..subs[i].name..","
        end
      end
	if #data<10 then spg=#data else spg=10 end
	saet={"style","actor","effect","text"}
	seaet={"start time","end time","actor","effect","text"}
	lrvlaet={"L","R","V","layer","actor","effect","text"}
	spgui={
	{x=0,y=0,class="checkbox",name="clay",label="layer"},
	{x=1,y=0,class="checkbox",name="cstart",label="start time"},
	{x=2,y=0,class="checkbox",name="cendt",label="end time"},
	{x=3,y=0,class="checkbox",name="cstyle",label="style"},
	{x=4,y=0,class="checkbox",name="cactor",label="actor"},
	{x=5,y=0,class="checkbox",name="ceffect",label="effect"},
	{x=6,y=0,class="checkbox",name="cL",label="L"},
	{x=7,y=0,class="checkbox",name="cR",label="R"},
	{x=8,y=0,class="checkbox",name="cV",label="V"},
	{x=9,y=0,class="checkbox",name="ctext",label="text"},
	 {x=10,y=0,class="label",label="<-- check columns to use"},
	{x=0,y=spg+1,class="dropdown",name="dlay",value="layer",items={"layer","L","R","V","style","actor","effect","text"}},
	{x=1,y=spg+1,class="dropdown",name="dstart",value="start time",items=seaet},
	{x=2,y=spg+1,class="dropdown",name="dendt",value="end time",items=seaet},
	{x=3,y=spg+1,class="dropdown",name="dstyle",value="style",items=saet},
	{x=4,y=spg+1,class="dropdown",name="dactor",value="actor",items=saet},
	{x=5,y=spg+1,class="dropdown",name="deffect",value="effect",items=saet},
	{x=6,y=spg+1,class="dropdown",name="dL",value="L",items=lrvlaet},
	{x=7,y=spg+1,class="dropdown",name="dR",value="R",items=lrvlaet},
	{x=8,y=spg+1,class="dropdown",name="dV",value="V",items=lrvlaet},
	{x=9,y=spg+1,class="dropdown",name="dtext",value="text",items=saet},
	 {x=10,y=spg+1,class="label",label="<-- columns to apply to"},
	 {x=0,y=spg+2,width=10,class="label",label="Paste over selected columns or copy the content of one column to another. (GUI shows only first 10 lines for reference.)"},
	}
	lines={}
	for li=1,#data do dtext=data[li]
	if not dtext:match("^Dialogue") and not dtext:match("^Comment") then
	ADD({{class="label",label="»"..dtext.."\nNot a valid/complete dialogue line."}},{"OK"},{close='OK'}) ak() end
	dline=string2line(dtext) table.insert(lines,dline) end
	for d=1,spg do
	  dtext=data[d]  dline=lines[d]
	  table.insert(spgui,{x=0,y=d,class="label",name="lay"..d,label=dline.layer})
	  table.insert(spgui,{x=1,y=d,class="label",name="start"..d,label=dline.start_time})
	  table.insert(spgui,{x=2,y=d,class="label",name="endt"..d,label=dline.end_time})
	  table.insert(spgui,{x=3,y=d,class="label",name="style"..d,label=dline.style})
	  table.insert(spgui,{x=4,y=d,class="label",name="actor"..d,label=dline.actor})
	  table.insert(spgui,{x=5,y=d,class="label",name="effect"..d,label=dline.effect})
	  table.insert(spgui,{x=6,y=d,class="label",name="margl"..d,label=dline.margin_l})
	  table.insert(spgui,{x=7,y=d,class="label",name="margr"..d,label=dline.margin_r})
	  table.insert(spgui,{x=8,y=d,class="label",name="margt"..d,label=dline.margin_t})
	  table.insert(spgui,{x=9,y=d,width=25,class="edit",name="text"..d,value=dline.text})
	end
	-- run gui
	repeat
	    if press=="Check all" then
		for key,val in ipairs(spgui) do
		  if val.class=="checkbox" then val.value=true end
		end
	    end
	    if press=="Uncheck all" then
		for key,val in ipairs(spgui) do
		  if val.class=="checkbox" then val.value=false end
		end
	    end
	press,rez=ADD(spgui,{"OK","Check all","Uncheck all","Cancel"},{ok='OK',close='Cancel'})
	until press~="Check all" and press~="Uncheck all"
	if press=="Cancel" then ak() end
	
	-- Apply pasteover
	for x,i in ipairs(sel) do
          line=subs[i]
	  if lines[x]~=nil then
	    if rez.clay then target=rez.dlay source=lines[x].layer line=shoot(line) end
	    if rez.cstart then target=rez.dstart source=lines[x].start_time line=shoot(line) end
	    if rez.cendt then target=rez.dendt source=lines[x].end_time line=shoot(line) end
	    if rez.cstyle then target=rez.dstyle source=lines[x].style line=shoot(line) end
	    if rez.cactor then target=rez.dactor source=lines[x].actor line=shoot(line) end
	    if rez.ceffect then target=rez.deffect source=lines[x].effect line=shoot(line) end
	    if rez.cL then target=rez.dL source=lines[x].margin_l line=shoot(line) end
	    if rez.cR then target=rez.dR source=lines[x].margin_r line=shoot(line) end
	    if rez.cV then target=rez.dV source=lines[x].margin_t line=shoot(line) end
	    if rez.ctext then target=rez.dtext source=lines[x].text line=shoot(line) end
	  end
	  subs[i]=line
	end
    end -- of superpasta
    
    
    -- PASTE ANY TAG --
    if not special then
    overloop(sel)
    warningstyles=""
    for x,i in ipairs(sel) do
      if data[x] then
        line=subs[i]
	text=line.text
	text2=data[x]
	if not text:match("^{\\") then text="{\\mc}"..text end
	if PM=="any tag" then text=text:gsub("^({\\[^}]*)}","%1"..text2.."}") end
	if PM=="layer" then line.layer=text2 end
	if PM=="actor" then line.actor=text2 end
	if PM=="effect" then line.effect=text2 end
	if PM=="style" then
	  sr=stylechk(subs,text2)
	  if not sr and not warningstyles:match(","..esc(text2)..",") then
	    warningstyles=warningstyles..","..text2..","
	  end
	  line.style=text2
	end
	if PM=="duration" then line.end_time=line.start_time+text2 end
	if PM=="comments" then text=text..text2 end
	if PM=="text mod." then text=textmod(text2) end
	if PM=="gbc text" then styleref=stylechk(subs,line.style) text=gbctext(text,text2) end
	if PM=="de-irc" then
	  line=string2line(text2)
	  text=line.text
	end
	text=text
	:gsub("{%*?\\[^}]-}",function(tg) tg=duplikill(tg) tg=extrakill(tg) return tg end)
	:gsub("\\mc","")
	:gsub("{}","")
	line.text=text
	subs[i]=line
	end
      end
    end
    
    if warningstyles~="" and warningstyles~=nil then warningstyles=warningstyles:gsub(",,",", ") :gsub("^,","") :gsub(",$","")
     ADD({{class="label",label="Warning! These styles don't exist: "..warningstyles}},{"OK"},{close='OK'})
    end
    
    if pasteover==1 then pr,rs=ADD({
    {width=40,class="label",name="ch1",label="line       % matched    matched words"},
    {x=0,y=1,width=40,height=18,class="textbox",name="ch2",value=pasterep},
    {x=0,y=19,width=40,height=4,class="textbox",name="ch3",value=podetails},
    {x=0,y=23,width=40,class="checkbox",name="ef",label="% in effect",value=false},
    },{"OK"},{close='OK'})
    	if not rs.ef then
	  for x,i in ipairs(sel) do l=subs[i] l.effect=l.effect:gsub("%[%d+%%%]","") subs[i]=l end
	end
    end
end

function shoot(line)
    if target=="layer" then line.layer=source end
    if target=="start time" then line.start_time=source end
    if target=="end time" then line.end_time=source end
    if target=="style" then line.style=source
	if source=="" then source="[unnamed style]" end
	if not styles:match(","..esc(source)..",") and not warningstyles:match(","..esc(source)..",") then
	warningstyles=warningstyles..","..source..","
	end
    end
    if target=="actor" then line.actor=source end
    if target=="effect" then line.effect=source end
    if target=="L" then line.margin_l=source end
    if target=="R" then line.margin_r=source end
    if target=="V" then line.margin_t=source end
    if target=="text" then line.text=source end
    return line
end

-- paste text over while keeping tags
function textmod(text2)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	  until not text:match("{(\\[^}]-)}{(\\[^}]-)}")
	vis=text2:gsub("%b{}","")
	ltrmatches=re.find(vis,".")
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match("^{(\\[^}]-)}") or ""
	text=text:gsub("^{\\[^}]-}","") :gsub("{[^\\}]-}","")
	count=0
	for seq in text:gmatch("[^{]-{%*?\\[^}]-}") do
	  chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	  pos=re.find(chars,".")
	  if pos then ps=#pos+count else ps=0+count end
	  tgl={p=ps,t=tak,a=as}
	  table.insert(tg,tgl)
	  count=ps
	end
    newline=""
    for i=1,#tk do
	newline=newline..tk[i]
	newt=""
	for n,t in ipairs(tg) do
	  if t.p==i then newt=newt..t.t as=t.a end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext="{"..stags.."}"..newline
    text=newtext
    return text
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

function string2line(str)
	local ltype,layer,s_time,e_time,style,actor,margl,margr,margv,eff,txt=str:match("(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)")
	l2={}
	l2.class="dialogue"
	if ltype=="Comment" then l2.comment=true else l2.comment=false end
	l2.layer=layer
	l2.start_time=string2time(s_time)
	l2.end_time=string2time(e_time)
	l2.style=style
	l2.actor=actor
	l2.margin_l=margl
	l2.margin_r=margr
	l2.margin_t=margv
	l2.effect=eff
	l2.text=txt
	l2.extra={}
	return l2
end

function string2time(timecode)
	if timecode==nil then ADD({{class="label",label="Invalid timecode."}},{"OK"},{close='OK'})
	ak() end
	timecode=timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)",function(a,b,c,d) return d*10+c*1000+b*60000+a*3600000 end)
	return timecode
end

tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay","b","i"}
tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
tags3={"pos","move","org","fad"}

function duplikill(tagz)
	tf=""
	for t in tagz:gmatch("\\t%b()") do tf=tf..t end
	tagz=tagz:gsub("\\t%b()","")
	for i=1,#tags1 do
	  tag=tags1[i]
	  tagz=tagz:gsub("\\"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%2%1")
	end
	tagz=tagz:gsub("\\1c&","\\c&")
	for i=1,#tags2 do
	  tag=tags2[i]
	  tagz=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1")
	end
	tagz=tagz
	:gsub("\\i?clip%b()([^}]-)(\\i?clip%b())","%1%2")
	:gsub("({\\[^}]-)}","%1"..tf.."}")
	return tagz
end

function extrakill(text)
	for i=1,#tags3 do
	  tag=tags3[i]
	  text=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%3%2")
	end
	text=text
	:gsub("(\\pos%b())([^}]-)(\\move%b())","%3%2")
	:gsub("(\\move%b())([^}]-)(\\pos%b())","%3%2")
	return text
end

function stylechk(subs,stylename)
  for i=1,#subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if stylename==st.name then styleref=st break end
    end
  end
  return styleref
end

function esc(str)
str=str
:gsub("%%","%%%%")
:gsub("%(","%%(")
:gsub("%)","%%)")
:gsub("%[","%%[")
:gsub("%]","%%]")
:gsub("%.","%%.")
:gsub("%*","%%*")
:gsub("%-","%%-")
:gsub("%+","%%+")
:gsub("%?","%%?")
return str
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end
function round(num) num=math.floor(num+0.5) return num end
function logg(m) aegisub.log("\n "..m) end

cbut={"OK","Copy to clipboard"}
copydialog=
{{class="label",label="Text to export:"},
{x=1,idth=49,class="label"},
{y=1,width=50,height=20,class="textbox",name="copytext"}}

-- GUI PART

function multicopy(subs,sel)
ADD=aegisub.dialog.display
ak=aegisub.cancel
copytab={"tags","text","all","------","export CR for pad","------","any tag","clip","position","blur","border","colour(s)","alpha","fscx","fscy","------","layer","duration","actor","effect","style","comments","# of characters","# of chars (no space)"}
pastab={"all","any tag","superpasta","gbc text","text mod.","de-irc","------","layer","duration","actor","effect","style","comments"}
fields={"style","actor","effect","text","layer","start_time","end_time","margin_l","margin_r","margin_t"}
	gui={
	{x=0,y=19,class="label",label="Copy:"},
	{x=1,y=19,width=3,height=1,class="dropdown",name="copymode",value="tags",items=copytab},
	{x=4,y=19,class="label",label="Paste extra:"},
	{x=5,y=19,width=2,class="dropdown",name="pastemode",value="all",items=pastab},
	{x=0,y=0,width=11,height=17,class="textbox",name="dat"},
	
	{x=0,y=17,width=2,class="checkbox",name="col",label="Copy from"},
	{x=2,y=17,width=2,class="dropdown",name="copyfrom",value=CF or "actor",items=fields},
	{x=4,y=17,class="label",label="       to"},
	{x=5,y=17,width=2,class="dropdown",name="copyto",value=CT or "effect",items=fields},
	{x=7,y=17,width=2,class="checkbox",name="switch",label="Switch"},
	
	{x=0,y=18,class="checkbox",name="c1",label="\\c",value=true},
	{x=1,y=18,class="checkbox",name="c2",label="\\2c"},
	{x=2,y=18,class="checkbox",name="c3",label="\\3c"},
	{x=3,y=18,class="checkbox",name="c4",label="\\4c"},
	{x=4,y=18,class="checkbox",name="alf",label="\\alpha",value=true},
	{x=5,y=18,class="checkbox",name="a1",label="\\1a"},
	{x=6,y=18,class="checkbox",name="a2",label="\\2a"},
	{x=7,y=18,class="checkbox",name="a3",label="\\3a"},
	{x=8,y=18,class="checkbox",name="a4",label="\\4a"},
	
	{x=9,y=18,class="label",label="Replace this..."},
	{x=10,y=18,class="label",label="...with this."},
	{x=8,y=19,class="label",label="      Replacer:"},
	{x=9,y=19,class="edit",name="rep1",value=lastrep1 or ""},
	{x=10,y=19,class="edit",name="rep2",value=lastrep2 or ""},
	{x=10,y=17,class="label",label="MultiCopy version "..script_version},
	}
	buttons={"Copy","Paste tags","Paste text","Paste extra","Paste from clipboard","Replace","Help","Cancel"}
	repeat
	if P=="Paste from clipboard" then
		klipboard=clipboard.get()
		for key,val in ipairs(gui) do
		  if val.name=="dat" then val.value=klipboard
		  else val.value=res[val.name] end
		end
	end
	if P=="Help" then
	herp=[[
COPY part copies specified things line by line. PASTE part pastes these things line by line.
The main idea is to copy something from X lines and paste it to another X lines.
'Copy from-to' is a quick copy function between columns. 'Switch' switches them. Copying strings to number fields does nothing.

tags = initial tags
text = text AFTER initial tags (will include inline tags)
all = tags+text, ie. everything in the Text field
any tag = copies whatever tag(s) you specify by typing in this field, like "org", "fad", "t", or "blur,c,alpha".

export CR for pad: signs go to top with {TS} timecodes; nukes linebreaks and other CR garbage, fixes styles, etc.

Paste part:
all: this is like regular paste over from a pad, but with checks to help identify where stuff breaks if the line count is different or shifted somewhere. If you're pasting over a script that has different line splitting than it should, this will show you pretty reliably where the discrepancies are.

text mod.: this pastes over text while keeping inline tags. If your line is {\t1}a{\t2}b{\t3}c and you paste "def", you will get {\t1}d{\t2}e{\t3}f. This simply counts characters, so if you paste "defgh", you get {\t1}d{\t2}e{\t3}fgh, and for "d", you get {\t1}d. Comments get nuked.

gbc text: for pasting over lines with gradient by character. You get this:
[initial tags][pasted text without last character][tag that was before last character][last character of pasted text]
For colours, the gradient should be replicated in full.

de-irc: paste straight from irc with timecodes and nicknames, and stuff gets parsed correctly.

If pasted data doesn't match line count of selection, you get choices as for what you want to do.

You can use Replacer on pasted data: copy 'bord', replace 'bord' with 'shad', and paste border values as shadow values.]]
	    for key,val in ipairs(gui) do
		if val.name=="dat" then val.value=herp
		else val.value=res[val.name] end
	    end
	end
	if P=="Replace" then
	    for key,val in ipairs(gui) do
		if val.name=="dat" then val.value=res[val.name]:gsub(esc(res.rep1),res.rep2)
		else val.value=res[val.name] end
	    end
	end
	P,res=ADD(gui,buttons,{close='Cancel'})
	until P~="Paste from clipboard" and P~="Help" and P~="Replace"
	CM=res.copymode	PM=res.pastemode CF=res.copyfrom CT=res.copyto
	if P=="Cancel" then ak() end
	if P=="Copy" then
	  if res.col then copycol(subs,sel)
	  else
	    if res.copymode=="tags" then copy(subs,sel)
	    elseif res.copymode=="text" then copyt(subs,sel)
	    elseif res.copymode=="all" then copyall(subs,sel)
	    elseif res.copymode=="export CR for pad" then crmod(subs,sel)
	    else copyc(subs,sel) end
	  end
	end
	if P=="Paste tags" then paste(subs,sel) end
	if P=="Paste text" then pastet(subs,sel) end
	if P=="Paste extra" then pastec(subs,sel) end

	aegisub.set_undo_point(script_name.." - "..P)
	return sel
end

aegisub.register_macro(script_name,script_description,multicopy)