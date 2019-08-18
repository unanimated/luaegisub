-- Use the Help button for some basic info.
-- Complete manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#multicopy

script_name="MultiCopy"
script_description="Lossless transfer of data between compatible storage units"
script_author="unanimated"
script_version="4.0"
script_namespace="ua.MultiCopy"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="4.0.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

clipboard=require'aegisub.clipboard'
re=require'aegisub.re'


-- COPY PART --

function copy(subs,sel)	-- tags
    copytags=""
    for z,i in ipairs(sel) do
    	progress("Copying from line: "..z.."/"..#sel)
	text=subs[i].text
	tags=text:match(STAG) or ""
	copytags=copytags..tags.."\n"
	if z==#sel then copytags=nRem(copytags) end
    end
    copydialog[2].label=""
    copydialog[3].value=copytags
    P=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copytags) end
end

function copyt(subs,sel)	-- text
    copytekst=""
    for z,i in ipairs(sel) do
    	progress("Copying from line: "..z.."/"..#sel)
	text=subs[i].text
	text=text:gsub(STAG,"")
	visible=text:gsub("%b{}","")
	if CM=="visible text" then text=visible end
	if CM=="text pattern" then
		pat=re.find(visible,res.dat)
		if pat then text=pat[1].str else text="" end
	end
	copytekst=copytekst..text.."\n"
	if z==#sel then copytekst=nRem(copytekst) end
    end
    words=0 for t in copytekst:gmatch("%S+") do words=words+1 end
    copydialog[2].label="("..copytekst:len().." characters, "..words.." words)"
    copydialog[3].value=copytekst
    P=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copytekst) end
end

function kopi(this)
	if this then cc=cc..this end
end

function copyc(subs,sel)	-- any tags; layeractoreffectetc.
    cc=""
    tagg=res.dat:gsub("\n","")
    local Y=4
    if CM=="combo" then
	rez=rez or {}
	local fields={"text","style","actor","effect","layer","start_time","end_time","margin_l","margin_r","margin_v"}
	local G={
	{x=0,y=0,width=2,class="label",label="Add to beginning:"},
	{x=2,y=0,width=2,class="edit",name="st",hint="Add this to the beginning of the string for each line"},
	{x=0,y=1,width=2,class="label",label="Add to end:"},
	{x=2,y=1,width=2,class="edit",name="ed",hint="Add this to the end of the string for each line"},
	{x=0,y=2,width=2,class="label",label="Separator:"},
	{x=2,y=2,width=2,class="edit",name="sep",hint="Separator between fields"},
	{x=0,y=3,class="label",label="Copy:"},
	{x=1,y=3,width=2,class="dropdown",name='f3',items=fields,value="text"},
	}
	repeat
	if P2=="Add line" or Y==4 then
		table.insert(G,{x=0,y=Y,class="checkbox",name='c'..Y,label="+",value=true})
		table.insert(G,{x=1,y=Y,width=2,class="dropdown",name='f'..Y,items=fields,value="text"})
		Y=Y+1
	end
	for k,v in ipairs(G) do
		if (v.class=="checkbox" or v.class=="dropdown" or v.class:match"edit") and rez[v.name]~=nil then v.value=rez[v.name] end
	end
	P2,rez=ADD(G,{"Copy","Add line","Esc"},{ok='Copy',close='Esc'})
	until P2~="Add line"
	if P2=="Esc" then ak() end
	rez.c3=true
	comb={}
	for a=3,Y-1 do
		for k,v in ipairs(G) do
			if v.y==a and v.class=="dropdown" then
				nam='c'..a
				nom=rez[v.name]:gsub('_v','_t')
				if rez[nam] then table.insert(comb,nom) end
			end
		end
	end
    end
    for z,i in ipairs(sel) do
	progress("Copying from line: "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	vis=text:gsub("%b{}","")
	nospace=vis:gsub(" ","")
	comments=""
	if tagg~="" then
		comments=text:match("{[^\\}]-"..esc(tagg).."[^\\}]-}") or ""
	else
		for com in text:gmatch("{[^\\}]-}") do comments=comments..com end
	end
	tagst=text:match(STAG) or ""
	tags=tagst:gsub("\\t%b()","")
	
	if CM=="combo" then
		local l=line[comb[1]]
		if #comb>1 then
			for c=2,#comb do
				local txt=line[comb[c]]
				if comb[c]:match("time") then txt=time2string(line[comb[c]]):gsub('^0:',''):gsub('%.00$','') end
				l=l..rez.sep..txt
			end
		end
		l=rez.st..l..rez.ed
		kopi(l)
	end
	
	if CM=="clip" then kopi(tags:match("\\i?clip%b()")) end
	if CM=="pos x" then kopi(tags:match("\\pos%(([^,]+)")) end
	if CM=="pos y" then kopi(tags:match("\\pos%([^,]+,([^)]+)")) end
	if CM=="colour(s)" and res.c1 then kopi(tags:match("\\1?c&H%x+&")) end
	if CM=="colour(s)" and res.c2 then kopi(tags:match("\\2c&H%x+&")) end
	if CM=="colour(s)" and res.c3 then kopi(tags:match("\\3c&H%x+&")) end
	if CM=="colour(s)" and res.c4 then kopi(tags:match("\\4c&H%x+&")) end
	if CM=="alpha" and res.alf then kopi(tags:match("\\alpha&H%x+&")) end
	if CM=="alpha" and res.a1 then kopi(tags:match("\\1a&H%x+&")) end
	if CM=="alpha" and res.a2 then kopi(tags:match("\\2a&H%x+&")) end
	if CM=="alpha" and res.a3 then kopi(tags:match("\\3a&H%x+&")) end
	if CM=="alpha" and res.a4 then kopi(tags:match("\\4a&H%x+&")) end
	
	if CM=="any tag" then
	    for tag in tagg:gmatch("[^,]+") do
		tag=tag:gsub(" ",""):gsub("\\","")
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
	    end
	end
	
	if CM=="layer" then cc=cc..line.layer end
	if CM=="margin l" then cc=cc..line.margin_l end
	if CM=="margin r" then cc=cc..line.margin_r end
	if CM=="margin v" then cc=cc..line.margin_t end
	if CM=="actor" then cc=cc..line.actor end
	if CM=="effect" then cc=cc..line.effect end
	if CM=="style" then cc=cc..line.style end
	if CM=="duration" then cc=cc..line.end_time-line.start_time end
	if CM=="comments" then cc=cc..comments end
	if CM=="# of characters" then cc=cc..vis:len() end
	if CM=="# of chars (no space)" then cc=cc..nospace:len() end
	
	if z~=#sel then cc=cc.."\n" end
    end
    copydialog[1].label="Data to export:"
    copydialog[2].label=""
    copydialog[3].value=cc
    P=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(cc) end
end

function copyall(subs,sel)	-- all
	copylines=""
    for z,i in ipairs(sel) do
    	progress("Copying from line: "..z.."/"..#sel)
	text=subs[i].text
	copylines=copylines..text.."\n"
	if z==#sel then copylines=nRem(copylines) end
    end
    words=0 for t in copylines:gmatch("%S+") do words=words+1 end
    copydialog[2].label="("..copylines:len().." characters, "..words.." words)"
    copydialog[3].value=copylines
    P=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copylines) end
end

-- CR Export for Pad --
function crmod(subs,sel)
    for i=1,#subs do
    	progress("Crunching line: "..i.."/"..#subs)
        if subs[i].class=="dialogue" then
        line=subs[i]
        text=line.text
	style=line.style
	text=text
	:gsub("^ *","")
	:gsub(" +"," ")
	:gsub("{\\i0}$","")

	-- change main style to Default
	style=style:gsub("[Ii]nternal","Italics")
	if style:match("[Ii]talics") and not style:match("[Ff]lashback") and not text:match("\\i1") then text="{\\i1}"..text end
	if style:match("[Mm]ain") or style:match("[Oo]verlap") or style:match("[Ii]talics")
	or style:match("[Ii]nternal") or style:match("[Ff]lashback") or style:match("[Nn]arrat") or style:match("^[Tt]op$")
	then style="Default" end

	-- nuke tags from signs, set actor to "Sign", add timecode
	if not style:match("Defa") then
	text=text:gsub("{[^}]-}","")
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
	text=text:gsub(" *\\[Nn] *"," ") :gsub("\\a6","\\an8")
	line.text=text
	end
	line.actor=""
	line.style=style
	line.text=text
        subs[i]=line
        end
    end
    -- move signs to the top of the script
    progress("Sorting")
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
        if subs[i].class=="dialogue" then
        line=subs[i]
	text=line.text
	copylines=copylines..text.."\n"
	if i==#subs then copylines=nRem(copylines) end
	subs[i]=line
	end
    end
    words=0 for t in copylines:gmatch("%S+") do words=words+1 end
    copydialog[2].label="("..copylines:len().." characters, "..words.." words)"
    copydialog[3].value=copylines
    P=ADD(copydialog,cbut,{close='OK'})
    if P=="Copy to clipboard" then clipboard.set(copylines) end
end

-- COPY BETWEEN COLUMNS --
function copycol(subs,sel)
    l="" r=""
    if res.attach then
	atgui={
	{x=1,y=1,width=2,class="edit",name="merge",hint="Something to place between the two attached strings.\nA space or ' - ' may be useful."},
	{x=0,y=0,class="label",label="Before / "},
	{x=1,y=0,class="checkbox",name="after",label="&After",hint="Attach '"..res.copyfrom.."' to the end of '"..res.copyto.."'.\n\n(Default is to the beginning.)"},
	{x=2,y=0,class="checkbox",name="delor",label="&Delete orig.",hint="Delete content of the 'copy from' column."},
	{x=0,y=1,class="label",label="Link: "}
	}
	if res.copyto=='text' then table.insert(atgui,{x=0,y=2,width=3,class="checkbox",name="kom",label="Attach <"..res.copyfrom.."> as {a &comment}"}) end
	for key,val in ipairs(atgui) do
		if rez and val.name then val.value=rez[val.name] end
	end
	CBC,rez=ADD(atgui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if CBC=="Cancel" then ak() end
	merge=rez.merge
	if rez.kom then l="{" r="}" end
    end
    for z,i in ipairs(sel) do
	line=subs[i]
	source=line[res.copyfrom]
	target=line[res.copyto]
	if type(target)=="number" then data=tonumber(source) else data=source end
	if data then
	  if res.attach then
	    if rez.after then data=target..l..merge..data..r
	    else data=l..data..merge..r..target
	    end
	  end
	  line[res.copyto]=data
	  if res.attach and rez.delor then
		line[res.copyfrom]=""
		if type(source)=="number" then line[res.copyfrom]=0 end
	  end
	end
	if res.switch and not res.attach then
	  if type(source)=="number" then data2=tonumber(target) else data2=target end
	  if data2 then line[res.copyfrom]=data2 end
	end
	subs[i]=line
    end
end

-- PASTE PART --

function paste(subs,sel)	-- tags
    data={}	raw=res.dat.."\n"	loop=nil	over=nil
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    if #data~=#sel then mispaste(subs,sel) end
    overloop(subs,sel)
    for z,i in ipairs(sel) do
      if data[z] then
	line=subs[i]
	text=line.text
	text=text:gsub(STAG,"")
	text=data[z]..text
	line.text=text
	subs[i]=line
      end
    end
end

function pastet(subs,sel)	-- text
    data={}	raw=res.dat.."\n"	loop=nil	over=nil
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    if #data~=#sel then mispaste(subs,sel) end
    overloop(subs,sel)
    for z,i in ipairs(sel) do
      if data[z] then
	line=subs[i]
	text=line.text
	tags=text:match(STAG) or ""
	text=text:gsub(esc(tags),"")
	txt2=data[z]
	matchfail=false
	-- using orig. line's inline tags
	if text:match(" {\\[^}]*}%w%w+") and not txt2:match(ATAG) then
	  -- match same words if found
	  for tgs,wrd in text:gmatch(" ({\\[^}]*})(%w%w+)") do
	    if txt2:match("^"..wrd.."%W") or txt2:match(" "..wrd.."%W") or txt2:match(" "..wrd.."$") then
	      txt2=txt2:gsub(wrd,tgs..wrd)
	    else matchfail=true
	    end
	  end
	  -- apply tags by word count
	  if txt2==data[z] or matchfail then
	    txt2=data[z]
	    text=text:gsub("{[^\\}]-}","")
	    words=0
	    tagtab={}
	    for w in text:gmatch("%S+") do
	      words=words+1
	      tag1=w:match(STAG)
	      tag2=w:match(ATAG.."$")
	      tagtab[words]={t1=tag1,t2=tag2}
	    end
	    wrds2=0
	    txt3=""
	    for w in txt2:gmatch("%S+") do
	      wrds2=wrds2+1
	      if tagtab[wrds2] and tagtab[wrds2].t1 then w=tagtab[wrds2].t1..w end
	      if tagtab[wrds2] and tagtab[wrds2].t2 then w=w..tagtab[wrds2].t2 end
	      txt3=txt3..w.." "
	    end
	    txt2=txt3:gsub(" $","")
	  end
	end
	text=tags..txt2
	text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	line.text=text
	subs[i]=line
      end
    end
end

function gbctext(text,text2)
    text=text:gsub("\\c&","\\1c&")
    stags=text:match(STAG) or ""
    lastag=text:match("("..ATAG..").$")
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

--	pasted data / selection mismatch	--
function mispaste(subs,sel)
	if raw=="\n" or raw=="" then t_error("No data provided.",1) end
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
	P=ADD(mispastegui,{B1,B2,"Cancel"},{close='Cancel'})
	if P=="Cancel" then ak() end
	if P=="Loop paste" then loop=true end
	if P=="Paste all "..#data.." lines" then addlines(subs,sel) over=true end
end

function overloop(subs,sel)
	if over then
	  ldiff=#data-#sel
	  last=#sel
	  for a=1,ldiff do if sel[last]+a<=#subs then table.insert(sel,sel[last]+a) end end
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

function addlines(subs,sel)
	if sel[#sel]==#subs then
	  moar=#data-#sel
	  line=subs[#subs]
	  if moar>0 then
	    for a=1,moar do
	      subs.append(line)
	    end
	  end
	end
end

--	MAIN PASTE PART		--

function pastec(subs,sel)
    pasteover=0	podetails=""	loop=nil	over=nil
    data={}	raw=res.dat.."\n" raw=raw:gsub("\n\n$","\n")
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    if PM=="superpasta" or PM=="all" or PM=="pasteover+" then special=true else special=false end
    if #data~=#sel and not special then mispaste(subs,sel) end
    
    -- PASTE OVER WITH CHECK
    if PM=="all" then pasteover=1 pasterep="" pnum=""	m100=0 m0=0 mtotal=0 om=0 omtotal=0 alter="Default"
    for i=1,#subs do 
        if subs[i].class=="style" and subs[i].name:match("Alt") then alter=subs[i].name end
	if subs[i].class=="dialogue" then z0=i-1 break end
    end
    susp=""	suspL=0	suspT=0	sustab={}
      for z,i in ipairs(sel) do
	line=subs[i]
	T1l=line.text					T2l=data[z] or ""	T2l=T2l:gsub("^%w+:(%S)","%1")
	T1=T1l:gsub("%b{}","") :gsub(" ?\\N"," ")	T2=T2l:gsub("%b{}","") :gsub(" ?\\N"," ")
	L1=T1:len()					L2=T2:len()
	ln=i-z0	if ln<10 then ln="00"..ln elseif ln<100 then ln="0"..ln end
	
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
    
    
    -- PASTEOVER+
    if PM=="pasteover+" then
	rez=nil	finished=nil
	tada={}	pasted={}
	LL="" RR=""
	MIS="!!! --- Line count mismatch: "
	for z,i in ipairs(sel) do table.insert(tada,subs[i].text) end
	for i=1,13 do
		LL=LL..tada[i].."\n"
		RR=RR..data[i].."\n"
	end
	LL=nRem(LL) RR=nRem(RR) zl=13 zr=13
	POG={
	{x=0,y=0,width=2,class="label",label="Original text. Don't modify this.    Number of lines to be sent with each 'Send':"},
	{x=3,y=0,width=3,class="label",label="Pasted text. Modify this so that the lines you're sending on both sides match.      Numbers at the bottom = lines to add."},
	{x=3,y=1,width=3,height=20,class="textbox",name="rite",value=RR},
	{x=0,y=1,width=3,height=20,class="textbox",name="left",value=LL},
	{x=2,y=0,class="intedit",name="send",value=5,min=1},
	{x=0,y=21,class="intedit",name="a1",value=AL or 10,min=1},
	{x=3,y=21,class="intedit",name="a2",value=AR or 10,min=1},
	{x=1,y=21,width=2,class="edit",name="i1",value=#tada.." lines total in original script. "..#tada-13 .." remaining."},
	{x=4,y=21,width=2,class="edit",name="i2",value=#data.." lines total in pasted data. "..#data-13 .." remaining."},
	}
	POP=""
	repeat
	POP,rez=ADD(POG,{"Add Left","Add Both","Send Next and Add Both","Send Next","Add Right","Unsend","Cancel"},
	{ok='Send Next',close='Cancel'})
	AL=rez.a1 AR=rez.a2 LL=rez.left RR=rez.rite
	-- Send
	sent=true
	if POP:match("Send Next") then S=0 sent=nil
	  _,brl=LL:gsub("\n","")	_,brr=RR:gsub("\n","")
	  if brr~=brl then
	    logL=MIS..brl+1 .." lines here. (End of script.) --- !!!"
	    logR=MIS..brr+1 .." lines here. (End of pasted data.) --- !!!"
	  end
	  -- Not Enough on Left
	  if brl<(rez.send) then
	    if zl<#tada then S=1 logL="!!! --- You don't have "..rez.send.." lines to send. Add more lines. "..#tada-zl.." remaining. --- !!!" end
	    if zl==#tada and zr<#data then S=1 logL="--- End of script. Some pasted data remaining. ---" end
	    if zl==#tada and zr==#data and brr~=brl then S=1 end
	  elseif zr==#data and zl<#tada then logL=MIS..brl+1 .." lines here. "..#tada-zl.." more to add. --- !!!"
	  end
	  -- Not Enough on Right
	  if brr<(rez.send) then
	    if zr<#data then S=1 logR="!!! --- You don't have "..rez.send.." lines to send. Add more lines. "..#data-zr.." remaining. --- !!!" end
	    if zr==#data and zl<#tada then S=1 logR="--- End of pasted data. Some lines in the script remaining. ---" end
	    if zr==#data and zl==#tada and brr~=brl then S=1 end
	  elseif zl==#tada and zr<#data then logR=MIS..brr+1 .." lines here. "..#data-zr.." more to add. --- !!!"
	  end
	  -- sending --
	  if S==0 then
	    LL=LL.."\n" RR=RR.."\n"
	    for l=1,rez.send do
	      table.insert(pasted,RR:match("^(.-)\n")) RR=RR:gsub("^.-\n","") LL=LL:gsub("^.-\n","")
	    end
	    LL=nRem(LL) RR=nRem(RR)
	    if #tada==zl and #data==zr and LL=="" and RR=="" then finished=true end
	    sent=true
	  end
	end
	-- Add Left
	if sent and POP:match("Add Left") or sent and POP:match("Add Both") then
	  if LL~="" then LL=LL.."\n" end
	  for i=zl+1,AL+zl do
	    if tada[i] then
		LL=LL..tada[i].."\n"
		zl=zl+1
	    end
	  end
	  LL=nRem(LL)
	end
	-- Add Right
	if sent and POP:match("Add Right") or sent and POP:match("Add Both") then
	  if RR~="" then RR=RR.."\n" end
	  for i=zr+1,AR+zr do
	    if data[i] then
		RR=RR..data[i].."\n"
		zr=zr+1
	    end
	  end
	  RR=nRem(RR)
	end
	if sent then
		logL=#tada-zl.." lines remaining in original script."
		logR=#data-zr.." lines remaining in pasted data."
		if zl==#tada then logL="--- End of script. ---" end
		if zr==#data then logR="--- End of data. ---" end
	end
	-- Unsend
	if POP=="Unsend" then
	  for u=#pasted,#pasted-rez.send+1,-1 do
	    LL=tada[u].."\n"..LL
	    RR=pasted[u].."\n"..RR
	    table.remove(pasted,u)
	  end
	end
	-- rebuild GUI
	if rez then for k,v in ipairs(POG) do
	  if v.name=="left" then v.value=LL end
	  if v.name=="rite" then v.value=RR end
	  if v.name=="i1" then v.value=logL end
	  if v.name=="i2" then v.value=logR end
	  if v.class=="intedit" then v.value=rez[v.name] end
	end end
	until POP=="Cancel" or finished
	
	if POP=="Cancel" then ak() end
	for z,i in ipairs(sel) do line=subs[i] line.text=pasted[z] subs[i]=line end
    end -- of pasteover+
    
    
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
	for z,i in ipairs(sel) do
            line=subs[i]
	    if lines[z]~=nil then
		if rez.clay then target=rez.dlay source=lines[z].layer line=shoot(line) end
		if rez.cstart then target=rez.dstart source=lines[z].start_time line=shoot(line) end
		if rez.cendt then target=rez.dendt source=lines[z].end_time line=shoot(line) end
		if rez.cstyle then target=rez.dstyle source=lines[z].style line=shoot(line) end
		if rez.cactor then target=rez.dactor source=lines[z].actor line=shoot(line) end
		if rez.ceffect then target=rez.deffect source=lines[z].effect line=shoot(line) end
		if rez.cL then target=rez.dL source=lines[z].margin_l line=shoot(line) end
		if rez.cR then target=rez.dR source=lines[z].margin_r line=shoot(line) end
		if rez.cV then target=rez.dV source=lines[z].margin_t line=shoot(line) end
		if rez.ctext then target=rez.dtext source=lines[z].text line=shoot(line) end
	    end
	    subs[i]=line
	end
    end -- of superpasta
    
    
    -- PASTE ANY TAG --
    if not special then
    overloop(subs,sel)
    warningstyles=""
    for z,i in ipairs(sel) do
      if data[z] then
        line=subs[i]
	text=line.text
	text2=data[z]
	if not text:match("^{\\") then text="{\\mc}"..text end
	if PM=="any tag" then
	  if text:match("^{[^}]-\\t") then text=text:gsub("^({[^}]-)\\t","%1"..text2.."\\t")
	  else text=text:gsub("^({\\[^}]-)}","%1"..text2.."}") end
	end
	if PM=="pos x" then text=text:gsub("(\\pos%()[^,]+","%1"..text2) end
	if PM=="pos y" then text=text:gsub("(\\pos%([^,]+,)[^,)]+","%1"..text2) end
	if PM=="layer" and text2:match('^%d+$') then line.layer=text2 end
	if PM=="margin l" and text2:match('^%d+$') then line.margin_l=text2 end
	if PM=="margin r" and text2:match('^%d+$') then line.margin_r=text2 end
	if PM=="margin v" and text2:match('^%d+$') then line.margin_t=text2 end
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
	if PM=="comments" then text2=text2:gsub("^([^{]-)(.*)([^}]-)$","{%1%2%3}") text=text..text2 end
	if PM=="text mod." then text=textmod2(text2) end
	if PM=="gbc text" then styleref=stylechk(subs,line.style) text=gbctext(text,text2) end
	if PM=="de-irc" then
	  line=string2line(text2)
	  text=line.text
	end
	if PM=="attach2text" then text=text..' '..text2 end
	 
	text=text
	:gsub(ATAG,function(tg) tg=duplikill(tg) tg=extrakill(tg,2) return tg end)
	:gsub("\\mc","")
	:gsub("{+}+","")
	line.text=text
	subs[i]=line
	end
      end
    end
    
    if warningstyles and warningstyles~="" then warningstyles=warningstyles:gsub(",,",", ") :gsub("^,","") :gsub(",$","")
     ADD({{class="label",label="Warning! These styles don't exist: "..warningstyles}},{"OK"},{close='OK'})
    end
    
    if pasteover==1 then pr,rs=ADD({
    {width=40,class="label",name="ch1",label="line       % matched    matched words"},
    {x=0,y=1,width=40,height=18,class="textbox",name="ch2",value=pasterep},
    {x=0,y=19,width=40,height=4,class="textbox",name="ch3",value=podetails},
    {x=0,y=23,width=40,class="checkbox",name="ef",label="% in effect",value=false},
    },{"OK"},{close='OK'})
    	if not rs.ef then
	  for z,i in ipairs(sel) do l=subs[i] l.effect=l.effect:gsub("%[%d+%%%]","") subs[i]=l end
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

-- paste text over while keeping tags --
function textmod2(text2)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
	vis=text2:gsub("%b{}","")
	ltrs=re.find(vis,".")
	  for l=1,#ltrs do
	    table.insert(tk,ltrs[l].str)
	  end
	stags=text:match(STAG) or ""
	text=text:gsub(STAG,"")
	count=0
	for seq in text:gmatch("[^{]-"..ATAG) do
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
    newtext=stags..newline
    text=newtext:gsub("{}","")
    return text
end

--	reanimatools	---------------------------------------------------------------------------
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function tagmerge(t) repeat t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return t end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function progress(msg) if aegisub.progress.is_cancelled() then ak() end aegisub.progress.title(msg) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

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
	if timecode==nil then t_error("Invalid timecode.",123) end
	timecode=timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)",function(a,b,c,d) return d*10+c*1000+b*60000+a*3600000 end)
	return timecode
end

function time2string(num)
	timecode=math.floor(num/1000)
	tc0=0
	tc1=math.floor(timecode/60)
	tc2=timecode%60
	numstr="00"..num
	tc3=numstr:match("(%d%d)%d$")
	repeat
	if tc2>=60 then tc2=tc2-60 tc1=tc1+1 end
	if tc1>=60 then tc1=tc1-60 tc0=tc0+1 end
	until tc2<60 and tc1<60
	if res and res.mega=="export" and tc0==1 and tc1<30 then tc0=0 tc1=tc1+60 end
	if tc1<10 then tc1="0"..tc1 end
	if tc2<10 then tc2="0"..tc2 end
	tc0=tostring(tc0)
	tc1=tostring(tc1)
	tc2=tostring(tc2)
	timestring=tc0..":"..tc1..":"..tc2.."."..tc3
	return timestring
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

function nRem(x) x=x:gsub("\n$","") return x end

cbut={"OK","Copy to clipboard"}
copydialog=
{{class="label",label="Text to export:"},
{x=1,width=49,class="label"},
{y=1,width=50,height=20,class="textbox",name="copytext"}}

herp=[[
COPY part copies specified things line by line. PASTE part pastes these things line by line.
The main idea is to copy something from X lines and paste it to another X lines.
'Copy from-to' is a quick copy function between columns. 'Switch' switches them. Copying strings to number fields does nothing.
'Attach' adds the copied value to the target value by combining them.

tags = initial tags; text = text AFTER initial tags (will include inline tags)
all = tags+text, ie. everything in the Text field
any tag = copies whatever tag(s) you specify by typing in this field, like "org", "fad", "t", or "blur,c,alpha".

export CR for pad: signs go to top with {TS} timecodes; nukes linebreaks and other CR garbage, fixes styles, etc.

Paste part:
all: this is like regular paste over from a pad, but with checks to help identify where stuff breaks if the line count is different or shifted somewhere. If you're pasting over a script that has different line splitting than it should, this will show you pretty reliably where the discrepancies are. pasteover+ goes even a bit further.

text mod.: this pastes over text while keeping inline tags. If your line is {\t1}a{\t2}b{\t3}c and you paste "def", you will get {\t1}d{\t2}e{\t3}f. This simply counts characters, so if you paste "defgh", you get {\t1}d{\t2}e{\t3}fgh, and for "d", you get {\t1}d. Comments get nuked.

gbc text: for pasting over lines with gradient by character. You get this:
[initial tags][pasted text without last character][tag that was before last character][last character of pasted text]
For colours, the gradient should be replicated in full.

de-irc: paste straight from irc with timecodes and nicknames, and stuff gets parsed correctly.

If pasted data doesn't match line count of selection, you get choices as for what you want to do.

You can use Replacer on pasted data: copy 'bord', replace 'bord' with 'shad', and paste border values as shadow values.]]

--	Config		--
function saveconfig()
mckonf="MC config\n\n"
  for key,val in ipairs(gui) do
    if val.class:match"edit" or val.class=="dropdown" then
      mckonf=mckonf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="save" then
      mckonf=mckonf..val.name..":"..tf(res[val.name]).."\n"
    end
  end
mckonfig=ADP("?user").."\\mc_config.conf"
file=io.open(mckonfig,"w")
file:write(mckonf)
file:close()
ADD({{class="label",label="Config saved to:\n"..mckonfig}},{"OK"},{close='OK'})
end

function loadconfig()
fconfig=ADP("?user").."\\mc_config.conf"
file=io.open(fconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	  for key,val in ipairs(gui) do
	    if val.class:match"edit" or val.class=="checkbox" or val.class=="dropdown" then
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

-- GUI PART
function multicopy(subs,sel)
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
ATAG="{%*?\\[^}]-}"
STAG="^{\\[^}]-}"
copytab={"tags","text","visible text","all","text pattern","------","export CR for pad","------","any tag","pos x","pos y","colour(s)","alpha","clip","------","actor","effect","style","comments","layer","margin l","margin r","margin v","duration","# of characters","# of chars (no space)","combo"}
pastab={"all","pasteover+","any tag","pos x","pos y","superpasta","gbc text","text mod.","de-irc","attach2text","------","actor","effect","style","comments","layer","margin l","margin r","margin v","duration"}
fields={"style","actor","effect","text","layer","start_time","end_time","margin_l","margin_r","margin_t"}
	gui={
	{x=0,y=19,class="label",label="Copy:"},
	{x=1,y=19,width=3,class="dropdown",name="copymode",value=CM or "tags",items=copytab},
	{x=4,y=19,class="label",label="Paste extra:"},
	{x=5,y=19,width=2,class="dropdown",name="pastemode",value=PM or "all",items=pastab},
	{x=0,y=0,width=13,height=17,class="textbox",name="dat"},
	
	{x=0,y=17,width=2,class="checkbox",name="col",label="Copy &from",hint="Copy from one column to another"},
	{x=2,y=17,width=2,class="dropdown",name="copyfrom",value=CF or "actor",items=fields},
	{x=4,y=17,class="label",label="       to"},
	{x=5,y=17,width=2,class="dropdown",name="copyto",value=CT or "effect",items=fields},
	{x=7,y=17,width=2,class="checkbox",name="switch",label="&Switch",hint="Switch the content of selected columns"},
	{x=9,y=17,width=2,class="checkbox",name="attach",label="&Attach",hint="Attach content from one column to that of another"},
	
	{x=0,y=18,class="checkbox",name="c1",label="\\c",value=true},
	{x=1,y=18,class="checkbox",name="c2",label="\\2c"},
	{x=2,y=18,class="checkbox",name="c3",label="\\3c"},
	{x=3,y=18,class="checkbox",name="c4",label="\\4c"},
	{x=4,y=18,class="checkbox",name="alf",label="\\alpha",value=true},
	{x=5,y=18,class="checkbox",name="a1",label="\\1a"},
	{x=6,y=18,class="checkbox",name="a2",label="\\2a"},
	{x=7,y=18,class="checkbox",name="a3",label="\\3a"},
	{x=8,y=18,width=2,class="checkbox",name="a4",label="\\4a"},
	
	{x=11,y=17,class="checkbox",name="rpt",label="Repeat last"},
	{x=12,y=18,class="checkbox",name="save",label="Save config",value=false},
	{x=8,y=19,width=2,class="label",label="Replacer:"},
	{x=10,y=19,width=2,class="edit",name="rep1",value=lastrep1 or "",hint="Replace this..."},
	{x=12,y=19,class="edit",name="rep2",value=lastrep2 or "",hint="...with this."},
	{x=10,y=18,width=2,class="checkbox",name="add",label="Add",hint="Replacer will instead add to the beginning/end of lines"},
	{x=12,y=17,class="label",label="MultiCopy version "..script_version}
	}
	buttons={"&Copy","Paste ta&gs","Paste &text","Paste e&xtra","Paste from clipboard","&Replace","Help","Escape"}
	repeat
	if P=="Paste from clipboard" then
		klipboard=clipboard.get()
		for key,val in ipairs(gui) do
			if val.name=="dat" then val.value=klipboard
			else val.value=res[val.name] end
		end
	end
	if P=="Help" then
	    for k,v in ipairs(gui) do
		if v.name=="dat" then v.value=herp
		else v.value=res[v.name] end
	    end
	end
	if P=="&Replace" then
	    for k,v in ipairs(gui) do
		if v.name=="dat" then
			if res.add then
				v.value=res.dat:gsub("([^\n]+)",res.rep1.."%1"..res.rep2)
			else
				v.value=res.dat:gsub(esc(res.rep1),res.rep2)
			end
		else v.value=res[v.name] end
	    end
	end
	if res and res.save then saveconfig() res.save=false P="" break end
	P,res=ADD(gui,buttons,{close='Escape'})
	until P~="Paste from clipboard" and P~="Help" and P~="&Replace"
	if P=="Escape" then ak() end
	
	if res.rpt and lastres then res=lastres end
	CM=res.copymode	PM=res.pastemode CF=res.copyfrom CT=res.copyto
	lastres=res
	if P=="&Copy" then
	  if res.col or res.attach or res.switch then copycol(subs,sel)
	  else
	    if res.copymode=="tags" then copy(subs,sel)
	    elseif res.copymode:match("text") then copyt(subs,sel)
	    elseif res.copymode=="all" then copyall(subs,sel)
	    elseif res.copymode=="export CR for pad" then crmod(subs,sel)
	    else copyc(subs,sel) end
	  end
	end
	if P=="Paste ta&gs" then paste(subs,sel) end
	if P=="Paste &text" then pastet(subs,sel) end
	if P=="Paste e&xtra" then pastec(subs,sel) end
	aegisub.set_undo_point(script_name.." - "..P)
	return sel
end

if haveDepCtrl then depRec:registerMacro(multicopy) else aegisub.register_macro(script_name,script_description,multicopy) end