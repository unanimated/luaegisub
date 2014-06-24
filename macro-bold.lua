-- switches between bold and regular [based on style and tags]
-- supports multiple \b tags in a line by switching 0 to 1 and vice versa

script_name="Bold"
script_description="Bold"
script_author="unanimated"
script_version="1.61"

function bold(subs, sel)
	for z, i in ipairs(sel) do
		local l=subs[i]
		text=l.text
		styleref=stylechk(subs,l.style)
		local sb=styleref.bold
		if sb==false then b="1" else b="0" end
		text=text:gsub("\\b([\\}])","\\b".. 1-b.."%1")
		    if text:match("^{[^}]*\\b%d[^}]*}") then
			text=text:gsub("\\b(%d)", function(num) return "\\b".. 1-num end)
		    else
			if text:match("\\b([01])") then bolt=text:match("\\b([01])") end
			if bolt==b then text=text:gsub("\\b(%d)", function(num) return "\\b".. 1-num end) end
			text="{\\b"..b.."}"..text
			text=text:gsub("{\\b(%d)}({\\[^}]*)}","%2\\b%1}")
		    end
		l.text=text
		subs[i]=l
	end
	aegisub.set_undo_point(script_name)
	return sel
end

function stylechk(subs,stylename)
    for i=1, #subs do
        if subs[i].class=="style" then
	    style=subs[i]
	    if stylename==style.name then
		styleref=style
		break
	    end
	end
    end
    return styleref
end

aegisub.register_macro(script_name, script_description, bold)