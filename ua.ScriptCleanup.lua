-- Disclaimer: RTFM! - http://unanimated.hostfree.pw/ts/scripts-manuals.htm#cleanup

script_name="Script Cleanup"
script_description="Garbage disposal and elimination of incriminating evidence"
script_author="unanimated"
script_version="5.0"
script_namespace="ua.ScriptCleanup"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
	script_version="5.0.0"
	depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

dont_delete_empty_tags=false	-- option to not delete {}

re=require'aegisub.re'

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
	
	if res.cleantag and text:match("{[*>]?\\") then
		txt2=text
		text=text:gsub("{\\\\k0}",""):gsub(">\\","\\"):gsub("{(\\[^}]-)} *\\N *{(\\[^}]-)}","\\N{%1%2}")
		repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
		text=text:gsub("({\\[^}]-){(\\[^}]-})","%1%2"):gsub("{.-\\r","{\\r"):gsub("^{\\r([\\}])","{%1")
		:gsub("\\fad%(0,0%)",""):gsub(ATAG.."$",""):gsub("^({\\[^}]-)\\frx0\\fry0","%1"):gsub("\\%a+%(%)","")
		text=text:gsub(ATAG,function(tgs)
			tgs2=tgs
			:gsub("\\+([\\}])","%1")
			:gsub("(\\[^\\})]+)",function(a) if not a:match'clip' and not a:match'\\fn' and not a:match'\\r' then a=a:gsub(' ','') end return a end)
			:gsub("(\\%a+)([%d%-]+%.%d+)",function(a,b) if not a:match("\\fn") then b=rnd2dec(b) end return a..b end)
			:gsub("(\\%a+)%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c) b=rnd2dec(b) c=rnd2dec(c) return a.."("..b..","..c..")" end)
			:gsub("(\\%a+)%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d,e) 
				return a.."("..rnd2dec(b)..","..rnd2dec(c)..","..rnd2dec(d)..","..rnd2dec(e) end)
			tgs2=duplikill(tgs2)
			tgs2=extrakill(tgs2)
			return tgs2
			end)
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
	
	if res.spaces then text=text:gsub("  +"," ") :gsub(" *$","") :gsub("^({\\[^}]-}) *","%1") end
	
	if res.nobreak2 then text=text:gsub("\\[Nn]","")
	elseif res.nobreak then
		text=text
		:gsub(" *{\\i0}\\N{\\i1} *"," ")
		:gsub("%*","_ast_")
		:gsub("\\[Nn]","*")
		:gsub(" *%*+ *"," ")
		:gsub("_ast_","*")
	end
	
	if res.hspace then text=text:gsub("\\h","") end
	if res.notag then text=text:gsub(ATAG,"") end
	if res.allcol then text=text:gsub("\\[1234]?c[^\\})]*","") end
	if res.alpha14 then text=text:gsub("\\[1234]a[^\\})]*","")
	elseif res.allphas then text=text:gsub("\\[1234]a[^\\})]*","") :gsub("\\alpha[^\\})]*","") end
	if res.xyshad then text=text:gsub("\\[xy]shad[^\\})]*","")
	elseif res.allshad then text=text:gsub("\\[xy]?shad[^\\})]*","") end
	if res.xyrot then text=text:gsub("\\fr[xy][^\\})]*","")
	elseif res.allrot then text=text:gsub("\\fr[^\\})]*","") end
	if res.allpers then text=text:gsub("\\f[ar][xyz][^\\})]*","") :gsub("\\org%b()","") end
	if res.scales then text=text:gsub("\\fsc[xy][^\\})]*","")
	elseif res.allsize then text=text:gsub("\\fs[%d.]+","") :gsub("\\fs([\\}%)])","%1") :gsub("\\fsc[xy][^\\})]*","") end
	if res.parent2 then text=text:gsub("(\\%a%a+)(%b())",function(a,b) if a=='\\pos' then return a..b else return "" end end) 
	elseif res.parent then text=text:gsub("\\%a%a+%b()","") end
	if res.ctrans then text=text:gsub(ATAG,function(tg) return cleantr(tg) end) end
	if res.inline2 then repeat text,r=text:gsub("(.)"..ATAG.."(.-{%*?\\)","%1%2") until r==0
	elseif res.inline then text=text:gsub("(.)"..ATAG,"%1") end
	
	if res.alphacol then
		text=text
		:gsub("alpha&(%x%x)&","alpha&H%1&")
		:gsub("alpha&?H?(%x%x)&?([\\}])","alpha&H%1&%2")
		:gsub("alpha&H0&","alpha&H00&")
		:gsub("alpha&H(%x%x)%x*&","alpha&H%1&")
		:gsub("(\\[1234]a)&(%x%x)&","%1&H%2&")
		:gsub("(\\[1234]a)(%x%x)([\\}])","%1&H%2&%3")
		:gsub("(\\[1234]?c&)(%x%x%x%x%x%x)&","%1H%2&")
		:gsub("(\\[1234]?c&H%x%x%x%x%x%x)([^&])","%1&%2")
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
    return sel
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
		text=line.text
		st2=text:match("\\r([^\\}]*)")
		st=line.style
		if not stylist:match(","..esc(st)..",") then stylist=stylist..st..",," end
		if st2 and st2~="" and not stylist:match(","..esc(st2)..",") then stylist=stylist..st2..",," end
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


-- kill everything
function killemall(subs,sel)
    if res.inverse then
	for k,v in ipairs(GUI) do
	  if v.x>4 and v.y>0 and v.name~="onlyt" then res[v.name]=not res[v.name] end
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
	if res.shadow then trgt=killtag("shad",trgt) end
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

function killtag(tag,t) repeat t,r=t:gsub("\\"..tag.."[%d%.%-]-([\\}])","%1") until r==0 return t end
function killctag(tag,t) t=t:gsub("\\"..tag.."&H%x+&","") repeat t,r=t:gsub("\\"..tag.."([\\}])","%1") until r==0 return t end


-- hide tags
function hide_tags(subs,sel)
	hide=true
	if res.inverse then hide=nil end
	local numbers="\\i\\b\\u\\s\\q\\a\\be\\blur\\bord\\fs\\fscx\\fscy\\shad\\an\\frz\\fry\\frx\\fsp\\fax\\fay\\"
	local alphacol="\\1a\\2a\\3a\\4a\\1c\\2c\\3c\\4c\\alpha\\"
	local parent="\\fad\\pos\\move\\org\\clip\\"
	local fontret="\\r\\fn\\"
	if hide then
		hidem={}
		for k,v in ipairs(GUI) do
			if v.x>4 and v.y>0 and v.name~='onlyt' and v.name~='kara' then
				nom=v.label:gsub("c, 1c","1c"):gsub("%(i%)","")
				if res[v.name] then table.insert(hidem,nom) end
			end
		end
	end
	
    for x,i in ipairs(sel) do
        line=subs[i]
	text=line.text:gsub("\\c&","\\1c&")
	startg=text:match("^{\\[^}]-}") or ""
	startg=trem(startg)
	t2=text:gsub("^{\\[^}]-}","")
	
	if hide then
	    for t=1,#hidem do
		local tag='\\'..hidem[t]
		local htag='//'..hidem[t]
		local chk=tag..'\\'
		tg=nil
		if numbers:match(chk) then
			tg=startg:match(tag.."([%d.-]+)")
			if tg then t2=t2.."{"..htag..tg.."}" end
			startg=startg:gsub(tag.."[%d.-]+","")
			if not tg and tag=="\\shad" then
				tg1=startg:match("\\xshad([%d.-]+)")
				tg2=startg:match("\\yshad([%d.-]+)")
				if tg1 then t2=t2.."{//xshad"..tg1.."}" end
				if tg2 then t2=t2.."{//yshad"..tg2.."}" end
				startg=startg:gsub("\\[xy]shad[%d.-]+","")
			end
		elseif alphacol:match(chk) then
			tg=startg:match(tag.."(&H%x+&)")
			if tg then t2=t2.."{"..htag..tg.."}" end
			startg=startg:gsub(tag.."&H%x+&","")
		elseif parent:match(chk) then
			tg=startg:match(tag.."(%b())")
			if not tg and tag=="\\clip" then tg=startg:match("\\iclip(%b())") tag='\\iclip' htag='//iclip' end
			if not tg and tag=="\\fad" then tg=startg:match("\\fade(%b())") tag='\\fade' htag='//fade' end
			if tg then t2=t2.."{"..htag..tg.."}" end
			startg=startg:gsub(tag.."%b()","")
		elseif fontret:match(chk) then
			tg=startg:match(tag.."([^\\}]*)")
			if tg then t2=t2.."{"..htag..tg.."}" end
			startg=startg:gsub(tag.."[^\\}]*","")
		elseif tag=='\\t' then
			t2=t2.."{"..trnsfrm:gsub("\\t","//t").."}"
		end
	    end
	    if res.hidline then
		-- hide inline
		inT=inline_pos(t2)
		t2=t2:gsub(ATAG,"")
		for k,v in ipairs(inT) do
			t2=t2..v.t:gsub("{%*?\\","{"..v.n.."//")
		end
	    end
	else
		local vis1,vis2=t2:gsub("%b{}","")
		local c=0
		repeat
			-- Unhide regular
			if res.skill then
				for hidden in t2:gmatch("{(//.-)}") do
					t2=t2:gsub("{"..esc(hidden).."}","")
					hidden=hidden:gsub("//","\\")
					startg=startg.."{"..hidden.."}"
				end
			end
			-- unhide inline
			if t2:match("{%d+//[^}]+}") and res.ikill then
				inT={}
				stT=''
				for num,tag in t2:gmatch("{(%d+)//([^}]+)}") do
					table.insert(inT,{n=num,t=tag})
				end
				for tag in t2:gmatch("{//[^}]+}") do stT=stT..tag end
				table.sort(inT,function(a,b) return tonumber(a.n)<tonumber(b.n) end)
				t2=t2:gsub("{%d+//[^}]+}","")
				if t2:match"{" then orig=t2 t2=t2:gsub("%b{}","") end
				t2=inline_ret2(t2,inT)
				if orig then t2=textmod(orig,t2) orig=nil end
				t2=t2..stT
			end
			vis2=t2:gsub("%b{}","")
			c=c+1
		until vis1==vis2 or c==666
		if vis1~=vis2 then logg('Error:\n  '..vis1..'\n> '..vis2) end
	end
	
	if not hide or hide and not res.trans then startg=startg.."{"..trnsfrm.."}" end
	text=duplikill(startg:gsub("}{",""):gsub("\\1c","\\c"))..t2
	text=text:gsub("{}",""):gsub("\\1c","\\c")
	if line.text~=text then line.text=text subs[i]=line end
    end
    return sel
end

-- save inline tags
function inline_pos(t)
	inTags={}
	tl=t:len()
	if tl==0 then return {} end
	p=0
	t1=''
	repeat
		seg=t:match("^(%b{})") -- try to match tags/comments
		if seg then
			if seg:match("{%*?\\") then table.insert(inTags,{n=p,t=seg}) end
		else
			seg=t:match("^([^{]+)") -- or match text
			if not seg then t_error("Error: There appears to be a problem with the brackets here...\n"..t1..t,1) end
			SL=re.find(seg,".")
			p=p+#SL -- position of next '{' [or end]
		end
		t1=t1..seg
		t=t:gsub("^"..esc(seg),"")
		tl=t:len()
	until tl==0
	return inTags
end

-- rebuild inline tags
function inline_ret2(t,tab)
	tl=t:len()
	nt=''
	kill='_Z#W_' -- this is supposed to never match
	for k,v in ipairs(tab) do
		N=tonumber(v.n)
		if N==0 then nt=nt..v.t
		else
			m='.'
			-- match how many chars at the start
			m=m:rep(N)
			RS=re.find(t,m)
			seg=RS[1].str
			seg=re.sub(seg,'^'..kill,'')
			nt=nt..seg..'{\\'..v.t..'}'
			kill=m -- how many matched in the last round
		end
	end
	-- the rest
	seg=re.sub(t,'^'..kill,'')
	nt=nt..seg
	return nt
end

--	reanimatools	-------
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function rnd2dec(num) num=math.floor((num*100)+0.5)/100 return num end
function logg(m) m=m or "nil" aegisub.log("\n "..m) end
function wrap(str) return "{"..str.."}" end
function nobra(t) return t:gsub("%b{}","") end
function nobrea(t) return t:gsub("%b{}",""):gsub("\\[Nh]","") end
function nobrea1(t) return t:gsub("%b{}",""):gsub(" *\\[Nh] *"," ") end
function tagmerge(t) repeat t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return t end
function progress(msg) if aegisub.progress.is_cancelled() then ak() end aegisub.progress.title(msg) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

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


function cleanup(subs,sel,act)
ADD=aegisub.dialog.display
ak=aegisub.cancel
if #sel==0 then t_error("No selection",1) end
ATAG="{[*>]?\\[^}]-}"
STAG="^{>?\\[^}]-}"
if act==0 then act=sel[1] end
chng=0 kleen=0
GUI={
{x=0,y=0,class="checkbox",name="nots",label="Remove TS timecodes",hint="Removes timecodes like {TS 12:36}"},
{x=0,y=1,class="checkbox",name="clear_a",label="Clear Actor field"},
{x=0,y=2,class="checkbox",name="clear_e",label="Clear Effect field"},
{x=0,y=3,class="checkbox",name="layers",label="Raise dialogue layer by 5"},
{x=0,y=4,class="checkbox",name="cleantag",label="Clean up tags",hint="Fixes duplicates, \\\\, \\}, }{, and other garbage"},
{x=0,y=5,class="checkbox",name="ctrans",label="Clean up transforms"},
{x=0,y=6,class="checkbox",name="overlap",label="Fix 1-frame gaps/overlaps"},
{x=0,y=7,class="checkbox",name="nocomline",label="Delete commented lines"},
{x=0,y=8,class="checkbox",name="noempty",label="Delete empty lines"},
{x=0,y=9,class="checkbox",name="alphacol",label="Try to fix alpha / colour tags"},
{x=0,y=10,class="checkbox",name="spaces",label="Fix start/end/double spaces"},
{x=0,y=12,class="checkbox",name="info",label="Print info"},
{x=0,y=13,class="checkbox",name="all",label="ALL OF THE ABOVE"},

{x=1,y=0,class="label",label="  "},

{x=2,y=0,width=2,class="checkbox",name="allcol",label="Remove all colour tags"},
{x=2,y=1,class="checkbox",name="allphas",label="Remove all alphas"},
{x=3,y=1,class="checkbox",name="alpha14",label="Only 1a-4a"},
{x=2,y=2,class="checkbox",name="allrot",label="Remove all rotations",hint="frx, fry, frz"},
{x=3,y=2,class="checkbox",name="xyrot",label="Only x, y",hint="remove frx, fry"},
{x=2,y=3,class="checkbox",name="allsize",label="Remove size/scaling",hint="fs, fscx, fscy"},
{x=3,y=3,class="checkbox",name="scales",label="Only scaling",hint="remove fscx, fscy"},
{x=2,y=4,class="checkbox",name="allshad",label="Remove all shadows",hint="shad, xshad, yshad"},
{x=3,y=4,class="checkbox",name="xyshad",label="Only x, y",hint="remove xshad, yshad"},
{x=2,y=5,class="checkbox",name="parent",label="Remove parentheses",hint="fad(e), (i)clip, pos, move, org\n(but not t)"},
{x=3,y=5,class="checkbox",name="parent2",label="Except \\pos",hint="fad(e), (i)clip, move, org\n(but not t or pos)"},
{x=2,y=6,width=2,class="checkbox",name="allpers",label="Remove all perspective",hint="frx, fry, frz, fax, fay, org"},

{x=2,y=7,width=2,class="label",label="      ~  Script Cleanup v"..script_version.."  ~"},

{x=2,y=8,width=2,class="checkbox",name="hspace",label="Remove hard spaces - \\h"},
{x=2,y=9,class="checkbox",name="nobreak",label="Remove line breaks"},
{x=3,y=9,class="checkbox",name="nobreak2",label="...no space",hint="Remove line breaks, leave no spaces"},
{x=2,y=10,class="checkbox",name="nostyle",label="Delete unused styles"},
{x=3,y=10,class="checkbox",name="nostyle2",label="Except Def.",hint="Delete unused styles except Default"},
{x=2,y=11,class="checkbox",name="inline",label="Remove inline tags"},
{x=3,y=11,class="checkbox",name="inline2",label="Except last",hint="Remove inline tags except the last one"},
{x=2,y=12,width=2,class="checkbox",name="nocom",label="Remove comments from lines",hint="Removes {comments} (not tags)"},
{x=2,y=13,width=2,class="checkbox",name="notag",label="Remove all {\\tags} from selected lines"},

{x=4,y=0,height=14,class="label",label="| \n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|"},

{x=5,y=0,class="checkbox",name="skill",label="[start]",value=true},
{x=6,y=0,class="checkbox",name="ikill",label="[inline]",value=true,hint="only kill, not hide"},
{x=7,y=0,width=2,class="checkbox",name="inverse",label="[inverse/unhide]",hint="kill all except checked ones\n\n'Unhide' for 'Hide Tags'"},
{x=7,y=1,width=2,class="checkbox",name="onlyt",label="[from \\t]",hint="remove only from transforms\n\n n/a for 'Hide Tags'"},

{x=5,y=1,class="checkbox",name="blur",label="blur"},
{x=5,y=2,class="checkbox",name="border",label="bord",hint="includes xbord and ybord [not for Hide]"},
{x=5,y=3,class="checkbox",name="shadow",label="shad",hint="includes xshad and yshad for Hide"},
{x=5,y=4,class="checkbox",name="fsize",label="fs"},
{x=5,y=5,class="checkbox",name="fspace",label="fsp"},
{x=5,y=6,class="checkbox",name="scalex",label="fscx"},
{x=5,y=7,class="checkbox",name="scaley",label="fscy"},
{x=5,y=8,class="checkbox",name="fname",label="fn"},
{x=5,y=9,class="checkbox",name="ital",label="i"},
{x=5,y=10,class="checkbox",name="bold",label="b"},
{x=5,y=11,class="checkbox",name="under",label="u"},
{x=5,y=12,class="checkbox",name="stri",label="s"},
{x=5,y=13,class="checkbox",name="wrap",label="q"},

{x=6,y=1,class="checkbox",name="bee",label="be"},
{x=6,y=2,class="checkbox",name="color1",label="c, 1c"},
{x=6,y=3,class="checkbox",name="color2",label="2c"},
{x=6,y=4,class="checkbox",name="color3",label="3c"},
{x=6,y=5,class="checkbox",name="color4",label="4c"},
{x=6,y=6,class="checkbox",name="alpha",label="alpha"},
{x=6,y=7,class="checkbox",name="alfa1",label="1a"},
{x=6,y=8,class="checkbox",name="alfa2",label="2a"},
{x=6,y=9,class="checkbox",name="alfa3",label="3a"},
{x=6,y=10,class="checkbox",name="alfa4",label="4a"},
{x=6,y=11,class="checkbox",name="align",label="a"},
{x=6,y=12,class="checkbox",name="anna",label="an"},
{x=6,y=13,class="checkbox",name="clip",label="(i)clip"},

{x=7,y=2,class="checkbox",name="fade",label="fad"},
{x=7,y=3,class="checkbox",name="posi",label="pos"},
{x=7,y=4,class="checkbox",name="move",label="move"},
{x=7,y=5,class="checkbox",name="org",label="org"},
{x=7,y=6,class="checkbox",name="frz",label="frz"},
{x=7,y=7,class="checkbox",name="frx",label="frx"},
{x=7,y=8,class="checkbox",name="fry",label="fry"},
{x=7,y=9,class="checkbox",name="fax",label="fax"},
{x=7,y=10,class="checkbox",name="fay",label="fay"},
{x=7,y=11,width=2,class="checkbox",name="kara",label="k/kf/ko"},
{x=7,y=12,class="checkbox",name="return",label="r"},
{x=7,y=13,class="checkbox",name="trans",label="t"},

{x=8,y=12,height=2,class="checkbox",name="hidline",label="hide\ninline",hint='Hide ALL inline tags'},
}
	P,res=ADD(GUI,
	{"Run selected","Comments","Tags","Dial 5","Clean Tags","^ Kill Tags","Hide Tags","Cancer"},{ok='Run selected',cancel='Cancer'})
	if P=="Cancer" then ak() end
	if P=="^ Kill Tags" then killemall(subs,sel) end
	if P=="Hide Tags" then hide_tags(subs,sel) end
	if P=="Comments" then res.nocom=true cleanlines(subs,sel) end
	if P=="Tags" then res.notag=true cleanlines(subs,sel) end
	if P=="Dial 5" then res.layers=true cleanlines(subs,sel) end
	if P=="Clean Tags" then res.cleantag=true cleanlines(subs,sel) end
	if P=="Run selected" then
	    C=0 for key,v in ipairs(GUI) do  if v.x<=3 and res[v.name] then C=1 end  end
	    if C==0 then t_error("Run Selected: Error - nothing selected",1) end
	    if res.all then 
		for key,v in ipairs(GUI) do  if v.x>0 and v.name then res[v.name]=false end  end
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
	return sel,act
end

if haveDepCtrl then depRec:registerMacro(cleanup) else aegisub.register_macro(script_name,script_description,cleanup) end