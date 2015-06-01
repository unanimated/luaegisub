--[[	Full manual: http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#masquerade

	• Masquerade
	Creates a mask with the selected shape
	"create mask on a new line" does the obvious and raises the layer of the current line by 1
	"remask" only changes an existing mask for another shape without changing tags
	"Save/delete mask" lets you save a mask from active line or delete one of your custom masks
	- to save a mask, type a name and the mask from your active line will be saved (appdata/masquerade.masks)
	- to delete a mask, type its name or type 'del' and select the name from the menu on the left

	• Shift Tags
	Allows you to shift tags by character or by word.
	For the first block, single tags can be moved right. For inline tags, each block can be moved left or right.

	• an8 / q2 (obvious)

	• Motion Blur
	Creates motion blur by duplicating the line and using some alpha.
	You can set a value for blur or keep the existing blur for each line.
	'Distance' is the distance between the \pos coordinates of the resulting 2 lines.
	If you use 3 lines, the 3rd one will be in the original position, i.e. in the middle.
	The direction is determined from the first 2 points of a vectorial clip (like with clip2frz/clip2fax).

	• Merge Tags
	Select lines with the SAME TEXT but different tags, and they will be merged into one line with tags from all of them.
	For example:
	{\bord2}AB{\shad3}C
	A{\fs55}BC
	-> {\bord2}A{\fs55}B{\shad3}C
	If 2 lines have the same tag in the same place, the value of the later line overrides the earlier one.

	• Alpha Shift
	Makes text appear letter by letter on frame-by-frame lines using alpha&HFF& like this:
	{alpha&HFF&}text
	t{alpha&HFF&}ext
	te{alpha&HFF&}xt
	tex{alpha&HFF&}t
	text

	• Alpha Time
	Either select lines that are already timed for alpha timing and need alpha tags, or just one line that needs to be alpha timed.
	In the GUI, split the line by hitting Enter where you want the alpha tags.
	If you make no line breaks, text will be split by spaces.
	Alpha Text is for when you have the lines already timed and just need the tags.
	Alpha Time is for one line. It will be split to equally long lines with alpha tags added.
	If you add "@" to your line first, alpha tags will replace the @, and no GUI will pop up.
	Example text:	This @is @a @test.

	• Strikealpha
	Replaces strikeout or underline tags with \alpha&H00& or \alpha&HFF&. Also @.
	@	->	{\alpha&HFF&}
	@0	->	{\alpha&H00&}
	{\u1}	->	{\alpha&HFF&}
	{\u0}	->	{\alpha&H00&}
	{\s0}	->	{\alpha&HFF&}
	{\s1}	->	{\alpha&H00&}
	@E3@	->	{\alpha&HE3&}

--]]

script_name="Masquerade"
script_description="Masquerade"
script_author="unanimated"
script_version="2.5"
script_namespace="ua.Masquerade"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="2.5.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

re=require'aegisub.re'

function addmask(subs,sel)
  for z=#sel,1,-1 do
    i=sel[z]
    l=subs[i]
    text=l.text
    l.layer=l.layer+1
    if res.masknew and not res.remask then
	if res.mask=="from clip" then
	if not text:match("\\clip") then
	  ADD({{class="label",label="No clip...",x=1,width=5,height=2}},{"OK"},{close='OK'}) ak()
	end
	l.text=nopar("clip",l.text) end
	subs.insert(i+1,l)
    end
    l.layer=l.layer-1
    if text:match("\\2c") then mcol="\\c"..text:match("\\2c(&H[%x]+&)") else mcol="" end
    
    -- REMASK
    if res.remask then
	if res.mask=="from clip" then
	  masklip()
	  l.text=nopar("clip",l.text)
	  nmask=ctext2 l.text=re_mask(l.text)
	else
	    for k=1,#allmasks do
	      if allmasks[k].n==res.mask then
		nmask=allmasks[k].m l.text=re_mask(l.text)
	      end
	    end
	end
    else
	-- STANDARD MASK
	if res.mask=="from clip" then
	  masklip()
	  l.text="{\\an7\\blur1\\bord0\\shad0\\fscx100\\fscy100"..mcol..mp..pos.."\\p1}"..ctext2
	else
	atags=""
	org=l.text:match("\\org%b()")		if org then atags=atags..org end
	frz=l.text:match("\\frz[%d%.%-]+")	if frz then atags=atags..frz end
	frx=l.text:match("\\frx[%d%.%-]+")	if frx then atags=atags..frx end
	fry=l.text:match("\\fry[%d%.%-]+")	if fry then atags=atags..fry end
	
	l.text=l.text:gsub(".*(\\pos%([%d%,%.%-]-%)).*","%1")
	if not l.text:match("\\pos") then l.text="" end
	  for k=1,#allmasks do
	    if allmasks[k].n==res.mask then
	      if res.mask:match("alignment grid") then
		l.text="{\\an7\\bord0\\shad0\\blur0.6"..l.text..atags.."\\c&H000000&\\alpha&H80&\\p1}"..allmasks[k].m
	      else
		l.text="{\\an7\\bord0\\shad0\\blur1"..l.text..mcol.."\\p1}"..allmasks[k].m
	      end
	      if res.mask=="square" then l.text=l.text:gsub("\\an7","\\an5") end
	    end
	  end
	if not l.text:match("\\pos") then l.text=l.text:gsub("\\p1","\\pos(640,360)\\p1") end
	end
    end
    subs[i]=l
  end
end

function masklip()
  text=text:gsub("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\clip(m %1 %2 l %3 %2 %3 %4 %1 %4)")
  if text:match("\\move") then text=text:gsub("\\move","\\pos") mp="\\move" else mp="\\pos" end
  ctext=text:match("clip%(m ([%d%.%a%s%-]+)")
  if text:match("\\pos") then
    pos=text:match("\\pos(%([^%)]+%))")
    local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)")
    xx=round(xx) yy=round(yy)
    ctext2=ctext:gsub("([%d%.%-]+)%s([%d%.%-]+)",function(a,b) return a-xx.." "..b-yy end)
  else pos="(0,0)" ctext2=ctext
  end
  ctext2="m "..ctext2:gsub("([%d%.]+)",function(a) return round(a) end)
end

function re_mask(text)
text=text
:gsub("\\fsc[xy][^}\\]+","")
:gsub("}m [^{]+","\\fscx100\\fscy100}"..nmask)
if res.mask=="square" then text=text:gsub("\\an7","\\an5") end
return text
end

function savemask(subs,sel,act)
masker=ADP("?user").."\\masquerade.masks"
file=io.open(masker)
  if file then masx=file:read("*all") io.close(file) end
  if masx==nil then masx="" end
  mask_name=res.maskname
  masx=masx:gsub(":\n$",":\n\n") :gsub(":$",":\n\n")
  -- delete mask
  deleted=0
    for m=1,#maasks do
      if mask_name=="del" then mask_name=res.mask end
      if maasks[m]==mask_name then
	if m<=10 then t_error("You can't delete a default mask.",true)
	else e_name=esc(mask_name) masx=masx:gsub("mask:"..e_name..":.-:\n\n","") t_error("Mask '"..mask_name.."' deleted",false)
	end
	deleted=1
      end
    end
  -- add new mask
  if deleted==0 then
    text=subs[act].text
    text=text:gsub("{[^}]-}","")
    newmask=text:match("m [%d%s%-mbl]+")
    newmask=newmask:gsub("%s*$","")
    if newmask==nil then t_error("No mask detected on active line.",true) end
    if mask_name=="mask name here" or mask_name=="" then
	p,rez=ADD({{class="label",label="Enter a proper name for the mask:"},
	{y=1,class="edit",name="mname"},},{"OK","Cancel"},{ok='OK',close='Cancel'})
	if p=="Cancel" then ak() end
	if rez.mname=="" then t_error("Naming fail",true) else mask_name=rez.mname end
      for m=1,#maasks do
        if maasks[m]==mask_name then
	  t_error("Mask '"..mask_name.."' already exists.",true)
        end
      end
    end
    new_mask="mask:"..mask_name..":"..newmask..":\n\n"
    masx=masx..new_mask
  end
  masx=masx:gsub(":\nmask",":\n\nmask")
  file=io.open(masker,"w")
  file:write(masx)
  file:close()
  if deleted==0 then
    ADD({{class="label",label="Mask '"..mask_name.."' saved to:\n"..masker}},{"OK"},{close='OK'})
  end
end

function add_an8(subs,sel)
    for z,i in ipairs(sel) do
    line=subs[i]
    text=line.text
    if line.text:match("\\an%d") and res.an8~="q2" then
	text=text:gsub("\\(an%d)","\\"..res.an8)
    end
    if line.text:match("\\an%d")==nil and res.an8~="q2" then
	text="{\\"..res.an8.."}"..text
	text=text:gsub("{\\(an%d)}{\\","{\\%1\\")
    end
    if res.an8=="q2" then
	if text:match("\\q2") then text=text:gsub("\\q2","")	text=text:gsub("{}","") else
	text="{\\q2}"..text	text=text:gsub("{\\q2}{\\","{\\q2\\")
	end
    end
    line.text=text
    subs[i]=line
    end
end

function alfashift(subs,sel)
    count=1
    for z,i in ipairs(sel) do
    line=subs[i]
    text=line.text
    aa=re.find(text,"\\{\\\\alpha\\&HFF\\&\\}[\\w[:punct:]]")
    if not aa then t_error("Line "..z.." does not \nappear to have \n\\alpha&&HFF&&",true) end
    if count>1 then
	switch=1
	repeat
	text=re.sub(text,"(\\{\\\\alpha\\&HFF\\&\\})([\\w[:punct:]])","\\2\\1")
	text=text
	:gsub("({\\alpha&HFF&}) "," %1")
	:gsub("({\\alpha&HFF&})\\N","\\N%1")
	:gsub("({\\alpha&HFF&})$","")
	switch=switch+1
	until switch>=count
    end
    count=count+1
    line.text=text
    subs[i]=line
    end
end

function strikealpha(subs,sel)
    for z,i in ipairs(sel) do
        l=subs[i]
	l.text=l.text
	:gsub("\\s1","\\alpha&H00&")
	:gsub("\\s0","\\alpha&HFF&")
	:gsub("\\u1","\\alpha&HFF&")
	:gsub("\\u0","\\alpha&H00&")
	:gsub("@(%x%x)@","{\\alpha&H%1&}")
	:gsub("@0","{\\alpha&H00&}")
	:gsub("@","{\\alpha&HFF&}")
	:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	subs[i]=l
    end
end

--	Motion Blur	--
function motionblur(subs,sel)
mblur=res.mblur mbdist=res.mbdist mbalfa=res.mbalfa mb3=res.mb3 keepblur=res.keepblur
    for z=#sel,1,-1 do
        i=sel[z]
	line=subs[i]
        text=line.text
	if text:match("\\clip%(m") then
	      if not text:match("\\pos") then text=getpos(subs,text) end
	      if not res.keepblur then text=addtag("\\blur"..mblur,text) end
	      text=text:gsub("{%*?\\[^}]-}",function(tg) return duplikill(tg) end)
	      c1,c2,c3,c4=text:match("\\clip%(m ([%-%d%.]+) ([%-%d%.]+) l ([%-%d%.]+) ([%-%d%.]+)")
	      if c1==nil then t_error("There seems to be something wrong with your clip",1) end
	      text=text:gsub("\\clip%b()","")
	      text=addtag3("\\alpha&H"..mbalfa.."&",text)
	      cx=c3-c1
	      cy=c4-c2
	      cdist=math.sqrt(cx^2+cy^2)
	      mbratio=cdist/mbdist*2
	      mbx=round(cx/mbratio*100)/100
	      mby=round(cy/mbratio*100)/100
	      text2=text:gsub("\\pos%(([%-%d%.]+),([%-%d%.]+)",function(a,b) return "\\pos("..a-mbx..","..b-mby end)
	      l2=line
	      l2.text=text2
	      subs.insert(i+1,l2)
	      table.insert(sel,sel[#sel]+1)
	      if res.mb3 then
		line.text=text
		subs.insert(i+1,line)
		table.insert(sel,sel[#sel]+1)
	      end
	      text=text:gsub("\\pos%(([%-%d%.]+),([%-%d%.]+)",function(a,b) return "\\pos("..a+mbx..","..b+mby end)
	else noclip=true
	end
	line.text=text
	subs[i]=line
    end
if noclip then t_error("Some lines weren't processed - missing clip.\n(2 points of a vectorial clip are needed for motion direction.)") noclip=nil end
end

--	Merge tags	--
function merge(subs,sel)
    tk={}
    tg={}
    stg=""
    for z,i in ipairs(sel) do
        line=subs[i]
        text=line.text
	text=text:gsub("{\\\\k0}","")
	repeat text,c=text until c==0
	vis=text:gsub("%b{}","")
	if z==1 then rt=vis
	letrz=re.find(rt,".")
	  for l=1,#letrz do
	    table.insert(tk,letrz[l].str)
	  end
	end
	if vis~=rt then t_error("Error. Inconsistent text.\nAll selected lines must contain the same text.",true) end
	stags=text:match("^{(\\[^}]-)}") or ""
	stg=stg..stags stg=duplikill(stg)
	text=text:gsub(STAG,"") :gsub("{[^\\}]-}","")
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
    newtext=extrakill(newtext,2)
    line=subs[sel[1]]
    line.text=newtext
    subs[sel[1]]=line
    for z=#sel,2,-1 do subs.delete(sel[z]) end
    sel={sel[1]}
    return sel
end

function shiftag(subs,sel,act)
    rine=subs[act]
    tags=rine.text:match(STAG) or ""
    ftags=tags:gsub("[{}]","")
    ftags=ftags:gsub("\\%a+%b()","") :gsub("\\an?%d","")
    cstext=rine.text:gsub(STAG,"")
    rept={"drept"}
    -- build GUI
    shiftab={
	{x=0,y=0,width=3,class="label",label="[  Start Tags (Shift Right only)  ]   ",},
	{x=3,y=0,class="label",label="[  Inline Tags  ]   ",},
	}
    ftw=1
    -- regular tags -> GUI
    for f in ftags:gmatch("\\[^\\]+") do lab=f:gsub("&","&&")
	  cb={x=0,y=ftw,width=2,class="checkbox",name="chk"..ftw,label=lab,value=false,realname=f}
	  table.insert(shiftab,cb)	ftw=ftw+1
	  table.insert(rept,f)
    end
    table.insert(shiftab,{x=0,y=ftw+1,class="label",label="Shift by letter /"})
    table.insert(shiftab,{x=1,y=ftw+1,class="checkbox",name="word",label="word"})
    table.insert(shiftab,{x=0,y=ftw+2,width=2,class="intedit",name="rept",value=1,min=1})
    table.insert(shiftab,{x=0,y=ftw+3,width=2,class="checkbox",name="nuke",label="remove selected tags"})
    itw=1
    -- inline tags
    if cstext:match(ATAG) then
      for f in cstext:gmatch(ATAG) do lab=f:gsub("&","&&")
	if itw==31 then lab="Error: 30 tags max" f="" end
	if itw==32 then break end
	  cb={x=3,y=itw,class="checkbox",name="chk2"..itw,label=lab,value=false,realname=f}
	  drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
	  if drept==0 then
	  table.insert(shiftab,cb)	itw=itw+1
	  table.insert(rept,f)
	  end
      end
    end
	repeat
	    if press=="All Inline Tags" then
		for key,val in ipairs(shiftab) do
		    if val.class=="checkbox" and val.x==3 then val.value=true end
		    if val.class=="checkbox" and val.x<3 then val.value=res[val.name] end
		end
	    end
	press,rez=ADD(shiftab,{"Shift Left","Shift Right","All Inline Tags","Cancel"},{ok='Shift Right',close='Cancel'})
	until press~="All Inline Tags"
	if press=="Cancel" then ak() end
	if press=="Shift Right" then R=true else R=false end
	if press=="Shift Left" then L=true else L=false end
	
	-- nuke tags
	if rez.nuke then
	  for key,val in ipairs(shiftab) do
	    if val.class=="checkbox" and rez[val.name] and val.x==0 and val.name~="nuke" then
	      tags=tags:gsub(esc(val.realname),"")
	      rez[val.name]=false
	    end
	    if val.class=="checkbox" and rez[val.name] and val.x==3 then
	      cstext=cstext:gsub(esc(val.realname),"")
	      rez[val.name]=false
	    end
	  end
	end

	-- shift inline tags
	if R then
	  for s=#shiftab,1,-1 do stab=shiftab[s]
	    if rez[stab.name] and stab.x==3 then stag=stab.realname etag=esc(stag) retag=resc(stag)
	    rep=0
		repeat
		if not rez.word then
		cstext=re.sub(cstext,retag.."(\\s?[\\w[:punct:]]\\s?)","\\1"..retag)
		cstext=cstext
		:gsub(etag.."(%s?\\N%s?)","%1"..stag)
		:gsub(etag.."(%s?{[^}]-}%s?)","%1"..stag)
		:gsub(etag.."(%s?\\N%s?)","%1"..stag)
		else
		cstext=cstext
		:gsub(etag.."(%s*%S+%s*)","%1"..stag)
		:gsub(etag.."(%s?\\N%s?)","%1"..stag)
		:gsub(etag.."({[^}]-})","%1"..stag)
		:gsub(etag.."(%s?\\N%s?)","%1"..stag)
		end
		rep=rep+1
		until rep==rez.rept
	    end
	  end
	elseif L then
	  for key,val in ipairs(shiftab) do
	    if rez[val.name]==true and val.x==3 then stag=val.realname etag=esc(stag) retag=resc(stag)
	    rep=0
		repeat
		if not rez.word then
		cstext=re.sub(cstext,"([\\w[:punct:]]\\s?)"..retag,retag.."\\1")
		cstext=cstext
		:gsub("(\\N%s?)"..etag,stag.."%1")
		:gsub("({[^}]-}%s?)"..etag,stag.."%1")
		:gsub("(\\N%s?)"..etag,stag.."%1")
		else
		cstext=cstext
		:gsub("([^%s]+%s*)"..etag,stag.."%1")
		:gsub("(\\N%s*)"..etag,stag.."%1")
		:gsub("(({[^}]-})%s*)"..etag,stag.."%1")
		:gsub("(\\N%s*)"..etag,stag.."%1")
		end
		rep=rep+1
		until rep==rez.rept
	    end
	  end
	  cstext=cstext:gsub("{%*?(\\[^}]-)}{%*?(\\[^}]-)}","{%1%2}")
	end
	
	cstext=cstext:gsub(ATAG,function(tg) return duplikill(tg) end)
	
	--shift start tags
	startags=""
	for key,val in ipairs(shiftab) do
	    if rez[val.name]==true and val.x==0 and val.name~="nuke" then stag=val.realname etag=esc(stag)
		if R then
		startags=startags..stag
		tags=tags:gsub(etag,"")
		end
	    end
	end
	
	if startags~="" and R then
	    cstext="{_T_}"..cstext
	    REP=0
	    if not rez.word then
		repeat
		cstext=re.sub(cstext,"\\{_T_\\}([\\w[:punct:]]\\s*)","\\1\\{_T_\\}")
		cstext=cstext
		:gsub("{_T_}(\\N%s?)","%1{_T_}")
		:gsub("{_T_}({[^}]-}%s*)","%1{_T_}")
		:gsub("{_T_}(\\N%s?)","%1{_T_}")
		REP=REP+1
		until REP==rez.rept
	    else
		repeat
		cstext=cstext
		:gsub("{_T_}(%s*[^%s]+%s*)","%1{_T_}")
		:gsub("{_T_}(%s?\\N%s?)","%1{_T_}")
		:gsub("{_T_}({[^}]-})","%1{_T_}")
		:gsub("{_T_}(%s?\\N%s?)","%1{_T_}")
		REP=REP+1
		until REP==rez.rept
	    end
	    cstext=cstext
	    :gsub("_T_",startags)
	    :gsub("{(%*?\\[^}]-)}{(%*?\\[^}]-)}","{%1%2}")
	end
	
	text=tags..cstext
	text=text:gsub("{(%*?\\[^}]-)}{(%*?\\[^}]-)}","{%1%2}")
	:gsub("^{}","")
	:gsub(ATAG,function(tg) return duplikill(tg) end) :gsub("^{%*","{")
	
    rine.text=text
    subs[act]=rine
end

function alfatime(subs,sel)
    -- collect / check text
    for z,i in ipairs(sel) do
	text=subs[i].text
	if z==1 then alfatext=text:gsub(STAG,"") end
	if z~=1 then alfatext2=text:gsub(STAG,"") 
	  if alfatext2~=alfatext then t_error("Text must be the same \nfor all selected lines",true) end
	end
    end
    
    if not alfatext:match("@") then
	-- GUI
	atGUI={{x=0,y=0,width=5,height=8,class="textbox",name="alfa",value=alfatext},
	{x=0,y=8,class="label",label="Break the text with 'Enter' the way it should be alpha-timed. (lines selected: "..#sel..")"},}
	pressed,rez=ADD(atGUI,{"Alpha Text","Alpha Time","Cancel"},{ok='Alpha Text',close='Cancel'})
	if pressed=="Cancel" then ak() end
	data=rez.alfa
    else
	data=alfatext:gsub("@","\n")
	pressed="Alpha Time"
    end
	if not data:match("\n") then data=data:gsub(" "," \n") end
	-- sort data into a table
	altab={}	data=data.."\n"
	ac=1
	data2=""
	for al in data:gmatch("(.-\n)") do 
	    al2=al:gsub("\n","{"..ac.."}") ac=ac+1 data2=data2..al2
	    if al~="" then 
	        table.insert(altab,al2) 
	    end
	end
	
    -- apply alpha text
    if pressed=="Alpha Text" then
      for z,i in ipairs(sel) do
        altxt=""
	for a=1,z do altxt=altxt..altab[a] end
	esctxt=esc(altxt)
	line=subs[i]
	text=line.text
	if altab[z]~=nil then
	  tags=text:match(STAG) or ""
	  text=data2
	  :gsub("\n","")
	  :gsub(esctxt,altxt.."{\\alpha&HFF&}")
	  :gsub("({\\alpha&HFF&}.-){\\alpha&HFF&}","%1")
	  :gsub("{\\alpha&HFF&}$","")
	  :gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	  :gsub("{%d+}","")
	  :gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	  text=tags..text
	end
	line.text=text
	subs[i]=line
      end
    end
    
    -- apply alpha text + split line
    if pressed=="Alpha Time" then
	line=subs[sel[1]]
	start=line.start_time
	endt=line.end_time
	dur=endt-start
	f=dur/#altab
	for a=#altab,1,-1 do
          altxt=""
	  altxt=altxt..altab[a]
	  esctxt=esc(altxt)
	  line.text=line.text:gsub("@","")
	  line2=line
	  tags=line2.text:match(STAG) or ""
	  line2.text=data2
	  :gsub("\n","")
	  :gsub(esctxt,altxt.."{\\alpha&HFF&}")
	  :gsub("({\\alpha&HFF&}.-){\\alpha&HFF&}","%1")
	  :gsub("{\\alpha&HFF&}$","")
	  :gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	  :gsub("{%d+}","")
	  line2.text=tags..line2.text
	  line2.start_time=start+f*(a-1)
	  line2.end_time=start+f+f*(a-1)
	  subs.insert(sel[1]+1,line2)
	end
	subs.delete(sel[1])
    end
end

--	reanimatools --
function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function logg(m) m=m or "nil" aegisub.log("\n "..m) end
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function resc(str) str=str:gsub("[%%%(%)%[%]%.%*%-%+%?%^%$\\{}]","\\%1") return str end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function addtag2(tag,text) 	-- mask version
	tg=tag:match("\\%d?%a+")
	text=text:gsub("^{(\\[^}]-)}","{"..tag.."%1}")
	:gsub("("..tg.."[^\\}]+)([^}]-)("..tg.."[^\\}]+)","%2%1")
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

function nopar(tag,t)
    t=t:gsub("\\"..tag.."%b()","") :gsub("{}","")
    return t
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

function masquerade(subs,sel,act)
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
ATAG="{%*?\\[^}]-}"
STAG="^{\\[^}]-}"
defmasks="mask:square:m 0 0 l 100 0 100 100 0 100:\n\nmask:rounded square:m -100 -25 b -100 -92 -92 -100 -25 -100 l 25 -100 b 92 -100 100 -92 100 -25 l 100 25 b 100 92 92 100 25 100 l -25 100 b -92 100 -100 92 -100 25 l -100 -25:\n\nmask:rounded square 2:m -100 -60 b -100 -92 -92 -100 -60 -100 l 60 -100 b 92 -100 100 -92 100 -60 l 100 60 b 100 92 92 100 60 100 l -60 100 b -92 100 -100 92 -100 60 l -100 -60:\n\nmask:rounded square 3:m -100 -85 b -100 -96 -96 -100 -85 -100 l 85 -100 b 96 -100 100 -96 100 -85 l 100 85 b 100 96 96 100 85 100 l -85 100 b -96 100 -100 96 -100 85 l -100 -85:\n\nmask:circle:m -100 -100 b -45 -155 45 -155 100 -100 b 155 -45 155 45 100 100 b 46 155 -45 155 -100 100 b -155 45 -155 -45 -100 -100:\n\nmask:equilateral triangle:m -122 70 l 122 70 l 0 -141:\n\nmask:right-angled triangle:m -70 50 l 180 50 l -70 -100:\n\nmask:alignment grid:m -500 -199 l 500 -199 l 500 -201 l -500 -201 m -701 1 l 700 1 l 700 -1 l -701 -1 m -500 201 l 500 201 l 500 199 l -500 199 m -1 -500 l 1 -500 l 1 500 l -1 500 m -201 -500 l -199 -500 l -199 500 l -201 500 m 201 500 l 199 500 l 199 -500 l 201 -500 m -150 -25 l 150 -25 l 150 25 l -150 25:\n\nmask:alignment grid 2:m -500 -199 l 500 -199 l 500 -201 l -500 -201 m -701 1 l 700 1 l 700 -1 l -701 -1 m -500 201 l 500 201 l 500 199 l -500 199 m -1 -500 l 1 -500 l 1 500 l -1 500 m -201 -500 l -199 -500 l -199 500 l -201 500 m 201 500 l 199 500 l 199 -500 l 201 -500 m -150 -25 l 150 -25 l 150 25 l -150 25 m -401 -401 l 401 -401 l 401 401 l -401 401 m -399 -399 l -399 399 l 399 399 l 399 -399:\n\n"
maasks={"from clip"}
allmasks={}
masker=ADP("?user").."\\masquerade.masks"
file=io.open(masker)
    if file then
	masx=file:read("*all")
	io.close(file)
    else masx=""
    end
    masklist=defmasks..masx
	for nam,msk in masklist:gmatch("mask:(.-):(.-):") do table.insert(maasks,nam) table.insert(allmasks,{n=nam,m=msk}) end
	GUI={
	{x=0,y=0,class="label",label="Mask:",},
	{x=1,y=0,class="dropdown",name="mask",items=maasks,value="square"},
	{x=0,y=1,width=2,class="checkbox",name="masknew",label="create mask on a new line",value=true},
	{x=2,y=1,width=3,class="checkbox",name="remask",label="remask",value=false},
	
	{x=11,y=0,class="checkbox",name="save",label="Save/delete mask    ",value=false},
	{x=11,y=1,width=2,class="edit",name="maskname",value="mask name here",hint="Type name of the mask you want to save/delete"},

	{x=3,y=0,class="dropdown",name="an8",items={"q2","an1","an2","an3","an4","an5","an6","an7","an8","an9"},value="an8"},
	
	{x=10,y=0,height=2,class="label",label=":\n:\n:",},
	
	{x=5,y=0,class="label",label="blur:"},
	{x=6,y=0,class="floatedit",name="mblur",value=mblur or 3,hint="motion blur"},
	{x=7,y=0,width=3,class="checkbox",name="keepblur",label="Keep current",value=keepblur,hint="keep current blur"},
	
	{x=5,y=1,class="label",label="dist:"},
	{x=6,y=1,class="floatedit",name="mbdist",value=mbdist or 6,hint="distance between positions"},
	{x=7,y=1,class="label",label="@ "},
	{x=8,y=1,class="dropdown",name="mbalfa",value=mbalfa or "80",items={"00","20","40","60","80","A0","C0","D0"},hint="alpha"},
	{x=9,y=1,class="checkbox",name="mb3",label="3L",value=mb3,hint="use 3 lines instead of 2"},
	
	{x=12,y=0,height=0,class="label",label="Masquerade "..script_version},
	}
	P,res=ADD(GUI,
	{"masquerade","shift tags","an8 / q2","motion blur","merge tags","alpha shift","alpha time","strikealpha","cancel"},{cancel='cancel'})
	if P=="cancel" then ak() end
	if P=="masquerade" and not res.save then addmask(subs,sel) end
	if P=="masquerade" and res.save then savemask(subs,sel,act) end
	if P=="strikealpha" then strikealpha(subs,sel) end
	if P=="an8 / q2" then add_an8(subs,sel,act) end
	if P=="alpha shift" then alfashift(subs,sel) end
	if P=="alpha time" then alfatime(subs,sel) end
	if P=="motion blur" then motionblur(subs,sel) end
	if P=="merge tags" then sel=merge(subs,sel) end
	if P=="shift tags" then shiftag(subs,sel,act) end
    aegisub.set_undo_point(script_name)
    return sel,act
end

if haveDepCtrl then depRec:registerMacro(masquerade) else aegisub.register_macro(script_name,script_description,masquerade) end