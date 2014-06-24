-- Adds \shad0 to selected lines, then cycles through 1, 2, 3, 4, 5, 6, 7, 8, 9, back to 0. 

script_name="Shadow cycle"
script_description="Add shadow tags to selected lines."
script_author="unanimated"
script_version="1.61"

sequence={"0","1","2","3","4","5","6","7","8","9"}	-- you can modify this

function shad(subs, sel)
    for z, i in ipairs(sel) do
	line=subs[i]
	text=line.text
	    tf=""
	    if text:match("^{\\[^}]-}") then
	    tags,after=text:match("^({\\[^}]-})(.*)")
		if tags:match("\\t") then 
		    for t in tags:gmatch("(\\t%([^%(%)]-%))") do tf=tf..t end
		    for t in tags:gmatch("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))","") do tf=tf..t end
		    tags=tags:gsub("\\t%([^%(%)]+%)","")
		    :gsub("\\t%([^%(%)]-%([^%)]-%)[^%)]-%)","")
		    :gsub("{}","")
		    text=tags..after
		end
	    end

	    sh=text:match("^{[^}]-\\shad([%d%.]+)")
	    if sh~=nil then
		for b=1,#sequence do
		    if sh==sequence[b] then sh2=sequence[b+1] end
		end
		if sh2==nil then sh2="0" end
		text=text:gsub("^({[^}]-\\shad)[%d%.]+","%1"..sh2)
	    else
		text="{\\shad0}" .. text
		text=text:gsub("{\\shad0}{\\","{\\shad0\\")
	    end

	text=text:gsub("^({\\[^}]-)}","%1"..tf.."}")
	line.text=text
	subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, shad)