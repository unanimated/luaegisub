-- Disclaimer: RTFM! - http://unanimated.xtreemhost.com/ts/scripts-manuals.htm#cleanup
-- If you get unexpected results because you didn't read what the script does, it's your fault.

script_name="Script Cleanup"
script_description="Removes selected stuff from script"
script_author="unanimated"
script_version="3.4"
script_namespace="ua.ScriptCleanup"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="3.4.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

dont_delete_empty_tags=false	-- option to not delete {}

function cleanlines(subs,sel)
    if res.all then
	for k,v in ipairs(GUI) do
	  if v.x==0 then res[v.name]=true end
	end
    end
    for z,i in ipairs(sel) do
	progress("Processing line: "..z.."/"..#sel)
	prog=math.floor(z/#sel*100)
 	aegisub.progress.set(prog)
	line=subs[i]
	text=line.text
	stl=line.style
	
	if res.nots and not res.nocom then text=text:gsub("{TS[^}]*} *","") end
	
	if res.nocom then
	    text=text:gsub("{[^\\}]-}","")
	    :gsub("{[^\\}]-\\N[^\\}]-}","")
	    :gsub("^({[^}]-}) *","%1")
	    :gsub(" *$","")
	end
	
	if res.clear_a then line.actor="" end
	if res.clear_e then line.effect="" end
	
	if res.layers and line.layer<5 then
	    if stl:match("Defa") or stl:match("Alt") or stl:match("Main") then line.layer=line.layer+5 end
	end
	
	if res.cleantag and text:match("{%*?\\") then
	    txt2=text
	    text=text:gsub("{\\\\k0}","") :gsub("{(\\[^}]-)} *\\N *{(\\[^}]-)}","\\N{%1%2}")
	    repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
	    text=text:gsub("({\\[^}]-){(\\[^}]-})","%1%2") :gsub("{.-\\r","{\\r") :gsub("^{\\r([\\}])","{%1")
	    text=text:gsub("\\fad%(0,0%)","") :gsub(ATAG.."$","")
	     for tgs in text:gmatch(ATAG) do
  	      tgs2=tgs
	      :gsub("\\([\\}])","%1")
	      :gsub("(\\%a+)([%d%-]+%.%d+)",function(a,b) if not a:match("\\fn") then b=rnd2dec(b) end return a..b end)
	      :gsub("(\\%a+)%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c) b=rnd2dec(b) c=rnd2dec(c) return a.."("..b..","..c..")" end)
	      :gsub("(\\%a+)%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d,e) 
		b=rnd2dec(b) c=rnd2dec(c) d=rnd2dec(d) e=rnd2dec(e) return a.."("..b..","..c..","..d..","..e end)
	      tgs2=duplikill(tgs2)
	      tgs2=extrakill(tgs2)
	      text=text:gsub(esc(tgs),tgs2)
	      :gsub("^({\\[^}]-)\\frx0\\fry0","%1")
	     end
	    if txt2~=text then kleen=kleen+1 end
	end
	
	if res.overlap then
	    if line.comment==false and stl:match("Defa") then
	    	start=line.start_time
		endt=line.end_time
		if i<#subs then nextline=subs[i+1] nextart=nextline.start_time end
		prevline=subs[i-1]
		prevstart=prevline.start_time
		prevend=prevline.end_time
		dur=line.end_time-line.start_time
		ms2fr=aegisub.frame_from_ms
		fr2ms=aegisub.ms_from_frame
		keyframes=aegisub.keyframes()
		startf=ms2fr(start)
		endf=ms2fr(endt)
		prevendf=ms2fr(prevend)
		nextartf=ms2fr(nextart)
		
		-- start gaps/overlaps
		if prevline.class=="dialogue" and prevline.style:match("Defa") and dur>50 then
		    	-- get keyframes
		    	kfst=0  kfprev=0
		    	for k,kf in ipairs(keyframes) do
		    	if kf==startf then kfst=1 end
		    	if kf==prevendf then kfprev=1 end
		    	end
		    	-- start overlap
		    	if start<prevend and prevend-start<=50 then
		    	if kfst==0 or kfprev==1 then nstart=prevend end
		    	end
		    	-- start gap
		    	if start>prevend and start-prevend<=50 then
		    	if kfst==0 and kfprev==1 then nstart=prevend end
		    	end
		end
		-- end gaps/overlaps
		if i<#subs and nextline.style:match("Defa") and dur>50 then
		    	--get keyframes
		    	kfend=0 kfnext=0
		    	for k,kf in ipairs(keyframes) do
		    	if kf==endf then kfend=1 end
		    	if kf==nextartf then kfnext=1 end
		    	end
		    	-- end overlap
		    	if endt>nextart and endt-nextart<=50 then
		    	if kfnext==1 and kfend==0 then nendt=nextart end
		    	end
		    	-- end gap
		    	if endt<nextart and nextart-endt<=50 then
		    	if kfend==0 or kfnext==1 then nendt=nextart end
		    	end
		end
	    end
	    if nstart then line.start_time=nstart end
	    if nendt then line.end_time=nendt end
	    nstart=nil nendt=nil
	end
	
	if res.spaces then text=text:gsub("%s%s+"," ") :gsub(" *$","") :gsub("^({\\[^}]-}) *","%1") end
	
	if res.nobreak then
		text=text
		:gsub(" *{\\i0}\\N{\\i1} *"," ")
		:gsub("%*","_ast_")
		:gsub("\\[Nn]","*")
		:gsub(" *%*+ *"," ")
		:gsub("_ast_","*")
	end
	
	if res.nobreak2 then text=text:gsub("\\[Nn]","") end
	if res.hspace then text=text:gsub("\\h","") end
	if res.notag then text=text:gsub(ATAG,"") end
	if res.allcol then text=text:gsub("\\[1234]?c[^\\}%)]*","") end
	if res.allphas then text=text:gsub("\\[1234]a[^\\}%)]*","") :gsub("\\alpha[^\\}%)]*","") end
	if res.allrot then text=text:gsub("\\fr[^\\}%)]*","") end
	if res.allpers then text=text:gsub("\\f[ar][xyz][^\\}%)]*","") :gsub("\\org%b()","") end
	if res.allsize then text=text:gsub("\\fs[%d%.]+","") :gsub("\\fs([\\}%)])","%1") :gsub("\\fsc[xy][^\\}%)]*","") end
	if res.ctrans then text=text:gsub(ATAG,function(tg) return cleantr(tg) end) end
	if res.inline then text=text:gsub("(.)"..ATAG,"%1") end
	if res.inline2 then repeat text,r=text:gsub("(.)"..ATAG.."(.-{%*?\\)","%1%2") until r==0 end
	
	if res.alphacol then
		text=text
		:gsub("alpha&(%x%x)&","alpha&H%1&")
		:gsub("alpha&?H?(%x%x)&?([\\}])","alpha&H%1&%2")
		:gsub("alpha&H0&","alpha&H00&")
		:gsub("alpha&H(%x%x)%x*&","alpha&H%1&")
		:gsub("(\\[1234]a)&(%x%x)&","%1&H%2&")
		:gsub("(\\[1234]a)(%x%x)([\\}])","%1&H%2&%3")
		:gsub("(\\[1234]?c&)(%x%x%x%x%x%x)&","%1H%2&")
		:gsub("(\\i?clip%([^%)]-) ?([\\}])","%1)%2")
		:gsub("(\\t%([^%)]-\\i?clip%([^%)]-%))([\\}])","%1)%2")
		:gsub("(fad%([%d,]+)([\\}])","%1)%2")
		:gsub("([1234]?[ac])H&(%x+)","%1&H%2")
		:gsub("([1234]?c&H)00(%x%x%x%x%x%x)","%1%2")
	end
	
	text=text:gsub("^ *","") :gsub("\\t%([^\\%)]-%)","") :gsub("{%*}","")
	if not dont_delete_empty_tags then text=text:gsub("{}","") end
	if line.text~=text then chng=chng+1 end
	line.text=text
	subs[i]=line
    end
    if res.info then
	infotxt="Lines with modified Text field: "..chng
	if res.cleantag then infotxt=infotxt.."\nChanges from Clean Tags: "..kleen end
	P,rez=ADD({{class="label",label=infotxt}},{"OK"},{close='OK'})
    end
    aegisub.set_undo_point(script_name)
    return sel
end

function rnd2dec(num)
num=math.floor((num*100)+0.5)/100
return num
end

-- delete commented lines from selected lines
function nocom_line(subs,sel)
	progress("Deleting commented lines")
	ncl_sel={}
	for s=#sel,1,-1 do
	    line=subs[sel[s]]
	    if line.comment then
		for z,i in ipairs(ncl_sel) do ncl_sel[z]=i-1 end
		subs.delete(sel[s])
	    else
		table.insert(ncl_sel,sel[s])
	    end
	end
	return ncl_sel
end

-- delete empty lines
function noempty(subs,sel)
	progress("Deleting empty lines")
	noe_sel={}
	for s=#sel,1,-1 do
	    line=subs[sel[s]]
	    if line.text=="" then
		for z,i in ipairs(noe_sel) do noe_sel[z]=i-1 end
		subs.delete(sel[s])
	    else
		table.insert(noe_sel,sel[s])
	    end
	end
	return noe_sel
end

-- delete commented or empty lines
function noemptycom(subs,sel)
	progress("Deleting commented/empty lines")
	noecom_sel={}
	for s=#sel,1,-1 do
	    line=subs[sel[s]]
	    if line.comment or line.text=="" then
		for z,i in ipairs(noecom_sel) do noecom_sel[z]=i-1 end
		subs.delete(sel[s])
	    else
		table.insert(noecom_sel,sel[s])
	    end
	end
	return noecom_sel
end

-- delete unused styles
function nostyle(subs,sel)
	stylist=",,"
	for i=#subs,1,-1 do
	    if subs[i].class=="dialogue" then
		line=subs[i]
		st=line.style
		if not stylist:match(","..esc(st)..",") then stylist=stylist..st..",," end
	    end
	    if subs[i].class=="style" then
		style=subs[i]
		if res.nostyle2 and style.name:match("Defa") or res.nostyle2 and style.name:match("Alt") then nodel=1 else nodel=0 end
		if not stylist:match(","..esc(style.name)..",") and nodel==0 then
		    subs.delete(i)
		    logg("\n Deleted style: "..style.name)
		    for s=1,#sel do sel[s]=sel[s]-1 end
		end
	    end
	end
	return sel
end

-- switch true/false
function ft(x) if x then return false else return true end end

-- kill everything
function killemall(subs,sel)
    if res.inverse then
	for k,v in ipairs(GUI) do
	  if v.x>3 and v.y>0 and v.name~="onlyt" then res[v.name]=ft(res[v.name]) end
	end
    end
    for z,i in ipairs(sel) do
      progress("Processing line: "..z.."/"..#sel)
      line=subs[i]
      text=line.text
      if res.onlyt then res.trans=false
	text=text:gsub(ATAG,function(t) return t:gsub("\\","|") end)
	:gsub("|t(%b())",function(t) return "\\t"..t:gsub("|","\\") end)
      end
      tags=text:match(STAG) or ""
      inline=text:gsub(STAG,"")
      if res.skill and res.ikill then trgt=text tg=3
      elseif res.ikill then trgt=inline tg=2
      else trgt=tags tg=1 end
	if res.border then trgt=killtag("[xy]?bord",trgt) end
	if res.shadow then trgt=killtag("[xy]?shad",trgt) end
	if res.blur then trgt=killtag("blur",trgt) end
	if res.bee then trgt=killtag("be",trgt) end
	if res.fsize then trgt=killtag("fs",trgt) end
	if res.fspace then trgt=killtag("fsp",trgt) end
	if res.scalex then trgt=killtag("fscx",trgt) end
	if res.scaley then trgt=killtag("fscy",trgt) end
	if res.fade then trgt=trgt:gsub("\\fade?%b()","") end
	if res.posi then trgt=trgt:gsub("\\pos%b()","") end
	if res.move then trgt=trgt:gsub("\\move%b()","") end
	if res.org then trgt=trgt:gsub("\\org%b()","") end
	if res.color1 then trgt=killctag("1?c",trgt) end
	if res.color2 then trgt=killctag("2c",trgt) end
	if res.color3 then trgt=killctag("3c",trgt) end
	if res.color4 then trgt=killctag("4c",trgt) end
	if res.alfa1 then trgt=killctag("1a",trgt) end
	if res.alfa2 then trgt=killctag("2a",trgt) end
	if res.alfa3 then trgt=killctag("3a",trgt) end
	if res.alfa4 then trgt=killctag("4a",trgt) end
	if res.alpha then trgt=killctag("alpha",trgt) end
	if res.clip then trgt=trgt:gsub("\\i?clip%b()","") end
	if res.fname then trgt=trgt:gsub("\\fn[^\\}]+","") end
	if res.frz then trgt=killtag("frz",trgt) end
	if res.frx then trgt=killtag("frx",trgt) end
	if res.fry then trgt=killtag("fry",trgt) end
	if res.fax then trgt=killtag("fax",trgt) end
	if res.fay then trgt=killtag("fay",trgt) end
	if res.anna then trgt=killtag("an",trgt) end
	if res.align then trgt=killtag("a",trgt) end
	if res.wrap then trgt=killtag("q",trgt) end
	if res["return"] then trgt=trgt:gsub("\\r.+([\\}])","%1") end
	if res.kara then trgt=trgt:gsub("\\[Kk][fo]?[%d%.]+([\\}])","%1") end
	if res.ital then repeat trgt,r=trgt:gsub("\\i[01]?([\\}])","%1") until r==0 end
	if res.bold then repeat trgt,r=trgt:gsub("\\b[01]?([\\}])","%1") until r==0 end
	if res.under then repeat trgt,r=trgt:gsub("\\u[01]?([\\}])","%1") until r==0 end
	if res.stri then repeat trgt,r=trgt:gsub("\\s[01]?([\\}])","%1") until r==0 end
	if res.trans then trgt=trgt:gsub("\\t%b()","") end
      trgt=trgt:gsub("\\t%([%d%.,]*%)","") :gsub("{%**}","")
      if tg==1 then tags=trgt elseif tg==2 then inline=trgt elseif tg==3 then text=trgt end
      if trgt~=text then text=tags..inline end
      if res.onlyt then text=text:gsub("{%*?|[^}]-}",function(t) return t:gsub("|","\\") end) end
      line.text=text
      subs[i]=line
    end
end

function killtag(tag,t) t=t:gsub("\\"..tag.."[%d%.%-]*","") return t end
function killctag(tag,t) t=t:gsub("\\"..tag.."&H%x+&","") repeat t,r=t:gsub("\\"..tag.."([\\}])","%1") until r==0 return t end

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

function cleantr(tags)
	trnsfrm=""
	for t in tags:gmatch("\\t%b()") do trnsfrm=trnsfrm..t end
	tags=tags:gsub("\\t%b()","")
	:gsub("^({[^}]*)}","%1"..trnsfrm.."}")
	return tags
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function logg(m) m=m or "nil" aegisub.log("\n "..m) end

function cleanup(subs,sel,act)
ADD=aegisub.dialog.display
ak=aegisub.cancel
if #sel==0 then t_error("No selection",1) end
ATAG="{%*?\\[^}]-}"
STAG="^{\\[^}]-}"
if act==0 then act=sel[1] end
chng=0 kleen=0
GUI={
{x=0,y=0,class="checkbox",name="nots",label="Remove TS timecodes",hint="Removes timecodes like {TS 12:36}"},
{x=0,y=1,class="checkbox",name="nocom",label="Remove comments from lines",hint="Removes {comments} (not tags)"},
{x=0,y=2,class="checkbox",name="clear_a",label="Clear Actor field"},
{x=0,y=3,class="checkbox",name="clear_e",label="Clear Effect field"},
{x=0,y=4,class="checkbox",name="layers",label="Raise dialogue layer by 5"},
{x=0,y=5,class="checkbox",name="cleantag",label="Clean up tags",hint="Fixes duplicates, \\\\, \\}, }{, and other garbage"},
{x=0,y=6,class="checkbox",name="overlap",label="Fix 1-frame gaps/overlaps"},
{x=0,y=7,class="checkbox",name="nocomline",label="Delete commented lines"},
{x=0,y=8,class="checkbox",name="noempty",label="Delete empty lines"},
{x=0,y=9,class="checkbox",name="alphacol",label="Try to fix alpha / colour tags"},
{x=0,y=10,class="checkbox",name="spaces",label="Fix start/end/double spaces"},
{x=0,y=12,class="checkbox",name="info",label="Print info"},
{x=0,y=13,class="checkbox",name="all",label="ALL OF THE ABOVE"},

{x=2,y=0,class="checkbox",name="allcol",label="Remove all colour tags"},
{x=2,y=1,class="checkbox",name="allphas",label="Remove all alpha tags"},
{x=2,y=2,class="checkbox",name="allrot",label="Remove all rotations"},
{x=2,y=3,class="checkbox",name="allpers",label="Remove all perspective"},
{x=2,y=4,class="checkbox",name="allsize",label="Remove size/scaling"},
{x=2,y=5,class="checkbox",name="nobreak",label="Remove linebreaks - \\N"},
{x=2,y=6,class="checkbox",name="nobreak2",label="Remove linebreaks - \\N (nospace)"},
{x=2,y=7,class="checkbox",name="hspace",label="Remove hard spaces - \\h"},
{x=2,y=8,class="checkbox",name="nostyle",label="Delete unused styles"},
{x=2,y=9,class="checkbox",name="nostyle2",label="Delete unused styles (leave Default)"},
{x=2,y=10,class="checkbox",name="ctrans",label="Move transforms to end of tag block"},
{x=2,y=11,class="checkbox",name="inline",label="Remove inline tags"},
{x=2,y=12,class="checkbox",name="inline2",label="Remove inline tags except the last"},
{x=2,y=13,class="checkbox",name="notag",label="Remove all {\\tags} from selected lines "},

{x=3,y=0,height=14,class="label",label="| \n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|"},

{x=4,y=0,class="checkbox",name="skill",label="[start]",value=true},
{x=5,y=0,class="checkbox",name="ikill",label="[inline]",value=true},
{x=6,y=0,class="checkbox",name="inverse",label="[inverse]",hint="kill all except checked ones"},
{x=6,y=1,class="checkbox",name="onlyt",label="[from \\t]",hint="remove only from transforms"},

{x=4,y=1,class="checkbox",name="blur",label="blur"},
{x=4,y=2,class="checkbox",name="border",label="bord",hint="includes xbord and ybord"},
{x=4,y=3,class="checkbox",name="shadow",label="shad",hint="includes xshad and yshad"},
{x=4,y=4,class="checkbox",name="fsize",label="fs"},
{x=4,y=5,class="checkbox",name="fspace",label="fsp"},
{x=4,y=6,class="checkbox",name="scalex",label="fscx"},
{x=4,y=7,class="checkbox",name="scaley",label="fscy"},
{x=4,y=8,class="checkbox",name="fname",label="fn"},
{x=4,y=9,class="checkbox",name="ital",label="i"},
{x=4,y=10,class="checkbox",name="bold",label="b"},
{x=4,y=11,class="checkbox",name="under",label="u"},
{x=4,y=12,class="checkbox",name="stri",label="s"},
{x=4,y=13,class="checkbox",name="wrap",label="q"},

{x=5,y=1,class="checkbox",name="bee",label="be"},
{x=5,y=2,class="checkbox",name="color1",label="c, 1c"},
{x=5,y=3,class="checkbox",name="color2",label="2c"},
{x=5,y=4,class="checkbox",name="color3",label="3c"},
{x=5,y=5,class="checkbox",name="color4",label="4c"},
{x=5,y=6,class="checkbox",name="alpha",label="alpha"},
{x=5,y=7,class="checkbox",name="alfa1",label="1a"},
{x=5,y=8,class="checkbox",name="alfa2",label="2a"},
{x=5,y=9,class="checkbox",name="alfa3",label="3a"},
{x=5,y=10,class="checkbox",name="alfa4",label="4a"},
{x=5,y=11,class="checkbox",name="align",label="a"},
{x=5,y=12,class="checkbox",name="anna",label="an"},
{x=5,y=13,class="checkbox",name="clip",label="(i)clip  "},

{x=6,y=2,class="checkbox",name="fade",label="fad"},
{x=6,y=3,class="checkbox",name="posi",label="pos"},
{x=6,y=4,class="checkbox",name="move",label="move"},
{x=6,y=5,class="checkbox",name="org",label="org"},
{x=6,y=6,class="checkbox",name="frz",label="frz"},
{x=6,y=7,class="checkbox",name="frx",label="frx"},
{x=6,y=8,class="checkbox",name="fry",label="fry"},
{x=6,y=9,class="checkbox",name="fax",label="fax"},
{x=6,y=10,class="checkbox",name="fay",label="fay"},
{x=6,y=11,class="checkbox",name="return",label="r"},
{x=6,y=12,class="checkbox",name="kara",label="k/kf/ko"},
{x=6,y=13,class="checkbox",name="trans",label="t"}
}
	P,res=ADD(GUI,
	{"Run selected","Comments","Tags","Dial 5","Clean Tags","^ Kill checked tags","Cancer"},{ok='Run selected',cancel='Cancer'})
	if P=="Cancer" then ak() end
	if P=="^ Kill checked tags" then killemall(subs,sel) end
	if P=="Comments" then res.nocom=true cleanlines(subs,sel) end
	if P=="Tags" then res.notag=true cleanlines(subs,sel) end
	if P=="Dial 5" then res.layers=true cleanlines(subs,sel) end
	if P=="Clean Tags" then res.cleantag=true cleanlines(subs,sel) end
	if P=="Run selected" then
	    C=0 for key,v in ipairs(GUI) do  if v.x==0 and res[v.name] or v.x==2 and res[v.name] then C=1 end  end
	    if C==0 then t_error("Run Selected: Error - nothing selected",1) end
	    if res.all then 
		for key,v in ipairs(GUI) do  if v.x==2 then res[v.name]=false end  end
		cleanlines(subs,sel)
		sel=noemptycom(subs,sel)
	    else cleanlines(subs,sel)
		if res.nocomline and res.noempty then sel=noemptycom(subs,sel)
		else
			if res.nocomline then sel=nocom_line(subs,sel) end
			if res.noempty then sel=noempty(subs,sel) end
		end
		table.sort(sel)
		if res.nostyle or res.nostyle2 then sel=nostyle(subs,sel) end
	    end
	end
	if act>#subs then act=#subs end
	aegisub.set_undo_point(script_name)
	return sel,act
end

if haveDepCtrl then depRec:registerMacro(cleanup) else aegisub.register_macro(script_name,script_description,cleanup) end