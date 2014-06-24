-- Know that feeling when you're editng and re-editing a line until you can't remember what the original was and you have to look it up?
-- If not, then go away. If you do, then here's a solution to let you easily see the original and edited line side by side.
-- The idea is that you save a backup, and then with a hotkey quickly bring up the saved lines for whatever you have selected.
-- "Save Backup" saves the current script to memory. (This gets erased if you reload automation scripts.)
-- "Save to File" saves it to a file with the name you see there, in the .ass script's folder. (You can make any number of those.)
-- "Load from File" loads lines from the file with the filename you see. (Type to change if you want from a different one.)
-- "Load from Memory" loads from memory, which is also what gets loaded by default (if you saved it before).
-- "Memory to File" saves the content of memory to a file.
-- "File to Memory" loads the content of a file to memory.
-- You can easily switch between different backups.
-- If you split/join lines, the backup will be off by those, but you can just select more lines to load the ones you need to see.

script_name="Backup Checker"
script_description="Backup Checker"
script_author="unanimated"
script_version="1.1"

function save(subs, sel)
    B={}
    for i=1, #subs do
 	if subs[i].class=="dialogue" then
        text=subs[i].text
	table.insert(B,text)
	end
    end
end

function savef(subs, sel)
    BF=""
    for i=1, #subs do
 	if subs[i].class=="dialogue" then
        text=subs[i].text
	BF=BF..text.."\n"
	end
    end
    BF=BF:gsub("\n$","")
    local file=io.open(scriptpath.."\\"..filename, "w")
    file:write(BF)
    file:close()
end

function back(subs,sel,act)
scriptpath=aegisub.decode_path("?script")
scriptname=aegisub.file_name()
savename=scriptname:gsub("%.ass","_backup.bak")
if #sel<=4 then boxheight=6 end
if #sel>=5 and #sel<9 then boxheight=8 end
if #sel>=9 and #sel<15 then boxheight=math.ceil(#sel*0.8) end
if #sel>=15 and #sel<18 then boxheight=12 end
if #sel>=18 then boxheight=15 end
c=0	
    for i=1, #subs do
	if subs[i].class=="dialogue" then break end
 	c=c+1
    end
    if B==nil then B={} end
    data=""
    for x, i in ipairs(sel) do
	if B[i-c]==nil then line="" else line=B[i-c] end
	data=data..line.."\n"
    end
    data=data:gsub("\n$","")
    if not data:match"%a" then data="--- Nothing saved yet. Click 'Save Backup' / 'Save to File' to back up the script now, or load backup from a file. ---" end
rine=act-c
gui={
    {x=0,y=0,width=33,height=1,class="label",name="top",label="Saved Text (Memory)"},
    {x=0,y=1,width=45,height=boxheight,class="textbox",name="dat",value=data},
    {x=33,y=0,width=5,height=1,class="label",label="Active Line: "..rine.."/"..#subs-c.."      " },
    {x=38,y=0,width=7,height=1,class="label",label="Backup Checker v"..script_version},
    
    {x=0,y=boxheight+1,width=1,height=1,class="label",label="Filename:"},
    {x=1,y=boxheight+1,width=15,height=1,class="edit",name="file",value=savename},
    {x=16,y=boxheight+1,width=17,height=1,class="edit",name="msg"},
    {x=33,y=boxheight+1,width=12,height=1,class="edit",name="idk"},
} 	
	but={"Load from Memory","Load from File","Save to Memory","Save to File","Memory to File","File to Memory","No Comments","OK"}
	repeat
	    if pressed=="Load from File" then FB={}
	      load=io.open(scriptpath.."\\"..filename)
	      if load~=nil then
		fileback=load:read("*all")
		io.close(load)
		fileback=fileback.."\n"
		ldata=""
		for l in fileback:gmatch("(.-)\n") do table.insert(FB,l) end
		for x, i in ipairs(sel) do
			if FB[i-c]==nil then FB[i-c]="" end
			ldata=ldata..FB[i-c].."\n"
		end
		for key,val in ipairs(gui) do
		    if val.name=="dat" then val.value=ldata
		    elseif val.name=="top" then val.label="Saved Text (File)"
		    elseif val.name=="msg" then val.value=""
		    else val.value=res[val.name] end
		end
	      else
		for key,val in ipairs(gui) do
		    if val.name=="msg" then val.value="» File \""..filename.."\" not found. «"
		    elseif val.name=="file" then val.value=savename
		    else val.value=res[val.name] end
		end
	      end
	    end	
	    if pressed=="Load from Memory" then
		for key,val in ipairs(gui) do
		    if val.name=="dat" then val.value=data
		    elseif val.name=="top" then val.label="Saved Text (Memory)"
		    elseif val.name=="msg" then val.value=""
		    else val.value=res[val.name] end
		end
	    end
	    if pressed=="Memory to File" then
		    if #B>0 then
			BF=""
			for i=1,#B do BF=BF..B[i].."\n" end
			BF=BF:gsub("\n$","")
			local file=io.open(scriptpath.."\\"..filename, "w")
			file:write(BF)
			file:close()
		    end
		for key,val in ipairs(gui) do
		    if val.name=="file" then val.value=savename
		    elseif val.name=="msg" then if #B==0 then val.value="Nothing in memory." else val.value="Backup saved to "..filename end
		    else val.value=res[val.name] end
		end
	    end
	    if pressed=="File to Memory" then
	      load=io.open(scriptpath.."\\"..filename)
	      if load~=nil then
		fileback=load:read("*all")
		io.close(load)
		fileback=fileback.."\n"
		B={}
		for l in fileback:gmatch("(.-)\n") do table.insert(B,l) end
		data=""
		    for x, i in ipairs(sel) do
			if B[i-c]==nil then line="" else line=B[i-c] end
			data=data..line.."\n"
		    end
		for key,val in ipairs(gui) do
		    if val.name=="file" then val.value=savename
		    elseif val.name=="msg" then val.value="Saved from "..filename.." to memory."
		    else val.value=res[val.name] end
		end
	      else
		for key,val in ipairs(gui) do
		    if val.name=="msg" then val.value="File "..filename.." not found."
		    else val.value=res[val.name] end
		end
	      end
	    end
	    if pressed=="No Comments" then
		for key,val in ipairs(gui) do
		    if val.name=="dat" then val.value=res.dat:gsub("{[^\\}]-}","")
		    else val.value=res[val.name] end
		end
	    end
	pressed,res=aegisub.dialog.display(gui,but,{close='OK'})
	filename=res.file
	if not filename:match("%.bak$") then filename=filename..".bak" end
	presd="Load from File,Load from Memory,Memory to File,File to Memory,No Comments"
	until not presd:match(pressed)
	
	if pressed=="OK" then    aegisub.cancel() end
	if pressed=="Save to Memory" then    save(subs,sel) end
	if pressed=="Save to File" then    savef(subs,sel) end
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, back)