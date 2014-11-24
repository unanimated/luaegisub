script_name="Unimportant"
script_description="Import stuff, number stuff, chapter stuff, replace stuff, do other stuff to stuff."
script_author="unanimated"
script_url1="http://unanimated.xtreemhost.com/ts/import.lua"
script_url2="https://raw.githubusercontent.com/unanimated/luaegisub/master/import.lua"
script_version="2.5"

require "clipboard"
re=require'aegisub.re'


--	IMPORT/EXPORT	-------------------------------------------------------------------------------------
function important(subs,sel,act)
	aline=subs[act]
	atext=aline.text
	atags=atext:match("^{(\\[^}]-)}") 
	if atags==nil then atags="" end
	atags=atags:gsub("\\move%([^%)]+%)","")
	atxt=atext:gsub("^{\\[^}]-}","")
	-- create table from user data (lyrics)
	sdata={}
	if res.mega=="update lyrics" and res.dat=="" then t_error("No lyrics given.",true)
	else
	res.dat=res.dat.."\n"
	  for dataline in res.dat:gmatch("(.-)\n") do
	    if dataline~="" then table.insert(sdata,dataline) end
	  end
	end

	-- user input
	sub1=res.rep1
	sub2=res.rep2
	sub3=res.rep3
	zer=res.zeros
	rest=res.rest
	
	-- this checks whether the pattern for lines with lyrics was found
	songcheck=0
	
	-- paths
	scriptpath=ADP("?script")
	if script_path=="relative" then path=scriptpath.."\\"..relative_path end
	if script_path=="absolute" then path=absolute_path end

	-- IMPORT -- 
	if res.mega:match("import") then
	    
	    noshift=false	defect=false	keeptxt=false	deline=false
	    
	    -- import-single-sign GUI
	    if res.mega=="import sign" then
		press,reslt=ADD({
		{x=0,y=0,width=1,height=1,class="label",label="File name:"},
		{x=0,y=1,width=2,height=1,class="edit",name="signame"},
		{x=1,y=0,width=2,height=1,class="dropdown",name="signs",items={"title","eptitle","custom","eyecatch"},value="custom"},
		{x=2,y=1,width=1,height=1,class="label",label=".ass"},
		{x=0,y=2,width=3,height=1,class="checkbox",name="matchtime",label="keep current line's times",value=true,},
		{x=0,y=3,width=3,height=1,class="checkbox",name="keeptext",label="keep current line's text",value=false,},
		{x=0,y=4,width=3,height=1,class="checkbox",name="keeptags",label="combine tags (current overrides) ",value=false,},
		{x=0,y=5,width=3,height=1,class="checkbox",name="addtags",label="combine tags (imported overrides)",value=false,},
		{x=0,y=6,width=3,height=1,class="checkbox",name="noshift",label="don't shift times (import as is)",value=false,},
		{x=0,y=7,width=3,height=1,class="checkbox",name="deline",label="delete original line",value=false,},
		},{"OK","Cancel"},{ok='OK',close='Cancel'})
		if press=="Cancel" then ak() end
		if reslt.signs=="custom" then signame=reslt.signame else signame=reslt.signs end
		noshift=reslt.noshift		keeptxt=reslt.keeptext	deline=reslt.deline
		keeptags=reslt.keeptags		addtags=reslt.addtags
	    end
	
	    -- read signs.ass
	    if res.mega=="import signs" then
		file=io.open(path.."signs.ass")
		if file==nil then ADD({{x=0,y=0,width=1,height=1,class="label",label=path.."signs.ass\nNo such file."}},{"ok"},{cancel='ok'}) ak() end
		signs=file:read("*all")
		io.close(file)
	    end
	
	    -- sort out if using OP, ED, signs, or whatever .ass and read the file
	    songtype=res.mega:match("import (%a+)")
	    if songtype=="sign" then songtype=signame end
	    file=io.open(path..songtype..".ass")
	    if file==nil then t_error(path..songtype..".ass\nNo such file.",true) end
	    song=file:read("*all")
	    io.close(file)
	    
	    -- cleanup useless stuff
	    song=song:gsub("^.-(Dialogue:)","%1")
	    song=song.."\n"
	    song=song:gsub("\n\n$","\n")
	    song=song:gsub("%[[^%]]-%]\n","\n")
	    -- make table out of lines
	    slines={}
	    for sline in song:gmatch("(.-)\n") do
		if sline~="" then table.insert(slines,sline) end
	    end
	    -- save (some) current line properties
	    btext=atext
	    basetime=aline.start_time
	    basend=aline.end_time
	    basestyle=aline.style
	    baselayer=aline.layer
	    
	    -- import-signs list and GUI
	    if res.mega=="import signs" then
		-- make a table of signs in signs.ass
		signlist={}
		signlistxt=""
		for x=1,#slines do
		    efct=slines[x]:match("%a+: %d+,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-(,[^,]-,).*")
		    --aegisub.log("\n efct "..efct)
		    esfct=esc(efct)
		    if not signlistxt:match(esfct) then signlistxt=signlistxt..efct end
		end
		for sn in signlistxt:gmatch(",([^,]-),") do table.insert(signlist,sn) end
		-- import-signs GUI
		button,reslt=ADD({
		{x=0,y=0,width=1,height=1,class="label",label="Choose a sign to import:"},
		{x=0,y=1,width=1,height=1,class="dropdown",name="impsign",items=signlist,value=signlist[1]},
		{x=0,y=2,width=1,height=1,class="checkbox",name="matchtime",label="keep current line's times",value=true,},
		{x=0,y=3,width=1,height=1,class="checkbox",name="keeptext",label="keep current line's text",value=false,},
		{x=0,y=4,width=1,height=1,class="checkbox",name="keeptags",label="combine tags (current overrides) ",value=false,},
		{x=0,y=5,width=1,height=1,class="checkbox",name="addtags",label="combine tags (imported overrides)",value=false,},
		{x=0,y=6,width=1,height=1,class="checkbox",name="noshift",label="don't shift times (import as is)",value=false,},
		{x=0,y=7,width=1,height=1,class="checkbox",name="defect",label="delete 'effect'",value=false,},
		{x=0,y=8,width=1,height=1,class="checkbox",name="deline",label="delete original line",value=false,},
		},{"OK","Cancel"},{ok='OK',close='Cancel'})
		if button=="Cancel" then ak() end
		if button=="OK" then whatsign=reslt.impsign end
		noshift=reslt.noshift		defect=reslt.defect	keeptxt=reslt.keeptext	deline=reslt.deline
		keeptags=reslt.keeptags		addtags=reslt.addtags
		-- nuke lines for the other signs
		for x=#slines,1,-1 do
		    efct=slines[x]:match("%a+: %d+,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,([^,]-),.*")
		    if efct~=whatsign then table.remove(slines,x) end
		end
	    end
	    
	    -- check start time of the first line (for overall shifting)
	    starttime=slines[1]:match("%a+: %d+,([^,]+)")
	    shiftime=string2time(starttime)
	    if res.mega:match("sign") and noshift then shiftime=0 end
	    
	    -- importing lines from whatever .ass
	    for x=#slines,1,-1 do
		local ltype,layer,s_time,e_time,style,actor,margl,margr,margv,eff,txt=slines[x]:match("(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)")
		l2=aline
		if ltype=="Comment" then l2.comment=true else l2.comment=false end
		l2.layer=layer
		-- timing/shifting depending on settings
		if res.mega:match("import sign") and reslt.matchtime then l2.start_time=basetime l2.end_time=basend else
		  s_time=string2time(s_time)
		  e_time=string2time(e_time)
		  if not noshift then s_time=s_time+basetime  e_time=e_time+basetime end
		  l2.start_time=s_time-shiftime
		  l2.end_time=e_time-shiftime
		end
		l2.style=style
		l2.actor=actor
		l2.margin_l=margl
		l2.margin_r=margr
		l2.margin_t=margv
		l2.effect=eff
		if defect then l2.effect="" end
		l2.text=txt
		atext=txt 
		if keeptxt and actor~="x" then
		    btext2=btext:gsub("{\\[^}]-}","")
		    l2.text=l2.text:gsub("^({\\[^}]-}).*","%1"..btext2) atext=btext2
		end
		if keeptags and actor~="x" then
		    l2.text=addtag(atags,l2.text)
		    l2.text=l2.text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
		end
		if addtags and actor~="x" then
		    l2.text="{"..atags.."}"..l2.text
		    l2.text=l2.text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		    :gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
		end
		
		--aegisub.log("\n btext "..btext)
		subs.insert(act+1,l2)
	    end
	    -- delete line if not keeping
	    if deline then res.keep=false end
	    if not res.keep then subs.delete(act) else 
	    -- keep line, restore initial state + comment out
	    atext=btext aline.comment=true aline.start_time=basetime aline.end_time=basend aline.style=basestyle aline.actor="" aline.effect=""
	    aline.layer=baselayer aline.text=atext subs[act]=aline
	    end
	end
	
	-- EXPORT --
	if res.mega=="export sign" then
	    exportsign=""
	    for x, i in ipairs(sel) do
            line=subs[i]
            text=line.text
	    if x==1 then snam=line.effect end
	    exportsign=exportsign..line.raw.."\n"
	    end
	    press,reslt=ADD({
		{x=0,y=0,class="label",label="Target:",},
		{x=0,y=1,class="label",label="Name:",},
		{x=1,y=0,width=2,height=1,class="dropdown",name="addsign",
			items={"Add to signs.ass","Save to new file:"},value="Add to signs.ass"},
		{x=1,y=1,width=2,height=1,class="edit",name="newsign",value=snam},
		},{"OK","Cancel"},{ok='OK',close='Cancel'})
	    if press=="Cancel" then ak() end
	    if press=="OK" then
	    if reslt.newsign=="" then t_error("No name supplied.",true) end
	    newsgn=reslt.newsign:gsub("%.ass$","")
	    if reslt.addsign=="Add to signs.ass" then 
		file=io.open(path.."signs.ass")
		sign=file:read("*all")
		file:close()
		exportsign=exportsign:gsub("(%u%a+: %d+,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-),[^,]-,(.-)\n","%1,"..reslt.newsign..",%2\n")
		sign=sign:gsub("%u%a+:.-,"..esc(reslt.newsign)..",.-\n","") :gsub("^\n*","")
		sign=sign.."\n"..exportsign
		file=io.open(path.."signs.ass","w")
		file:write(sign)
	    end
	    if reslt.addsign=="Save to new file:" then
		file=io.open(path..newsgn..".ass","w")
		file:write(exportsign)
	    end
	    file:close()
	    end
	end

	-- Update Lyrics
	if res.mega=="update lyrics" then
	  sup1=esc(sub1)	sup2=esc(sub2)
	  for x, i in ipairs(sel) do
	  progress("Updating Lyrics... "..round(x/#sel)*100 .."%")
            local line=subs[i]
            local text=subs[i].text
	
		songlyr=sdata
		if line.style:match(rest) then stylecheck=1 else stylecheck=0 end
		if res.restr and stylecheck==0 then pass=0 else pass=1 end
		if res.field=="actor" then marker=line.actor
		elseif res.field=="effect" then marker=line.effect end
		denumber=marker:gsub("%d","")
		-- marked lines
		if marker:match(sup1.."%d+"..sup2) and denumber==sub1..sub2 and pass==1 then
		    index=tonumber(marker:match(sup1.."(%d+)"..sup2))
		    puretext=text:gsub("{%*?\\[^}]-}","")
		    lastag=text:match("({\\[^}]-}).$")
		    if songlyr[index]~=nil and songlyr[index]~=puretext then
			text=text:gsub("^({\\[^}]-}).*","%1"..songlyr[index])
			if not text:match("^{\\[^}]-}") then text=songlyr[index] end
		    end
		    songcheck=1
		    if songlyr[index]~=puretext then
			if lastag~=nil then text=text:gsub("(.)$",lastag.."%1") end
			change="   (Changed)"
			else change=""
		    end
		    aegisub.log("\nupdate: "..puretext.." --> "..songlyr[index]..change)
		end
	    line.text=text
	    subs[i]=line
	  end
	end
    
    if res.mega=="update lyrics" and songcheck==0 then press,reslt=ADD({{x=0,y=0,width=1,height=1,class="label",label="The "..res.field.." field of selected lines doesn't match given pattern \""..sub1.."#"..sub2.."\".\n(Or style pattern wasn't matched if restriction enabled.)\n#=number sequence"}},{"ok"},{cancel='ok'}) end
    
    noshift=nil		defect=nil	keeptxt=nil	deline=nil	keeptags=nil	addtags=nil
end




--	 NUMBERS	-------------------------------------------------------------------------------------
function numbers(subs,sel)
    z=zer:len()
	if sub3:match("[,/;]") then startn,int=sub3:match("(%d+)[,/;](%d+)") else startn=sub3:gsub("%[.-%]","") int=1 end
	if sub3:match("%[") then numcycle=tonumber(sub3:match("%[(%d+)%]")) else numcycle=0 end
	if sub3=="" then startn=1 end
	startn=tonumber(startn)
	if startn==nil or numcycle>0 and startn>numcycle then t_error("Wrong parameters.",true) end
	
    for i=1,#sel do
        line=subs[sel[i]]
        text=subs[sel[i]].text
	
	if res.modzero=="number lines" then
	progress("Numbering... "..round(i/#sel)*100 .."%")
		index=i
		count=math.ceil(index/int)+(startn-1)
		  if numcycle>0 and count>numcycle then repeat count=count-(numcycle-startn+1) until count<=numcycle end
		count=tostring(count)
		if z>count:len() then repeat count="0"..count until z==count:len() end
		number=sub1..count..sub2
		
		if res.field=="actor" then line.actor=number end 
		if res.field=="effect" then line.effect=number end
		if res.field=="layer" then line.layer=count end
	end
	
	if res.modzero=="add to marker" then
	progress("Adding... "..round(i/#sel)*100 .."%")
		if res.field=="actor" then line.actor=sub1..line.actor..sub2
		elseif res.field=="effect" then line.effect=sub1..line.effect..sub2
		elseif res.field=="text" then text=sub1..text..sub2
		end
	end

	line.text=text
	subs[sel[i]]=line
    end
end




--	CHAPTERS	-------------------------------------------------------------------------------------
function chopters(subs,sel)
  if res.marker=="effect" and res.nam=="effect" then t_error("Error. Both marker and name cannot be 'effect'.",true) end
  if res.chmark then
    if res.lang~="" then kap=res.lang else kap=res.chap end
    for x, i in ipairs(sel) do
      line=subs[i]
      text=line.text
	if res.marker=="actor" then line.actor="chptr" end
	if res.marker=="effect" then line.effect="chptr" end
	if res.marker=="comment" then text=text.."{chptr}" end
	if res.nam=="effect" then line.effect=kap end
	if res.nam=="comment" then text="{"..kap.."}"..text end
      line.text=text
      subs[i]=line
    end
  else
	euid=2013
	chptrs={}
	subchptrs={}
	if res.lang=="" then clang="eng" else clang=res.lang end
    for i=1, #subs do
      if subs[i].class == "info" then
	if subs[i].key=="Video File" then videoname=subs[i].value  videoname=videoname:gsub("%.mkv","") end
      end
      
      if subs[i].class == "dialogue" then
        local line=subs[i]
	local text=subs[i].text
	local actor=line.actor
	local effect=line.effect
	local start=line.start_time
	if text:match("{[Cc]hapter}") or text:match("{[Cc]hptr}") or text:match("{[Cc]hap}") then comment="chapter" else comment="" end
	if res.marker=="actor" then marker=actor:lower() end
	if res.marker=="effect" then marker=effect:lower() end
	if res.marker=="comment" then marker=comment:lower() end
	
	    if marker=="chapter" or marker=="chptr" or marker=="chap" then
		if res.nam=="comment" then
		name=text:match("^{([^}]*)}")
		name=name:gsub(" [Ff]irst [Ff]rame","")
		name=name:gsub(" [Ss]tart","")
		name=name:gsub("part a","Part A")
		name=name:gsub("part b","Part B")
		name=name:gsub("preview","Preview")
		else
		name=effect
		end
		
		if name:match("::") then main,subname=name:match("(.+)::(.+)") sub=1
		else sub=0
		end
		
		lineid=start+2013
		
		timecode=math.floor(start/1000)
		tc1=math.floor(timecode/60)
		tc2=timecode%60
		tc3=start%1000
		tc4="00"
		if tc2==60 then tc2=0 tc1=tc1+1 end
		if tc1>119 then tc1=tc1-120 tc4="02" end
		if tc1>59 then tc1=tc1-60 tc4="01" end
		if tc1<10 then tc1="0"..tc1 end
		if tc2<10 then tc2="0"..tc2 end
		if tc3<100 then tc3="0"..tc3 end
		linetime=tc4..":"..tc1..":"..tc2.."."..tc3
		if linetime=="00:00:00.00" then linetime="00:00:00.033" end
		
		if sub==0 then
		cur_chptr={id=lineid,name=name,tim=linetime}
		table.insert(chptrs,cur_chptr)
		else
		cur_chptr={id=lineid,subname=subname,tim=linetime,main=main}
		table.insert(subchptrs,cur_chptr)
		end
	    
	    end
	if line.style=="Default" then euid=euid+text:len() end
      end
    end

	-- subchapters
	subchapters={}
    for c=1,#subchptrs do
	local ch=subchptrs[c]
	
	ch_main=ch.main
	ch_uid=ch.id
	ch_name=ch.subname
	ch_time=ch.tim
	
	schapter="      <ChapterAtom>\n        <ChapterDisplay>\n          <ChapterString>"..ch_name.."</ChapterString>\n          <ChapterLanguage>"..clang.."</ChapterLanguage>\n        </ChapterDisplay>\n        <ChapterUID>"..ch_uid.."</ChapterUID>\n        <ChapterTimeStart>"..ch_time.."</ChapterTimeStart>\n        <ChapterFlagHidden>0</ChapterFlagHidden>\n        <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      </ChapterAtom>\n"
	
	subchapter={main=ch_main,chap=schapter}
	table.insert(subchapters,subchapter)
    end
    
	-- chapters
	insert_chapters=""
	
	if res.intro then
	insert_chapters="    <ChapterAtom>\n      <ChapterUID>"..#subs.."</ChapterUID>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>Intro</ChapterString>\n        <ChapterLanguage>"..clang.."</ChapterLanguage>\n      </ChapterDisplay>\n      <ChapterTimeStart>00:00:00.033</ChapterTimeStart>\n    </ChapterAtom>\n"
	
	end
	
	table.sort(chptrs,function(a,b) return a.tim<b.tim end)
	
    for c=1,#chptrs do
	local ch=chptrs[c]
	
	ch_uid=ch.id
	ch_name=ch.name
	ch_time=ch.tim
	
	local subchaps=""
	for c=1,#subchapters do 
	local subc=subchapters[c]
	if subc.main==ch_name then subchaps=subchaps..subc.chap end
	end
	
	chapter="    <ChapterAtom>\n      <ChapterUID>"..ch_uid.."</ChapterUID>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>"..ch_name.."</ChapterString>\n        <ChapterLanguage>"..clang.."</ChapterLanguage>\n      </ChapterDisplay>\n"..subchaps.."      <ChapterTimeStart>"..ch_time.."</ChapterTimeStart>\n    </ChapterAtom>\n"

	insert_chapters=insert_chapters..chapter
    end
	
	chapters="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<Chapters>\n  <EditionEntry>\n    <EditionFlagHidden>0</EditionFlagHidden>\n    <EditionFlagDefault>0</EditionFlagDefault>\n    <EditionUID>"..euid.."</EditionUID>\n"..insert_chapters.."  </EditionEntry>\n</Chapters>"
   
    chdialog=
	{{x=0,y=0,width=35,height=1,class="label",label="Text to export:"},
	{x=0,y=1,width=35,height=20,class="textbox",name="copytext",value=chapters},
	{x=0,y=21,width=35,height=1,class="label",label="File will be saved in the same folder as the .ass file."},}
	
    pressed,reslt=ADD(chdialog,{"Save xml file","Cancel","Copy to clipboard",},{cancel='Cancel'})
    if pressed=="Copy to clipboard" then    clipboard.set(chapters) end
    if pressed=="Save xml file" then    
	scriptpath=ADP("?script")
	scriptname=aegisub.file_name()
	scriptname=scriptname:gsub("%.ass","")
	
	if ch_script_path=="relative" then path=scriptpath.."\\"..relative_path end
	if ch_script_path=="absolute" then path=absolute_path end
	
	if res.sav=="script" then filename=scriptname else filename=videoname end
	local file=io.open(path.."\\"..filename..".xml", "w")
	file:write(chapters)
	file:close()
    end
  end
end




--	STUFF	-------------------------------------------------------------------------------------
function stuff(subs,sel)
    repl=0
    data={}	raw=res.dat.."\n"
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    
    -- DATES GUI --
    if res.stuff=="format dates" then
	dategui=
	{{x=0,y=0,class="dropdown",name="date",value="January 1st",items={"January 1","January 1st","1st of January","1st January"}},
	{x=1,y=0,class="checkbox",name="log",label="log",value=false,}}
	pres,rez=ADD(dategui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
	datelog=""
    end
    
    -- MOTION BLUR GUI
    if res.stuff=="motion blur" then
	mblurgui={
	  {x=0,y=0,width=2,class="checkbox",name="keepblur",label="Keep current blur...",value=true},
	  {x=0,y=1,class="label",label="...or use blur:"},
	  {x=1,y=1,class="floatedit",name="mblur",value=mblur or 3},
	  
	  {x=0,y=2,class="label",label="Distance:"},
	  {x=1,y=2,class="floatedit",name="mbdist",value=mbdist or 6},
	  
	  {x=0,y=3,class="label",label="Alpha: "},
	  {x=1,y=3,class="dropdown",name="mbalfa",value=mbalfa or "80",items={"00","20","40","60","80","A0","C0","D0"}},
	  
	  {x=0,y=4,width=2,class="checkbox",name="mb3",label="Use 3 lines instead of 2",value=mb3},
	  {x=0,y=5,width=2,class="label",label="Direction = first 2 points of a clip"},
	}
	pres,rez=ADD(mblurgui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
	mblur=rez.mblur mbdist=rez.mbdist mbalfa=rez.mbalfa mb3=rez.mb3
    end
    
    -- EXPLODE GUI --
    if res.stuff=="explode" then
	-- remember values
	if exploded then
	    exx=expl_dist_x exy=expl_dist_y htype=ex_hor vtype=ex_ver expropx=xprop expropy=yprop exf=exfad cfad=cfade
	    exinvx=xinv exinvy=yinv implo=implode exquence=exseq exkom=excom seqinv=invseq seqpercent=seqpc rmmbr=exremember
	else
	    exx=0 exy=0 htype="all" vtype="all" expropx=false expropy=false exf=0 cfad=0 exinvx=false exinvy=false
	    implo=false exquence=false exkom=false seqinv=false seqpercent=100 rmmbr=false
	end
	explodegui={
	  {x=0,y=0,class="label",label="Horizontal distance: "},
	  {x=1,y=0,class="floatedit",name="edistx",value=exx,hint="Maximum horizontal distance for move"},
	  {x=0,y=1,class="label",label="Vertical distance: "},
	  {x=1,y=1,class="floatedit",name="edisty",value=exy,hint="Maximum vertical distance for move"},
	  
	  {x=2,y=0,class="label",label="direction: "},
	  {x=3,y=0,class="dropdown",name="hortype",value=htype,items={"only left","mostly left","all","mostly right","only right"}},
	  {x=4,y=0,class="checkbox",name="xprop",label="proportional",value=expropx,hint="Uniform move rather than random"},
	  {x=5,y=0,class="checkbox",name="xinv",label="inverse",value=exinvx,hint="Uniform move in the other direction"},
	  
	  {x=2,y=1,class="label",label="direction: "},
	  {x=3,y=1,class="dropdown",name="vertype",value=vtype,items={"only up","mostly up","all","mostly down","only down"}},
	  {x=4,y=1,class="checkbox",name="yprop",label="proportional",value=expropy,hint="Uniform move rather than random"},
	  {x=5,y=1,class="checkbox",name="yinv",label="inverse",value=exinvy,hint="Uniform move in the other direction"},
	  
	  {x=0,y=2,class="checkbox",name="ecfo",label="Custom fade:",hint="Default is line length",value=cfad},
	  {x=1,y=2,class="floatedit",name="exfad",value=exf},
	  
	  {x=2,y=2,class="checkbox",name="exseq",label="sequence",value=exquence,hint="move in a sequence instead of all at the same time"},
	  {x=3,y=2,class="floatedit",name="seqpc",value=seqpercent,step=nil,min=1,max=100,hint="how much time should the sequence take up"},
	  {x=4,y=2,class="label",label="% of move"},
	  {x=5,y=2,class="checkbox",name="invseq",label="inverse",value=seqinv,hint="inverse sequence"},
	  
	  {x=0,y=3,class="checkbox",name="impl",label="Implode",value=implo},
	  {x=1,y=3,class="checkbox",name="rem",label="Same for all lines",value=rmmbr,hint="use only for layered lines with the same text"},
	  {x=3,y=3,class="checkbox",name="excom",label="Leave original line commented out",value=exkom,width=3},
	}
	pres,rez=ADD(explodegui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
    	expl_dist_x=rez.edistx	expl_dist_y=rez.edisty
	exfad=rez.exfad		cfade=rez.ecfo
	ex_hor=rez.hortype	ex_ver=rez.vertype
	xprop=rez.xprop		yprop=rez.yprop
	xinv=rez.xinv		yinv=rez.yinv
	implode=rez.impl	exseq=rez.exseq
	seqpc=round(rez.seqpc)	invseq=rez.invseq
	exremember=rez.rem	excom=rez.excom
	exploded=true
    end
    
    -- Randomized Transforms GUI --
    if res.stuff=="randomized transforms" then
	rine=subs[sel[1]]
	durone=rine.end_time-rine.start_time
	rtgui={
	  {x=0,y=0,class="checkbox",name="rtfad",label="Random Fade",width=2,value=true},
	  {x=0,y=1,class="checkbox",name="rtdur",label="Random Duration",width=2,value=true},
	  {x=2,y=0,class="label",label="Min: "},
	  {x=2,y=1,class="label",label="Max: "},
	  {x=3,y=0,class="floatedit",name="minfad",width=1,value=math.floor(durone/5),min=0},
	  {x=3,y=1,class="floatedit",name="maxfad",width=1,value=durone},
	  {x=4,y=0,class="checkbox",name="rtin",label="Fade In",width=3,value=false,hint="In instead of Out"},
	  {x=4,y=1,class="checkbox",name="maxisdur",label="Max = Current Duration",width=4,value=true,hint="The maximum will be the duration of each selected line"},
	  
	  {x=0,y=3,class="label",label="Transform"},
	  {x=1,y=3,class="dropdown",name="rttag",value="blur",
	    items={"blur","bord","shad","fs","fsp","fscx","fscy","fax","fay","frz","frx","fry","xbord","ybord","xshad","yshad"}},
	  {x=2,y=3,class="label",label="Min: "},
	  {x=4,y=3,class="label",label=" Max: "},
	  {x=3,y=3,class="floatedit",name="mintfn",width=1,value=0,hint="Minimum value for a given tag"},
	  {x=5,y=3,class="floatedit",name="maxtfn",width=3,value=0,hint="Maximum value for a given tag"},
	  
	  {x=0,y=4,class="label",width=2,label="Colour Transform"},
	  {x=2,y=4,class="label",label="Max: "},
	  {x=3,y=4,class="floatedit",name="rtmaxc",value=100,min=1,max=100,hint="Maximum % of colour change.\nColour tag must be present. Otherwise set to 100%."},
	  {x=4,y=4,class="label",label="%"},
	  {x=5,y=4,class="checkbox",name="rtc1",label="\\c ",value=true},
	  {x=6,y=4,class="checkbox",name="rtc3",label="\\3c ",value=false},
	  {x=7,y=4,class="checkbox",name="rtc4",label="\\4c ",value=false},
	  
	  {x=0,y=5,class="checkbox",name="rtacc",label="Use Acceleration",width=2,value=false},
	  {x=2,y=5,class="label",label="Min: "},
	  {x=3,y=5,class="floatedit",name="minacc",width=1,value=1,min=0},
	  {x=4,y=5,class="label",label=" Max:"},
	  {x=5,y=5,class="floatedit",name="maxacc",width=3,value=1,min=0},
	  
	  {x=0,y=6,class="checkbox",name="rtmx",label="Random Move X",width=2,value=false},
	  {x=2,y=6,class="label",label="Min: "},
	  {x=3,y=6,class="floatedit",name="minmx",width=1,value=0},
	  {x=4,y=6,class="label",label=" Max:"},
	  {x=5,y=6,class="floatedit",name="maxmx",width=3,value=0},
	  
	  {x=0,y=7,class="checkbox",name="rtmy",label="Random Move Y",width=2,value=false},
	  {x=2,y=7,class="label",label="Min: "},
	  {x=3,y=7,class="floatedit",name="minmy",width=1,value=0},
	  {x=4,y=7,class="label",label=" Max:"},
	  {x=5,y=7,class="floatedit",name="maxmy",width=3,value=0},
	}
	if rtremember then
	    for key,val in ipairs(rtgui) do
		if val.class~="label" then val.value=rez[val.name] end
	    end
	end
	rtchoice={"Fade/Duration","Number Transform","Colour Transform","Help","Cancel"}
	rthlp={"Fade/Duration","Number Transform","Colour Transform","Cancel"}
	pres,rez=ADD(rtgui,rtchoice,{ok='Fade/Duration',close='Cancel'})
	if pres=="Help" then
	    rthelp={x=0,y=8,width=8,height=4,class="textbox",value="This is supposed to be used after 'split into letters' or with gradients.\n\nFade/Duration Example:  Min: 500, Max: 2000.\nA random number between those is generated for each line, let's say 850.\nThis line's duration will be 850ms, and it will have a 850ms fade out.\n\nNumber Transform Example:  Blur, Min: 0.6, Max: 2.5\nRandom number generated: 1.7. Line will have: \\t(\\blur1.7)\n\nRandom Colour Transform creates transforms to random colours. \nMax % transform limits how much the colour can change.\n\nAccel works with either transform function.\n\nRandom Move works as an additional option with any function.\nIt can be used on its own if you uncheck other stuff. Works with Fade In."}
	    table.insert(rtgui,rthelp)
	    pres,rez=ADD(rtgui,rthlp,{ok='Fade/Duration',close='Cancel'})
	end
	if pres=="Cancel" then ak() end
	if pres=="Fade/Duration" then RTM="FD" end
	if pres=="Number Transform" then RTM="NT" end
	if pres=="Colour Transform" then RTM="CT" end
	rtremember=true
	RTF=rez.rtfad	RTD=rez.rtdur
	MnF=rez.minfad	MxF=rez.maxfad
	RTin=rez.rtin	RTMax=rez.maxisdur
	RTT=rez.rttag	MnT=rez.mintfn		MxT=rez.maxtfn
	RTA=rez.rtacc	MnA=rez.minacc	MxA=rez.maxacc
	MnX=rez.minmx	MxX=rez.maxmx	MnY=rez.minmy	MxY=rez.maxmy
	MxC=round(rez.rtmaxc*255/100)
	rtcol={}
	if rez.rtc1 then table.insert(rtcol,1) end
	if rez.rtc3 then table.insert(rtcol,3) end
	if rez.rtc4 then table.insert(rtcol,4) end
    end
    
    -- Clone Clip GUI --
    if res.stuff=="clone clip" then
	if clone_h then cchc=clone_h else cchc=2 end
	if clone_v then ccvc=clone_v else ccvc=2 end
	if dist_h then cchd=dist_h else cchd=20 end
	if dist_v then ccvd=dist_v else ccvd=20 end
	if ccshift then ccsh=ccshift else ccsh=0 end
	ccgui={
	  {x=0,y=0,class="label",label="Horizontal distance:  "},
	  {x=1,y=0,class="intedit",name="hdist",value=cchd,min=1},
	  {x=0,y=1,class="label",label="Horizontal clones:  "},
	  {x=1,y=1,class="intedit",name="hclone",value=cchc,min=1},
	  {x=0,y=2,class="label",label="Vertical distance:  "},
	  {x=1,y=2,class="intedit",name="vdist",value=ccvd,min=1},
	  {x=0,y=3,class="label",label="Vertical clones:  "},
	  {x=1,y=3,class="intedit",name="vclone",value=ccvc,min=1},
	  {x=0,y=4,class="label",label="Shift even rows by:"},
	  {x=1,y=4,class="intedit",name="ccshift",value=ccsh,min=0},
	}
	pres,rez=ADD(ccgui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then ak() end
	clone_h=rez.hclone	dist_h=rez.hdist
	clone_v=rez.vclone	dist_v=rez.vdist
	ccshift=rez.ccshift
    end
    
    -- DISSOLVE GUI ---------------------------------------------------------------------------------------------
    if res.stuff=="dissolve text" then
	if dlast then ddistance=v_dist ddlines=dlines dshape=shape dalter=alternate dissin=disin otherd=otherdis v2direction=v2d
	else ddistance=10 ddlines=10 dshape="square" dalter=true dissin=false otherd=false v2direction="randomly"
	end
	dissgui={
	  {x=0,y=0,class="label",label="Distance between points:  "},
	  {x=1,y=0,class="floatedit",name="ddist",value=ddistance,min=4,step=2},
	  {x=0,y=1,class="label",label="Shape of clips:"},
	  {x=1,y=1,class="dropdown",name="shape",items={"square","square 2","diamond","triangle 1","triangle 2","hexagon","wave/hexagram","vertical lines","horizontal lines"},value=dshape},
	  {x=0,y=2,class="checkbox",name="alt",label="Shift even rows (all except vertical/horizontal lines)",value=dalter,width=2},
	  {x=0,y=3,class="checkbox",name="disin",label="Reverse effect (fade in rather than out)",value=dissin,width=2},
	  {x=0,y=4,class="checkbox",name="otherdiss",label="Dissolve v2.  ...  Lines:",value=otherd,hint="only square, diamond, vertical lines"},
	  {x=1,y=4,class="floatedit",name="modlines",value=ddlines,min=6,step=2},
	  {x=0,y=5,class="label",label="      Dissolve v2:   Dissolve"},
	  {x=1,y=5,class="dropdown",name="v2dir",items={"randomly","from top","from bottom","from left","from right"},value=v2direction},
	}
	pres,rez=ADD(dissgui,{"OK","What Is This","Cancel"},{ok='OK',close='Cancel'})
	if pres=="What Is This" then
	    dishelp={x=0,y=6,width=10,height=8,class="textbox",value="The script can either automatically draw a clip around the text,\nor you can make your own clip.\nThe automation only considers position, alignment, and scaling,\nso for anything more complex, make your own.\nYou can just try it without a clip,\nand if the result isn't right, draw a clip first. (Only 4 points!)\n\n'Distance between points' will be the distance between the\nstarting points of all the little iclips.\nLess Distance = more clips = more lag,\nso use the lowest values only for smaller text.\nYou can run this on one line or fbf lines.\nThe ideal 'fade' is as many frames as the given Distance.\nThat way the clips grow by 1 pixel per frame.\nAny other way doesn't look too good,\nbut you can apply Distance 10 over 20 lines\nand have each 2 consecutive lines identical.\nMore Distance than lines doesn't look so bad, and the effect is 'faster'.\nIf you apply this to 1 line, the line will be split to have the effect applied to as many frames as the Distance is. (This is preferred.)\nFor hexagon, the actual distance is twice the input. (It grows faster.)\n\nThe shapes should be self-explanatory, so just experiment.\n\n'Shift even rows' means that even rows will have an offset\nfrom odd rows by half of the given Distance.\nNot checking this will have a slightly different and less regular effect,\nthough it also depends on the shape. Again, experiment.\n\nIf you need to apply this to several layers, you have to do it one by one. The GUI remembers last values. But more layers = more lag.\n\nAll kinds of things can make this lag, so use carefully.\nLines are less laggy than other shapes.\nHorizontal lines are the least laggy. (Unless you have vertical text.)\n\nFor longer fades, use more Distance.\nThis works great with vertical lines but is pretty useless with horizontal.\n\n'Reverse effect' is like fade in while the default is fade out.\nWith one line selected, it applies to the first frames.\n\n'Dissolve v2' is a different kind of dissolve\nand only works with square, diamond, and vertical lines.\nLine count for this is independent on distance between points.\nIt's the only effect that allows Distance 4.\n'Shift even rows' has no effect here.\n\nYou can set a direction of Dissolve v2.\nObviously top and bottom is nonsense for vertical lines.\n'Reverse effect' reverses the direction too, so choose the opposite.\n\nThere may be weird results with some combinations of settings.\nThere may be some malfunctions, as the script is pretty complex.\nSome of them -might- be fixed by reloading automation scripts.\nMakes no sense with \\move. Nukes \\fad.\n\nThere are some fun side effects.\nFor example with 'square 2' and 'Shift even rows',\nyou get a brick wall on the last frame."}
	    table.insert(dissgui,dishelp)
	    pres,rez=ADD(dissgui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	end
	if pres=="Cancel" then ak() end
	dlast=true
	v_dist=rez.ddist
	shape=rez.shape
	alternate=rez.alt
	disin=rez.disin
	otherdis=rez.otherdiss
	dlines=rez.modlines
	v2d=rez.v2dir
	dis2=false
	if v2d=="randomly" then dir=5 end
	if v2d=="from top" then dir=8 end
	if v2d=="from bottom" then dir=2 end
	if v2d=="from left" then dir=4 end
	if v2d=="from right" then dir=6 end
	if not otherdis and v_dist==4 then
	  t_error("Distance 4 is only allowed for square mod. Changing to 6.")
	  v_dist=6
	end
	if otherdis then
	    if shape=="square" or shape=="diamond" or shape=="vertical lines" then dis2=true else dis2=false end
	    if shape=="square" then alternate=false end
	    if shape=="diamond" then alternate=true end
	end
	if dis2 and #sel==1 then linez=dlines 
	elseif dis2 and #sel>1 then linez=#sel
	else linez=v_dist end
	
	-- DISSOLVE create lines if only one selected ------------------------
	if #sel==1 then
	    rine=subs[sel[1]]
	    rine.text=rine.text:gsub("\\fad%(.-%)","")
	    start=rine.start_time	    endt=rine.end_time
	    startf=ms2fr(start)		    endf=ms2fr(endt)
	    lframes=ms2fr(endt-start)
	      if lframes<linez then t_error("Line must be at least "..linez.." frames long.",true) end
	    if disin then
	      for l=1,linez do
		rine.start_time=fr2ms(startf+l-1)
		rine.end_time=fr2ms(startf+l)
		subs.insert(sel[1],rine)
		sel[1]=sel[1]+1
	      end
	      for s=1,linez do   table.insert(sel,sel[1]-s)   end
	      table.sort(sel)
	      rine.start_time=fr2ms(startf+linez)
	      rine.end_time=endt
	      subs[sel[#sel]]=rine
	      table.remove(sel,#sel)
	    else
	      for l=1,linez do
		rine.start_time=fr2ms(endf-l)
		rine.end_time=fr2ms(endf-l+1)
		subs.insert(sel[1]+1,rine)
	      end
	      for s=1,linez do   table.insert(sel,sel[1]+s)   end
	      rine.start_time=start
	      rine.end_time=fr2ms(endf-linez)
	      subs[sel[1]]=rine
	      table.remove(sel,1)
	    end
	end
    if disin then table.sort(sel,function(a,b) return a>b end) end
    
    -- DISSOLVE Initial Calculations -----------------------------------------------------------------
    line=subs[sel[1]]
    text=line.text
	text=text:gsub("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d) 
		a=math.floor(a) b=math.floor(b) c=math.ceil(c) d=math.ceil(d) 
		return string.format("\\clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
	-- draw clip when no clip present
	if not text:match("\\clip") then
	    styleref=stylechk(subs,line.style)
	    vis=text:gsub("{[^}]-}","")
	    width,height,descent,ext_lead=aegisub.text_extents(styleref,vis)
	    bord=text:match("\\bord([%d%.]+)")	if bord==nil then bord=styleref.outline end
	    bord=math.ceil(bord)
	    scx=text:match("\\fscx([%d%.]+)")	if scx==nil then scx=styleref.scale_x end	scx=scx/100
	    scy=text:match("\\fscy([%d%.]+)")	if scy==nil then scy=styleref.scale_y end	scy=scy/100
	    wi=round(width)
	    he=round(height)
	    text2=getpos(subs,text)
	    if not text:match("\\pos") then text=text2 end
	    xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	    if h_al=="left" then	cx1=xx			cx2=xx+wi*scx end
	    if h_al=="right" then	cx1=xx-wi*scx		cx2=xx end
	    if h_al=="mid" then	cx1=xx-wi/2*scx		cx2=xx+wi/2*scx end
	    if v_al=="top" then	cy1=yy			cy2=yy+he*scy end
	    if v_al=="bottom" then	cy1=yy-he*scy		cy2=yy end
	    if v_al=="mid" then	cy1=yy-he/2*scy		cy2=yy+he/2*scy end
	    cx1=math.floor(cx1-bord)   cx2=math.ceil(cx2+bord)
	    cy1=math.floor(cy1-bord)   cy2=math.ceil(cy2+bord)
	    text=addtag("\\clip(m "..cx1.." "..cy1.." l "..cx2.." "..cy1.." "..cx2.." "..cy2.." "..cx1.." "..cy2..")",text)
	end
	-- get outermost clip points even if it's irregular (though it should be fucking regular)
	exes={} wais={}
	klip=text:match("\\clip%(m [%d%-]+ [%d%-]+ l [%d%-]+ [%d%-]+ [%d%-]+ [%d%-]+ [%d%-]+ [%d%-]+")
	for ex,wai in klip:gmatch("([%d%-]+) ([%d%-]+)") do
		table.insert(exes,tonumber(ex))
		table.insert(wais,tonumber(wai))
	end
	table.sort(exes)	  table.sort(wais)
	x1=exes[1]-2	  x2=exes[4]+2	  y1=wais[1]-2	  y2=wais[4]+2
	width=x2-x1	height=y2-y1
	h_dist=2*v_dist
	if shape=="hexagon" then h_dist=math.floor(h_dist*2) end
	rows=math.ceil(height/v_dist)
	rows2=math.ceil(height/v_dist/2)
	points=math.ceil(width/h_dist)+1
	if shape=="horizontal lines" then vert=2*v_dist rows=math.ceil(rows/2)+1 else vert=v_dist end
	if shape:match("triangle") or shape=="wave/hexagram" then rows=rows+1 end
	  
	xpoints={}
	for w=1,points do point=x1+h_dist*(w-1) table.insert(xpoints,point) end
	ypoints={}
	for w=1,rows do point=y1+vert*(w-1) table.insert(ypoints,point) end
	ypoints2={}
	for w=1,rows2 do point=y1+2*v_dist*(w-1) table.insert(ypoints2,point) end
	  
	-- this is all centers of individual iclip shapes
	allpoints1={}
	for w=1,#ypoints do
	    for z=1,#xpoints do
		u=0
		if alternate and w%2==0 then u=h_dist/2 else u=0 end	-- every even row is shifted by half of h_dist from odd rows
		rnum=math.random(2000,6000)
		if dir==5 then rindex=rnum end
		if dir==8 then rindex=rnum*ypoints[w]^2 end
		if dir==4 then rindex=rnum*xpoints[z]^2 end
		if dir==2 then rindex=0-rnum*ypoints[w]^2 end
		if dir==6 then rindex=0-rnum*xpoints[z]^2 end
		point={xpoints[z]+u,ypoints[w],rindex}
		table.insert(allpoints1,point)
	    end
	end
	  
	allpoints2={}
	for w=1,#ypoints2 do
	    for z=1,#xpoints do
		u=0
		if alternate and w%2==0 then u=h_dist/2 else u=0 end	-- every even row is shifted by half of h_dist from odd rows
		rnum=math.random(2000,6000)
		if dir==5 then rindex=rnum end
		if dir==8 then rindex=rnum*ypoints2[w]^2 end
		if dir==4 then rindex=rnum*xpoints[z]^2 end
		if dir==2 then rindex=0-rnum*ypoints2[w]^2 end
		if dir==6 then rindex=0-rnum*xpoints[z]^2 end
		point={xpoints[z]+u,ypoints2[w],rindex}
		table.insert(allpoints2,point)
	    end
	end
	
	if dis2 and shape=="square" or shape=="square 2" or shape=="hexagon" then allpoints=allpoints2 else allpoints=allpoints1 end
	if dis2 and shape=="vertical lines" then allpoints={}
	    for w=1,#xpoints do
		rnum=math.random(2000,6000)
		if dir==4 then rindex=rnum*xpoints[w]^2
		elseif dir==6 then rindex=0-rnum*xpoints[w]^2
		else rindex=rnum end
		table.insert(allpoints,{xpoints[w],0,rindex})
	    end
	end
	if dis2 then table.sort(allpoints,function(a,b) return a[3]<b[3] end) end
	
	-- DISSOLVE v2 Calculations ------------------------------------------
	if dis2 then d2c=0 fullclip="" dis2tab={} rnd=1 ppl=#allpoints/linez
	    for w=1,#allpoints do
	      pt=allpoints[w]
	      vd=v_dist
	      
	      if shape=="square" then
	      krip="m "..pt[1]-vd.." "..pt[2]-vd.." l "..pt[1]+vd.." "..pt[2]-vd.." "..pt[1]+vd.." "..pt[2]+vd.." "..pt[1]-vd.." "..pt[2]+vd.." "
	      end
	      
	      if shape=="diamond" then
		krip="m "..pt[1].." "..pt[2]-vd.." l "..pt[1]+vd.." "..pt[2].." "..pt[1].." "..pt[2]+vd.." "..pt[1]-vd.." "..pt[2].." "
	      end
	      
	      if shape=="vertical lines" then
		krip="m "..pt[1]-v_dist.." "..y1.." l "..pt[1]+v_dist.." "..y1.." "..pt[1]+v_dist.." "..y2.." "..pt[1]-v_dist.." "..y2.." "
	      end
	      
	      fullclip=fullclip..krip
	      d2c=d2c+1
	      if d2c>=math.floor(ppl) and w>=ppl*rnd then d2c=0 rnd=rnd+1 table.insert(dis2tab,fullclip) end
	  end
	end
    -- DISSOLVE END --------------------------------------------------------------------
    end
    
    -- What is the Matrix --
    if res.stuff=="what is the Matrix?" then
        matrixgui={
	  {x=0,y=0,class="label",label="Max. transformations per letter: "},
	  {x=1,y=0,class="intedit",name="tpl",value=4,min=2},
	  {x=0,y=1,class="label",label="Frames to stay the same: "},
	  {x=1,y=1,class="intedit",name="fts",value=2,min=1},
	  {x=0,y=2,class="label",label="Character set: "},
	  {x=1,y=2,class="dropdown",name="charset",items={"UPPERCASE","lowercase","Both","More","Everything"},value="Both"},
	  {x=0,y=3,class="label",label="Chance to keep letter (0-10):"},
	  {x=1,y=3,class="intedit",name="mkeep",value=5,min=0,max=10},
	  {x=0,y=4,width=2,class="checkbox",name="showall",label="Show all letters from the start",value=true,},
	  {x=0,y=5,width=2,class="label",label="Monospace fonts are optimal. For others, use left alignment."},
	}
	if matrixres then
	  for key,val in ipairs(matrixgui) do
	    if val.class=="checkbox" or val.class=="dropdown" or val.class=="intedit" then val.value=rez[val.name] end
	  end
	end
	pres,rez=ADD(matrixgui,{"What Is the Matrix?","Cancel"},{ok='What Is the Matrix?',close='Cancel'})
	if pres=="Cancel" then ak() end
	AB="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	ab="abcdefghijklmnopqrstuvwxyz"
	Ab="!?()$&+-="
	aB="@#%^*/[]';:,.|"
	if rez.charset=="UPPERCASE" then chset=AB.." "
	elseif rez.charset=="lowercase" then chset=ab.." "
	elseif rez.charset=="Both" then chset=AB..ab.." "
	elseif rez.charset=="More" then chset=AB..ab..Ab.." "
	else chset=AB..ab..Ab..aB.." " end
	ABC=chset:len()
	mframes=rez.tpl
	fpl=rez.fts
	matrixres=rez
    end
    
    if res.stuff=="time by frames" then frs=res.rep1:match("%-?%d+") or 0 fre=res.rep2:match("%-?%d+") or 0
	rine=subs[sel[1]]
	fstart=ms2fr(rine.start_time)
	fendt=ms2fr(rine.end_time)
	rine.start_time=fr2ms(fstart)
	rine.end_time=fr2ms(fendt)
	subs[sel[1]]=rine
	if frs==0 and fre==0 then t_error("Use Left/Right to input \nnumber of frames \nto shift by for start/end.",true) end
    end
    
    if res.stuff:match("replacer") then table.sort(sel,function(a,b) return a>b end) end
    
    -- LINES START HERE ----------------------------------------------------------------------
    for i=#sel,1,-1 do
        line=subs[sel[i]]
        text=line.text
	style=line.style
	
	-- What is the Matrix --
	if res.stuff=="what is the Matrix?" then
	    start=line.start_time endt=line.end_time
	    startf=ms2fr(start)
	    tags=text:match("^{\\[^}]-}") or ""
	    visible=text:gsub("{[^}]-}","")
	    ltrs={}
	    ltrs2={}
	    matches=re.find(visible,".")
	      for l=1,#matches do
	        table.insert(ltrs,matches[l].str)
		r=math.random(1,ABC)
	        table.insert(ltrs2,chset:sub(r,r))
	      end
	    base=""
	    lines={}
	    for l=1,#ltrs do
	      for f=1,mframes do
		if f<mframes then
		    x=math.random(1,ABC)
		    letter=chset:sub(x,x)
		    z=math.random(0,9)
		    if z<rez.mkeep and f>1 then letter=lastletter end
		    if l==1 and letter==" " then letter="e" end
		    if l==#ltrs and letter==" " then letter="s" end
		    txt=base..letter
		    lastletter=letter
		else letter=ltrs[l] txt=base..letter base=txt
		end
		if not rez.showall then txt=txt.."{\\alpha&HFF&}" end
		for n=l+1,#ltrs do
		  if rez.showall then
		    y=math.random(1,ABC)
		    letter=chset:sub(y,y)
		    z=math.random(0,9)
		    if z<rez.mkeep and n>l then letter=ltrs2[n] end
		    ltrs2[n]=letter
		    if n==#ltrs and letter==" " then letter="k" end
		    txt=txt..letter
		  else
		    txt=txt..ltrs[n]
		  end
		end
		txt=tags..txt
		fact=l*mframes+f-mframes-1
		startfr=startf+fact*fpl
		st=fr2ms(startfr)
		et=fr2ms(startfr+fpl)
		l2={txt,st,et}
		table.insert(lines,l2)
	      end
	      lastletter=nil
	    end
	    for ln=#lines,1,-1 do
	      lin=lines[ln]
	      line.text=lin[1]
	      line.start_time=lin[2]
	      line.end_time=lin[3]
	      if ln==#lines and endt>lin[3] then line.end_time=endt end
	      subs.insert(sel[i]+1,line)
	    end
	    line.comment=true
	end
	
	if res.stuff=="save/load" and i==1 then
	    if savedata==nil then savedata="" end
	    if res.dat~="" then
		savedata=savedata.."\n\n"..res.dat
		savedata=savedata
		:gsub("^\n\n","")
		:gsub("\n\n\n","\n\n")
		ADD({{class="label",label="Data saved.",x=0,y=0,width=20,height=2}},{"OK"},{close='OK'})
	    else
		ADD({{x=0,y=0,width=50,height=18,class="textbox",name="savetxt",value=savedata},},{"OK"},{close='OK'})
	    end
	end
	
	if res.stuff=="replacer" then
	  lim=sub3:match("^%d+")
	  if lim==nil then limit=1 else limit=tonumber(lim) end
	  replicant1=sub1:gsub("\\","\\"):gsub("\\\\","\\")
	  replicant2=sub2:gsub("\\","\\"):gsub("\\\\","\\")
	  tk=text
	  count=0
	  if res.regex=="lua patterns" then
	    repeat 
	    text=text:gsub(replicant1,replicant2) count=count+1
	    until count==limit
	    if text~=tk then repl=repl+1
	      if res.log then 
		r1=replicant1:gsub("%%%(","_L_"):gsub("%%%)","_R_"):gsub("%(",""):gsub("%)",""):gsub("_L_","%%%("):gsub("_R_","%%%)")
		for l1 in tk:gmatch(r1) do
		  aegisub.log("\nOrig: "..l1)
		  l2=l1:gsub(replicant1,replicant2)
		  aegisub.log("\nMod: "..l2)
		end
	      end
	    end
	  else
	    repeat
	    text=re.sub(text,replicant1,replicant2) count=count+1
	    until count==limit
	    if text~=tk then repl=repl+1 
	      if res.log then 
		for r1 in re.gfind(tk,replicant1) do
		  aegisub.log("\nOrig: "..r1)
		  r2=re.sub(r1,replicant1,replicant2)
		  aegisub.log("\nMod: "..r2)
		end
	      end
	    end
	  
	  end
	end
	
	if res.stuff=="lua calc" then
	    lim=sub3:match("^%d+")
	    if lim==nil then limit=1 else limit=tonumber(lim) end
	    replicant1=sub1:gsub("\\","\\")
	    replicant2=sub2:gsub("\\","\\")
	    replicant1=sub1:gsub("\\\\","\\")
	    replicant2=sub2:gsub("\\\\","\\")
	    replicant2="||"..replicant2.."||"
	    replicant2=replicant2:gsub("%.%.","||")
	    tk=text
	    count=0
	    repeat 
	    text=text:gsub(replicant1,function(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p)
		tab1={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p"}
		tab2={a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p}
		r2=replicant2
		asd=1
		repeat
		for r=1,16 do
		  r2=r2
		  :gsub(tab1[r].."%*([%d%.]+)",function(num) return tab2[r]*tonumber(num) end)
		  :gsub(tab1[r].."%/([%d%.]+)",function(num) return tab2[r]/tonumber(num) end)
		  :gsub(tab1[r].."%+([%d%.]+)",function(num) return tab2[r]+tonumber(num) end)
		  :gsub(tab1[r].."%-([%d%.]+)",function(num) return tab2[r]-tonumber(num) end)
		  :gsub("([%d%.]+)%*([%d%.]+)",function(n1,n2) return tonumber(n1)*tonumber(n2) end)
		  :gsub("([%d%.]+)%/([%d%.]+)",function(n1,n2) return tonumber(n1)/tonumber(n2) end)
		  :gsub("([%d%.]+)%+([%d%.]+)",function(n1,n2) return tonumber(n1)+tonumber(n2) end)
		  :gsub("([%d%.]+)%-([%d%.]+)",function(n1,n2) return tonumber(n1)-tonumber(n2) end)
		end
		for r=1,16 do
		    if tab2[r]~=nil then 
		    r2=r2:gsub("([|%*%/%+%-])"..tab1[r].."|","%1"..tab2[r].."|")
		    r2=r2:gsub("%("..tab1[r].."%)","("..tab2[r]..")")
		    end
		end
		r2=r2:gsub("round%(([^%)]+)%)",function(num) return math.floor(tonumber(num)+0.5) end)
		asd=asd+1
		until not r2:match("[%*%/%+%-]") or asd==12
		r2=r2:gsub("||","")
		return r2 end) count=count+1
	    until count==limit
	    if text~=tk then repl=repl+1 end
	end
	
	if res.stuff=="add comment" then
		text=text.."{"..res.dat.."}"
	end
	
	if res.stuff=="add comment line by line" then
		kom=data[i] 
		if kom then text=text.."{"..kom.."}" end
	end
	
	if res.stuff=="make comments visible" then
		text=text:gsub("{([^\\}]-)}","%1")
	end
	
	if res.stuff=="switch commented/visible" then
		text=text
		:gsub("\\N","_br_")
		:gsub("{([^\\}]-)}","}%1{")
		:gsub("^([^{]+)","{%1")
		:gsub("([^}]+)$","%1}")
		:gsub("([^}])({\\[^}]-})([^{])","%1}%2{%3")
		:gsub("^({\\[^}]-})([^{])","%1{%2")
		:gsub("([^}])({\\[^}]-})$","%1}%2")
		:gsub("{}","")
		:gsub("_br_","\\N")
	end
	
	if res.stuff=="reverse text" then
	    text=(text:match("^{\\[^}]-}") or "")..text.reverse(text:gsub("{[^}]-}",""))
	end
	
	if res.stuff=="reverse words" then
	    tags=(text:match("^{\\[^}]-}") or "")
	    text=text:gsub("{[^}]-}","")
	    nt=""
	    for l in text:gmatch("[^%s]+") do nt=" "..l..nt end
	    nt=nt:gsub("^ ","")
	    text=tags..nt
	end
	
	-- MOTION BLUR ------------------
	if res.stuff=="motion blur" then
	    if text:match("\\clip%(m") then
	      if not text:match("\\pos") then text=getpos(subs,text) end
	      if not rez.keepblur then text=addtag("\\blur"..mblur,text) end
	      c1,c2,c3,c4=text:match("\\clip%(m ([%-%d%.]+) ([%-%d%.]+) l ([%-%d%.]+) ([%-%d%.]+)")
	      if c1==nil then t_error("There seems to be something wrong with your clip",true) end
	      text=text:gsub("\\clip%b()","")
	      text=addtag("\\alpha&H"..mbalfa.."&",text)
	      cx=c3-c1
	      cy=c4-c2
	      cdist=math.sqrt(cx^2+cy^2)
	      mbratio=cdist/mbdist*2
	      mbx=round(cx/mbratio*100)/100
	      mby=round(cy/mbratio*100)/100
	      text2=text:gsub("\\pos%(([%-%d%.]+),([%-%d%.]+)",function(a,b) return "\\pos("..a-mbx..","..b-mby end)
	      l2=line
	      l2.text=text2
	      subs.insert(sel[i]+1,l2)
	      table.insert(sel,sel[#sel]+1)
	      if rez.mb3 then
		line.text=text
		subs.insert(sel[i]+1,line)
		table.insert(sel,sel[#sel]+1)
	      end
	      text=text:gsub("\\pos%(([%-%d%.]+),([%-%d%.]+)",function(a,b) return "\\pos("..a+mbx..","..b+mby end)
	    else noclip=true
	    end
	end
	
	-- REVERSE TRANSFORMS ------------------
	if res.stuff=="reverse transforms" then
	    styleref=stylechk(subs,line.style)
	    text=text:gsub("\\1c","\\c")
	    tags=(text:match("^{\\[^}]-}") or "")
	    text=text:gsub("^{[^}]-}","")
	    tags=cleantr(tags)
	    tags=duplikill(tags)
	    tags=tags:gsub("\\fs(%d)","\\fsize%1")
	    notrans=tags:gsub("\\t%b()","")
	    for tr in tags:gmatch("\\t%b()") do
		tr=tr:gsub("\\i?clip%([^%)]+%)","") :gsub("\\t%(","") :gsub("%)$","")
		for tag in tr:gmatch("\\[1234]?%a+") do
		    if not notrans:match(tag) then
			tags=fill_in(tags,tag)
		    end
		    tags=tags:gsub(tag.."([^\\}]+)([^}]-)"..tag.."([^\\}%)]+)",tag.."%3%2"..tag.."%1")
		end
	    end
	    tags=tags:gsub("(i?clip%([^%)]+%))([^}]-\\t[^}]-)(i?clip%([^%)]+%))","%3%2%1")
	    tags=tags:gsub("\\fsize","\\fs")
	    text=tags..text
	end
	
	if res.stuff=="fake capitals" then
	    tags=(text:match("^{\\[^}]-}") or "")
	    text=text:gsub("^{\\[^}]-}","")
		:gsub("(%u)","{\\fs"..sub1.."}%1{\\fs}")
		:gsub("{\\fs}(%p?){\\fs%d+}","{\\fs}%1")
	    repeat
		text=text:gsub("{\\fs}([%w']+){\\fs}","{\\fs}%1")
	    until not text:match("{\\fs}([%w']+){\\fs}")
	    text=tags..text
	    text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	end
	
	if res.stuff=="format dates" then
	    text2=text:gsub("{[^}]-}","")
	    if rez.date=="January 1" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)(st|nd|th)","\\1 \\2")
		text=re.sub(text,"(\\d+)(st|nd|th|st of|nd of|th of) (January|February|March|April|May|June|July|August|September|October|November|December)","\\3 \\1")
	    end
	    if rez.date=="January 1st" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)","\\1 \\2th")
		text=re.sub(text,"(\\d+)(st|nd|th|st of|nd of|th of) (January|February|March|April|May|June|July|August|September|October|November|December)","\\3 \\1th")
		text=text:gsub("(%d)thth","%1th") :gsub("1thst","1st") :gsub("2thnd","2nd") :gsub("1th","1st") :gsub("2th","2nd")
	    end
	    if rez.date=="1st of January" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)(st|nd|th)?","\\2\\3 of \\1")
		text=re.sub(text,"(\\d+) of (January|February|March|April|May|June|July|August|September|October|November|December)","\\1th of \\2")
		text=text:gsub("(%d)thth","%1th") :gsub("1thst","1st") :gsub("2thnd","2nd") :gsub("1th","1st") :gsub("2th","2nd")
		text=re.sub(text,"(\\d+)(st|nd|th) (January|February|March|April|May|June|July|August|September|October|November|December)","\\1\\2 of \\3")
	    end
	    if rez.date=="1st January" then
		text=re.sub(text,"(January|February|March|April|May|June|July|August|September|October|November|December) (\\d+)(st|nd|th)?","\\2\\3 \\1")
		text=re.sub(text,"(\\d+) (January|February|March|April|May|June|July|August|September|October|November|December)","\\1th \\2")
		text=text:gsub("(%d)thth","%1th") :gsub("1thst","1st") :gsub("2thnd","2nd") :gsub("1th","1st") :gsub("2th","2nd")
		text=re.sub(text,"(\\d+)(st|nd|th) of (January|February|March|April|May|June|July|August|September|October|November|December)","\\1\\2 \\3")
	    end
	    textn=text:gsub("{[^}]-}","")
	    if text2~=textn then datelog=text2.." -> "..textn.."\n"..datelog end
	end
	
	if res.stuff=="transform \\k to \\t\\alpha" then
	    repeat text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until not text:match("{(\\[^}]-)}{(\\[^}]-)}")
	    if text:match("^{[^}]-\\alpha") then alf=text:match("^{[^}]-\\alpha&H(%x%x)&") else alf="00" end
	    text=text:gsub("\\alpha&H%x%x&","")
	    tab={}
	    for kpart in text:gmatch("{[^}]-\\k[fo][%d%.]+[^}]-}[^{]*") do
		table.insert(tab,kpart)
	    end
	    lastim=0
	    text=""
	    for k=1,#tab do
		part=tab[k]
		tim=tonumber(part:match("\\k[fo]([%d%.]+)"))*10
		part=part:gsub("\\k[fo][%d%.]+","\\alpha&HFF&\\t("..lastim..","..lastim+tim..",\\alpha&H"..alf.."&)")
		tab[k]=part
		lastim=lastim+tim
		text=text..tab[k]
	    end
	end
	
	-- SPLIT and EXPLODE -------------------------------------------
	if res.stuff=="split into letters" or res.stuff=="explode" then
	    l2=line
	    tags=(text:match("^{\\[^}]-}") or "")
	    vis=text:gsub("{[^}]-}","")
	    af="{\\alpha&HFF&}"
	    a0="{\\alpha&H00&}"
	    letters={}
	    ltrmatches=re.find(vis,".")
	    for l=1,#ltrmatches do
		table.insert(letters,ltrmatches[l].str)
	    end
	    if savetab==nil then savetab={} end
	    -- create texts for all resulting lines
	    for l=#letters,1,-1 do
	    tx=af
		ltr=a0..letters[l]..af
		for t=1,#letters do
		    ltr2=letters[t]
		    if t==l then ltr2=ltr end
		    tx=tx..ltr2
		end
		tx=textmod(text,tx)
		txt2=tags..tx
		if not txt2:match("\\pos") then txt2=getpos(subs,txt2) end
		txt2=txt2:gsub("{\\alpha&HFF&}$","")
		txt2=txt2:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		txt2=txt2:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
		  -- Explode
		  if res.stuff=="explode" then
		    dur=line.end_time-line.start_time
		    if cfade then FO=exfad else FO=dur end
		    if implode then expfad="\\fad("..FO..",0)" else expfad="\\fad(0,"..FO..")" end
		    if FO==0 then EFO="" else EFO=expfad end
		    if ex_hor=="all" then 		ex1a=0-expl_dist_x	ex1b=expl_dist_x end
		    if ex_hor=="only left" then 	ex1a=0-expl_dist_x	ex1b=0 end
		    if ex_hor=="only right" then 	ex1a=0			ex1b=expl_dist_x end
		    if ex_hor=="mostly left" then 	ex1a=0-expl_dist_x	ex1b=expl_dist_x/3 end
		    if ex_hor=="mostly right" then 	ex1a=0-expl_dist_x/3	ex1b=expl_dist_x end
		    if ex_ver=="all" then 		ex2a=0-expl_dist_y	ex2b=expl_dist_y end
		    if ex_ver=="only up" then 		ex2a=0-expl_dist_y	ex2b=0 end
		    if ex_ver=="only down" then 	ex2a=0			ex2b=expl_dist_y end
		    if ex_ver=="mostly up" then 	ex2a=0-expl_dist_y	ex2b=expl_dist_y/3 end
		    if ex_ver=="mostly down" then 	ex2a=0-expl_dist_y/3	ex2b=expl_dist_y end
		    rvrs=#letters-l+1
		    if xinv then xind=rvrs else xind=l end
		    if yinv then yind=rvrs else yind=l end
		    if invseq then seqt=rvrs else seqt=l end
		    if implode then seqt=#letters-seqt+1 end
		    if exremember and i<#sel then
			tab=savetab[rvrs]
			ex1=tab.x1 ex2=tab.x2
		    else
		      if xprop then
			xhdist=(ex1b-ex1a)/#letters
			ex1=round(ex1a+xhdist*xind)
		      else
			ex1=math.ceil(math.random(ex1a,ex1b))
		      end
		      if yprop then
			xvdist=(ex2b-ex2a)/#letters
			ex2=round(ex2a+xvdist*yind)
		      else
			ex2=math.ceil(math.random(ex2a,ex2b))
		      end
		    end
		    if exremember and i==#sel then table.insert(savetab,{x1=ex1,x2=ex2}) end
		    
		    -- move sequence
		    if exseq then
		        tfrag=round(dur/#letters/(100/seqpc))
			xt1=tfrag*seqt-tfrag
		    else
		        xt1=0
		    end
		    xt2=dur
		    if implode and exseq then xt2=dur-xt1 xt1=0 end
		    txt2=txt2:gsub("\\move%(([%d%.%-]+),([%d%.%-]+).-%)","\\pos(%1,%2)")
		    txt2=txt2:gsub("\\fad%(.-%)","")
		    if implode then
			txt2=txt2:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",
		        function(a,b) return EFO.."\\move("..a+ex1..","..b+ex2..","..a..","..b..","..xt1..","..xt2..")" end)
		    else
			txt2=txt2:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",
		        function(a,b) return EFO.."\\move("..a..","..b..","..a+ex1..","..b+ex2..","..xt1..","..xt2..")" end)
		    end
		    txt2=txt2:gsub("{\\[^}]-}$","")
		  end
		l2.text=txt2
		if letters[l]~=" " then subs.insert(sel[i]+1,l2) table.insert(sel,sel[#sel]+i) end
		
	    end
	    line.comment=true
	end
	
	-- Clone Clip
	if res.stuff=="clone clip" and text:match("\\clip%((.-)%)") then
	    text=text:gsub("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d) 
		a=math.floor(a) b=math.floor(b) c=math.ceil(c) d=math.ceil(d) 
		return string.format("\\clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
	    clip=text:match("\\clip%((.-)%)")
	    clip=clip.." "
	    h_clip=clip
	    for h=1,clone_h-1 do
		hc=clip:gsub("([%d%-]+) ([%d%-]+)",function(a,b) return a+dist_h*h.." "..b end)
		h_clip=h_clip..hc
	    end
	    fullclip=h_clip
	    for v=1,clone_v-1 do
		if v%2==1 then offset=ccshift else offset=0 end
		vc=h_clip:gsub("([%d%-]+) ([%d%-]+)",function(a,b) return a+offset.." "..b+dist_v*v end)
		fullclip=fullclip..vc
	    end
	    fullclip=fullclip:gsub(" $","")
	    text=text:gsub("\\clip%((.-)%)","\\clip("..fullclip..")")
	end
	
	-- DISSOLVE Individual Lines --------------------------------------------------------------------------------------
	if res.stuff=="dissolve text" then
	  
	  fullklip=""
	  -- radius of clips based on # of sel. lines and shapes
	  r=math.ceil(i*linez/#sel-1) 
	  if shape=="diamond" and not alternate then r=math.floor(r*1.5) end
	  if shape:match("triangle") and alternate then r=math.floor(r*1.4) end
	  if shape:match("triangle") and not alternate then r=math.floor(r*1.5) end
	  if shape=="wave/hexagram" then r=math.floor(r*1.55) end
	  xpt=0		sw=0	osq=0
	  
	  if not dis2 and not shape:match("lines") and r>0 then
	    for w=1,#allpoints do
	      pt=allpoints[w]
	      
	      if shape=="square" or shape=="square 2" then
		krip="m "..pt[1]-r.." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]-r.." "..pt[1]+r.." "..pt[2]+r.." "..pt[1]-r.." "..pt[2]+r.." "
	      end
	      
	      if shape=="diamond" then
		krip="m "..pt[1].." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2].." "..pt[1].." "..pt[2]+r.." "..pt[1]-r.." "..pt[2].." "
	      end
	      
	      if shape=="triangle 1" then
		krip="m "..pt[1].." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]+r.." "..pt[1]-r.." "..pt[2]+r.." "
	      end
	      
	      if shape=="triangle 2" then
		krip="m "..pt[1]-r.." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]-r.." "..pt[1].." "..pt[2]+r.." "
	      end
	      
	      if shape=="hexagon" then
		krip="m "..pt[1].." "..pt[2]-2*r.." l "..pt[1]+2*r.." "..pt[2]-r.." "..pt[1]+2*r.." "..pt[2]+r.." "..pt[1].." "..pt[2]+2*r.." "..pt[1]-2*r.." "..pt[2]+r.." "..pt[1]-2*r.." "..pt[2]-r.." "
	      end
	      
	      if shape=="wave/hexagram" then
		if sw==0 then
		krip="m "..pt[1].." "..pt[2]-r+1 .." l "..pt[1]+r.." "..pt[2]+r+1 .." "..pt[1]-r.." "..pt[2]+r+1 .." "
		else
		krip="m "..pt[1]-r.." "..pt[2]-r.." l "..pt[1]+r.." "..pt[2]-r.." "..pt[1].." "..pt[2]+r.." "
		end
		xpt=xpt+1
		if xpt==#xpoints then xpt=0 sw=1-sw end
	      end
	      
	      fullklip=fullklip..krip
	    end
	  end
	  
	  if not dis2 and shape=="vertical lines" and r>0 then
	    for w=1,#xpoints do
	      pt=xpoints[w]
		krip="m "..pt-r.." "..y1.." l "..pt+r.." "..y1.." "..pt+r.." "..y2.." "..pt-r.." "..y2.." "
	      fullklip=fullklip..krip
	    end
	  end
	  
	  if not dis2 and shape=="horizontal lines" and r>0 then
	    for w=1,#ypoints do
	      pt=ypoints[w]
		krip="m "..x1-vert.." "..pt-r.." l "..x2+vert.." "..pt-r.." "..x2+vert.." "..pt+r.." "..x1-vert.." "..pt+r.." "
	      fullklip=fullklip..krip
	    end
	  end
	  
	  if dis2 and r>0 then fullklip=dis2tab[r] end
	  
	  fullklip=fullklip:gsub(" $","")
	  
	  text=text:gsub("\\clip%(.-%)","")
	  if r>0 then text=addtag("\\iclip("..fullklip..")",text) end
	end
	-- DISSOLVE END 2 ----------------------------------------------
	
	-- RANDOMIZED TRANSFORMS ---------------------------------------
	if res.stuff=="randomized transforms" then
	  dur=line.end_time-line.start_time
	  if RTMax then MxF=dur end
	  
	    -- Fade/Duration
	    if RTM=="FD" then
	      FD=math.random(MnF,MxF)
	      if RTD and not RTin then line.end_time=line.start_time+FD end
	      if RTD and RTin then line.start_time=line.end_time-FD end
	      if RTF and not RTin then text="{\\fad(0,"..FD..")}"..text text=text:gsub(FD.."%)}{",FD..")") end
	      if RTF and RTin then text="{\\fad("..FD..",0)}"..text text=text:gsub(",0%)}{",",0)") end
	    end
	    
	    -- Number Transform
	    if RTM=="NT" then
	      NT=math.random(MnT*10,MxT*10)/10
	      if RTA then NTA=math.random(MnA*10,MxA*10)/10 axel=NTA.."," else axel="" end
	      text=addtag("\\t("..axel.."\\"..RTT..NT..")",text)
	    end
	    
	    -- Colour Transform
	    if RTM=="CT" then
	      CTfull=""
	      for c=1,#rtcol do
		ctype="\\"..rtcol[c].."c"
		ctype=ctype:gsub("\\1c","\\c")
	        Bluu,Grin,Rett=text:match("^{[^}]-"..ctype.."&H(%x%x)(%x%x)(%x%x)&")
		if Bluu~=nil then
		  R=tonumber(Rett,16)
		  G=tonumber(Grin,16)
		  B=tonumber(Bluu,16)
		  Red=math.random(R-MxC,R+MxC)
		  Green=math.random(G-MxC,G+MxC)
		  Blue=math.random(B-MxC,B+MxC)
		else
		  Red=math.random(0,255)
		  Green=math.random(0,255)
		  Blue=math.random(0,255)
		end
		CT=ctype.."&H"..tohex(Blue)..tohex(Green)..tohex(Red).."&"
		CTfull=CTfull..CT
	      end
	      if RTA then NTA=math.random(MnA*10,MxA*10)/10 axel=NTA.."," else axel="" end
	      if CTfull~="" then text=addtag("\\t("..axel..CTfull..")",text) end
	    end
	    
	    -- Move X
	    if rez.rtmx then
	      MMX=math.random(MnX,MxX)
	      text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d) if RTin then a=a+MMX else c=c+MMX end
		return "\\move("..a..","..b..","..c..","..d end)
	      text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)",
		function(a,b) a2=a if RTin then a=a+MMX else a2=a2+MMX end
		return "\\move("..a..","..b..","..a2..","..b end)
	    end
	    
	    -- Move Y
	    if rez.rtmy then
	      MMY=math.random(MnY,MxY)
	      text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d) if RTin then b=b+MMY else d=d+MMY end
		return "\\move("..a..","..b..","..c..","..d end)
	      text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)",
		function(a,b) b2=b if RTin then b=b+MMY else b2=b2+MMY end
		return "\\move("..a..","..b..","..a..","..b2 end)
	    end
	end
	
	if res.stuff=="time by frames" and i>1 then
	    line.start_time=fr2ms(fstart+(i-1)*frs)
	    line.end_time=fr2ms(fendt+(i-1)*fre)
	end
	
	line.text=text
	subs[sel[i]]=line
	if res.stuff=="split into letters" or res.stuff=="explode" and not rez.excom then subs.delete(sel[i]) table.remove(sel,#sel) end
	if res.stuff=="what is the Matrix?" then subs.delete(sel[i]) end
    end
    if res.stuff:match"replacer" then aegisub.progress.task("All stuff has been finished.")
	if repl==1 then rp=" modified line" else rp=" modified lines" end
	press,reslt=ADD({},{repl..rp},{cancel=repl..rp})
    end
    if res.stuff=="format dates" and rez.log then aegisub.log(datelog) end
    if noclip then t_error("Some lines weren't processed - missing clip.") noclip=nil end
    savetab=nil
end


function fill_in(tags,tag)
    if tag=="\\bord" then tags=tags:gsub("^{","{"..tag..styleref.outline)
    elseif tag=="\\shad" then tags=tags:gsub("^{","{"..tag..styleref.shadow)
    elseif tag=="\\fscx" then tags=tags:gsub("^{","{"..tag..styleref.scale_x)
    elseif tag=="\\fscy" then tags=tags:gsub("^{","{"..tag..styleref.scale_y)
    elseif tag=="\\fsize" then tags=tags:gsub("^{","{"..tag..styleref.fontsize)
    elseif tag=="\\fsp" then tags=tags:gsub("^{","{"..tag..styleref.spacing)
    elseif tag=="\\alpha" then tags=tags:gsub("^{","{"..tag.."&H00&")
    elseif tag=="\\1a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color1:match("H%x%x").."&")
    elseif tag=="\\2a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color2:match("H%x%x").."&")
    elseif tag=="\\3a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color3:match("H%x%x").."&")
    elseif tag=="\\4a" then tags=tags:gsub("^{","{"..tag.."&"..styleref.color4:match("H%x%x").."&")
    elseif tag=="\\c" then tags=tags:gsub("^{","{"..tag..styleref.color1:gsub("H%x%x","H"))
    elseif tag=="\\2c" then tags=tags:gsub("^{","{"..tag..styleref.color2:gsub("H%x%x","H"))
    elseif tag=="\\3c" then tags=tags:gsub("^{","{"..tag..styleref.color3:gsub("H%x%x","H"))
    elseif tag=="\\4c" then tags=tags:gsub("^{","{"..tag..styleref.color4:gsub("H%x%x","H"))
    else tags=tags:gsub("^{","{"..tag.."0")
    end
    return tags
end



--	Jump to Next	--
function nextsel(subs,sel)
lm=nil
i=sel[1]
marks={}
for x,i in ipairs(sel) do
  rine=subs[i]
  txt=rine.text:gsub("{[^}]-}","")
  if res.field=="text" then mark=txt end
  if res.field=="style" then mark=rine.style end
  if res.field=="actor" then mark=rine.actor end
  if res.field=="effect" then mark=rine.effect end
  if res.field=="layer" then mark=rine.layer end
  if mark=="" then mark="_empty_" end
  if mark~=lm then table.insert(marks,mark) end
  lm=mark
end
count=1
repeat
  line=subs[i+count]
  txt2=line.text:gsub("{[^}]-}","")

  if res.field=="text" then hit=txt2 end
  if res.field=="style" then hit=line.style end
  if res.field=="actor" then hit=line.actor end
  if res.field=="effect" then hit=line.effect end
  if res.field=="layer" then hit=line.layer end
  if hit=="" then hit="_empty_" end
  ch=0
  for m=1,#marks do if marks[m]==hit then ch=1 end end
  if ch==0 or i+count==#subs then sel={i+count} end
  count=count+1
until ch==0 or hit==nil or i+count>#subs
return sel
end



--	Alpha Shift	--
function alfashift(subs,sel)
    count=1
    for x, i in ipairs(sel) do
    line=subs[i]
    text=line.text
    if not text:match("{\\alpha&HFF&}[%w%p]") then t_error("Line "..x.." does not \nappear to have \n\\alpha&&HFF&&",true) end
    if count>1 then
	switch=1
	repeat 
	text=text
	:gsub("({\\alpha&HFF&})([%w%p])","%2%1")
	:gsub("({\\alpha&HFF&})(%s)","%2%1")
	:gsub("({\\alpha&HFF&})(\\N)","%2%1")
	:gsub("({\\alpha&HFF&})$","")
	switch=switch+1
	until switch>=count
    end
    count=count+1
    line.text=text
    subs[i]=line
    end
end



--	Merge inline tags	--
function merge(subs,sel)
    tk={}
    tg={}
    stg=""
    for x, i in ipairs(sel) do
        line=subs[i]
        text=line.text
	text=text:gsub("{\\\\k0}","")
	repeat text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	    until not text:match("{(\\[^}]-)}{(\\[^}]-)}")
	vis=text:gsub("{[^}]-}","")
	if x==1 then rt=vis
	ltrmatches=re.find(rt,".")
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	end
	if vis~=rt then t_error("Error. Inconsistent text.",true) end
	stags=text:match("^{(\\[^}]-)}")
	if stags~=nil then stg=stg..stags stg=duplikill(stg) end
	text=text:gsub("^{\\[^}]-}","") :gsub("{[^\\}]-}","")
	count=0
	for seq in text:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
    end
    newline=""
    for i=1,#tk do
	newline=newline..tk[i]
	newt=""
	for n, t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t newt=duplikill(newt) newt=newt:gsub("%*$","") end
	end
	if newt~="" then newline=newline.."{"..newt.."}" end
    end
    newtext="{"..stg.."}"..newline
    line=subs[sel[1]]
    line.text=newtext
    subs[sel[1]]=line
    for i=#sel,2,-1 do subs.delete(sel[i]) end
    sel={sel[1]}
    return sel
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


--	Honorificslaughterhouse		--
function honorifix(subs,sel)
    for i=#subs,1,-1 do
      if subs[i].class=="dialogue" then
        line=subs[i]
        text=line.text
	text=text
	:gsub("%-san","{-san}")
	:gsub("%-chan","{-chan}")
	:gsub("%-kun","{-kun}")
	:gsub("%-sama","{-sama}")
	:gsub("%-niisan","{-niisan}")
	:gsub("%-oniisan","{-oniisan}")
	:gsub("%-oniichan","{-oniichan}")
	:gsub("%-oneesan","{-oneesan}")
	:gsub("%-oneechan","{-oneechan}")
	:gsub("%-neesama","{-neesama}")
	:gsub("%-sensei","{-sensei}")
	:gsub("%-se[mn]pai","{-senpai}")
	:gsub("%-dono","{-dono}")
	:gsub("Onii{%-chan}","Brother{Onii-chan}")
	:gsub("Onii{%-san}","Brother{Onii-san}")
	:gsub("Onee{%-chan}","Sister{Onee-chan}")
	:gsub("Onee{%-san}","Sister{Onee-san}")
	:gsub("Onee{%-sama}","Sister{Onee-sama}")
	:gsub("onii{%-chan}","brother{onii-chan}")
	:gsub("onii{%-san}","brother{onii-san}")
	:gsub("onee{%-chan}","sister{onee-chan}")
	:gsub("onee{%-san}","sister{onee-san}")
	:gsub("onee{%-sama}","sister{onee-sama}")
	:gsub("{{","{")
	:gsub("}}","}")
	:gsub("({[^{}]-){(%-%a-)}([^{}]-})","%1%2%3")
	line.text=text
        subs[i]=line
      end
    end
end


--	framerate	--
function framerate(subs)
    f1=res.fps1
    f2=res.fps2
    for i=1, #subs do
        if subs[i].class=="dialogue" then
            local line=subs[i]
	    line.start_time=line.start_time/f2*f1
	    line.end_time=line.end_time/f2*f1
            subs[i]=line
        end
    end
end

--	reanimatools 	--
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
	return l2
end

function string2time(timecode)
	timecode=timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)",function(a,b,c,d) return d*10+c*1000+b*60000+a*3600000 end)
	return timecode
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
	tags=tags:gsub("^({[^}]*)}","%1"..trnsfrm.."}")
	return tags
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
    elseif num==14 then num="E"
    end
return num
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
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

function getpos(subs,text)
    for i=1,#subs do
	if subs[i].class=="info" then
	    local k=subs[i].key
	    local v=subs[i].value
	    if k=="PlayResX" then resx=v end
	    if k=="PlayResY" then resy=v end
        end
	if resx==nil then resx=0 end
	if resy==nil then resy=0 end
        if subs[i].class=="style" then
            local st=subs[i]
	    if st.name==line.style then
		acleft=st.margin_l	if line.margin_l>0 then acleft=line.margin_l end
		acright=st.margin_r	if line.margin_r>0 then acright=line.margin_r end
		acvert=st.margin_t	if line.margin_t>0 then acvert=line.margin_t end
		acalign=st.align	if text:match("\\an%d") then acalign=text:match("\\an(%d)") end
		aligntop="789" alignbot="123" aligncent="456"
		alignleft="147" alignright="369" alignmid="258"
		if alignleft:match(acalign) then horz=acleft h_al="left"
		elseif alignright:match(acalign) then horz=resx-acright h_al="right"
		elseif alignmid:match(acalign) then horz=resx/2 h_al="mid" end
		if aligntop:match(acalign) then vert=acvert v_al="top"
		elseif alignbot:match(acalign) then vert=resy-acvert v_al="bottom"
		elseif aligncent:match(acalign) then vert=resy/2 v_al="mid" end
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

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end
function round(num) num=math.floor(num+0.5) return num end
function logg(m) return aegisub.log("\n "..m) end

--	Config Stuff	--
function saveconfig()
unconf="Unimportant Configuration\n\n"
  for key,val in ipairs(unconfig) do
    if val.class=="floatedit" or val.class=="dropdown" then
      unconf=unconf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="save" then
      unconf=unconf..val.name..":"..tf(res[val.name]).."\n"
    end
  end

unimpkonfig=ADP("?user").."\\unimportant.conf"
  file=io.open(unimpkonfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	imp1=konf:match("imp1:(.-)\n")
	imp2=konf:match("imp2:(.-)\n")
	imp3=konf:match("imp3:(.-)\n")
	chap1=konf:match("chap1:(.-)\n")
	chap2=konf:match("chap2:(.-)\n")
	chap3=konf:match("chap3:(.-)\n")
    end
    if imp1==nil then imp1="relative" end
    if imp2==nil then imp2="" end
    if imp3==nil then imp3="D:\\typesetting\\" end
    if chap1==nil then chap1="relative" end
    if chap2==nil then chap2="" end
    if chap3==nil then chap3="D:\\typesetting\\" end

  savestuff={
  {x=0,y=0,class="label",label="Import script path:"},
  {x=0,y=1,class="label",label="Import relative path:"},
  {x=0,y=2,class="label",label="Import absolute path:"},
  {x=0,y=3,class="label",label="Chapters save path:"},
  {x=0,y=4,class="label",label="Chapters relative path:"},
  {x=0,y=5,class="label",label="Chapters absolute path:"},
  {x=1,y=0,class="dropdown",name="imp1",items={"relative","absolute"},value=imp1},
  {x=1,y=1,class="edit",width=16,name="imp2",value=imp2},
  {x=1,y=2,class="edit",width=16,name="imp3",value=imp3},
  {x=1,y=3,class="dropdown",name="chap1",items={"relative","absolute"},value=chap1},
  {x=1,y=4,class="edit",width=16,name="chap2",value=chap2},
  {x=1,y=5,class="edit",width=16,name="chap3",value=chap3},
  }
  
  click,rez=ADD(savestuff,{"Save","Cancel"},{ok='Save',close='Cancel'})
  if click=="Cancel" then ak() end
  rez.imp3=rez.imp3:gsub("[^\\]$","%1\\")
  rez.chap3=rez.chap3:gsub("[^\\]$","%1\\")
  
  for key,val in ipairs(savestuff) do
    if val.x==1 then
      unconf=unconf..val.name..":"..rez[val.name].."\n"
    end
  end
  
file=io.open(unimpkonfig,"w")
file:write(unconf)
file:close()
ADD({{class="label",label="Config saved to:\n"..unimpkonfig}},{"OK"},{close='OK'})
end

function loadconfig()
unimpkonfig=ADP("?user").."\\unimportant.conf"
file=io.open(unimpkonfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	if konf:match("^%-%-") then konf=""
	else
	  for key,val in ipairs(unconfig) do
	    if val.class=="floatedit" or val.class=="checkbox" or val.class=="dropdown" then
	      if konf:match(val.name) then val.value=detf(konf:match(val.name..":(.-)\n")) end
	      if lastimp and val.name=="stuff" then val.value=lastuff end
	      if lastimp and val.name=="log" then val.value=lastlog end
	      if lastimp and val.name=="zeros" then val.value=lastzeros end
	      if lastimp and val.name=="field" then val.value=lastfield end
	    end
	  end
	end
	script_path=konf:match("imp1:(.-)\n") if script_path==nil then script_path="relative" end
	relative_path=konf:match("imp2:(.-)\n") if relative_path==nil then relative_path="" end
	absolute_path=konf:match("imp3:(.-)\n") if absolute_path==nil then absolute_path="D:\\typesetting\\" end
	ch_script_path=konf:match("chap1:(.-)\n") if ch_script_path==nil then ch_script_path="relative" end
	ch_relative_path=konf:match("chap2:(.-)\n") if ch_relative_path==nil then ch_relative_path="" end
	ch_absolute_path=konf:match("chap3:(.-)\n") if ch_absolute_path==nil then ch_absolute_path="D:\\typesetting\\" end
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



function analyze(l)
    text=l.text
    dur=l.end_time-l.start_time
    dura=dur/1000
    txt=text:gsub("{[^}]-}","") :gsub("\\N","")
    visible=text:gsub("{\\alpha&HFF&}[^{}]-{[^{}]-}","")	:gsub("{\\alpha&HFF&}[^{}]*$","")	:gsub("{[^{}]-}","")
			:gsub("\\[Nn]","*")	:gsub("%s?%*+%s?"," ")	:gsub("^%s+","")	:gsub("%s+$","")
    wrd=0	for word in txt:gmatch("([%a\']+)") do wrd=wrd+1 end
    chars=visible:gsub(" ","")	:gsub("[%.,\"]","")
    char=chars:len()
    cps=math.ceil(char/dura)
    if dur==0 then cps=0 end
end

function info(subs,sel,act)
    styletab={}
    dc=0
    sdur=0
    S=subs[sel[1]].start_time
    E=subs[sel[#sel]].end_time
    video=nil stitle=nil colorspace=nil resx=nil resy=nil
    prop=aegisub.project_properties()
    for x,i in ipairs(sel) do
	line=subs[i]
	dur=line.end_time-line.start_time
	if line.start_time<S then S=line.start_time end
	if line.end_time>E then E=line.end_time end
	sdur=sdur+dur
    end
    seldur=sdur/1000
    for i=1, #subs do
        if subs[i].class=="info" then
	    local k=subs[i].key
	    local v=subs[i].value
	    if k=="Title" then stitle=v end
	    if k=="Video File" then video=v end
	    if k=="YCbCr Matrix" then colorspace=v end
	    if k=="PlayResX" then resx=v end
	    if k=="PlayResY" then resy=v end
        end
	if video==nil then video=prop.video_file:gsub("^.*\\","") end
	if stitle==nil then sct="" else sct="Script title: "..stitle.."\n" end
	if video==nil then vf="" else vf="Video file: "..video.."\n" end
	if resy==nil then reso="" else reso="Script resolution: "..resx.."x"..resy.."\n" end
	if colorspace==nil then cols="" else cols="Colorspace: "..colorspace.."\n" end
	nfo=sct..vf..reso..cols
        if subs[i].class=="style" then
            local s=subs[i]
	    table.insert(styletab,s)
        end
        if subs[i].class=="dialogue" then
 	    dc=dc+1
            local l=subs[i]
	    if i==act then
		ano=dc
		analyze(l)
		for s=1,#styletab do st=styletab[s]
		    if st.name==l.style then
			acfont=st.fontname 
			acsize=st.fontsize
			acalign=st.align
			acleft=st.margin_l
			acright=st.margin_r
			acvert=st.margin_t
			acbord=st.outline
			acshad=st.shadow
			if st.bold then actbold="Bold" else actbold="Regular" end
		    end 
		end
		aligntop="789" alignbot="123" aligncent="456"
		alignleft="147" alignright="369" alignmid="258"
		if aligntop:match(acalign) then vert=acvert
		elseif alignbot:match(acalign) then vert=resy-acvert
		elseif aligncent:match(acalign) then vert=resy/2 end
		if alignleft:match(acalign) then horz=acleft
		elseif alignright:match(acalign) then horz=resx-acright
		elseif alignmid:match(acalign) then horz=resx/2 end
		
		aktif="Active line: "..ano.."\nStyle used: "..l.style.."\nFont used: "..acfont.."\nWeight: "..actbold.."\nFont size: "..acsize.."\nBorder: "..acbord.."\nShadow: "..acshad.."\nDuration: "..dura.."s\nCharacters: "..char.."\nCharacters per second: "..cps.."\nDefault position: "..horz..","..vert.."\n\nVisible text:\n"..visible
	    end
        end

    end
    infodump=nfo.."Styles used: "..#styletab.."\nDialogue lines: "..dc..", Selected: "..#sel.."\nCombined length of selected lines: "..seldur.."s\nSelection duration: "..(E-S)/1000 .."s\n\n"..aktif
end

help_i=[[
- IMPORT/EXPORT -

This allows you to import OP/ED or signs (or whatever) from an external .ass file.
OP/ED must be saved as OP.ass and ED.ass; a sign can have any name.
The .ass file may contain headers, or it can be just the dialogue lines.
The imported stuff will be shifted to your currently selected line (or the first one in your selection).
The first line of the saved file works as a reference point, so use a "First frame of OP" line etc.
(You can save your OP/ED shifted to 0 or you can just leave it as is;
   the times will be recalculated to start at the current line.)
"keep line" will keep your current line and comment it. Otherwise the line gets deleted.

IMPORT SIGN / IMPORT SIGNS - works like OP/ED, but you have to input the sign's name.
The difference between the two is:\nSIGN - each sign must be saved in its own .ass file.
In the GUI, input the sign's/file's name, for example "eptitle"[.ass].
SIGNS - all signs must be saved in signs.ass.
They are distinguished by what's in the "effect" field - that's the sign's name.
For SIGN, make something like eptitle.ass, eyecatch.ass;
for SIGNS, put "eptitle" or "eyecatch" in the effect field, and put all the signs in signs.ass.
(You can have blank lines between signs for clarity. The script can deal with those.)
The GUI will then show you a list of signs that it gets from the effect fields.
I recommend using SIGNS, as it's imo more efficient (but SIGN was written first and I didn't nuke it).

Options:\nWith nothing checked, stuff is shifted to the first frame of your active line (like OP/ED).
(SIGN) File name: "custom" will use what you type below. The other ones are presets.
"keep current line's times" - all imported lines will have the start/end time of your active line
"keep current line's text" - all imported lines will have their text (not tags) replaced with your active line's text
   - If you want to replace only some lines and keep others, like masks, put 'x' in actor field of the mask.
"combine tags (current overrides)" - tags from current + imported line get combined (current overrides imported)
"combine tags (imported overrides)" - same as above, but imported overrides current
   - Both of these will also be ignored for imported lines that have "x" in actor field.
"don't shift times" - times of imported lines will be kept as they were saved
"delete original line" - this overrides the "keep line" option in the main menu.
(I thought it would be convenient to have it here.)

EXPORT SIGN - Saves the selected sign(s) either to 'signs.ass' or to a new file.
Effect field must contain the signs' names.

You can use relative or absolute paths. (Check the settings below.)
Default is the script's folder. If you want the default to be one folder up, use "..\".
You can use an absolute path, have one huge signs.ass there,
and have all the signs marked "show_name-sign_name" in the effect field.\n\n]]

help_u=[[
UPDATE LYRICS

This is probably the most complicated part, but if your songs have some massive styling with layers + tracking,
this will make updating lyrics, which would otherwise be a pain in the ass, really easy.
The only styling that will prevent this from working is inline tags - gradient by character etc.

The prerequisite here is that your OP/ED MUST have NUMBERED lines!
(See NUMBERS section - might be good to read that first.)
The numbers must correspond to the verses, not to lines in the script.
If line 1 of the SONG is mocha-tracked over 200 frames, all of those frames must be numbered 01.
It is thus most convenient to number the lines before you start styling, when it's still simple.

How this works:
Paste your updated lyrics into the large, top-left area of the GUI.
Use the Left and Right fields to set the markers to detect the right lines.
Without markers it will just look for numbers.
If your OP lines are numbered with "OP01eng", you must set "OP" under Left and "eng" under Right.
For now, everything is case-sensitive (I might change that later if it gets really annoying and pointless).
You must also correctly set the actor/effect choice in the bottom-right part of the GUI.
If you pasted lyrics, selected "update lyrics", and set markers and actor/effect.
Then hit Import, and lyrics will be updated.

How it works - example:
The lyrics you pasted in the data box get their lines assigned with numbers from 1 to whatever.
Let's say your markers are "OP01eng" and you're using the effect field.
The script looks for lines with that pattern in the effect field.
When it finds one, it reads the number (for example "01" from "OP01eng")
and replaces the line's text (skipping tags) with line 1 from the pasted lyrics.
For every line marked "OP##eng" it replaces the current lyrics with line ## from your pasted updated lyrics.

To make sure this doesn't fuck up tremendously, it shows you a log with all replacements at the end.

That's pretty much all you really need to know for updating lyrics, but there are a few more things.

If the script doesn't find any lines that match the markers, it gives you a message like this:
"The effect field of selected lines doesn't match given pattern..."
This means the lines either don't exist in your selection, or you probably forgot to set the markers.

"style restriction" is an extra option that lets you limit the replacing to lines whose style contains given pattern.
Let's give some examples:
You check the restriction and type "OP" in the field below.
You can now select the whole script instead of selecting only the OP lines,
and only lines with "OP" in style will be updated.
You may have the ED numbered the same way, but the "OP" restriction will ignore it.
This can be also useful if you have lines numbered just 01, 02 etc.,
and you have english and romaji, all mixed together.
If your styles are OP-jap and OP-eng, you can type "jap" in the restriction field if you're updating romaji
to make sure the script doesn't update the english lines as well (replacing them with romaji).
It is, however, recommended to just use different markers, like j01 / e01.]]

help_c=[[
- CHAPTERS -

This will generate chapters from the .ass file

MARKER: For a line to be used for chapters, it has to be marked with "chapter"/"chptr"/"chap"
in actor/effect field (depending on settings) or the same 3 options as a separate comment, ie. {chapter} etc.

CHAPTER NAME: What will be used as chapter name.
It's either the content of the effect field, or the line's FIRST comment.
If the comment is {OP first frame} or {ED start}, the script will remove " first frame" or " start",
so you can keep those.

If you use default settings, just put "chapter" in actor field and make comments like {OP} or {Part A}.

Subchapters: You can make subchapters like this {Part A::Scene 5}.
This will be a subchapter of "Part A" called "Scene 5".

If you want a different LANGUAGE than 'eng', set it in the textbox below "chapter mark"

CHAPTER MARK: Sets the selected chapter for selected line(s). Uses marker and name. (Doesn't create xml.)
If you want a custom chapter name, type it in the textbox below this.]]

help_n=[[
- NUMBERS -

This is a tool to number lines and add various markers to actor/effect fields.
The dropdown with "01" lets you choose how many leading zeros you want.
The Left and Right fields will add stuff to the numbers. If Left is "x" and Right is "yz",
the first marker will be "x01yz".
What makes this function much more versatile is the "Mod" field.
If you put in one number, then that's the number from which the numbering will start, so "5" -> 5, 6, 7, etc.
You can, however, use a comma or slash to modify the numbering some more.
"8,3" or "8/3" will start numbering from 8, repeating each number 3 times, so 8, 8, 8, 9, 9, 9, 10, 10, 10, etc.
This allows you to easily number lines that are typeset in layers etc.
Additionally, you can set a limit in [], for example 1/3[2], which will start from 1, use each number 3 times,
and only go up to 2 and then start again, so: 1 1 1 2 2 2 1 1 1 2 2 2
2/3[4] would give you 2 2 2 3 3 3 4 4 4 2 2 2 3 3 3 4 4 4 ...

"add to marker" uses the Left and Right fields to add stuff to the current content of actor/effect/text.
If you number lines for the OP, you can set "OP-" in Left and "-eng" in Right to get "OP-01-eng".
(Mod does nothing when adding markers.)]]

help_d=[[
- DO STUFF -

- Save/Load -
You can use this to save for example bits of text you need to paste frequently (like a multi-clipboard).
Paste text in the data area to save it. If the data area is empty, the function will load your saved texts.

- Lua Replacer -
Use "Left" and "Right" for a lua regexp replace function.

- Perl Replacer -
Use "Left" and "Right" for a perl regexp replace function.

- Lua Calc -
Use "Left" and "Right" with lua regexp to perform calculations on captured numbers.
Captures will be named a, b, c... up to p (16 captures max).
Functions are +, -, *, /, and round(a), which rounds the number captured in a.
> Example: (%d)(%d)(%d) -> a+1b*2c-3
This will match 3-digit patterns, add 1 to first digit, multiply the second by 2, and subtract 3 from the 3rd.
If you want to leave one of the captures as is, use .. to separate it from other letters: a+1b..c-3
> Example: pos%(([%d%.]+),([%d%.]+) -> pos(a+50,b-100
This will shift position right by 50 and up by 100.

- Jump to Next -
This is meant to get you to the "next sign" in the subtitle grid.
When mocha-tracking 1000+ lines, it can be a pain in the ass to find where one sign ends and another begins.
Select lines that belong to the current "sign", ie. different layers/masks/texts.
The script will search for the first line in the grid that doesn't match any of the selected ones,
based on the "Marker".

- Alpha Shift -
Shifts {\alpha&HFF&} by one letter for each line. Text thus appears letter by letter.
It's an alternative to the script that spawns \ko, but this works with shadow too.
Duplicate a line with {\alpha&HFF&} however many times you need and run the script on the whole selection.

- Motion Blur - 
Creates motion blur by duplicating the line and using some alpha.
By default you keep the existing blur for each line, but you can set a value to override all lines.
'Distance' is the distance between the \pos coordinates of the resulting 2 lines.
If you use 3 lines, the 3rd one will be in the original position, i.e. in the middle.
The direction is determined from the first 2 points of a vectorial clip (like with clip2frz/clip2fax).

- Merge Inline Tags -
Select lines with the same text but different tags,
and they will be merged into one line with tags from all of them.
For example:
{\bord2}AB{\shad3}C\nA{\fs55}BC
-> {\bord2}A{\fs55}B{\shad3}C

- Add Comment -
Text that you type here in this box will be added as a {comment} at the end of selected lines.

- Make Comments Visible -
Nukes { } from comments, thus making them part of the text visible on screen.

- Switch Commented/Visible -
Comments out what's visible and makes visible what's commented. Allows switching between two texts.

- Reverse Text -
Reverses text (character by character). Nukes comments and inline tags.

- Reverse Words -
Reverses text (word by word). Nukes comments and inline tags.

- Reverse Transforms -
\blur1\t(\blur3) becomes \blur3\t(\blur1). Only for initial tags. Only one transform for each tag.

- Fake Capitals -
Creates fake capitals by increasing font size for first letters.
With all caps, for first letters of words. With mixed text, for uppercase letters.
Set the \fs for the capitals in the Left field.
Looks like this: {\fs60}F{\fs}AKE {\fs60}C{\fs}APITALS

- Format Dates -
Formats dates to one of 4 options. Has its own GUI. Only converts from the other 3 options in the GUI.

- Split into Letters -
Makes a line for each letter, making the other letters invisible with alpha.
This lets you do things with each letter separately.

- Explode -
This splits the line into letters and makes each of them move in a different direction and fade out.

- Dissolve Text -\nVarious modes of dissolving text. Has its own Help.

- Randomized Transforms -
Various modes of randomly transforming text. Has its own Help.

- Clone Clip -
Clones/replicates a clip you draw.
Set how many rows/columns and distances between them, and you can make large patterns.

- Time by Frames -
Left = frames to shift start time by, each line (2 = each new line starts 2 frames later than previous)
Right = frames to shift end time by, each line (4 = each new line ends 4 frames later than previous)

- Honorificslaughterhouse -
Comments out honorifics.

- Convert Framerate -
Converts framerate from a to b where a is the input from "Left" and b is input from "Right".]]



--	Unimportant GUI		-------------------------------------------------------------------------------------
function unimportant(subs,sel,act)
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
aegisub.progress.title("Loading Unimportant Stuff")
aegisub.progress.task("This should take less than a second, so you won't really read this.")
if datata==nil then data="" else data=datata end
if sub1==nil then sub1="" end
if sub2==nil then sub2="" end
if sub3==nil then sub3=1 end
msg={"If it breaks, it's your fault.","This should be doing something...","Breaking your computer. Please wait.","Unspecified operations in progress.","This may or may not work.","Trying to avoid bugs...","Zero one one zero one zero...","10110101001101101010110101101100001","I'm surprised anyone's using this","If you're seeing this for too long, it's a bad sign.","This might hurt a little.","Please wait... I'm pretending to work.","Close all your programs and run."}
rm=math.random(1,#msg)	msge=msg[rm]
if lastimp then dropstuff=lastuff lok=lastlog zerozz=lastzeros fld=lastfield
else dropstuff="replacer" lok=false zerozz="01" fld="effect" end
g_impex={"import OP","import ED","import sign","import signs","export sign","update lyrics"}
g_stuff={"save/load","replacer","lua calc","jump to next","alpha shift","motion blur","merge inline tags","add comment","add comment line by line","make comments visible","switch commented/visible","reverse text","reverse words","reverse transforms","fake capitals","format dates","split into letters","explode","dissolve text","randomized transforms","clone clip","what is the Matrix?","time by frames","honorificslaughterhouse","transform \\k to \\t\\alpha","convert framerate"}
unconfig={
	-- Sub --
	{x=0,y=16,width=3,height=1,class="label",label="Left                                                    "},
	{x=3,y=16,width=3,height=1,class="label",label="Right                                                   "},
	{x=6,y=16,width=3,height=1,class="label",label="Mod                                                     "},
	{x=0,y=17,width=3,height=1,class="edit",name="rep1",value=sub1},
	{x=3,y=17,width=3,height=1,class="edit",name="rep2",value=sub2},
	{x=6,y=17,width=3,height=1,class="edit",name="rep3",value=sub3,hint="start/count by[limit]"},
	
	-- import
	{x=9,y=3,width=2,height=1,class="label",label="Import/Export"},
	{x=9,y=4,width=2,height=1,class="dropdown",name="mega",items=g_impex,value="import signs"},
	{x=11,y=4,width=1,height=1,class="checkbox",name="keep",label="keep line",value=true,},
	{x=9,y=5,width=3,height=1,class="checkbox",name="restr",label="style restriction (lyrics)",value=false,},
	{x=9,y=6,width=3,height=1,class="edit",name="rest"},
	
	-- chapters
	{x=9,y=7,width=1,height=1,class="label",label="Chapters"},
	{x=10,y=7,width=2,height=1,class="checkbox",name="intro",label="autogenerate \"Intro\"",value=true,},
	{x=9,y=8,width=2,height=1,class="label",label="chapter marker:"},
	{x=11,y=8,width=1,height=1,class="dropdown",name="marker",items={"actor","effect","comment"},value="actor"},
	{x=9,y=9,width=2,height=1,class="label",label="chapter name:"},
	{x=11,y=9,width=1,height=1,class="dropdown",name="nam",items={"comment","effect"},value="comment"},
	{x=9,y=10,width=2,height=1,class="label",label="filename from:"},
	{x=11,y=10,width=1,height=1,class="dropdown",name="sav",items={"script","video"},value="script"},
	{x=9,y=11,width=2,height=1,class="checkbox",name="chmark",label="chapter mark:",value=false,hint="just sets the marker. no xml."},
	{x=11,y=11,width=1,height=1,class="dropdown",name="chap",items={"Intro","OP","Part A","Part B","Part C","ED","Preview"},value="OP"},
	{x=9,y=12,width=3,height=1,class="edit",name="lang"},
	
	-- numbers
	{x=9,y=13,width=2,height=1,class="label",label="Numbers"},
	{x=9,y=14,width=2,height=1,class="dropdown",name="modzero",items={"number lines","add to marker"},value="number lines"},
	{x=11,y=14,width=1,height=1,class="dropdown",name="zeros",items={"1","01","001","0001"},value=zerozz},
	{x=9,y=15,width=2,height=1,class="dropdown",name="field",items={"actor","effect","layer","style","text"},value=fld},
	
	-- stuff
	{x=0,y=15,width=1,height=1,class="label",label="Stuff  "},
	{x=1,y=15,width=2,height=1,class="dropdown",name="stuff",items=g_stuff,value=dropstuff}, --dropstuff
	{x=3,y=15,width=1,height=1,class="dropdown",name="regex",items={"lua patterns","perl regexp"},value="perl regexp"},
	{x=4,y=15,width=1,height=1,class="checkbox",name="log",label="log",value=lok,hint="replacers"},
	{x=8,y=15,width=1,height=1,class="label",label="Marker:"},
	
	-- textboxes
	{x=0,y=0,width=9,height=15,class="textbox",name="dat",value=data},
	{x=9,y=1,width=3,height=1,class="label",label=" Selected Lines: "..#sel},
	
	-- help
	{x=9,y=0,width=3,height=1,class="dropdown",name="help",
	items={"--- Help menu ---","Import/Export","Update Lyrics","Do Stuff","Numbers","Chapters"},value="--- Help menu ---"},
	{x=9,y=17,width=3,height=1,class="label",label="   Unimportant version: "..script_version},
}
	loadconfig()
	repeat
	  if pressed=="Help" then aegisub.progress.title("Loading Help") aegisub.progress.task("RTFM")
	    if res.help=="Import/Export" then help=help_i end
	    if res.help=="Update Lyrics" then help=help_u end
	    if res.help=="Do Stuff" then help=help_d end
	    if res.help=="Numbers" then help=help_n end
	    if res.help=="Chapters" then help=help_c end
	    if res.help=="--- Help menu ---" then help="Choose something from the menu, dumbass -->" end
		for key,val in ipairs(unconfig) do
		    if val.name=="dat" then val.value=help end
		end
	  end
	  if pressed=="Info" then aegisub.progress.title("Gathering Info") aegisub.progress.task("...") info(subs,sel,act)
		for key,val in ipairs(unconfig) do
		    if val.name=="dat" then val.value=infodump end
		end
	  end
	pressed,res=ADD(unconfig,
	{"Import/Export","Do Stuff","Numbers","Chapters","Info","Help","Save Config","Cancel"},{ok='Import/Export',cancel='Cancel'})
	until pressed~="Help" and pressed~="Info"
	if pressed=="Cancel" then    ak() end
	lastimp=true lastuff=res.stuff lastlog=res.log lastzeros=res.zeros lastfield=res.field
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	progress("Doing Stuff") aegisub.progress.task(msge)
	    sub1=res.rep1
	    sub2=res.rep2
	    sub3=res.rep3
	    zer=res.zeros
	if pressed=="Import/Export" then    important(subs,sel,act) end
	if pressed=="Numbers" then    numbers(subs,sel) end
	if pressed=="Chapters" then    chopters(subs,sel) end
	if pressed=="Do Stuff" then
	    if res.stuff=="jump to next" then sel=nextsel(subs,sel)
	    elseif res.stuff=="convert framerate" then framerate(subs)
	    elseif res.stuff=="alpha shift" then alfashift(subs,sel)
	    elseif res.stuff=="merge inline tags" then sel=merge(subs,sel)
	    elseif res.stuff=="honorificslaughterhouse" then honorifix(subs,sel)
	    else stuff(subs,sel) end
	end
	if pressed=="Save Config" then saveconfig() end
    
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, unimportant)