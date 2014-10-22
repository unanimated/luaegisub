--[[

	Muxing script version 1.1
	Read everything here before using it.
	
	
	DISCLAIMER
	
	You are receiving this badly written piece of code for several reasons:
	
	1. I can't write good code
	2. I don't have time to learn to write good code
	3. I don't particularly care about good code, as long as my bad code works
	4. The people who can write good code spend more time criticizing my code than writing their own
	5. I have somehow accidentally become the main lua-code-writer in fansubbing (hell knows why), so you don't have much choice
	
	Conclusion: deal with it.
	
	
	
	TERMS AND CONDITIONS
	
	
	1. You may NOT use this software if
	
	  - You are autistic about badly written code.
	    This includes complaining about things written in a way you don't like, even though they work,
	    spending hours criticizing bad code instead of writing a better one,
	    complaining about code you're not even using, and so on.
	    
	  - You are a citizen of the United States of America or Israel.
	    We do not support ZioNazi countries that routinely break International Law, murder innocent civilians by thousands,
	    use their police/military to beat up elderly people, taser children to death, or shoot whole families while raiding the wrong house,
	    invade other countries on false premises, organize or support coup d'etats in other countries, support dictators worldwide,
	    create terrorist organizations and then tell us we have to fight them, engage routinely in false-flag terrorism,
	    feed us daily with lies about Saddam's nonexistent WMDs, Hamas's rockets that are either nonexistent or fired by MOSSAD agents,
	    and other similar things, and generally strive every day to fuck up the whole planet.
	    
	  - You work for Monsanto or another rabidly insane corporation hell-bent on destroying the Earth.
	  
	  - You are under 30 years of age. Kids shouldn't play with badly written code.
	  
	  
	2. You are NOT allowed to
	
	  - Steal any part of this code, because it's bad for you to use bad code.
	  
	  - Modify this code in any way, because modifying bad code is like playing with grenades.
	  
	  - Sell this code, because selling bad code equals terrorism!
	  
	  
	3. You ARE allowed to
	
	  - Use this code to do what it's designed to do (see USAGE section), as long as conditions 1 and 2 are met.
	  
	  - Report real bugs, as in when the software isn't correctly doing what it claims to be able to do.
	  
	  - Ask for new features, as long as such features make sense within the scope of what this software does.
	  
	  - Read the comments in this file and learn something about writing lua scripts for Aegisub.
	  
	  - Use the software beyond its limitations (see point 4) ONLY AT YOUR OWN RISK.
	    I will not be responsible for any damage you cause that way.
	  
	  - Write better code.
	  
	  - Do all kinds of things that have no relation to this software whatsoever, like bungee jumping.
	  
	  
	4. Limitations:
	
	  This software has a (probably large) number of limitations, both documented and undocumented.
	  Documented ones are as follows:
	  
	  - This software is designed to work on Windows, even though Windows is shit, because that's the only OS I have and can work with.
	    As such, what the software will do on other OSs is completely unpredictable to me, thus it may or may not work as intended,
	    and may possibly harm your computer or do even worse things, like stab you in the eye or end the world.
	    
	  - Unicode characters in file/folder names.
	    Running lua from within Aegisub has various limitations compared to running it just under Windows,
	    especially with regards to messing with files and folders. I don't possess extensive knowledge on these matters,
	    but my personal experience shows that unicode characters in file/folder names is a likely factor to make things not work,
	    without it being very clear why exactly it is that they are not working.
	    Therefore it is recommended that folder names and file names do not contain any such characters.
	    
	  - External programs (without which this software's functionality is limited or impossible)
	    
	    I. Mkvmerge.
	       Mkvmerge is absolutely necessary for this software to do anything of use, i.e. muxing, its primary purpose.
	       Mkvmerge must be installed on your computer and a path to it given in the top field of this software's GUI.
	       Note that the file required is mkvmerge.exe and not mmg.exe.
	       
	    II. Enfis_SFV.exe
	        This is required if you want your muxed mkv file to automatically contain its CRC in the filename.
		If you don't need this feature, Enfis is not necessary.
		
	    III. xdelta
	         If you wish to create an xdelta file that patches your source video to the muxed video,
		 you need to download xdelta3.exe and input its location in the GUI.
		 Whether you call it xdelta3.exe or xdelta.exe or whatever else is unimportant,
		 as long as it's the correct file and the file path/name is correct.
		 
	    IV. Lua for Windows
	        This is not required if you don't need CRC/xdelta but is necessary if you want to use those.
		The reason is that the code that creates the CRC/xdelta can only be run after a video file is muxed
		and thus is run outside of Aegisub.
		As the only language I can write this in is lua, it requires Lua for Windows to run.
		You can download this for free from the Internet.
		Note: It would be possible to do everything from Aegisub if run right away,
		      but I wanted the whole process to be executable from a single batch file that you can run later.
	  
	  - You can not change the contents of the source video, i.e. whatever streams it already has will be used.
	  
	  - You can mux only two subtitle files.
	  
	  - You can only set track name and language for subtitle files.
	  
	  - You have to set the language code manually, thus you have to know what the correct code is.
	    You can't just type 'english' and think it will work. You can check these codes in mkvmerge.
	    The correct for English is 'eng (English)'. You can use either of those two - 'eng' or 'English'.
	    But there is a difference between 'English' and 'english', the latter being invalid.
	  
	  - Detecting muxed video name and episode number
	    This process is currently very limited and not very likely to be significantly improved,
	    unless unexpectedly good suggestions arise.
	    This name and number are used for two things:
	    - to try to determine the muxed encode's name
	    - to locate fonts folder if set to "script folder/ep number" or "video folder/ep number"
	    There are two places to look for these variables:
	    - (primary) Script title (in Properties in Aegisub)
	    - (secondary) script filename (.ass file)
	    If at least one of these contains the show's name and episode number, things should work well,
	    assuming the number is the last thing in the name.
	    If no number is found, the whole string is the name, and episode number is an empty string.
	    (Thus "script folder/ep number" should become the same as "script folder".)
	    If for whatever reason this process doesn't produce the desired results,
	    you have to type Muxed video name manually.
	    This is important when creating an xdelta file, as it will contain the given filename,
	    and if you rename the muxed file later, the patch will not work!
	    
	  Other limitations are possible, even likely.
	  If you find such limitations and think they could reasonably be removed, report them.
	
	
	
	USAGE
	
	
	1. To ensure correct usage, read TERMS AND CONDITIONS first.
	
	
	2. What this script can do.
	
	   This script should be able, fairly easily, to mux a video and subtitle file you have loaded in your Aegisub.
	   It can mux a secondary subtitle file that you select.
	   It can also mux a selected xml file with chapters.
	   When all appropriate conditions are met, it can add correct CRC to the muxed file's name.
	   When even more conditions are met, it can create an xdelta file to patch the source video to the muxed one.
	   It can also, for various reasons, fail to do the things just described.
	   It can possibly drive you mad by repeated failures for reasons you're desperately trying to ascertain
	   but which inexplicably keep eluding you.
	   It can occasionally fail to even load because you're using a shitty browser called Chrome,
	   which likes to add, for reasons unclear, html tags to downloaded lua files.
	   It can lock your Aegisub for a while if you're muxing a huge video file.
	   It can most likely do other unspecified things that no one has discovered yet. Those are, however, not intentional.
	
	
	3. Explanation of the GUI.
	
	  - mkvmerge.exe
	    This is an essential part of this software. You can't mux without this file.
	    Use the mkvmerge button at the bottom and navigate to where your mkvmerge.exe is.
	    To make the GUI remember the path, use the 'Save settings' button.
	  
	  - Fonts folder
	    This is where the script will look for fonts that are to be muxed.
	    The presets are for the script folder and video folder (which may be the same).
	    The option with '/fonts' means the fonts should be in a folder called 'fonts' in the script/video folder.
	    The option with '/ep number' means that instead of 'fonts', the folder will be called for example '01'.
	    This number is determined as described in TERMS AND CONDITIONS under '4. Limitations',
	    section 'Detecting muxed video name and episode number'.
	    If you use 'custom path:', use the 'fonts' button at the bottom, navigate to the folder where your fonts are,
	    and select one of the fonts. (Aegisub doesn't allow selecting just folders. The filename will be removed.)
	    
	  - Group tag
	    Here you can set your group's tag, which will be automatically used at the beginning of the muxed video's name.
	    Example: [TerribleSubs]
	    
	  - Enfis_SFV.exe
	    This is needed only when creating CRC (which is needed when making an xdelta file.)
	    It's an external binary which you can download for example here: http://unanimated.xtreemhost.com/SFV_Checker.zip
	    
	  - xdelta(3).exe
	    This is needed only when creating an xdelta patch. Easily downloadable from the Internet.
	    It doesn't matter whether the name is xdelta.exe or xdelta3.exe as long as the path leads to the correct file.
	    
	  - Muxed video name:
	    The script tries to build this name from information it collects.
	    Again, see section 'Detecting muxed video name and episode number' for more details.
	    the basic pattern is: 'GroupTag Name - EpNumber.mkv'
	    Depending on how you name your script's Title and filename, this may be more or less useful.
	    Adjust the filename manually as needed.
	    When using CRC, the CRC is inserted after the episode number automatically after muxing, with the usual pattern.
	    
	  - Source video
	    This is the video to be used for muxing and should be the video you have loaded in Aegisub.
	    Obviously, trying to mux without video loaded will result in failure.
	    
	  - -A/-S/-M/nc/nt
	    Options for source video. (Disable audio, subs, attachments, chapters, tags.)
	  
	  - File/segment title
	    Same as in mkvmerge, this is what's displayed in medianfo and players as the 'Movie name'.
	  
	  - Video options
	    Additional options for source video. May include --track-name etc.
	  
	  - Subtitle 1
	    This is the subtitle file to be used for muxing and should be the subtitle file you have loaded in Aegisub.
	    Obviously, trying to mux without the correct subtitle file loaded will result in failure.
	    
	  - Set as default
	    This is useful when the input video already has subtitles and you want your subs to be the default ones.
	    
	  - Subtitle 1 mkv title
	    This is the title of the subtitles that you can see in your player when selecting a subtitle stream.
	    This field is optional.
	    
	  - Language
	    This is the language displayed in your player for this subtitle stream.
	    This field is optional.
	    
	  - Subtitle 2
	    You can use one instance of alternative subtitles, for example with/without honorifics, or another language.
	    Use the 'Subs 2' button to locate the file (or paste a correct path).
	    
	  - Subtitle 2 mkv title + language
	    Same as for the first one; optional.
	    
	  - Chapters
	    If you need to mux chapters, use the Chapters button to locate the xml file.
	    If it exists in the same folder as your subtitle file and has the same naming pattern, it will be selected automatically.
	    It will, however, only be muxed if the checkbox is checked.
	    
	  - Create CRC
	    Use this if you want the CRC in the filename of the muxed file.
	    This requires Enfis_SFV.exe as explained above, as well as Lua for Windows.
	    
	  - Create xdelta patch
	    Use this if you want an xdelta file that patches the source video (premux, workraw) to the muxed file.
	    This requires Enfis_SFV.exe, xdelta3.exe, and Lua for Windows.
	    You can't make an xdelta without creating CRC.
	    
	  - Delete temporary files when done
	    The whole process creates a bunch of files required for everything to work.
	    These normally serve no purpose when everything works and can and should be deleted afterwards.
	    If, however, the process fails at some point, it's useful to keep the files to determine what exactly failed.
	    
	  - Keep cmd window open
	    This, again, is not necessary, and in fact rather useless when everything works,
	    but can be helpful when the muxing fails, as the cmd window will stay open
	    and you should be able to see which part of the process failed.
	    
	  - Buttons:
	    Mux: Creates files needed for muxing. (Muxing itself has to be confirmed in a later dialog.)
	    mkvmerge: lets you select mkvmerge.exe on your HD.
	    fonts: lets you select a folder containing fonts for muxing (though you need to select one of the files).
	    Enfis: lets you select Enfis_SFV.exe on your HD.
	    xdelta: lets you select xdelta3.exe on your HD.
	    Subs 2: lets you select an alternative subtitle file.
	    Chapters: lets you select chapters file (xml).
	    Save settings: Saves settings - top 5 lines of GUI (except custom path), languages for subs, and bottom 4 checkboxes.
	    Cancel: Casts level 3 Invisibility on your GUI. (Lasts until summoned again.)
	
	
	4. The Muxing Process.
	
	   When you set up everything correctly, click on the Mux button.
	   A cmd window will flash and close.
	   This part of the process creates the necessary files for muxing.
	   Then a dialog will pop up (assuming there was no error) that will list:
	   - Files to mux (video, subtitles)
	   - Number of fonts to mux that the script found
	   - The final filename of the muxed mkv
	   - Location of 'muxing.bat' (should be same as video's location)
	   
	   In case of any problems, or during first tests, it's useful to check these statistics.
	   
	   Make sure the video and subtitle files are correct.
	   The number of fonts should give you an idea if it found all of them. (Only ttf and otf are supported.)
	   Make sure the muxed file's name is correct, especially if doing CRC.
	   When doing CRC, the filename will contain [CRC], because the actual CRC hasn't been created yet; it will be replaced later.
	   
	   'muxing.bat' is what executes the whole muxing process, including CRC and xdelta if selected.
	   
	   If you click Yes, the muxing starts immediately.
	   If you click No, you can run 'muxing.bat' later.
	   
	   Running things from Windows may in some cases have more permissions than running things from Aegisub,
	   so choosing No and running the batch file from Windows may have higher rate of success.
	   (I don't really know the specifics, though, so don't quote me on that.)
	   
	   What happens when you start muxing:
	   
	   - A batch file (mux.bat) in the fonts folder muxes the video + subtitles + fonts.
	     This should have a relatively low chance to fail, compared to the later parts.
	     If you don't do CRC, this is all that needs to be done.
	     
	   - CRC creation / xdelta
	     Enfis_SFV.exe is called to create a sfv file with the CRC.
	     sfv.lua (in video folder) creates 'patchrel.bat' and possibly 'xdbatch.bat' (if making xdelta).
	     Creating xdelta without CRC is not allowed.
	     patchrel adds the correct CRC to the muxed video's name.
	     xdbatch creates the xdelta file.
	     Note: sfv.lua could do the renaming and patching right away, but i hate running os.execute from lua,
	           because it's a pain in the ass and causes more problems than anything else, so i prefer those bat files.
	
	
	5. Predictable Problems and Possible Solutions.
	
	   It's probably quite likely that the first try won't work, as there are plenty of things that can go wrong.
	   Several basic things to do in such a case would be:
	   I. Make sure all the filenames and file paths are correct, that all the needed files actually exist in the right place.
	   II. Check 'Keep cmd window open'. If you get to muxing at least, the cmd window should tell you what part failed.
	   III. uncheck 'Delete temporary files when done'.
	        While the cmd window will tell you what part of the process failed, it may not clearly tell you why.
		Find which of the temp files it failed at, and try to execute that file under Windows.
		You should open a new cmd window first and navigate to the folder, so that the window stays open and shows you the error.
		This is especially the case with sfv.lua. If the problem is with that one,
		running it from a cmd window under Windows will tell you which line it failed at and why.
	   IV. If the process fails with CRC or xdelta, try the same without CRC first to see if that part works.
	       This narrows down where the error occurred.
	   
	   The problems are often with files or folders not found, which may be because they were incorrectly specified,
	   they had unicode characters in them, possibly some characters that have a function in batch files
	   (I only work around '=' in folder names; not sure what others are a problem), or for other reasons(?).
	   It can be useful to test in a simply named folder in the root, like 'D:\sub', to eliminate naming problems.
	   
	   If you start muxing and muxing actually occurs, you see the progress of muxing in the cmd window.
	   This takes a while, depending on the size of the video.
	   If the cmd window disappears within about 5 seconds and the process fails, it's probably the muxing that failed.
	   If you keep the cmd window open and scroll up to the muxing part, you should see the relevant error.
	   
	   Make sure you have Lua for Windows installed (for CRC), and that lua files are associated with it!
	   If this isn't the case, it may be hard to detect what's failing.
	   
	   ttc (and other, even weirder types of) fonts don't get muxed. Don't use them.
	
	
	6. Tips and Recommendations.
	
	   - Don't use unicode characters anywhere in the process.
	   
	   - For smooth automatic naming, use this pattern in the script's Title: 'Show's name 01' or 'Show's name - 01',
	     where 01 is the episode number.
	     The Title is ignored if it's empty or the default, in which case the .ass filename is used.
	     Generally speaking, just use the 'name number' pattern with space, ' - ', or nothing in between.
	     
	   - At least until you get things to work reliably, test with mkvextract or mmg if all fonts are actually in the muxed mkv.
	
	
	7. List of external software used
	
	   mkvmerge - http://www.videohelp.com/tools/MKVtoolnix
	   Lua for Windows - http://code.google.com/p/luaforwindows/downloads/list
	   Enfis_SFV - http://www.softpedia.com/get/System/File-Management/Command-Line-SFV-Checker.shtml#download
		    or http://unanimated.xtreemhost.com/SFV_Checker.zip
	   xdelta - http://code.google.com/p/xdelta/downloads/list
	   
	   mkvmerge is the only essential one. Others only for advanced functions.
	
	
--]]

-- Everything in this script is extensively documented for educational and possibly entertainment purposes.


-- Here's where you learn about the generic name, boring description, notorious author, and current version of this abominable software.
script_name="Multiplexer"
script_description="Muxes stuff using mkvmerge"
script_author="unanimated"
script_version="1.1"

-- Here's where the actual script starts, though that's not really true because in a way it starts at the top,
-- and from a technical point of view it starts at the last line, which then redirects here.
-- Let's just settle on the idea that the main function starts here, though it might still be debated which function is the main one.
function mux(subs,sel)
    
    -- This is where your settings are stored, assuming you saved them there.
    -- In case you didn't know, '?user' is the folder of your Application Data, which differs based on your OS.
    muxconfig=aegisub.decode_path("?user").."\\mux-config.conf"
    
    -- This is where your video is located, assuming you have one loaded. If you don't, you're doing it wrong.
    vpath=aegisub.decode_path("?video").."\\"
    
    -- This is where your currently loaded subtitle file (.ass) is located.
    -- It better be the one you want to mux because if it isn't, you're doing it even wronger.
    spath=aegisub.decode_path("?script").."\\"
    
    -- This is the filename of your ass. Yes, that's a bad pun.
    -- Somehow when dealing with Aegisub, you always get bad ass puns. That was a pun too. See what I mean?
    scriptname=aegisub.file_name()
    
    -- This erases any possible videoname remaining from the last run of the script.
    -- You see, I write terrible code (5 of 4 'experts' says so, so it's clearly true),
    -- so I use global variables everywhere, because I don't really like the local ones.
    -- Global ones seem so much more practical. They're supposed to be slower,
    -- but it's not like I'm computing an intergalactic journey for a spaceship here.
    -- So occasionally, I have to erase some of these global variables so that they don't cause confusion.
    videoname=nil
    
    -- This attempts to translate the subtitle filename into the show's name and episode number.
    -- This of course assumes you're working on an episode of a show, which easily may not be the case.
    -- However, as this is mostly intended for people who do work on such things, it is fairly likely that this might work.
    -- If it doesn't, well, shit happens. You'll just get bad default naming.
    -- In the end, it's probably your fault because you had shitty filenaming in the first place.
    show,ep=scriptname:match("^(.-)%s*(%d+)%.ass")
    
    -- Here, if you don't have a number in the filename, we try to check if maybe you have OVA in the name.
    -- This would tell us that you're not working on a regular episode, but an OVA, in which case we use 'OVA' instead of the episode number.
    -- Now, it's marginally possible that you named your file in all caps, and it ends with 'OVA', like 'ANNA KOURNIKOVA'.
    -- In such a case we apologize for the unexpected results and politely ask, "What the fuck are you subbing?"
    -- If 'OVA' isn't detected either, we'll just take the whole name as is (without the .ass), and to hell with the number.
    if ep==nil then
	show,ep=scriptname:match("^(.-)%s*(OVA)$")
	if ep==nil then show=scriptname:gsub("%.ass","") ep="" end
    end

    -- Here we try to read your saved settings, assuming you saved any.
    -- It is most likely to succeed if you did, unless you were dumb enough to fuck with the saved file and did something wrong with it.
    -- Should that be the case, you're an idiot, and things will break. Don't fuck with things you don't understand.
    file=io.open(muxconfig)
    if file~=nil then
	-- This is the part where the file with the settings actually exists (though it's not clear yet what's really in it).
	konf=file:read("*all")
	io.close(file)
	mmgpath=konf:match("mmgpath:(.-)\n")
	fontpath=konf:match("ffpath:(.-)\n")
	tag=konf:match("tag:(.-)\n")
	sfvpath=konf:match("enfis:(.-)\n")
	xdpath=konf:match("xdelta:(.-)\n")
	lang1=konf:match("lang1:(.-)\n")
	lang2=konf:match("lang2:(.-)\n")
	crc=detf(konf:match("crc:(.-)\n"))
	patch=detf(konf:match("patch:(.-)\n"))
	delete=detf(konf:match("delete:(.-)\n"))
	cmdopen=detf(konf:match("cmdopen:(.-)\n"))
    else
	-- This is the part where it doesn't exist, so we create some default values.
	mmgpath=""
	fontpath="custom path:"
	tag="[SomeShitGroup]"
	sfvpath="download from http://unanimated.xtreemhost.com/SFV_Checker.zip or elsewhere"
	xdpath=""
	lang1="eng"
	lang2=""
	crc=false
	patch=false
	delete=true
	cmdopen=false
    end

    -- This is the part where we check the info section of your ass and look for the name of your video file and script title.
    for i=1,#subs do
	l=subs[i]
	if l.class=="info" then
	  -- Here we found the info part, so we look for those other things.
	  -- Finding the info part is rather easy, by the way, as it's always at the beginning.
	  -- At least that's the latest theory.
	  if l.key=="Video File" then videoname=l.value end
	  if l.key=="Title" then title=l.value end
	end
	-- This is where we break this process because the party's over.
	if l.class~="info" then break end
    end
    
    -- Now, if video file wasn't found, nothing's lost yet!
    -- In fact, it would only be found with an older version of Aegisub, which I hope you're not using, because that would be lame.
    -- So now, in a newer version, we get the video name from this thing called project_properties.
    -- If we don't find that either, it means you don't have any video loaded, in which case...
    -- Well, in which case things break and we don't really give a fuck, because you should have loaded it.
    -- How the hell do you wanna mux without a video? You wanna make a fucking mks? Nigger pls.
    if videoname==nil then videoname=aegisub.project_properties().video_file:gsub("^.*\\","") end
    
    -- Now we have a title, so we try to get an episode number from it if possible.
    -- Or maybe we don't have a title because we just got an empty string.
    -- Or maybe we just have "Default Aegisub file", which is just as useless.
    -- Anyway, we use what's useful and ignore what's useless, and in the latter case revert to using the filename.
    if title==nil or title=="Default Aegisub file" then title=show end
    if title:match("%d+$") then ep=title:match("(%d+)$") title=title:gsub("%s?%-?%s?%d+$","") end
    
    -- Here we compile the name for the muxed file from what we have.
    -- We use the group tag, that is if you already have one saved.
    -- Then we take the name we dug out of the title or filename, and attach the episode number if we have found one.
    -- If what we found was some stupid shit, it's because you name your things stupidly, so balme yourself for the result.
    if tag~="" then tag2=tag.." " else tag2="" end
    if ep~="" then ep2=" - "..ep else ep2="" end
    mvideo=tag2..title..ep2..".mkv"
    
    -- Should it somehow happen that the name ends up the same as your source video, we ad '_muxed' to avoid an obvious fuckup.
    -- By the way, did you ever notice that the word 'fuckup' looks like something you could put on your french fries? Weird.
    if mvideo==videoname then mvideo=mvideo:gsub("%.mkv","_muxed.mkv") end
    
    -- Here we make a leap of faith and check if by any chance you have a chapter file in the same folder as your subtitle file,
    -- and if by any chance you named it the same (save for the extension).
    -- Should that be the case, you're cool, and we automatically list this file in the GUI to save you the trouble of looking for it.
    ch_name=spath..scriptname:gsub("%.ass",".xml")
    file=io.open(ch_name)
    if file==nil then ch_name="" else file:close() end
    
    -- Now we build that mostrous thing called GUI with all those fields and checkboxes and buttons.
    GUI={
	-- First the part where you select the things that don't change (unless you weird and change them every time).
	-- Most of the things in this block are taken from your saved settings (if you saved them).
	{x=0,y=0,class="label",label="mkvmerge.exe:"},		{x=1,y=0,width=11,class="edit",name="mmgpath",value=mmgpath},
	{x=0,y=1,class="label",label="Fonts folder:"},
	{x=1,y=1,width=2,class="dropdown",name="ff",value=fontpath,items={"script folder","script folder/fonts","script folder/ep number","video folder","video folder/fonts","video folder/ep number","custom path:"}},
	{x=3,y=1,width=9,class="edit",name="fontspath",value=fontspath or "(only custom path goes here)"},
	{x=0,y=2,class="label",label="Group tag:"},		{x=1,y=2,width=11,class="edit",name="tag",value=tag},
	{x=0,y=3,class="label",label="Enfis_SFV.exe:"},	{x=1,y=3,width=11,class="edit",name="enfis",value=sfvpath},
	{x=0,y=4,class="label",label="xdelta(3).exe:"},	{x=1,y=4,width=11,class="edit",name="xdelta",value=xdpath},
	
	-- This is just some writing, mostly me repeating the same things again because users can be pretty dumb.
	{x=1,y=5,width=7,class="label",label="'Save settings' saves the above + languages + the bottom 4 checkboxes."},
	
	-- Here's video stuff
	{x=0,y=6,class="label",label="Muxed video name:"},	{x=1,y=6,width=11,class="edit",name="mvid",value=mvideo},
	{x=0,y=7,class="label",label="Source video:"},		{x=1,y=7,width=6,class="edit",name="vid",value=videoname},
	{x=7,y=7,class="checkbox",name="noA",label="-A ",hint="no audio"},
	{x=8,y=7,class="checkbox",name="noS",label="-S",hint="no subtitles"},
	{x=9,y=7,class="checkbox",name="noM",label="-M ",hint="no attachments"},
	{x=10,y=7,class="checkbox",name="noC",label="nc",hint="no chapters"},
	{x=11,y=7,class="checkbox",name="noT",label="nt",hint="no tags"},
	{x=0,y=8,class="label",label="File/segment title:"},	{x=1,y=8,width=4,class="edit",name="vtitle"},
	{x=5,y=8,width=3,class="checkbox",name="VO",label="Video options:",hint="additional input video options"},
	{x=8,y=8,width=4,class="edit",name="vopt"},
	
	-- Here's primary subtitle stuff
	{x=0,y=9,class="label",label="Subtitle 1:"},		{x=1,y=9,width=8,class="edit",name="subs",value=spath..scriptname},
	{x=9,y=9,width=3,class="checkbox",name="defsub",label="Set as default",hint="You can use this when orginal video already has subs"},
	{x=0,y=10,class="label",label="Subtitle 1 title:"},{x=1,y=10,width=6,class="edit",name="subname1",value=""},
	{x=7,y=10,width=2,class="label",label="    Language:  "},{x=9,y=10,width=3,class="edit",name="lang1",value=lang1 or ""},
	
	-- Here's secondary subtitle stuff
	{x=0,y=11,class="checkbox",name="sub2",label="Subtitle 2:"},{x=1,y=11,width=11,class="edit",name="subs2",value=""},
	{x=0,y=12,class="label",label="Subtitle 2 title:"},{x=1,y=12,width=6,class="edit",name="subname2",value=""},
	{x=7,y=12,width=2,class="label",label="    Language:  "},{x=9,y=12,width=3,class="edit",name="lang2",value=lang2 or ""},
	
	-- And here's chapter stuff
	{x=0,y=13,class="checkbox",name="ch",label="Chapters",value=false},
	{x=1,y=13,width=11,class="edit",name="chapters",value=ch_name},
	
	-- This block is checkboxes with additional options
	{x=0,y=14,class="checkbox",name="sfv",label="Create CRC",value=crc,hint="requires Enfis_SFV.exe and lua for windows"},
	{x=1,y=14,class="checkbox",name="xd",label="Create xdelta patch",value=patch,hint="requires Enfis_SFV.exe, xdelta3.exe, lua for win"},
	{x=3,y=14,width=2,class="checkbox",name="del",label="Delete temporary files when done      ",value=delete},
	{x=5,y=14,width=4,class="checkbox",name="cmd",label="Keep cmd window open",value=cmdopen},
	
	-- This shows the user what version of this software this is
	{x=9,y=14,width=3,class="label",label="      [ Multiplexer v"..script_version.." ]"},
    }
    
    -- This is where we attach a function to most of the buttons in the GUI.
    -- The function opens a dialog and lets you browse your HD and find and select the file required.
    -- It shows you what it is you need to find, in case your attention span is really fucking short.
    -- It also mostly only lets you select files with the right extension, in case you're an idiot.
    -- Once you select stuff, it adds it to the appropriate place in the GUI, while keeping the other stuff unchanged.
    repeat
    if pressed=="mkvmerge" then
	mmg_path=aegisub.dialog.open("mkvmerge.exe","",spath,"*.exe",false,true)
	gui("mmgpath",mmg_path)
    end
    if pressed=="fonts" then
	ff_path=aegisub.dialog.open("Fonts folder (Select any file in it)","",spath,"",false,true)
	if ff_path then ff_path=ff_path:gsub("\\[%w%s]+%.%w+$","\\") end
	gui("fontspath",ff_path)
    end
    if pressed=="Enfis" then
	sfv_path=aegisub.dialog.open("Enfis_SFV.exe","",spath,"*.exe",false,true)
	gui("enfis",sfv_path)
    end
    if pressed=="xdelta" then
	xd_path=aegisub.dialog.open("xdelta(3).exe","",spath,"*.exe",false,true)
	gui("xdelta",xd_path)
    end
    if pressed=="Subs 2" then
	s2_path=aegisub.dialog.open("Secondary subtitle file","",spath,"*.ass",false,true)
	gui("subs2",s2_path)
    end
    if pressed=="Chapters" then
	ch_path=aegisub.dialog.open("Chapters","",spath,"*.xml",false,true)
	gui("chapters",ch_path)
    end
    
    -- This is a rather important part, because it saves your settings.
    -- Without this, you'd have to input everything every time, which would be pretty damn annoying.
    -- So thank some ancient deities that I know how to do this, because if I didn't, nobody else would probably do it.
    if pressed=="Save settings" then
	
	-- These 4 lines use a cool function that converts boolean values to text.
	-- OK, maybe it's not really that cool. Whatever. Shut up.
	kcrc=tf(res.sfv)
	kxdel=tf(res.xd)
	kdel=tf(res.del)
	kcmd=tf(res.cmd)
	
	-- This is where a list of settings to save and their current values is written.
	konf="mmgpath:"..res.mmgpath.."\nffpath:"..res.ff.."\ntag:"..res.tag.."\nenfis:"..res.enfis.."\nxdelta:"..res.xdelta.."\nlang1:"..res.lang1.."\nlang2:"..res.lang2.."\ncrc:"..kcrc.."\npatch:"..kxdel.."\ndelete:"..kdel.."\ncmdopen:"..kcmd.."\n"
	
	-- Now we create the file (in the place we specified at the beginning of this whole function).
	file=io.open(muxconfig,"w")
	file:write(konf)
	file:close()
	
	-- We need to make sure that any changes we made in the GUI don't get reverted, so we apply the current values.
	for k,v in ipairs(GUI) do v.value=res[v.name] end
	
	-- This lets you know that your settings were saved, and where.
	-- It's good to do this for 2 reasons:
	-- 1. You know that something actually happened, and was successful.
	-- 2. You know where the settings are, in case you ever need it. (But don't fuck with it if you don't know what you're doing.)
	aegisub.dialog.display({{class="label",label="Settings saved to:\n"..muxconfig}},{"OK"},{close='OK'})
    end
    
    -- This is the part where we actually build the GUI.
    -- You may ask, "Wait! WTF? How are we only building it now when we were messing with it for a while?"
    -- Well, that's a good question. The not-too-long answer is something like this:
    -- All we've done so far with the GUI is inside a 'repeat' loop that displays the GUI again each time a button activates a function.
    -- So the first time, with no button pressed yet, it ran all the way here to display the GUI.
    -- Then, after pressing buttons, it does the stuff above, comes back here, and displays it again.
    pressed,res=aegisub.dialog.display(GUI,{"Mux","mkvmerge","fonts","Enfis","xdelta","Subs 2","Chapters","Save settings","Cancel"},{ok='Mux',close='Cancel'})
    
    -- This is what breaks the repeat loop. Either it's Cancel, which gives you cancer... (better not click that)
    -- or it's Mux, which says, "OK, I'm done with this fucking clicking around in this stupid GUI. Let's have some action!"
    until pressed=="Mux" or pressed=="Cancel"
    
    -- This is where you get cancer.
    if pressed=="Cancel" then aegisub.cancel() end
    
    -- If you get here, it means you didn't get cancer (that's good news!) and that files for muxing are being prepared,
    -- of which, as you can see, the user is properly being informed, because if there's one thing worse than cancer, it's uninformed public.
    aegisub.progress.title("Preparing files for muxing...")
    
    -- Here we take some results from the GUI and give them an easier-to-use name because it's easier to use.
    -- It is mainly done with the ones that get referenced later multiple times. If it's used only once, no need to bother.
    video=res.vid
    mvideo=res.mvid
    subname1=res.subname1
    subname2=res.subname2
    lang1=res.lang1
    lang2=res.lang2
    fontspath=res.fontspath
    if res.vtitle~="" then vtitle=" --title "..quo(res.vtitle) else vtitle="" end
    
    -- Here we anticipate the possibility that you didn't read the fucking instructions and are doing something stupid,
    -- namely trying to create an xdelta without creating CRC when we clearly said it's not allowed.
    -- So if you check xdelta and not CRC, we check CRC for you.
    if res.xd then res.sfv=true end
    
    -- It has come to our attention that some people will select mmg.exe instead of mkvmerge.exe,
    -- so this is where we tell them they're doing it wrong.
    if res.mmgpath:match("mmg.exe") then t_error("ERROR: Youre doing it wrong.\n'mmg.exe' is not 'mkvmerge.exe'.",true) end
    
    -- In case you still got a wrong file anyway, here we tell you so to save you one "Why isn't this working?" moment.
    if not res.mmgpath:match("mkvmerge.exe") then t_error("ERROR:\n'"..res.mmgpath.."' is not a valid 'mkvmerge.exe' file.",true) end
    
    
    -- This is the part where we write a script that gets the CRC, renames the muxed mkv file, and creates an xdelta
    if res.sfv then
	
	-- First we check if you actually input the path to Enfis_SFV.exe.
	-- If you didn't, we decide to proceed without creating CRC.
	if res.enfis=="" then
	  t_error("Enfis_SFV.exe not specified.\nProceeding without CRC.")
	  bat_crc=""
	else
	  -- Here we do another check, to see if Enfis_SFV.exe that you point to actually exists.
	  -- If it doesn't, mission failed.
	  -- It will not fail, however, at least not at this point, if you pointed to a different file that exists.
	  -- In such a case operations would proceed, but the CRC would not be created because you're a douchebag.
	  file=io.open(res.enfis)
	  if file==nil then t_error("FILE NOT FOUND!\n"..res.enfis,true) else file:close() end
	  
	  -- If you successfully made it this far, we insert '[CRC]' in the filename.
	  -- This will later be replaced with the actual CRC, once we know what it is.
	  mvideo=mvideo:gsub("%.mkv"," [CRC].mkv")
	  
	  -- This is the command line that creates a file with the CRC, which will be run from 'muxing.bat'.
	  bat_crc=quo(res.enfis).." -f=\"whatisthisidonteven.sfv\" "..quo(mvideo).."\ncall sfv.lua\ncall patchrel\ncall xdbatch\n"
	  
	  -- This is a pain-in-the-ass part of the code that creates sfv.lua.
	  -- Getting all these quotation marks and escape slashes right is fucking hell.
	  -- Anyway, this sfv.lua is what will be reading the sfv file with the CRC
	  -- and creating batch scripts for renaming the mkv and creating an xdelta.
	  luavpath=vpath:gsub("\\","\\\\")
	  sfvlua="file=io.open(\""..luavpath.."whatisthisidonteven.sfv\")\nsfvtext=file:read(\"*all\")\nfile:close()\ncrc=sfvtext:match(\"%.mkv%s(%x+)\")\nvideo=\""..mvideo.."\"\ncrc_name=video:gsub(\"%[CRC%]\",\"[\"..crc..\"]\")\ncrctext=\"rename \\\""..mvideo.."\\\" \\\"\"..crc_name..\"\\\"\"\nfile=io.open(\""..luavpath.."patchrel.bat\",\"w\")\nfile:write(crctext)\nfile:close()\n"
	  
	  -- Here's the (optional) xdelta part.
	  if res.xd then
	    -- Again, we check if the given xdelta3.exe exists, because we know some of you are morons,
	    -- and in absence of said file we politely inform you that there will be no patching for reasons just explained.
	    file=io.open(res.xdelta)
	    if file==nil then
	      t_error("FILE NOT FOUND!\n"..res.xdelta.."\nProceeding without patching.")
	      xdtext=""
	    else 
	      -- This is the xdelta part of the pain-in-the-ass sfv.lua code, and will be attached if making xdelta was selected.
	      luaxd=res.xdelta:gsub("\\","\\\\")
	      xdt="xdtext=\"call \\\""..luaxd.."\\\" -f -s \\\""..video.."\\\" \\\"\"..crc_name..\"\\\" \\\""..show..ep..".xdelta\\\"\"\nfile=io.open(\""..luavpath.."xdbatch.bat\",\"w\")\nfile:write(xdtext)\nfile:close()"
	    end
	  else
	    -- If xdelta wasn't selected, we give this empty string a few lines later, and we delete patching from the batch.
	    xdt=""
	    bat_crc=bat_crc:gsub("\ncall xdbatch","")
	  end
	  
	  -- Proceeding to write sfv.lua, consisting of the CRC part and xdelta part that, as previously mentioned,
	  -- may be an empty string in the case of making xdelta not being selected.
	  file=io.open(vpath.."sfv.lua","w")
	  file:write(sfvlua..xdt)
	  file:close()
	  
	end
    else
	-- If we're not making CRC, an empty string will be supplied to the main batch file. (In other words basically nothing.)
	bat_crc=""
    end
    
    
    -- This simple part of the code defines what the path to fonts-to-mux is based on given settings.
    -- It's so simple that even you can write it. Or at least understand it, I'm sure!
    if res.ff=="script folder" then ffpath=spath end
    if res.ff=="script folder/fonts" then ffpath=spath.."fonts" end
    if res.ff=="script folder/ep number" then ffpath=spath..ep end
    if res.ff=="video folder" then ffpath=vpath end
    if res.ff=="video folder/fonts" then ffpath=vpath.."fonts" end
    if res.ff=="video folder/ep number" then ffpath=vpath..ep end
    if res.ff=="custom path:" then ffpath=res.fontspath end
    -- Here we add a backslash at the end, so that we don't have to do it multiple times later.
    ffpath=ffpath.."\\"
    
    
    -- This determines what to do based on whether the user wishes to mux a chapters file.
    if res.ch then
	-- If we're muxing chapters, this string will be added to the muxing batch file.
	bat_chap="--chapters "..quo(res.chapters).." "
	
	-- Again check if chapters file actually exists.
	-- (Yeah, this is rather boring and repetitive, but people tend to be repetitively stupid,
	-- and constant checking of everything saves them from a lot of the bad kind of errors.
	-- This way, they get the good kind of error, that is to say, one that tells them clearly what's wrong.)
	-- If chapters don't exist where they should, the process proceeds without them.
	file=io.open(res.chapters)
	if file==nil then t_error("Chapters not found:\n"..res.chapters.."\nProceeding without.") bat_chap="" else file:close() end
    else
	-- If chapters aren't selected for muxing, empty string goes to final batch file.
	bat_chap=""
    end
    
    
    -- Here we infiltrate the fonts folder and secretly plant a file there.
    -- This file will shortly be used to get the filenames of fonts.
    list="cd /d "..quo(ffpath).."\ndir /b>files.txt\n del list.bat"
    file=io.open(ffpath.."list.bat","w")
    file:write(list)
    file:close()
    
    -- Now we use that file we just created to create another file. Yes, it's like Inception. We have to go a level deeper.
    -- Since os.execute from lua is a pain in the ass, we escape '=' in folder names.
    -- It just happens that i have '=' in a folder name, so I did that one.
    -- I'm not particularly motivated at this point to find out what other characters might cause the same issues.
    exffpath=ffpath:gsub("%=","^=")
    os.execute("\""..exffpath.."list.bat\"")
    
    -- Once we've created files.txt (which contains a list of all files in the fonts folder) by using list.bat,
    -- we read its contents into a variable called fontext.
    file=io.open(ffpath.."files.txt")
    fontext=file:read("*all")
    file:close()
    
    -- We create an empty table where all filenames from fontext will go.
    fontslist={}
    
    -- This line takes each line from fontext and throws it into that table above.
    for line in fontext:gmatch("(.-)\n") do table.insert(fontslist,line) end
    
    -- muxbatch is the content of the muxing script, here started as an empty string.
    -- fc is font counter. This will be useful later so that the user knows how many fonts were found.
    muxbatch="" fc=0
    
    -- Here's a loop that goes through the above-mentioned table, and for every line that ends with .ttf or .otf
    -- creates a line for the muxing batch to mux that font, adds it to muxbatch, and increases the font count by 1.
    for i=1,#fontslist do
	fline=fontslist[i]
	if fline:match("%.[TtOo][Tt][Ff]$") then fc=fc+1
	
	-- This is the already infamous part of code where we use x-truetype-font mime type for otf as well as ttf.
	-- Some people are aggressively autistic about this and demand it to change.
	-- As we have said, currently this way works in every case we know of,
	-- whereas we know of countless instances where the so called 'correct' way doesn't work.
	-- We therefore prefer what works everywhere over what is 'correct' but doesn't work everywhere.
	-- Once cases appear where the incorrect way doesn't work, we will change this.
	-- Until then, fuck off.
	muxbatch=muxbatch.."--attachment-mime-type application/x-truetype-font --attach-file "..quo(fline).." " end
    end
    
    -- Here's another of those endless checks.
    -- If muxbatch ends up being an empty string, it means no fonts were added, for whatever reason,
    -- and the user is therefore informed of this curious development, as it may be rather vital,
    -- and is given a message showing the path where the fonts were not found,
    -- so that he/she may know that he/she didn't put any fonts in that path,
    -- either because he/she didn't collect the fonts, or because he/she collected them somewhere else,
    -- or possibly because he/she has done some other stupid thing.
    if muxbatch=="" then t_error("Warning: No fonts found in "..ffpath) end
    
    -- Here information is collected about track name and language of primary subtitles.
    -- Instructions for muxing script are written accordingly.
    if subname1~="" then tn1=" --track-name 0:"..quo(subname1) else tn1="" end
    if lang1~="" then ln1=" --language 0:"..lang1 else ln1="" end
    
    -- Here the same is done for secondary subtitles if the user has decided to use said feature. (Else we go with an empty string again.)
    if res.sub2 then
	if subname2~="" then tn2=" --track-name 0:"..quo(subname2) else tn2="" end
	if lang2~="" then ln2=" --language 0:"..lang2 else ln2="" end
	subs2=tn2..ln2.." "..quo(res.subs2)
    else
	subs2=""
    end
    
    -- This line determines whether we need to set the subtitle track as default.
    if res.defsub then defsub=" --default-track 0:true" else defsub="" end
    -- This is options for input video.
    vopt=""
    if res.noA then vopt=vopt.." -A" end
    if res.noS then vopt=vopt.." -S" end
    if res.noM then vopt=vopt.." -M" end
    if res.noC then vopt=vopt.." --no-chapters" end
    if res.noT then vopt=vopt.." -T --no-global-tags" end
    if res.VO then vopt=vopt.." "..res.vopt end
    -- Here the main chunk of the muxing script is written, namely the path to mkvmerge.exe,
    -- output video file, input video file, subtitles with information just collected a few lines above,
    -- chapters as collected earlier, and at the end is attached the list of fonts that we already have.
    muxbatch=quo(res.mmgpath)..vtitle.." -o "..quo(vpath..mvideo)..vopt.." "..quo(vpath..video)..tn1..ln1..defsub.." "..quo(res.subs)..subs2.." "..bat_chap..muxbatch
    
    -- Here the actual muxing script is written and saved in the fonts directory.
    file=io.open(ffpath.."mux.bat","w")
    file:write(muxbatch)
    file:close()
    
    
    -- This piece of code that will be attached at the end of the main batch file contains information to delete temporary files
    -- if that option has been activated, while in the opposite case, as you can surely guess by now, an empty string is supplied.
    if res.del then
	delete="\ndel \""..ffpath.."files.txt\"\ndel \""..ffpath.."mux.bat\"\ndel \"patchrel.bat\"\ndel \"xdbatch.bat\"\ndel \"sfv.lua\"\ndel \"whatisthisidonteven.sfv\"\ndel \"muxing.bat\"\n"
    else
	delete=""
    end
    
    
    -- Here we finally come to the part where we write the main batch file that runs everything else.
    -- This file can be run later, assuming you don't delete any of the necessary files by then, and it will do the whole job.
    -- This first line adds a 'pause', that is to say prevent the cmd window from closing, when such instructions are supplied.
    if res.cmd then pause="pause" else pause="" end
    
    -- This next, rather short, line utilizes a number of things that we've created earlier.
    -- The whole affair consist of these steps:
    -- 1. navigate to the fonts folder
    -- 2. execute mux.bat, which is the muxing script, which will mux all the necessary files
    -- 3. navigate to video folder
    -- The following apply only when such options were selected:
    -- 4. use Enfis to create a sfv file with CRC for the muxed video
    -- 5. execute sfv.lua which creates patchrel.bat and xdbatch.bat
    -- 6. execute patchrel, renaming the muxed file to have the CRC in name
    -- 7. execute xdbatch, creating the xdelta file
    -- 8. pause, i.e. keep cmd window open until the 'any' key is pressed
    -- 9. delete temporary files
    BAT="cd /d "..quo(ffpath).."\ncall mux.bat\ncd /d "..quo(vpath).."\n"..bat_crc..pause..delete
    
    -- batch is the location of muxing.bat
    batch=vpath.."muxing.bat"
    
    -- Here all the instructions are being written into muxing.bat.
    local xfile=io.open(batch,"w")
    xfile:write(BAT)
    xfile:close()
    
    
    -- As a last step, all relevant information about the operation to take place is collected here,
    -- and it will be displayed for the user to glance over and confirm that everything looks as it's supposed to,
    -- or realize that in his/her boundless stupidity he/she did something wrong and has to start again.
    summary="Files to mux:\n\nVideo file:        "..video.."\nSubtitle file 1:  "..res.subs.."\nSubtitle file 2:  "..res.subs2.."\nFonts to mux:  "..fc.."\n\nMuxed file:      "..mvideo.."\n\nBatch file:       "..batch.."\n\nYou can mux now or run this batch file later.\nIf muxing from Aegisub doesn't work,\njust run the batch file.\n\nMux now?"
    
    -- Here we display the dialog where the user can choose to either commence operations at once,
    -- or leave that for a later time.
    P=aegisub.dialog.display({{class="label",label=summary}},{"Yes","No"},{ok='Yes',close='No'})
    if P=="Yes" then
	-- If a decision is made to proceed, the user is informed that muxing is taking place
	-- while a cmd window should be executing all scheduled operations.
	aegisub.progress.title("Muxing...")
	
	-- As mentioned before, ox.execute from lua is a pest, and thus an escape sequence is implemented again.
	batch=batch:gsub("%=","^=")
	
	-- This is where things finally start to move and you await anxiously the verdict of either success or failure.
	os.execute(quo(batch))
    end
end

-- This little function is used for the Open dialog.
-- It takes the result, applies it to the corresponding field in the GUI,
-- and updates all other fields with current values.
function gui(a,b)
  for k,v in ipairs(GUI) do
    if b==nil then b="" end
    if v.name==a then v.value=b else v.value=res[v.name] end
  end
end

-- This function sends an error message to the user, and if given such instructions, cancels all operations.
function t_error(message,cancel)
  aegisub.dialog.display({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then aegisub.cancel() end
end

-- This little function takes a string and wraps it in quotation marks.
function quo(x)
    x="\""..x.."\""
    return x
end

-- This converts boolean values to their corresponding text counterparts.
function tf(val)
    if val==true then ret="true" else ret="false" end
    return ret
end

-- This, contrary to the previous function, takes strings, converts 'true' or 'false' to boolean values,
-- and leaves anything else as is.
function detf(txt)
    if txt=="true" then ret=true
    elseif txt=="false" then ret=false
    else ret=txt end
    return ret
end

-- This escape function is used for gsub.
-- According to line0, it could be written better, and it's true, but fuck it. It works, and I like it this way.
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

-- This line, as I'm sure everyone knows, registers the mux function in Aegisub so that it appears in the menu and you can use it.
aegisub.register_macro(script_name,script_description,mux)