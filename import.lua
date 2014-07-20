script_name="Unimportant"
script_description="Import stuff, number stuff, chapter stuff, replace stuff, do other stuff to stuff."
script_author="unanimated"
script_version="1.8"

require "clipboard"
re=require'aegisub.re'

--	SETTINGS	--

-- IMPORT --
import="import signs"			-- options: "import OP","import ED","import sign","import signs","export sign","update lyrics"
keep_line=true				-- options: true / false
style_restriction=false		-- options: true / false
script_path="relative"			-- options: "relative" / "absolute"
relative_path=""			-- relative to where your script is -> "..\\OPED\\" = one folder up and then OPED folder
					-- backslashes must be double and must be included at the end. default "" is the script folder.
absolute_path="D:\\typesetting\\"	-- absolute path to import scripts from if you set script_path to "absolute" (case-sensitive)

-- CHAPTERS --
default_marker="actor"			-- options: "actor","effect","comment"
default_chapter_name="comment"		-- options: "comment","effect"
default_save_name="script"		-- options: "script","video"
deafault_chapter_mark="OP"		-- options: "Intro","OP","Part A","Part B","Part C","ED","Preview"
autogenerate_intro=true			-- options: true / false
ch_script_path="relative"		-- options: "relative" / "absolute"
ch_relative_path=""			-- relative to where your script is -> "..\\chapters\\" = one folder up and then 'chapters' folder
					-- backslashes must be double and must be included at the end. default "" is the script folder.
ch_absolute_path="D:\\typesetting\\"	-- absolute path to save chapters if you set script_path to "absolute" (case-sensitive)

-- NUMBERS --
actor_effect="effect"			-- options: "actor","effect","layer","style","text"
numbering="01"				-- options: "1","01","001","0001"

-- STUFF --
default_stuff="lua replacer"		-- options: just read them in the menu (backslashes must be double)

--	--	--	--

function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end
function round(num) num=math.floor(num+0.5) return num end

function important(subs, sel, act)
	aline=subs[act]
	atext=aline.text
	atags=atext:match("^{(\\[^}]-)}") 
	if atags==nil then atags="" end
	atags=atags:gsub("\\move%([^%)]+%)","")
	atxt=atext:gsub("^{\\[^}]-}","")
	-- create table from user data (lyrics)
	sdata={}
	if res.mega=="update lyrics" and res.dat=="" then aegisub.dialog.display({{x=0,y=0,width=1,height=1,class="label",label="No lyrics given."}},{"ok"},{cancel='ok'}) aegisub.cancel()
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
	scriptpath=aegisub.decode_path("?script")
	if script_path=="relative" then path=scriptpath.."\\"..relative_path end
	if script_path=="absolute" then path=absolute_path end

	-- IMPORT -- 
	if res.mega:match("import") then
	    
	    noshift=false	defect=false	keeptxt=false	deline=false
	    
	    -- import-single-sign GUI
	    if res.mega=="import sign" then
		press,reslt=aegisub.dialog.display({
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
		if press=="Cancel" then aegisub.cancel() end
		if reslt.signs=="custom" then signame=reslt.signame else signame=reslt.signs end
		noshift=reslt.noshift		keeptxt=reslt.keeptext	deline=reslt.deline
		keeptags=reslt.keeptags		addtags=reslt.addtags
	    end
	
	    -- read signs.ass
	    if res.mega=="import signs" then
		file=io.open(path.."signs.ass")
		if file==nil then aegisub.dialog.display({{x=0,y=0,width=1,height=1,class="label",label=path.."signs.ass\nNo such file."}},{"ok"},{cancel='ok'}) aegisub.cancel() end
		signs=file:read("*all")
		io.close(file)
	    end
	
	    -- sort out if using OP, ED, signs, or whatever .ass and read the file
	    songtype=res.mega:match("import (%a+)")
	    if songtype=="sign" then songtype=signame end
	    file=io.open(path..songtype..".ass")
	    if file==nil then aegisub.dialog.display({{x=0,y=0,width=1,height=1,class="label",label=path..songtype..".ass\nNo such file."}},{"ok"},{cancel='ok'}) aegisub.cancel() end
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
		button,reslt=aegisub.dialog.display({
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
		if button=="Cancel" then aegisub.cancel() end
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
	    if line.effect=="" then aegisub.dialog.display({{class="label",label="Effect must contain name."}},{"OK"},{close='OK'}) aegisub.cancel() end
	    if x==1 then snam=line.effect end
	    exportsign=exportsign..line.raw.."\n"
	    end
	    press,reslt=aegisub.dialog.display({
		{x=0,y=0,width=2,height=1,class="dropdown",name="addsign",
			items={"Add to signs.ass","Save to new file:"},value="Add to signs.ass"},
		{x=0,y=1,width=2,height=1,class="edit",name="newsign",value=snam},
		},{"OK","Cancel"},{ok='OK',close='Cancel'})
	    if press=="Cancel" then aegisub.cancel() end
	    if press=="OK" then
	    newsgn=reslt.newsign:gsub("%.ass$","")
	    if reslt.addsign=="Add to signs.ass" then file=io.open(path.."signs.ass","a") exportsign="\n"..exportsign end
	    if reslt.addsign=="Save to new file:" then file=io.open(path..newsgn..".ass","w") end
	    file:write(exportsign)
	    file:close()
	    end
	end

	-- Update Lyrics
	if res.mega=="update lyrics" then
	  sup1=esc(sub1)	sup2=esc(sub2)
	  for x, i in ipairs(sel) do
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
    
    if res.mega=="update lyrics" and songcheck==0 then press,reslt=aegisub.dialog.display({{x=0,y=0,width=1,height=1,class="label",label="The "..res.field.." field of selected lines doesn't match given pattern \""..sub1.."#"..sub2.."\".\n(Or style pattern wasn't matched if restriction enabled.)\n#=number sequence"}},{"ok"},{cancel='ok'}) end
    
    noshift=nil		defect=nil	keeptxt=nil	deline=nil	keeptags=nil	addtags=nil
end

--	 NUMBERS	--
function numbers(subs, sel)
    z=zer:len()
	if sub3:match("[,/;]") then startn,int=sub3:match("(%d+)[,/;](%d+)") else startn=sub3:gsub("%[.-%]","") int=1 end
	if sub3:match("%[") then numcycle=tonumber(sub3:match("%[(%d+)%]")) else numcycle=0 end
	if sub3=="" then startn=1 end
	startn=tonumber(startn)
	if startn==nil or numcycle>0 and startn>numcycle then
	    aegisub.dialog.display({{class="label",label="Wrong parameters."}},{"OK"},{close='OK'}) 
	    aegisub.cancel() 
	end
	
    for i=1,#sel do
        line=subs[sel[i]]
        text=subs[sel[i]].text
	
	if res.modzero=="number lines" then
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
		if res.field=="actor" then line.actor=sub1..line.actor..sub2
		elseif res.field=="effect" then line.effect=sub1..line.effect..sub2
		elseif res.field=="text" then text=sub1..text..sub2
		end
	end

	line.text=text
	subs[sel[i]]=line
    end
end

--	CHAPTERS	--
function chopters(subs, sel)
  if res.marker=="effect" and res.nam=="effect" then 
	aegisub.dialog.display({{class="label",label="Error. Both marker and name cannot be 'effect'."}},{"OK"},{close='OK'}) aegisub.cancel() 
  end
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
	--line.effect="chptr"
	--text="{"..res.chap.."}"
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
	
    pressed,reslt=aegisub.dialog.display(chdialog,{"Save xml file","Cancel","Copy to clipboard",},{cancel='Cancel'})
    if pressed=="Copy to clipboard" then    clipboard.set(chapters) end
    if pressed=="Save xml file" then    
	scriptpath=aegisub.decode_path("?script")
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

--	STUFF	--
function stuff(subs, sel)
    repl=0
    data={}	raw=res.dat.."\n"
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    
    -- DATES GUI --
    if res.stuff=="format dates" then
	dategui=
	{{x=0,y=0,class="dropdown",name="date",value="January 1st",items={"January 1","January 1st","1st of January","1st January"}},
	{x=1,y=0,class="checkbox",name="log",label="log",value=false,}}
	pres,rez=aegisub.dialog.display(dategui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	if pres=="Cancel" then aegisub.cancel() end
	datelog=""
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
	pres,rez=aegisub.dialog.display(dissgui,{"OK","What Is This","Cancel"},{ok='OK',close='Cancel'})
	if pres=="What Is This" then
	    dishelp={x=0,y=6,width=10,height=8,class="textbox",value="The script can either automatically draw a clip around the text,\nor you can make your own clip.\nThe automation only considers position, alignment, and scaling,\nso for anything more complex, make your own.\nYou can just try it without a clip,\nand if the result isn't right, draw a clip first. (Only 4 points!)\n\n'Distance between points' will be the distance between the\nstarting points of all the little iclips.\nLess Distance = more clips = more lag,\nso use the lowest values only for smaller text.\nYou can run this on one line or fbf lines.\nThe ideal 'fade' is as many frames as the given Distance.\nThat way the clips grow by 1 pixel per frame.\nAny other way doesn't look too good,\nbut you can apply Distance 10 over 20 lines\nand have each 2 consecutive lines identical.\nMore Distance than lines doesn't look so bad, and the effect is 'faster'.\nIf you apply this to 1 line, the line will be split to have the effect applied to as many frames as the Distance is. (This is preferred.)\nFor hexagon, the actual distance is twice the input. (It grows faster.)\n\nThe shapes should be self-explanatory, so just experiment.\n\n'Shift even rows' means that even rows will have an offset\nfrom odd rows by half of the given Distance.\nNot checking this will have a slightly different and less regular effect,\nthough it also depends on the shape. Again, experiment.\n\nIf you need to apply this to several layers, you have to do it one by one. The GUI remembers last values. But more layers = more lag.\n\nAll kinds of things can make this lag, so use carefully.\nLines are less laggy than other shapes.\nHorizontal lines are the least laggy. (Unless you have vertical text.)\n\nFor longer fades, use more Distance.\nThis works great with vertical lines but is pretty useless with horizontal.\n\n'Reverse effect' is like fade in while the default is fade out.\nWith one line selected, it applies to the first frames.\n\n'Dissolve v2' is a different kind of dissolve\nand only works with square, diamond, and vertical lines.\nLine count for this is independent on distance between points.\nIt's the only effect that allows Distance 4.\n'Shift even rows' has no effect here.\n\nYou can set a direction of Dissolve v2.\nObviously top and bottom is nonsense for vertical lines.\n'Reverse effect' reverses the direction too, so choose the opposite.\n\nThere may be weird results with some combinations of settings.\nThere may be some malfunctions, as the script is pretty complex.\nSome of them -might- be fixed by reloading automation scripts.\nMakes no sense with \\move. Nukes \\fad.\n\nThere are some fun side effects.\nFor example with 'square 2' and 'Shift even rows',\nyou get a brick wall on the last frame."}
	    table.insert(dissgui,dishelp)
	    pres,rez=aegisub.dialog.display(dissgui,{"OK","Cancel"},{ok='OK',close='Cancel'})
	end
	if pres=="Cancel" then aegisub.cancel() end
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
	  aegisub.dialog.display({{class="label",label="Distance 4 is only allowed for square mod. Changing to 6."}},{"OK"},{close='OK'})
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
	      if lframes<linez then
		aegisub.dialog.display({{class="label",label="Line must be at least "..linez.." frames long."}},
		{"OK"},{close='OK'})		aegisub.cancel()
	      end
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
    
    if res.stuff:match("replacer") then table.sort(sel,function(a,b) return a>b end) end
    
    for i=#sel,1,-1 do
        line=subs[sel[i]]
        text=line.text
	style=line.style
	
	if res.stuff=="save/load" and i==1 then
	    if savedata==nil then savedata="" end
	    if res.dat~="" then
		savedata=savedata.."\n\n"..res.dat
		savedata=savedata
		:gsub("^\n\n","")
		:gsub("\n\n\n","\n\n")
		aegisub.dialog.display({{class="label",label="Data saved.",x=0,y=0,width=20,height=2}},{"OK"},{close='OK'})
	    else
		aegisub.dialog.display({{x=0,y=0,width=50,height=18,class="textbox",name="savetxt",value=savedata},},{"OK"},{close='OK'})
	    end
	end
	
	if res.stuff=="lua replacer" then
	    lim=sub3:match("^%d+")
	    if lim==nil then limit=1 else limit=tonumber(lim) end
	    replicant1=sub1:gsub("\\","\\"):gsub("\\\\","\\")
	    replicant2=sub2:gsub("\\","\\"):gsub("\\\\","\\")
	    tk=text
	    count=0
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
	end
	
	if res.stuff=="perl replacer" then
	    lim=sub3:match("^%d+")
	    if lim==nil then limit=1 else limit=tonumber(lim) end
	    replicant1=sub1:gsub("\\","\\"):gsub("\\\\","\\")
	    replicant2=sub2:gsub("\\","\\"):gsub("\\\\","\\")
	    tk=text
	    count=0
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
		if kom~=nil then text=text.."{"..kom.."}" end
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
	    tags=text:match("^{\\[^}]-}") if tags==nil then tags="" end
	    text=text:gsub("{[^}]-}","")
	    nt=""
	    for l in text:gmatch(".") do nt=l..nt end
	    text=tags..nt
	end
	
	if res.stuff=="reverse words" then
	    tags=text:match("^{\\[^}]-}") if tags==nil then tags="" end
	    text=text:gsub("{[^}]-}","")
	    nt=""
	    for l in text:gmatch("[^%s]+") do nt=" "..l..nt end
	    nt=nt:gsub("^ ","")
	    text=tags..nt
	end
	
	if res.stuff=="fake capitals" then
	    tags=text:match("^{\\[^}]-}") if tags==nil then tags="" end
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
	
	line.text=text
	subs[sel[i]]=line
    end
    if res.stuff:match"replacer" then aegisub.progress.task("All stuff has been finished.")
	if repl==1 then rp=" modified line" else rp=" modified lines" end
	press,reslt=aegisub.dialog.display({},{repl..rp},{cancel=repl..rp})
    end
    if res.stuff=="format dates" and rez.log then aegisub.log(datelog) end
end

--	Jump to Next	--
function nextsel(subs, sel)
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

--	Alpha Shift
function alfashift(subs, sel)
    count=1
    for x, i in ipairs(sel) do
        local line=subs[i]
	local text=line.text
	if not text:match("{\\alpha&HFF&}[%w%p]") then aegisub.dialog.display({{class="label",
		label="Line "..x.." does not \nappear to have alpha FF",x=0,y=0,width=1,height=2}},{"OK"}) aegisub.cancel() end
	    if count>1 then
		switch=1
		repeat 
		text=text:gsub("({\\alpha&HFF&})([%w%p])","%2%1")
		text=text:gsub("({\\alpha&HFF&})(%s)","%2%1")
		text=text:gsub("({\\alpha&HFF&})(\\N)","%2%1")
		text=text:gsub("({\\alpha&HFF&})$","")
		switch=switch+1
		until switch>=count
	    end
	count=count+1
	line.text=text
        subs[i]=line
    end
end

--	Merge inline tags
function merge(subs, sel)
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
	  for c in rt:gmatch(".") do
	    table.insert(tk,c)
	  end
	end
	if vis~=rt then aegisub.dialog.display({{class="label",label="Error. Inconsistent text."}},{"OK"},{close='OK'}) aegisub.cancel() end
	stags=text:match("^{(\\[^}]-)}")
	if stags~=nil then stg=stg..stags stg=duplikill(stg) end
	text=text:gsub("^{\\[^}]-}","") :gsub("{[^\\}]-}","")
	count=0
	for seq in text:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=chars:len()+count
	    tgl={p=pos,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=pos
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

--	Honorificslaughterhouse
function honorifix(subs, sel)
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

--	framerate
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
	if tagz:match("\\t") then 
	    for t in tagz:gmatch("(\\t%([^%(%)]-%))") do tf=tf..t end
	    for t in tagz:gmatch("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))","") do tf=tf..t end
	    tagz=tagz:gsub("\\t%([^%(%)]+%)","")
	    tagz=tagz:gsub("\\t%([^%(%)]-%([^%)]-%)[^%)]-%)","")
	end
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
	tagz=tagz:gsub("(\\pos%([^%)]+%))([^}]-)(\\pos%([^%)]+%))","%1%2")
	tagz=tagz:gsub("({\\[^}]-)}","%1"..tf.."}")
	return tagz
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
    for i=1, #subs do
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
	if video==nil then prop=aegisub.project_properties() video=prop.video_file:gsub("^.*\\","") end
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

help_i="- IMPORT/EXPORT -\n\nThis allows you to import OP/ED or signs (or whatever) from an external .ass file.\nOP/ED must be saved as OP.ass and ED.ass; a sign can have any name.\nThe .ass file may contain headers, or it can be just the dialogue lines.\nThe imported stuff will be shifted to your currently selected line (or the first one in your selection).\nThe first line of the saved file works as a reference point, so use a \"First frame of OP\" line etc.\n(You can save your OP/ED shifted to 0 or you can just leave it as is; the times will be recalculated to start at the current line.)\n\"keep line\" will keep your current line and comment it. Otherwise the line gets deleted (you can change it in settings).\n\nIMPORT SIGN / IMPORT SIGNS - works like OP/ED, but you have to input the sign's name.\nThe difference between the two is:\nSIGN - each sign must be saved in its own .ass file. \nIn the GUI, input the sign's/file's name, for example \"eptitle\"[.ass].\nSIGNS - all signs must be saved in signs.ass. \nThey are distinguished by what's in the \"effect\" field - that's the sign's name.\nFor SIGN, make something like eptitle.ass, eyecatch.ass;\nfor SIGNS, put \"eptitle\" or \"eyecatch\" in the effect field, and put all the signs in signs.ass.\n(You can have blank lines between signs for clarity. The script can deal with those.)\nThe GUI will then show you a list of signs that it gets from the effect fields.\nI recommend using SIGNS, as it's imo more efficient (but SIGN was written first and I didn't nuke it).\n\nOptions:\nWith nothing checked, stuff is shifted to the first frame of your active line (like OP/ED).\n(SIGN) File name: \"custom\" will use what you type below. The other ones are presets.\n\"keep current line's times\" - all imported lines will have the start/end time of your active line\n\"keep current line's text\" - all imported lines will have their text (not tags) replaced with your active line's text\n   - If you want to replace only some lines and keep others, like masks, put 'x' in actor field of the mask.\n\"combine tags (current overrides)\" - tags from current + imported line get combined (current overrides imported)\n\"combine tags (imported overrides)\" - same as above, but imported overrides current\n   - Both of these will also be ignored for imported lines that have \"x\" in actor field.\n\"don't shift times\" - times of imported lines will be kept as they were saved\n\"delete original line\" - this overrides the \"keep line\" option in the main menu. \n(I thought it would be convenient to have it here.)\n\nEXPORT SIGN - Saves the selected sign(s) either to 'signs.ass' or to a new file.\nEffect field must contain the signs' names.\n\nYou can use relative or absolute paths. (Check the settings below.)\nDefault is the script's folder. If you want the default to be one folder up, use \"..\\\".\nYou can use an absolute path, have one huge signs.ass there, \nand have all the signs marked \"show_name-sign_name\" in the effect field.\n\n"

help_u="UPDATE LYRICS\n\nThis is probably the most complicated part, but if your songs have some massive styling with layers and mocha tracking,\nthis will make updating lyrics, which would otherwise be a pain in the ass, really easy.\nThe only styling that will prevent this from working is inline tags - gradient by character etc.\n\nThe prerequisite here is that your OP/ED MUST have NUMBERED lines! (See NUMBERS section - might be good to read that first.)\nThe numbers must correspond to the verses, not to lines in the script.\nIf line 1 of the SONG is mocha-tracked over 200 frames, all of those frames must be numbered 01.\nIt is thus most convenient to number the lines before you start styling, when it's still simple.\n\nHow this works:\nPaste your updated lyrics into the large, top-left area of the GUI.\nUse the Left and Right fields to set the markers to detect the right lines.\nWithout markers it will just look for numbers.\nIf your OP lines are numbered with \"OP01eng\", you must set \"OP\" under Left and \"eng\" under Right.\nFor now, everything is case-sensitive (I might change that later if it gets really annoying and pointless).\nYou must also correctly set the actor/effect choice in the bottom-right part of the GUI.\nIf you pasted lyrics, selected \"update lyrics\", and set markers and actor/effect, then hit Import, and lyrics will be updated.\n\nHow it works - example: The lyrics you pasted in the data box get their lines assigned with numbers from 1 to whatever.\nLet's say your markers are \"OP01eng\" and you're using the effect field.\nThe script looks for lines with that pattern in the effect field.\nWhen it finds one, it reads the number (for example \"01\" from \"OP01eng\")\nand replaces the line's text (skipping tags) with line 1 from the pasted lyrics.\nFor every line marked \"OP##eng\" it replaces the current lyrics with line ## from your pasted updated lyrics.\n\nTo make sure this doesn't fuck up tremendously, it shows you a log with all replacements at the end.\n\nThat's pretty much all you really need to know for updating lyrics, but there are a few more things.\n\nIf the script doesn't find any lines that match the markers, it gives you a message like this:\n\"The effect field of selected lines doesn't match given pattern...\"\nThis means the lines either don't exist in your selection, or you probably forgot to set the markers.\n\n\"style restriction\" is an extra option that lets you limit the replacing to lines whose style contains given pattern.\nLet's give some examples:\nYou check the restriction and type \"OP\" in the field below.\nYou can now select the whole script instead of selecting only the OP lines, and only lines with \"OP\" in style will be updated.\nYou may have the ED numbered the same way, but the \"OP\" restriction will ignore it.\nThis can be also useful if you have lines numbered just 01, 02 etc., and you have english and romaji, all mixed together.\nIf your styles are OP-jap and OP-eng, you can type \"jap\" in the restriction field if you're updating romaji\nto make sure the script doesn't update the english lines as well (replacing them with romaji).\nIt is, however, recommended to just use different markers, like j01 / e01.\n"

help_c="- CHAPTERS -\n\nThis will generate chapters from the .ass file\n\nMARKER: For a line to be used for chapters, it has to be marked with \"chapter\"/\"chptr\"/\"chap\" in actor/effect field (depending on settings) or the same 3 options as a separate comment, ie. {chapter} etc.\n\nCHAPTER NAME: What will be used as chapter name. It's either the content of the effect field, or the line's FIRST comment. If the comment is {OP first frame} or {ED start}, the script will remove \" first frame\" or \" start\", so you can keep those.\n\nIf you use default settings, just put \"chapter\" in actor field and make comments like {OP} or {Part A}.\n\nSubchapters: You can make subchapters like this {Part A::Scene 5}. This will be a subchapter of \"Part A\" called \"Scene 5\".\n\nIf you want a different LANGUAGE than 'eng', set it in the textbox below \"chapter mark\"\n\nCHAPTER MARK: Sets the selected chapter for selected line(s). Uses marker and name. (Doesn't create xml.)\nIf you want a custom chapter name, type it in the textbox below this."

help_n="- NUMBERS -\n\nThis is a tool to number lines and add various markers to actor/effect fields.\nThe dropdown with \"01\" lets you choose how many leading zeros you want.\nThe Left and Right fields will add stuff to the numbers. If Left is \"x\" and Right is \"yz\", the first marker will be \"x01yz\".\nWhat makes this function much more versatile is the \"Mod\" field.\nIf you put in one number, then that's the number from which the numbering will start, so \"5\" -> 5, 6, 7, etc.\nYou can, however, use a comma or slash to modify the numbering some more.\n\"8,3\" or \"8/3\" will start numbering from 8, repeating each number 3 times, so 8, 8, 8, 9, 9, 9, 10, 10, 10, etc.\nThis allows you to easily number lines that are typeset in layers etc.\nAdditionally, you can set a limit in [], for example 1/3[2], which will start from 1, use each number 3 times,\nand only go up to 2 and then start again, so: 1 1 1 2 2 2 1 1 1 2 2 2\n2/3[4] would give you 2 2 2 3 3 3 4 4 4 2 2 2 3 3 3 4 4 4 ...\n\n\"add to marker\" uses the Left and Right fields to add stuff to the current content of actor/effect/text.\nIf you number lines for the OP, you can set \"OP-\" in Left and \"-eng\" in Right to get \"OP-01-eng\".\n(Mod does nothing when adding markers.)"

help_d="- DO STUFF -\n\n- Save/Load -\nYou can use this to save for example bits of text you need to paste frequently (like a multi-clipboard).\nPaste text in the data area to save it. If the data area is empty, the function will load your saved texts.\n\n- Lua Replacer -\nUse \"Left\" and \"Right\" for a lua regexp replace function.\n\n- Perl Replacer -\nUse \"Left\" and \"Right\" for a perl regexp replace function.\n\n- Lua Calc -\nUse \"Left\" and \"Right\" with lua regexp to perform calculations on captured numbers.\nCaptures will be named a, b, c... up to p (16 captures max).\nFunctions are +, -, *, /, and round(a), which rounds the number captured in a.\n> Example: (%d)(%d)(%d) -> a+1b*2c-3\nThis will match 3-digit patterns, add 1 to first digit, multiply the second by 2, and subtract 3 from the 3rd.\nIf you want to leave one of the captures as is, use .. to separate it from other letters: a+1b..c-3 \n> Example: pos%(([%d%.]+),([%d%.]+) -> pos(a+50,b-100\nThis will shift position right by 50 and up by 100. \n\n- Jump to Next -\nThis is meant to get you to the \"next sign\" in the subtitle grid.\nWhen mocha-tracking 1000+ lines, it can be a pain in the ass to find where one sign ends and another begins.\nSelect lines that belong to the current \"sign\", ie. different layers/masks/texts.\nThe script will search for the first line in the grid that doesn't match any of the selected ones, based on the \"Marker\".\n\n- Alpha Shift -\nShifts {\\alpha&HFF&} by one letter for each line. Text thus appears letter by letter.\nIt's an alternative to the script that spawns \\ko, but this works with shadow too.\nDuplicate a line with {\\alpha&HFF&} however many times you need and run the script on the whole selection.\n\n- Merge Inline Tags -\nSelect lines with the same text but different tags, and they will be merged into one line with tags from all of them. For example:\n{\\bord2}AB{\\shad3}C\nA{\\fs55}BC\n-> {\\bord2}A{\\fs55}B{\\shad3}C\n\n- Add Comment -\nText that you type here in this box will be added as a {comment} at the end of selected lines.\n\n- Make Comments Visible -\nNukes { } from comments, thus making them part of the text visible on screen.\n\n- Switch Commented/Visible -\nComments out what's visible and makes visible what's commented. Allows switching between two texts.\n\n- Reverse text -\nReverses text (character by character). Nukes comments and inline tags.\n\n- Reverse Words -\nReverses text (word by word). Nukes comments and inline tags.\n\n- Fake Capitals -\nCreates fake capitals by increasing font size for first letters.\nWith all caps, for first letters of words. With mixed text, for uppercase letters.\nSet the \\fs for the capitals in the Left field.\nLooks like this: {\\fs60}F{\\fs}AKE {\\fs60}C{\\fs}APITALS\n\n- Format Dates -\nFormats dates to one of 4 options. Has its own GUI. Only converts from the other 3 options in the GUI.\n\n- Dissolve Text -\nVarious modes of dissolving text. Has its own Help.\n\n- Honorificslaughterhouse -\nComments out honorifics.\n\n- Convert Framerate -\nConverts framerate from a to b where a is the input from \"Left\" and b is input from \"Right\".\n"


function unimportant(subs, sel, act)
aegisub.progress.title("Loading Unimportant Stuff")
aegisub.progress.task("This should take less than a second, so you won't really read this.")
--aline=subs[act]
--active=aline.text:gsub("^{\\[^}]*}","")
--anocom=aline.text:gsub("{[^}]-}","")
--actime=(aline.end_time-aline.start_time)/1000
if datata==nil then data="" else data=datata end
if sub1==nil then sub1="" end
if sub2==nil then sub2="" end
if sub3==nil then sub3=1 end
--if res.stuff~=nil then val_stuff=res.stuff else val_stuff="lua replacer" end
msg={"If it breaks, it's your fault.","This should be doing something...","Breaking your computer. Please wait.","Unspecified operations in progress.","This may or may not work.","Trying to avoid bugs...","Zero one one zero one zero...","10110101001101101010110101101100001","I'm surprised anyone's using this","If you're seeing this for too long, it's a bad sign."}
rm=math.random(1,#msg)	msge=msg[rm]
dmark=deafault_chapter_mark
if lastimp then dropstuff=lastuff logg=lastlog else dropstuff=default_stuff logg=false end
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
	{x=9,y=4,width=2,height=1,class="dropdown",name="mega",
	items={"import OP","import ED","import sign","import signs","export sign","update lyrics"},value=import},
	{x=11,y=4,width=1,height=1,class="checkbox",name="keep",label="keep line",value=keep_line,},
	{x=9,y=5,width=3,height=1,class="checkbox",name="restr",label="style restriction (lyrics)",value=style_restriction,},
	{x=9,y=6,width=3,height=1,class="edit",name="rest"},
	
	-- chapters
	{x=9,y=7,width=1,height=1,class="label",label="Chapters"},
	{x=10,y=7,width=2,height=1,class="checkbox",name="intro",label="autogenerate \"Intro\"",value=autogenerate_intro,},
	{x=9,y=8,width=2,height=1,class="label",label="chapter marker:"},
	{x=11,y=8,width=1,height=1,class="dropdown",name="marker",items={"actor","effect","comment"},value=default_marker},
	{x=9,y=9,width=2,height=1,class="label",label="chapter name:"},
	{x=11,y=9,width=1,height=1,class="dropdown",name="nam",items={"comment","effect"},value=default_chapter_name},
	{x=9,y=10,width=2,height=1,class="label",label="filename from:"},
	{x=11,y=10,width=1,height=1,class="dropdown",name="sav",items={"script","video"},value=default_save_name},
	{x=9,y=11,width=2,height=1,class="checkbox",name="chmark",label="chapter mark:",value=false,hint="just sets the marker. no xml."},
	{x=11,y=11,width=1,height=1,class="dropdown",name="chap",items={"Intro","OP","Part A","Part B","Part C","ED","Preview"},value=dmark},
	{x=9,y=12,width=3,height=1,class="edit",name="lang"},
	
	-- numbers
	{x=9,y=13,width=2,height=1,class="label",label="Numbers"},
	{x=9,y=14,width=2,height=1,class="dropdown",name="modzero",items={"number lines","add to marker"},value="number lines"},
	{x=11,y=14,width=1,height=1,class="dropdown",name="zeros",items={"1","01","001","0001"},value=numbering},
	{x=9,y=15,width=2,height=1,class="dropdown",name="field",items={"actor","effect","layer","style","text"},value=actor_effect},
	
	-- stuff
	{x=0,y=15,width=1,height=1,class="label",label="Stuff  "},
	{x=1,y=15,width=2,height=1,class="dropdown",name="stuff",items={"save/load","lua replacer","perl replacer","lua calc","jump to next","alpha shift","merge inline tags","add comment","add comment line by line","make comments visible","switch commented/visible","reverse text","reverse words","fake capitals","format dates","dissolve text","honorificslaughterhouse","transform \\k to \\t\\alpha","convert framerate"},value=dropstuff},
	{x=3,y=15,width=1,height=1,class="checkbox",name="log",label="log",value=logg,hint="replacers"},
	{x=8,y=15,width=1,height=1,class="label",label="Marker:"},
	
	-- textboxes
	{x=0,y=0,width=9,height=15,class="textbox",name="dat",value=data},
	{x=9,y=1,width=3,height=1,class="label",label=" Selected Lines: "..#sel},
	
	-- help
	{x=9,y=0,width=3,height=1,class="dropdown",name="help",items={"--- Help menu ---","Import/Export","Update Lyrics","Do Stuff","Numbers","Chapters"},value="--- Help menu ---"},
	{x=9,y=17,width=3,height=1,class="label",label="   Unimportant version: "..script_version},
}

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
	pressed,res=aegisub.dialog.display(unconfig,
	{"Import/Export","Do Stuff","Numbers","Chapters","Info","Help","Cancel"},{ok='Import/Export',cancel='Cancel'})
	until pressed~="Help" and pressed~="Info"
	if pressed=="Cancel" then    aegisub.cancel() end
	cancelled=aegisub.progress.is_cancelled()
	if cancelled then aegisub.cancel() end
	lastimp=true lastuff=res.stuff lastlog=res.log
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	aegisub.progress.title("Doing Stuff") aegisub.progress.task(msge)
	    sub1=res.rep1
	    sub2=res.rep2
	    sub3=res.rep3
	    zer=res.zeros
	if pressed=="Import/Export" then    important(subs, sel, act) end
	if pressed=="Numbers" then    numbers(subs, sel) end
	if pressed=="Chapters" then    chopters(subs, sel) end
	if pressed=="Do Stuff" then
	    if res.stuff=="jump to next" then sel=nextsel(subs, sel)
	    elseif res.stuff=="convert framerate" then framerate(subs)
	    elseif res.stuff=="alpha shift" then alfashift(subs,sel)
	    elseif res.stuff=="merge inline tags" then sel=merge(subs,sel)
	    elseif res.stuff=="honorificslaughterhouse" then honorifix(subs,sel)
	    else stuff(subs, sel) end
	end
    
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, unimportant)