--
--****************************
--*** Minimal Display Bars ***
--****************************
--* Coded by: ATPHHe
--* Date Created: 02/19/2020
--* Date Modified: 06/27/2020
--*******************************
--
--============================================================

MinimalDisplayBarsB4220 = {}

MinimalDisplayBarsB4220.MOD_ID = "MinimalDisplayBarsB4220"

local gameVersion = getCore():getVersionNumber()
MinimalDisplayBarsB4220.gameVersionNum = 0

local tempIndex, _ = string.find(gameVersion, " ")

if tempIndex ~= nil then
    MinimalDisplayBarsB4220.gameVersionNum = tonumber(string.sub(gameVersion, 0, tempIndex))
    if MinimalDisplayBarsB4220.gameVersionNum == nil then 
        tempIndex, _ = string.find(gameVersion, ".") + 1 
        MinimalDisplayBarsB4220.gameVersionNum = tonumber(string.sub(gameVersion, 0, tempIndex))
    end
else
    MinimalDisplayBarsB4220.gameVersionNum = tonumber(gameVersion)
end
tempIndex = nil
gameVersion = nil

-- Optional, read-only layout preset. It is never loaded as a user's active
-- configuration unless they explicitly select it from the Menu bar.
MinimalDisplayBarsB4220.legacyLayoutPresetFileName = "presets/Legacy_PreUpdate_Layout.cfg"
MinimalDisplayBarsB4220.currentLayoutPresetFileName = "presets/Current_Layout.cfg"
-- Build 42 no longer writes configuration files into the Workshop mod directory.
-- Keep its configuration separate from the legacy Build 41 file as well.
-- Build 42 only permits Lua mods to write .ini, .cfg, .txt, or .log files in
-- Zomboid/Lua.  The saved data remains Lua-table text, but uses .cfg so the
-- game's restricted file writer can create and update it.
MinimalDisplayBarsB4220.configFileName = "MOD Config Options (".. MinimalDisplayBarsB4220.MOD_ID ..")B42.cfg"
--local configFileLocation = getMyDocumentFolder() .. getFileSeparator() .. MinimalDisplayBarsB4220.configFileName

MinimalDisplayBarsB4220.configFileLocations = {}

MinimalDisplayBarsB4220.configTables = {}

--============================================================

-- Configuration helpers

function MinimalDisplayBarsB4220.compare_and_insert(t1, t2, ignore_mt)
    
    local isEqual = true
    
    if not t1 then
        return false
    end
    
    if not t2 then
        t2 = {}
        isEqual = false
    end
    
    if type(t1) == "table" then
        for k1,v1 in pairs(t1) do
            local v2 = t2[k1]
            if (v2 == nil) then 
                -- Missing settings must receive their own copy. Sharing the
                -- default table would let one player's change alter the
                -- defaults used for later players or newly added bars.
                t2[k1] = MinimalDisplayBarsB4220.deepcopy(v1)
                isEqual = false
            end
            
            if type(t1[k1]) == "table" then
                if not MinimalDisplayBarsB4220.compare_and_insert(t1[k1], t2[k1], ignore_mt) then
                    isEqual = false
                end
            end
            
        end
    end
    
    return isEqual
end

function MinimalDisplayBarsB4220.deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in pairs(orig) do
                copy[MinimalDisplayBarsB4220.deepcopy(orig_key, copies)] = MinimalDisplayBarsB4220.deepcopy(orig_value, copies)
            end
            setmetatable(copy, MinimalDisplayBarsB4220.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Persistent configuration I/O


--[[

TablePersistence is a small code snippet that allows storing and loading of lua variables containing primitive types. It is licensed under the MIT license, use it how ever is needed. A more detailed description and complete source can be downloaded on http://the-color-black.net/blog/article/LuaTablePersistence. A fork has been created on github that included lunatest unit tests: https://github.com/hipe/lua-table-persistence

Shortcomings/Limitations:
- Does not export udata
- Does not export threads
- Only exports a small subset of functions (pure lua without upvalue)

]]
local write, writeIndent, writers, refCount;
MinimalDisplayBarsB4220.io_persistence =
{
	store = function (path, modID, ...)
		local file = getFileWriter(path, true, false)
		if not file then
			return error("Unable to open " .. tostring(path) .. " for writing.");
		end
		local n = select("#", ...);
		-- Count references
		local objRefCount = {}; -- Stores reference that will be exported
		for i = 1, n do
			refCount(objRefCount, (select(i,...)));
		end;
		-- Export Objects with more than one ref and assign name
		-- First, create empty tables for each
		local objRefNames = {};
		local objRefIdx = 0;
		file:write("-- Persistent Data (for "..modID..")\n");
		file:write("local multiRefObjects = {\n");
		for obj, count in pairs(objRefCount) do
			if count > 1 then
				objRefIdx = objRefIdx + 1;
				objRefNames[obj] = objRefIdx;
				file:write("{};"); -- table objRefIdx
			end;
		end;
		file:write("\n} -- multiRefObjects\n");
		-- Then fill them (this requires all empty multiRefObjects to exist)
		for obj, idx in pairs(objRefNames) do
			for k, v in pairs(obj) do
				file:write("multiRefObjects["..idx.."][");
				write(file, k, 0, objRefNames);
				file:write("] = ");
				write(file, v, 0, objRefNames);
				file:write(";\n");
			end;
		end;
		-- Create the remaining objects
		for i = 1, n do
			file:write("local ".."obj"..i.." = ");
			write(file, (select(i,...)), 0, objRefNames);
			file:write("\n");
		end
		-- Return them
		if n > 0 then
			file:write("return obj1");
			for i = 2, n do
				file:write(" ,obj"..i);
			end;
			file:write("\n");
		else
			file:write("return\n");
		end;
		if type(path) == "string" then
			file:close();
		end;
	end;

	--[[
  load = function (path, modID)
		local f;
		if type(path) == "string" then
            if getFileReader then
                f = getFileReader(path, true);
            end
            if f == nil and getModFileReader then
                f = getModFileReader(modID, path, true);
            end
            if f == nil then return nil end

            local contents = "";
            local scanLine = f:readLine();
            while scanLine do
                
                contents = contents.. scanLine .."\r\n";
                
                scanLine = f:readLine();
                if not scanLine then break end
            end
            
            f:close();
            
            f = contents;
		else
			f = path:read('*a');
		end
		if f then
            local func = loadstring(f);
            if func then
                return func();
            else
                return nil;
            end
		else
			return nil, e;
		end;
	end;
  ]]
  load = function (path, modID)
    local f;
    if type(path) == "string" then
      if getFileReader then
        f = getFileReader(path, true);
      end
      if f == nil and getModFileReader then
        f = getModFileReader(modID, path, true);
      end
      if f == nil then return nil end
      local contents = "";
      local scanLine = f:readLine();
      while scanLine do
        contents = contents.. scanLine .."\r\n";
        scanLine = f:readLine();
        if not scanLine then break end
      end
      f:close();
      f = contents;
    else
      f = path:read('*a');
    end
    if f then
      return MinimalDisplayBarsB4220.io_persistence.parseData(f);
    else
      return nil;
    end;
  end;
  -- Parses the Lua-table text store() writes. B42.20 removed loadstring,
  -- so the config must not be executed.
  parseData = function (text)
    local pos, len = 1, #text;
    local shared = {};
    local function skipSpace()
      while pos <= len do
        local c = text:sub(pos, pos);
        if c == ' ' or c == '\t' or c == '\r' or c == '\n' then
          pos = pos + 1;
        elseif c == '-' and text:sub(pos + 1, pos + 1) == '-' then
          local nl = text:find('\n', pos, true);
          pos = nl and (nl + 1) or (len + 1);
        else
          return;
        end
      end
    end
    local function readString()
      local quote = text:sub(pos, pos);
      pos = pos + 1;
      local out = {};
      while pos <= len do
        local c = text:sub(pos, pos);
        if c == '\\' then
          local nxt = text:sub(pos + 1, pos + 1);
          if nxt == 'n' then out[#out + 1] = '\n';
          elseif nxt == 't' then out[#out + 1] = '\t';
          elseif nxt == 'r' then out[#out + 1] = '\r';
          else out[#out + 1] = nxt; end
          pos = pos + 2;
        elseif c == quote then
          pos = pos + 1;
          return table.concat(out);
        else
          out[#out + 1] = c;
          pos = pos + 1;
        end
      end
      return table.concat(out);
    end
    local function skipUnknown()
      local c = text:sub(pos, pos);
      if c == '"' or c == "'" then readString(); return; end
      local name = text:match('^[%a_][%w_%.]*', pos);
      if name then
        pos = pos + #name;
        skipSpace();
        local open = text:sub(pos, pos);
        if open == '(' or open == '[' then
          local close = (open == '(') and ')' or ']';
          local depth = 0;
          while pos <= len do
            local ch = text:sub(pos, pos);
            if ch == '"' or ch == "'" then
              readString();
            else
              if ch == open then depth = depth + 1;
              elseif ch == close then
                depth = depth - 1;
                if depth == 0 then pos = pos + 1; return; end
              end
              pos = pos + 1;
            end
          end
        end
        return;
      end
      pos = pos + 1;
    end
    local readValue;
    local function readTable()
      local t = {};
      pos = pos + 1;
      while pos <= len do
        skipSpace();
        local c = text:sub(pos, pos);
        if c == '}' or c == '' then pos = pos + 1; return t; end
        local key;
        if c == '[' then
          pos = pos + 1;
          skipSpace();
          if text:sub(pos, pos) == '"' or text:sub(pos, pos) == "'" then
            key = readString();
          else
            local raw = text:match('^[^%]]*', pos) or '';
            pos = pos + #raw;
            key = tonumber(raw) or raw;
          end
          skipSpace();
          if text:sub(pos, pos) == ']' then pos = pos + 1; end
          skipSpace();
          if text:sub(pos, pos) == '=' then pos = pos + 1; end
          skipSpace();
          local ok, value = readValue();
          if ok and key ~= nil then t[key] = value; end
        else
          local ok, value = readValue();
          if ok then t[#t + 1] = value; end
        end
        skipSpace();
        local sep = text:sub(pos, pos);
        if sep == ';' or sep == ',' then pos = pos + 1; end
      end
      return t;
    end
    readValue = function ()
      skipSpace();
      local c = text:sub(pos, pos);
      if c == '{' then return true, readTable();
      elseif c == '"' or c == "'" then return true, readString();
      elseif text:sub(pos, pos + 3) == 'true' then pos = pos + 4; return true, true;
      elseif text:sub(pos, pos + 4) == 'false' then pos = pos + 5; return true, false;
      elseif text:sub(pos, pos + 2) == 'nil' then pos = pos + 3; return true, nil;
      elseif text:sub(pos, pos + 14) == 'multiRefObjects' then
        local idx = text:match('^multiRefObjects%s*%[%s*(%d+)%s*%]', pos);
        if idx then
          local whole = text:match('^multiRefObjects%s*%[%s*%d+%s*%]', pos);
          pos = pos + #whole;
          local n = tonumber(idx);
          shared[n] = shared[n] or {};
          return true, shared[n];
        end
        skipUnknown();
        return false, nil;
      else
        local num = text:match('^%-?%d+%.?%d*[eE]?[%-+]?%d*', pos);
        if num and num ~= '' then
          pos = pos + #num;
          return true, tonumber(num);
        end
      end
      skipUnknown();
      return false, nil;
    end
    local returned = text:match('return%s+([%w_]+)');
    if returned then
      local declaration = text:find('local%s+' .. returned .. '%s*=%s*{');
      if declaration then
        pos = text:find('{', declaration, true);
        return (readTable());
      end
    end
    local brace = text:find('{', 1, true);
    if not brace then return nil; end
    pos = brace;
    return (readTable());
  end;
}

-- Private methods

-- write thing (dispatcher)
write = function (file, item, level, objRefNames)
	writers[type(item)](file, item, level, objRefNames);
end;

-- write indent
writeIndent = function (file, level)
	for i = 1, level do
		file:write("\t");
	end;
end;

-- recursively count references
refCount = function (objRefCount, item)
	-- only count reference types (tables)
	if type(item) == "table" then
		-- Increase ref count
		if objRefCount[item] then
			objRefCount[item] = objRefCount[item] + 1;
		else
			objRefCount[item] = 1;
			-- If first encounter, traverse
			for k, v in pairs(item) do
				refCount(objRefCount, k);
				refCount(objRefCount, v);
			end;
		end;
	end;
end;

-- Format items for the purpose of restoring
writers = {
	["nil"] = function (file, item)
        file:write("nil");
    end;
	["number"] = function (file, item)
        file:write(tostring(item));
    end;
	["string"] = function (file, item)
        file:write(string.format("%q", item));
    end;
	["boolean"] = function (file, item)
        if item then
            file:write("true");
        else
            file:write("false");
        end
    end;
	["table"] = function (file, item, level, objRefNames)
        local refIdx = objRefNames[item];
        if refIdx then
            -- Table with multiple references
            file:write("multiRefObjects["..refIdx.."]");
        else
            -- Single use table
            file:write("{\r\n");
            for k, v in pairs(item) do
                writeIndent(file, level+1);
                file:write("[");
                write(file, k, level+1, objRefNames);
                file:write("] = ");
                write(file, v, level+1, objRefNames);
                file:write(";\r\n");
            end
            writeIndent(file, level);
            file:write("}");
        end;
    end;
	["function"] = function (file, item)
        -- Does only work for "normal" functions, not those
        -- with upvalues or c functions
        local dInfo = debug.getinfo(item, "uS");
        if dInfo.nups > 0 then
            file:write("nil --[[functions with upvalue not supported]]");
        elseif dInfo.what ~= "Lua" then
            file:write("nil --[[non-lua function not supported]]");
        else
            local r, s = pcall(string.dump,item);
            if r then
                file:write(string.format("loadstring(%q)", s));
            else
                file:write("nil --[[function could not be dumped]]");
            end
        end
    end;
	["thread"] = function (file, item)
        file:write("nil --[[thread]]\r\n");
    end;
	["userdata"] = function (file, item)
        file:write("nil --[[userdata]]\r\n");
    end;
}

-- Creates the user's writable configuration from the current defaults. The
-- packaged defaults are never modified at runtime.
local function recreateConfigFiles(locationIndex, defaults)
    if not defaults then return nil end

    -- Do not keep a reference to the shipped/default table. A new player must
    -- receive an independent, writable copy in Zomboid/Lua as a .cfg file.
    local fileContents = MinimalDisplayBarsB4220.deepcopy(defaults)
    MinimalDisplayBarsB4220.io_persistence.store(
        MinimalDisplayBarsB4220.configFileLocations[locationIndex], 
        MinimalDisplayBarsB4220.MOD_ID, 
        fileContents)
    return fileContents
end


--*********************************************
-- Custom Tables
local DEFAULT_SETTINGS = {
    
    ["moveBarsTogether"] = false,
    
    ["menu"] = {
        ["x"] = 70,
        ["y"] = 15,
        ["width"] = 15,
        ["height"] = 15,
        ["l"] = 3,
        ["t"] = 3,
        ["r"] = 3,
        ["b"] = 3,
        ["color"] = {red = (255 / 255), 
                    green = (255 / 255), 
                    blue = (255 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = true,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["hp"] = {
        ["x"] = 70,
        ["y"] = 30,
        ["width"] = 25,
        ["height"] = 200,
        ["l"] = 3,
        ["t"] = 3,
        ["r"] = 3,
        ["b"] = 3,
        ["color"] = {red = (0 / 255), 
                    green = (128 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["hunger"] = {
        ["x"] = 70 + (30 * 1),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (255 / 255), 
                    green = (255 / 255), 
                    blue = (10 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Status_Hunger.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["thirst"] = {
        ["x"] = 70 + (30 * 1) + (25 * 1),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (173 / 255), 
                    green = (216 / 255), 
                    blue = (230 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Status_Thirst.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["endurance"] = {
        ["x"] = 70 + (30 * 1) + (25 * 2),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (244 / 255), 
                    green = (244 / 255), 
                    blue = (244 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Status_DifficultyBreathing.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["fatigue"] = {
        ["x"] = 70 + (30 * 1) + (25 * 3),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (240 / 255), 
                    green = (240 / 255), 
                    blue = (170 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Mood_Sleepy.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["boredomlevel"] = {
        ["x"] = 70 + (30 * 1) + (25 * 4),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (170 / 255), 
                    green = (170 / 255), 
                    blue = (170 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Mood_Bored.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["unhappynesslevel"] = {
        ["x"] = 70 + (30 * 1) + (25 * 5),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (128 / 255), 
                    green = (128 / 255), 
                    blue = (255 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Mood_Sad.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["temperature"] = {
        ["x"] = 70 + (30 * 1) + (25 * 6),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (0 / 255), 
                    green = (255 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Status_TemperatureHot.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["calorie"] = {
        ["x"] = 70 + (30 * 1) + (25 * 7),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255), 
                    green = (255 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/TraitNutritionist.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["stress"] = {
        ["x"] = 70 + (30 * 1) + (25 * 8),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (255 / 255),
                    green = (102 / 255),
                    blue = (102 / 255),
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Mood_Stressed.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["sickness"] = {
        ["x"] = 70 + (30 * 1) + (25 * 9),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (154 / 255),
                    green = (205 / 255),
                    blue = (50 / 255),
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Mood_Ill.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["carbohydrates"] = {
        ["x"] = 70 + (30 * 1) + (25 * 10),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255),
                    green = (255 / 255),
                    blue = (0 / 255),
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = false,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/TraitNutritionist.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["proteins"] = {
        ["x"] = 70 + (30 * 1) + (25 * 11),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255),
                    green = (255 / 255),
                    blue = (0 / 255),
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = false,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/TraitNutritionist.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["fats"] = {
        ["x"] = 70 + (30 * 1) + (25 * 12),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255),
                    green = (255 / 255),
                    blue = (0 / 255),
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = false,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/TraitNutritionist.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["corpse_sickness"] = {
        ["x"] = 70 + (30 * 1) + (25 * 13),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (154 / 255),
                    green = (205 / 255),
                    blue = (50 / 255),
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = false,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Mood_Nauseous.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
    ["discomfort"] = {
        ["x"] = 70 + (30 * 1) + (25 * 14),
        ["y"] = 30,
        ["width"] = 20,
        ["height"] = 200,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (255 / 255),
                    green = (165 / 255),
                    blue = (0 / 255),
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = false,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/32/Mood_Discomfort.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
    },
        
    
}

-- Status bars start below vanilla inventory windows and mouse-over UI.  Keep
-- only the small Menu bar on top so Reset All remains available regardless of
-- where the player placed the rest of the HUD.  Existing configurations are
-- migrated once, after which the user can freely use the foreground toggle.
local HUD_LAYER_MIGRATION_VERSION = 1

local function migrateHudLayerPriority(configTable)
    if not configTable then return false end

    local changed = false
    local menuSettings = configTable["menu"]
    if type(menuSettings) == "table" and menuSettings["alwaysBringToTop"] ~= true then
        menuSettings["alwaysBringToTop"] = true
        changed = true
    end

    if configTable["hudLayerMigrationVersion"] ~= HUD_LAYER_MIGRATION_VERSION then
        for idName, settings in pairs(configTable) do
            if idName ~= "menu" and type(settings) == "table" and settings["alwaysBringToTop"] ~= false then
                settings["alwaysBringToTop"] = false
                changed = true
            end
        end
        configTable["hudLayerMigrationVersion"] = HUD_LAYER_MIGRATION_VERSION
        changed = true
    end

    return changed
end

DEFAULT_SETTINGS["hudLayerMigrationVersion"] = HUD_LAYER_MIGRATION_VERSION

-- Build 42.20 stores the current Moodle artwork in media/ui/Moodles/32.
-- Update only the old shipped paths, leaving any manually customised path intact.
local B42_MOODLE_IMAGE_PATHS = {
    ["media/ui/Moodles/Moodle_Icon_Hungry.png"] = "media/ui/Moodles/32/Status_Hunger.png",
    ["media/ui/Moodles/Moodle_Icon_Thirsty.png"] = "media/ui/Moodles/32/Status_Thirst.png",
    ["media/ui/Moodles/Moodle_Icon_Endurance.png"] = "media/ui/Moodles/32/Status_DifficultyBreathing.png",
    ["media/ui/Moodles/32/Mood_Exhausted.png"] = "media/ui/Moodles/32/Status_DifficultyBreathing.png",
    ["media/ui/Moodles/Moodle_Icon_Tired.png"] = "media/ui/Moodles/32/Mood_Sleepy.png",
    ["media/ui/Moodles/Moodle_Icon_Bored.png"] = "media/ui/Moodles/32/Mood_Bored.png",
    ["media/ui/Moodles/Moodle_Icon_Unhappy.png"] = "media/ui/Moodles/32/Mood_Sad.png",
    ["media/ui/MDBTemperature.png"] = "media/ui/Moodles/32/Status_TemperatureHot.png",
}

local function migrateB42MoodleImagePaths(configTable)
    if not configTable then return false end

    local changed = false
    for _, settings in pairs(configTable) do
        if type(settings) == "table" then
            local replacement = B42_MOODLE_IMAGE_PATHS[settings["imageName"]]
            if replacement then
                settings["imageName"] = replacement
                changed = true
            end
        end
    end

    -- 4.3.5-b42.20 briefly assigned the Hunger Moodle to Calories. Restore
    -- the original Nutritionist icon without touching any other icon choice.
    local calorieSettings = configTable["calorie"]
    if calorieSettings and calorieSettings["imageName"] == "media/ui/Moodles/32/Status_Hunger.png" then
        calorieSettings["imageName"] = "media/ui/TraitNutritionist.png"
        changed = true
    end

    return changed
end


--**********************************************
-- Vanilla Functions


--*************************************
-- Custom Functions

MinimalDisplayBarsB4220.displayBars = {} -- This should store all the display bars as they are created.
MinimalDisplayBarsB4220.displayBarMenus = {} -- Stores the menu box so it can be recreated after respawn.
MinimalDisplayBarsB4220.moveBarsTogetherPanels = {} -- Keeps the group anchor stable while bars are hidden or shown.

-- Build 42 replaced the individual Stats getters with a typed generic getter.
local function getStat(isoPlayer, stat)
    if not isoPlayer then return 0 end

    local stats = isoPlayer:getStats()
    if not stats then return 0 end

    local value = stats:get(stat)
    if type(value) ~= "number" or value ~= value then return 0 end

    return value
end

-- All display-bar colours use normalised RGB components (0.0-1.0).
-- Keep these helpers before their callers: Lua local functions are only
-- visible after their declaration.
local function rgbToHsv(r, g, b)
    local maxValue = math.max(r, g, b)
    local minValue = math.min(r, g, b)
    local difference = maxValue - minValue
    local hue = 0

    if difference ~= 0 then
        if maxValue == r then
            hue = ((g - b) / difference) % 6
        elseif maxValue == g then
            hue = (b - r) / difference + 2
        else
            hue = (r - g) / difference + 4
        end
        hue = hue / 6
    end

    local saturation = maxValue == 0 and 0 or difference / maxValue
    return {hue, saturation, maxValue}
end

local function hsvToRgb(h, s, v)
    local segment = math.floor(h * 6)
    local fraction = h * 6 - segment
    local low = v * (1 - s)
    local falling = v * (1 - fraction * s)
    local rising = v * (1 - (1 - fraction) * s)

    segment = segment % 6
    if segment == 0 then return {v, rising, low} end
    if segment == 1 then return {falling, v, low} end
    if segment == 2 then return {low, v, rising} end
    if segment == 3 then return {low, falling, v} end
    if segment == 4 then return {rising, low, v} end
    return {v, low, falling}
end

--==========================
-- Health Functions
local function calcHealth(value)
    return value / 100 
end
local function getHealth(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getBodyDamage():getHealth()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcHealth( isoPlayer:getBodyDamage():getHealth() ) 
        end
    end
end

local hpTickCounter = 0
local function onTickHP()
    hpTickCounter = hpTickCounter + 1
end

local hpWarningFlash = {}
local onPlayerUpdateTick = 0
local function onPlayerUpdateCheckBodyDamage(isoPlayer)
    
    if onPlayerUpdateTick < 15 then 
        onPlayerUpdateTick = onPlayerUpdateTick + 1
        return;
    else
        onPlayerUpdateTick = 0
    end
    
    local bodyParts = isoPlayer:getBodyDamage():getBodyParts();
    local size = bodyParts:size()-1;
    for i=0, size do
        local bodyPart = bodyParts:get(i);
        
        local bandageLife = bodyPart:getBandageLife();
        local bandaged = bodyPart:bandaged();
        local stitched = bodyPart:stitched();
        local isSplint = bodyPart:isSplint();
        local bitten = bodyPart:bitten();
        local bleeding = bodyPart:bleeding();
        local scratched = bodyPart:scratched();
        local deepWounded = bodyPart:isDeepWounded();
        local burnTime = bodyPart:getBurnTime();
        local fractureTime = bodyPart:getFractureTime();
        local haveBullet = bodyPart:haveBullet();
        if --(bandageLife <= 0 and bandaged)
                (deepWounded and not stitched) 
                or (bitten and not bandaged) 
                or (bleeding and not bandaged) 
                or (scratched and not bandaged) 
                or (deepWounded and not bandaged) 
                or (burnTime > 0.0 and not bandaged) 
                or (fractureTime > 0.0 and not isSplint)
                or (haveBullet) then
            hpWarningFlash[isoPlayer] = true;
            break;
        end
        
        if i >= size then 
            hpWarningFlash[isoPlayer] = false; 
        end
    end
    
    local moodles = isoPlayer:getMoodles()
    local poison = getStat(isoPlayer, CharacterStat.POISON)
    if isoPlayer:getBodyDamage():getNumPartsBleeding() >= 1
            --or isoPlayer:getBodyDamage():getInfectionLevel() >= 31.7 
            --or isoPlayer:getBodyDamage():getFakeInfectionLevel() >= 31.7
            or moodles:getMoodleLevel(MoodleType.SICK) == 4
            or moodles:getMoodleLevel(MoodleType.THIRST) == 4
            or moodles:getMoodleLevel(MoodleType.HUNGRY) == 4 
            or (poison > 10.0 and moodles:getMoodleLevel(MoodleType.SICK) >= 1)
            or isoPlayer:isOnFire()
            or moodles:getMoodleLevel(MoodleType.BLEEDING) >= 1 then
        hpWarningFlash[isoPlayer] = true;
    end
    
    return;
end

local function getColorHealth(isoPlayer) 
    local hpRatio = 0
    
    if not isoPlayer:isDead() then
        hpRatio = getHealth(isoPlayer) 
    end
    
    local color
    if 0 <= hpRatio and hpRatio < 1 then
        color = { red = (255 / 255), 
                    green = (255 / 255) * (math.pow(0.1, 1 - hpRatio)), 
                    blue = (10 / 255) * (1 - hpRatio), 
                    alpha = 0.75 }
    elseif hpRatio < 0 then
        color = { red = (255 / 255), 
                    green = (0 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75 }
    else
        local r = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["red"]
        local g = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["green"]
        local b = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["blue"]
        local a = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["alpha"]
        color = { red = ( r ), 
                    green = ( g ), 
                    blue = ( b ), 
                    alpha = a }
    end
    
    if hpWarningFlash[isoPlayer] then
        local hsv = rgbToHsv(color.red, color.green, color.blue)
        local sat = 0.5 * math.sin(hpTickCounter / 30 * math.pi) + 0.5
        
        local rgb = hsvToRgb(hsv[1], sat, hsv[3])
        --print(rgb[1] .. " " .. rgb[2] .. " " .. rgb[3])
        color.red = rgb[1]
        color.green = rgb[2]
        color.blue = rgb[3]
    end
    
    --print(hpWarningFlash[isoPlayer])
    
    return color
end

-- Hunger Functions
local function calcHunger(value)
    return 1 - value
end
local function getHunger(isoPlayer, useRealValue) 
    if useRealValue then
        return getStat(isoPlayer, CharacterStat.HUNGER)
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcHunger(getStat(isoPlayer, CharacterStat.HUNGER))
        end
    end
end

local function getColorHunger(isoPlayer) 
    local color
    color = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["hunger"]["color"]
    return color
end

-- Thirst Functions
local function calcThirst(value)
    return 1 - value
end
local function getThirst(isoPlayer, useRealValue) 
    if useRealValue then
        return getStat(isoPlayer, CharacterStat.THIRST)
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcThirst(getStat(isoPlayer, CharacterStat.THIRST))
        end
    end
end

local function getColorThirst(isoPlayer) 
    local color
    color = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["thirst"]["color"]
    return color
end

-- Endurance Functions
local function calcEndurance(value)
    return value
end
local function getEndurance(isoPlayer, useRealValue) 
    if useRealValue then
        return getStat(isoPlayer, CharacterStat.ENDURANCE)
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcEndurance(getStat(isoPlayer, CharacterStat.ENDURANCE))
        end
    end
end

local function getColorEndurance(isoPlayer) 
    local color
    color = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["endurance"]["color"]
    return color
end

-- Fatigue Functions
local function calcFatigue(value)
    return value
end

-- The stats object can briefly report zero during an MP player hand-off, while
-- the synchronized tired Moodle is already available.  This fallback affects
-- only the bar readout; it never writes to Stats or to the player.
local function getSyncedFatigue(isoPlayer)
    local fatigue = getStat(isoPlayer, CharacterStat.FATIGUE)
    if fatigue > 0 then return fatigue end

    local moodles = isoPlayer and isoPlayer:getMoodles()
    local tiredLevel = moodles and moodles:getMoodleLevel(MoodleType.TIRED) or 0
    if tiredLevel > 0 then
        return tiredLevel / 4
    end

    return fatigue
end

local function getFatigue(isoPlayer, useRealValue) 
    if useRealValue then
        return getSyncedFatigue(isoPlayer)
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcFatigue(getSyncedFatigue(isoPlayer))
        end
    end
end

local function getColorFatigue(isoPlayer) 
    local color
    color = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["fatigue"]["color"]
    return color
end

-- BoredomLevel Functions
local function calcBoredomLevel(value)
    return value / 100
end
local function getBoredomLevel(isoPlayer, useRealValue)
    if useRealValue then
        return getStat(isoPlayer, CharacterStat.BOREDOM)
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcBoredomLevel(getStat(isoPlayer, CharacterStat.BOREDOM))
        end
    end
end

local function getColorBoredomLevel(isoPlayer, useRealValue) 
    local color
    color = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["boredomlevel"]["color"]
    return color
end

-- UnhappynessLevel (UnhappinessLevel) Functions
local function calcUnhappynessLevel(value)
    --print(value)
    return value / 100
end
local function getUnhappynessLevel(isoPlayer, useRealValue) 
    if useRealValue then
        return getStat(isoPlayer, CharacterStat.UNHAPPINESS)
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcUnhappynessLevel(getStat(isoPlayer, CharacterStat.UNHAPPINESS))
        end
    end
end

local function getColorUnhappynessLevel(isoPlayer) 
    local color
    color = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["unhappynesslevel"]["color"]
    return color
end

-- Stress Functions
local function calcStress(value)
    return value
end

local function getStress(isoPlayer, useRealValue)
    local stress = getStat(isoPlayer, CharacterStat.STRESS)
    if useRealValue then
        return stress
    elseif isoPlayer:isDead() then
        return -1
    else
        return calcStress(stress)
    end
end

local function getColorStress(isoPlayer)
    return MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["stress"]["color"]
end

-- Sickness Functions
local function calcSickness(value)
    return value
end

local function getSickness(isoPlayer, useRealValue)
    local sickness = getStat(isoPlayer, CharacterStat.SICKNESS)
    if useRealValue then
        return sickness
    elseif isoPlayer:isDead() then
        return -1
    else
        return calcSickness(sickness)
    end
end

local function getColorSickness(isoPlayer)
    return MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["sickness"]["color"]
end

-- Corpse Sickness is tracked separately from the regular Sickness stat in
-- Build 42.  It uses FOOD_SICKNESS on a 0-100 scale.
local function calcCorpseSickness(value)
    return value / 100
end

local function getCorpseSickness(isoPlayer, useRealValue)
    local sickness = getStat(isoPlayer, CharacterStat.FOOD_SICKNESS)
    if useRealValue then
        return sickness
    elseif isoPlayer:isDead() then
        return -1
    else
        return calcCorpseSickness(sickness)
    end
end

local function getColorCorpseSickness(isoPlayer)
    return MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["corpse_sickness"]["color"]
end

-- Discomfort has its own 0-100 character stat. It is not part of Pain or
-- the normal Sickness stat, so expose it as a dedicated optional bar.
local function calcDiscomfort(value)
    return value / 100
end

local function getDiscomfort(isoPlayer, useRealValue)
    local discomfort = getStat(isoPlayer, CharacterStat.DISCOMFORT)
    if useRealValue then
        return discomfort
    elseif isoPlayer:isDead() then
        return -1
    else
        return calcDiscomfort(discomfort)
    end
end

local function getColorDiscomfort(isoPlayer)
    return MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["discomfort"]["color"]
end

-- Temperature Functions
local maxTempLim = 41  -- 41.0 C
local minTempLim = 19  -- 19.0 C
local function calcTemperature(value)
    return (value - minTempLim) / (maxTempLim - minTempLim)
end
local function getTemperature(isoPlayer, useRealValue) 
    local temperature = isoPlayer:getBodyDamage():getThermoregulator():getCoreTemperature()
    if useRealValue then
        return temperature
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcTemperature(temperature)
        end
    end
end

local function getColorTemperature(isoPlayer) 
    local tempRatio = getTemperature(isoPlayer) 
    
    local color
    if calcTemperature(20.0) <= tempRatio and tempRatio < calcTemperature(36.5) then
        local hue = (180 + (80 - 80 * ( (tempRatio - calcTemperature(20.0)) / (calcTemperature(36.5) - calcTemperature(minTempLim)) ))) / 360
        local rgb = hsvToRgb(hue, 1, 1)
        --print(hue * 360)
        --print(rgb[1].." "..rgb[2].." "..rgb[3])
        color = { red = rgb[1], 
                    green = rgb[2], 
                    blue = rgb[3], 
                    alpha = 0.75 }
    elseif calcTemperature(36.5) <= tempRatio and tempRatio <= calcTemperature(37.5) then
        local hue = (60 + (120 - 120 * ( (tempRatio - calcTemperature(36.5)) / (calcTemperature(37.5) - calcTemperature(36.5)) ))) / 360
        local rgb = hsvToRgb(hue, 1, 1)
        --print(hue * 360)
        --print(rgb[1].." "..rgb[2].." "..rgb[3])
        color = { red = rgb[1], 
                    green = rgb[2], 
                    blue = rgb[3], 
                    alpha = 0.75 }
    elseif calcTemperature(37.5) < tempRatio and tempRatio <= calcTemperature(40.0) then
        local hue = (0 + (60 - 60 * ( (tempRatio - calcTemperature(37.5)) / (calcTemperature(40.0) - calcTemperature(37.5)) ))) / 360
        local rgb = hsvToRgb(hue, 1, 1)
        --print(hue * 360)
        --print(rgb[1].." "..rgb[2].." "..rgb[3])
        color = { red = rgb[1], 
                    green = rgb[2], 
                    blue = rgb[3], 
                    alpha = 0.75 }
    else
        color = { red = (255 / 255), 
                    green = (255 / 255), 
                    blue = (255 / 255), 
                    alpha = 0.75 }
    end
    
    return color
end

-- Calorie Functions
local maxCalorie = 3700  -- 3700 calories
local minCalorie = -2200  -- -2200 calories
local function calcCalorie(value)
    return (value - minCalorie) / (maxCalorie - minCalorie)
end
local function getCalorie(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getNutrition():getCalories()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcCalorie( isoPlayer:getNutrition():getCalories() )
        end
    end
end

local function getColorCalorie(isoPlayer) 
    local color
    color = MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["calorie"]["color"]
    return color
end

-- Macronutrient Functions
-- Build 42 clamps carbohydrates, proteins, and lipids to this shared range.
local maxMacronutrient = 1000
local minMacronutrient = -500

local function calcMacronutrient(value)
    return (value - minMacronutrient) / (maxMacronutrient - minMacronutrient)
end

local function getCarbohydrates(isoPlayer, useRealValue)
    local value = isoPlayer:getNutrition():getCarbohydrates()
    if useRealValue then return value end
    if isoPlayer:isDead() then return -1 end
    return calcMacronutrient(value)
end

local function getProteins(isoPlayer, useRealValue)
    local value = isoPlayer:getNutrition():getProteins()
    if useRealValue then return value end
    if isoPlayer:isDead() then return -1 end
    return calcMacronutrient(value)
end

local function getFats(isoPlayer, useRealValue)
    local value = isoPlayer:getNutrition():getLipids()
    if useRealValue then return value end
    if isoPlayer:isDead() then return -1 end
    return calcMacronutrient(value)
end

local function getColorCarbohydrates(isoPlayer)
    return MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["carbohydrates"]["color"]
end

local function getColorProteins(isoPlayer)
    return MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["proteins"]["color"]
end

local function getColorFats(isoPlayer)
    return MinimalDisplayBarsB4220.configTables[isoPlayer:getPlayerNum() + 1]["fats"]["color"]
end



--============================
-- Moodlet Threshold Tables
local function getMoodletThresholdTables() 
    local t = {
        ["hunger"] = {
            [1] = calcHunger(0.15), -- 0.15 / 1.00
            [2] = calcHunger(0.25),
            [3] = calcHunger(0.45),
            [4] = calcHunger(0.70),
        },
        ["thirst"] = {
            [1] = calcThirst(0.12), -- 0.12 / 1.00
            [2] = calcThirst(0.25),
            [3] = calcThirst(0.70),
            [4] = calcThirst(0.84),
        },
        ["endurance"] = {
            [1] = calcEndurance(0.10), -- 0.10 / 1.00
            [2] = calcEndurance(0.25),
            [3] = calcEndurance(0.50),
            [4] = calcEndurance(0.75),
        },
        ["fatigue"] = {
            [1] = calcFatigue(0.60), -- 0.60 / 1.00
            [2] = calcFatigue(0.70),
            [3] = calcFatigue(0.80),
            [4] = calcFatigue(0.90),
        },
        ["boredomlevel"] = {
            [1] = calcBoredomLevel(25), -- 25/100
            [2] = calcBoredomLevel(50),
            [3] = calcBoredomLevel(75),
            [4] = calcBoredomLevel(90),
        },
        ["unhappynesslevel"] = {
            [1] = calcUnhappynessLevel(20), -- 20/100
            [2] = calcUnhappynessLevel(45),
            [3] = calcUnhappynessLevel(60),
            [4] = calcUnhappynessLevel(80),
        },
        ["stress"] = {
            [1] = calcStress(0.25),
            [2] = calcStress(0.50),
            [3] = calcStress(0.75),
            [4] = calcStress(0.90),
        },
        ["sickness"] = {
            [1] = calcSickness(0.25),
            [2] = calcSickness(0.50),
            [3] = calcSickness(0.75),
            [4] = calcSickness(0.90),
        },
        ["corpse_sickness"] = {
            [1] = calcCorpseSickness(25),
            [2] = calcCorpseSickness(50),
            [3] = calcCorpseSickness(75),
            [4] = calcCorpseSickness(90),
        },
        ["discomfort"] = {
            [1] = calcDiscomfort(25),
            [2] = calcDiscomfort(50),
            [3] = calcDiscomfort(75),
            [4] = calcDiscomfort(90),
        },
        ["temperature"] = {
            [1] = calcTemperature(30.0), -- 30.0 C (MIN: 19.0 C, MAX: 41.0 C)
            [2] = calcTemperature(25.0),
            [3] = calcTemperature(36.5),
            [4] = calcTemperature(37.5),
            [5] = calcTemperature(39.0),
        },
            
            
    }
    
    return t
end


function MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(playerIndex)
    local displayBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
    if not displayBars then return end

    local barHP = displayBars["hp"]
    if not barHP then return end

    local moveBarsTogetherRectangle = MinimalDisplayBarsB4220.moveBarsTogetherPanels[playerIndex]

    if barHP.moveBarsTogether then
        -- Do not recreate the hidden group anchor when a bar is shown or
        -- hidden. Recreating it changes its origin and causes every child
        -- bar to snap back when Move Bars Together is enabled.
        if not moveBarsTogetherRectangle then
            for _, bar in pairs(displayBars) do
                if bar and bar.parent then
                    moveBarsTogetherRectangle = bar.parent
                    break
                end
            end
        end

        if not moveBarsTogetherRectangle then
            local minX = 1000000
            local maxX = 0
            local minY = 1000000
            local maxY = 0
            local hasBars = false

            -- Include intentionally hidden bars in the initial bounds, but
            -- use their current coordinates so an existing custom layout is
            -- never replaced with defaults.
            for _, bar in pairs(displayBars) do
                if bar then
                    if bar.x < minX then minX = bar.x end
                    if bar.x + bar:getWidth() > maxX then maxX = bar.x + bar:getWidth() end
                    if bar.y < minY then minY = bar.y end
                    if bar.y + bar:getHeight() > maxY then maxY = bar.y + bar:getHeight() end
                    hasBars = true
                end
            end

            if not hasBars then return end

            moveBarsTogetherRectangle = ISPanel:new(
                minX,
                minY,
                maxX - minX,
                maxY - minY)
            moveBarsTogetherRectangle:instantiate()
            moveBarsTogetherRectangle:addToUIManager()
            moveBarsTogetherRectangle:setVisible(false)
        end

        MinimalDisplayBarsB4220.moveBarsTogetherPanels[playerIndex] = moveBarsTogetherRectangle

        for _, bar in pairs(displayBars) do
            if bar then
                if bar.moveBarsTogether then
                    bar.parent = moveBarsTogetherRectangle
                    bar.parentOldX = nil
                    bar.parentOldY = nil
                else
                    bar.parent = nil
                end
            end
        end
        return
    end

    -- The option was turned off: detach all bars and remove the one retained
    -- group anchor. The next enable creates a new anchor from the current
    -- user layout.
    if not moveBarsTogetherRectangle then moveBarsTogetherRectangle = barHP.parent end
    for _, bar in pairs(displayBars) do
        if bar then
            if not moveBarsTogetherRectangle and bar.parent then
                moveBarsTogetherRectangle = bar.parent
            end
            bar.parent = nil
            bar.parentOldX = nil
            bar.parentOldY = nil
        end
    end
    if moveBarsTogetherRectangle then
        moveBarsTogetherRectangle:removeFromUIManager()
    end
    MinimalDisplayBarsB4220.moveBarsTogetherPanels[playerIndex] = nil
end

-- The group panel is only a drag anchor. Recalculate it from the bars after
-- applying an optional layout preset, rather than allowing a previous anchor
-- position to offset the newly selected layout.
function MinimalDisplayBarsB4220.refreshMoveBarsTogetherAnchor(playerIndex)
    local groupAnchor = MinimalDisplayBarsB4220.moveBarsTogetherPanels[playerIndex]
    local displayBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
    if not groupAnchor or not displayBars then return end

    local minX = nil
    local minY = nil
    for _, bar in pairs(displayBars) do
        if bar and bar.parent == groupAnchor then
            minX = not minX and bar.x or math.min(minX, bar.x)
            minY = not minY and bar.y or math.min(minY, bar.y)
        end
    end

    if minX ~= nil then groupAnchor:setX(minX) end
    if minY ~= nil then groupAnchor:setY(minY) end
end

local function resetBar(bar)
    if not bar then return end

    local settings = MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]
    local defaults = DEFAULT_SETTINGS[bar.idName]
    if not settings or not defaults then return end

    for key in pairs(settings) do
        -- Preserve the player's display and interaction choices while
        -- restoring the bar's geometry, colour, and icon defaults.
        if key ~= "isMovable"
                and key ~= "isResizable"
                and key ~= "alwaysBringToTop"
                and key ~= "showMoodletThresholdLines"
                and key ~= "isCompact"
                and key ~= "showImage" then
            settings[key] = MinimalDisplayBarsB4220.deepcopy(defaults[key])
        end
    end

    bar:resetToConfigTable()
    MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(bar.playerIndex)
    MinimalDisplayBarsB4220.io_persistence.store(
        bar.fileSaveLocation,
        MinimalDisplayBarsB4220.MOD_ID,
        MinimalDisplayBarsB4220.configTables[bar.coopNum])
end

-- Apply only geometry from an optional layout preset. Visibility, colours,
-- icons, Move Bars Together, and all other player settings stay unchanged.
local LAYOUT_PRESET_KEYS = {"x", "y", "width", "height", "isVertical", "l", "t", "r", "b"}

local function applyLayoutPreset(generic_bar, presetFileName)
    if not generic_bar then return false end

    local preset = MinimalDisplayBarsB4220.io_persistence.load(
        presetFileName,
        MinimalDisplayBarsB4220.MOD_ID)
    if type(preset) ~= "table" then return false end

    local playerConfig = MinimalDisplayBarsB4220.configTables[generic_bar.coopNum]
    if not playerConfig then return false end

    for idName, presetSettings in pairs(preset) do
        local currentSettings = playerConfig[idName]
        if type(presetSettings) == "table" and type(currentSettings) == "table" then
            for _, key in ipairs(LAYOUT_PRESET_KEYS) do
                if presetSettings[key] ~= nil then
                    currentSettings[key] = MinimalDisplayBarsB4220.deepcopy(presetSettings[key])
                end
            end
        end
    end

    local menuBar = MinimalDisplayBarsB4220.displayBarMenus[generic_bar.playerIndex]
    if menuBar then menuBar:resetToConfigTable() end

    local displayBars = MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]
    if displayBars then
        for _, bar in pairs(displayBars) do
            if bar then bar:resetToConfigTable() end
        end
    end

    MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
    MinimalDisplayBarsB4220.refreshMoveBarsTogetherAnchor(generic_bar.playerIndex)
    MinimalDisplayBarsB4220.io_persistence.store(
        generic_bar.fileSaveLocation,
        MinimalDisplayBarsB4220.MOD_ID,
        playerConfig)
    return true
end

local function toggleMovable(bar)
    if bar.moveWithMouse then
        bar.moveWithMouse = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["isMovable"] = false
    else
        bar.moveWithMouse = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["isMovable"] = true
    end
end

local function toggleResizeable(bar)
    if bar.resizeWithMouse then
        bar.resizeWithMouse = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["isResizable"] = false
    else
        bar.resizeWithMouse = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["isResizable"] = true
    end
end

local function toggleAlwaysBringToTop(bar)
    if bar.alwaysBringToTop then
        bar.alwaysBringToTop = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["alwaysBringToTop"] = false
    else
        bar.alwaysBringToTop = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["alwaysBringToTop"] = true
    end

    if bar.applyLayerPriority then
        bar:applyLayerPriority()
    end
end

local function toggleMoodletThresholdLines(bar)
    if bar.showMoodletThresholdLines then
        bar.showMoodletThresholdLines = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["showMoodletThresholdLines"] = false
    else
        bar.showMoodletThresholdLines = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["showMoodletThresholdLines"] = true
    end
end

local function toggleCompact(bar)
    if bar.isCompact then
        bar.isCompact = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["isCompact"] = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["height"] = 200
    else
        bar.isCompact = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["isCompact"] = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["height"] = 75
    end
end

local function toggleMoveBarsTogether(bar)
    if bar.moveBarsTogether then
        bar.moveBarsTogether = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum]["moveBarsTogether"] = false
    else
        bar.moveBarsTogether = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum]["moveBarsTogether"] = true
    end
    --bar:resetToConfigTable()
end

local function toggleShowImage(bar)
    if bar.showImage then
        bar.showImage = false
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["showImage"] = false
    else
        bar.showImage = true
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["showImage"] = true
    end
    --bar:resetToConfigTable() 
end

-- ContextMenu
local contextMenu = nil
MinimalDisplayBarsB4220.displayBarPropertiesPanel = nil
local colorPicker = nil

local function setHeightWidth(bar)
    
    if not bar then return end
    
    if MinimalDisplayBarsB4220.displayBarPropertiesPanel and MinimalDisplayBarsB4220.displayBarPropertiesPanel.close then 
        MinimalDisplayBarsB4220.displayBarPropertiesPanel:close() 
    end
    
    MinimalDisplayBarsB4220.displayBarPropertiesPanel = 
        ISDisplayBarPropertiesPanelB4220:new(
            bar:getX(), 
            bar:getY(), 
            bar)
    
    bar.displayBarPropertiesPanel = MinimalDisplayBarsB4220.displayBarPropertiesPanel
    MinimalDisplayBarsB4220.displayBarPropertiesPanel:initialise()
    MinimalDisplayBarsB4220.displayBarPropertiesPanel:addToUIManager()
    
    local screenHeight = getCore():getScreenHeight()
    local bottom = (MinimalDisplayBarsB4220.displayBarPropertiesPanel.y + MinimalDisplayBarsB4220.displayBarPropertiesPanel.height)
    if bottom > screenHeight then
        MinimalDisplayBarsB4220.displayBarPropertiesPanel:setY(MinimalDisplayBarsB4220.displayBarPropertiesPanel.y - (bottom - screenHeight))
    end
    
    local screenWidth = getCore():getScreenWidth()
    local right = (MinimalDisplayBarsB4220.displayBarPropertiesPanel.x + MinimalDisplayBarsB4220.displayBarPropertiesPanel.width)
    if right > screenWidth then
        MinimalDisplayBarsB4220.displayBarPropertiesPanel:setX(MinimalDisplayBarsB4220.displayBarPropertiesPanel.x - (right - screenWidth))
    end
    
    return
end

local function setBarColor(bar)
    
    if not bar then return end
    
    if colorPicker and colorPicker.close then colorPicker:close() end
    
    colorPicker = ISColorPickerMDBB4220:new(bar.x, bar.y)
    bar.colorPicker = colorPicker
    colorPicker:initialise()
    
    colorPicker:setInitialColor(
        ColorInfo.new(
            bar.color.red, 
            bar.color.green, 
            bar.color.blue, 
            bar.color.alpha)
        )
        
    colorPicker.pickedTarget = bar
    colorPicker.pickedFunc = function(bar, color, isFinalSelection)
        bar.color = 
        {
            red = color.r, 
            green = color.g, 
            blue = color.b, 
            alpha = bar.color.alpha
        }
            
        MinimalDisplayBarsB4220.configTables[bar.coopNum][bar.idName]["color"] = bar.color
        -- Dragging over the palette previews colours immediately, but only
        -- the committed mouse-up selection writes the user's .cfg.
        if isFinalSelection then
            MinimalDisplayBarsB4220.io_persistence.store(
                bar.fileSaveLocation,
                MinimalDisplayBarsB4220.MOD_ID,
                MinimalDisplayBarsB4220.configTables[bar.coopNum])
        end
        
        colorPicker:close()
        
        return
    end
        
    local screenHeight = getCore():getScreenHeight()
    local bottom = (colorPicker.y + colorPicker.height)
    if bottom > screenHeight then
        colorPicker.y = (colorPicker.y - (bottom - screenHeight))
    end
    
    local screenWidth = getCore():getScreenWidth()
    local right = (colorPicker.x + colorPicker.width)
    if right > screenWidth then
        colorPicker.x = (colorPicker.x - (right - screenWidth))
    end
    
    colorPicker:addToUIManager()
    
    return
end

-- prevent UI from covering this context menu and color picker
local contextMenuTicks = 0

local function preventContextCoverup()
    
    contextMenuTicks = contextMenuTicks + 1
    
    if contextMenuTicks >= 16 then
        contextMenuTicks = 0
        
        -- Prevent minimal display bars from covering context and other clicked UI.
        if contextMenu and not contextMenu:isVisible() then
            contextMenu = nil
        elseif MinimalDisplayBarsB4220.displayBarPropertiesPanel and not MinimalDisplayBarsB4220.displayBarPropertiesPanel:isVisible() then
            MinimalDisplayBarsB4220.displayBarPropertiesPanel = nil
        elseif colorPicker and not colorPicker:isVisible() then
            colorPicker = nil
        end
        
    end
    
end



-- Existing .cfg files can predate newly added bars. Make visibility controls
-- self-healing so a user can enable a new hidden bar immediately, even if a
-- previous load did not yet add that bar's settings to the configuration.
local function ensureDisplayBarSettings(bar)
    if not bar then return nil end

    local playerConfig = MinimalDisplayBarsB4220.configTables[bar.coopNum]
    local defaults = DEFAULT_SETTINGS[bar.idName]
    if not playerConfig or not defaults then return nil end

    if not playerConfig[bar.idName] then
        playerConfig[bar.idName] = MinimalDisplayBarsB4220.deepcopy(defaults)
    end
    return playerConfig[bar.idName]
end

local function setDisplayBarVisibility(bar, isVisible)
    local settings = ensureDisplayBarSettings(bar)
    if not settings then return false end

    settings["isVisible"] = isVisible
    bar:setVisible(isVisible)
    return true
end

-- Reset All replaces the active configuration table. Every existing UI panel
-- must then point at that new table as well; otherwise a later death/respawn
-- visibility restore could read stale settings from the discarded table.
function MinimalDisplayBarsB4220.rebindUiBarsToConfig(playerIndex, coopNum)
    local playerConfig = MinimalDisplayBarsB4220.configTables[coopNum]
    if not playerConfig then return end

    local menuBar = MinimalDisplayBarsB4220.displayBarMenus[playerIndex]
    if menuBar then menuBar.configTable = playerConfig end

    local displayBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
    if displayBars then
        for _, bar in pairs(displayBars) do
            if bar then bar.configTable = playerConfig end
        end
    end
end

MinimalDisplayBarsB4220.showContextMenu = function(generic_bar, dx, dy)

	contextMenu = ISContextMenu.get(
        generic_bar.playerIndex, 
        (generic_bar.x + dx), (generic_bar.y + dy), 
        1, 1
    )
    
    -- Title
	--contextMenu:addOption("--- " .. getText("ContextMenu_MinimalDisplayBars_Title") .. " ---")
    contextMenu:addOption("--- " .. "Minimal Display Bars" .. " ---")
    
    -- Display Bar Name
    contextMenu:addOption("==/   " .. getText("ContextMenu_MinimalDisplayBars_".. generic_bar.idName .."") .. "   \\==")
    
    -- Bar HP
    local barHP = MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]["hp"]
    
    -- === Menu ===
    if generic_bar.idName == "menu" then
    
        -- Reset All
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Reset"),
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                -- Use the in-script defaults after their Build 42 migrations.
                -- The packaged file is intentionally read-only and may be an
                -- older release, so Reset All must not restore obsolete UI
                -- layer priorities.
                local defaults = DEFAULT_SETTINGS
                if not defaults then return end

                MinimalDisplayBarsB4220.configTables[generic_bar.coopNum] =
                    MinimalDisplayBarsB4220.deepcopy(defaults)
                MinimalDisplayBarsB4220.rebindUiBarsToConfig(
                    generic_bar.playerIndex,
                    generic_bar.coopNum)
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                if generic_bar then 
                    generic_bar:resetToConfigTable() end
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        bar:resetToConfigTable() 
                    end
                end
                
                MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end)

        -- Layout presets are opt-in. They modify only the selected layout
        -- fields and never replace the active user .cfg with a shipped file.
        local presetSubMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Layout_Presets")),
            presetSubMenu)
        presetSubMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Apply_Legacy_Layout"),
            generic_bar,
            function(generic_bar)
                applyLayoutPreset(generic_bar, MinimalDisplayBarsB4220.legacyLayoutPresetFileName)
            end)
        presetSubMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Apply_Current_Layout"),
            generic_bar,
            function(generic_bar)
                applyLayoutPreset(generic_bar, MinimalDisplayBarsB4220.currentLayoutPresetFileName)
            end)
        
        -- Show Display Bar
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Show_Bar")), 
            subMenu
        )
        subMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Show_All_Display_Bars"),
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        setDisplayBarVisibility(bar, true)
                    end
                end
                
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                -- recreate MoveBarsTogether panel when showing a display bar
                MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end
        )
        
        for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
            if bar then 
                local targetBar = bar
                subMenu:addOption(
                    getText("ContextMenu_MinimalDisplayBars_".. targetBar.idName ..""),
                    targetBar,
                    function(targetBar)
                        if not setDisplayBarVisibility(targetBar, true) then return end
                        
                        MinimalDisplayBarsB4220.io_persistence.store(
                            targetBar.fileSaveLocation, 
                            MinimalDisplayBarsB4220.MOD_ID, 
                            MinimalDisplayBarsB4220.configTables[targetBar.coopNum])
                        
                        -- recreate MoveBarsTogether panel when showing a display bar
                        MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(targetBar.playerIndex)
                        
                        return
                    end
                )
            end
        end
        
        -- Hide Display Bar
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Hide_Bar")), 
            subMenu
        )
        subMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Hide_All_Display_Bars"),
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        setDisplayBarVisibility(bar, false)
                    end
                end
                
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                -- recreate MoveBarsTogether panel when hiding a display bar
                MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end
        )
        
        for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
            if bar then 
                local targetBar = bar
                subMenu:addOption(
                    getText("ContextMenu_MinimalDisplayBars_".. targetBar.idName ..""),
                    targetBar,
                    function(targetBar)
                        if not setDisplayBarVisibility(targetBar, false) then return end
                        
                        MinimalDisplayBarsB4220.io_persistence.store(
                            targetBar.fileSaveLocation, 
                            MinimalDisplayBarsB4220.MOD_ID, 
                            MinimalDisplayBarsB4220.configTables[targetBar.coopNum])
                        
                        -- recreate MoveBarsTogether panel when hiding a display bar
                        MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(targetBar.playerIndex)
                        
                        return
                    end
                )
            end
        end
        
        -- Set Height/Width
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Set_HeightWidth")), 
            subMenu
        )
        for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
            if bar then 
                subMenu:addOption(
                    getText("ContextMenu_MinimalDisplayBars_".. bar.idName ..""),
                    nil,
                    function()
                        if not bar then return end
                        setHeightWidth(bar)
                    end
                )
            end
        end
        
        -- Change Display Bar Color
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Set_Color")), 
            subMenu
        )
        
        for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
            
            if bar.idName ~= "temperature" then
                
                if bar then 
                    subMenu:addOption(
                        getText("ContextMenu_MinimalDisplayBars_".. bar.idName ..""),
                        nil,
                        function()
                            if not bar then return end
                            setBarColor(bar)
                        end
                    )
                end
                
            end
            
        end
        
        -- Toggle Movable All
        local str
        if barHP.moveWithMouse == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Movable_All")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Movable_All")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)

                if not generic_bar then return end
                
                if generic_bar then 
                    toggleMovable(generic_bar) end
                
                toggleMovable(barHP) 
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.moveWithMouse ~= bar.moveWithMouse then
                            toggleMovable(bar) 
                        end
                    end
                end
                
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                return
            end
        )
            
        -- Toggle Always Bring Display Bars To Top
        local str
        if barHP.alwaysBringToTop == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Always_Bring_Display_Bars_To_Top")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Always_Bring_Display_Bars_To_Top")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                toggleAlwaysBringToTop(barHP)
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.alwaysBringToTop ~= bar.alwaysBringToTop then
                            toggleAlwaysBringToTop(bar) 
                        end
                    end
                end
                
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                return
            end
        )
            
        -- Toggle Moodlet Threshold Lines
        local str
        if barHP.showMoodletThresholdLines == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Moodlet_Threshold_Lines")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Moodlet_Threshold_Lines")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                toggleMoodletThresholdLines(barHP) 
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.showMoodletThresholdLines ~= bar.showMoodletThresholdLines then
                            toggleMoodletThresholdLines(bar) 
                        end
                    end
                end
                
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                return
            end
        )
            
        -- Toggle Move Bars Together
        local str
        if barHP.moveBarsTogether == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Move_Bars_Together")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Move_Bars_Together")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                toggleMoveBarsTogether(barHP) 
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.moveBarsTogether ~= bar.moveBarsTogether then
                            toggleMoveBarsTogether(bar) 
                        end
                    end
                end
                
                MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                return
            end
        )
        
        -- Toggle Show Image
        local str
        if barHP.showImage == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Show_Icon")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Show_Icon")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                toggleShowImage(barHP) 
                
                for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.showImage ~= bar.showImage then
                            toggleShowImage(bar) 
                        end
                    end
                end
                
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                return
            end
        )
        
    else
    
    -- === Display Bars ===
        -- reset
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Reset_Display_Bar"),
            generic_bar,
            function(generic_bar)
                resetBar(generic_bar)
                return
            end
        )
        
        -- set vertical
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Set_Vertical"),
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                if MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] == false then 
                    
                    generic_bar.isVertical = true
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] = true
                    
                    local oldW = tonumber(generic_bar.oldWidth)
                    local oldH = tonumber(generic_bar.oldHeight)
                    generic_bar:setWidth(oldH)
                    generic_bar:setHeight(oldW)
                    
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["width"] = generic_bar:getWidth()
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["height"] = generic_bar:getHeight()
                    
                    MinimalDisplayBarsB4220.io_persistence.store(
                        generic_bar.fileSaveLocation, 
                        MinimalDisplayBarsB4220.MOD_ID, 
                        MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                    
                    -- recreate MoveBarsTogether panel
                    MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                end
                return
            end
        )
        
        -- set horizontal
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Set_Horizontal"),
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                if MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] == true then 
                    
                    generic_bar.isVertical = false
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] = false
                    
                    local oldW = tonumber(generic_bar.oldWidth)
                    local oldH = tonumber(generic_bar.oldHeight)
                    generic_bar:setWidth(oldH)
                    generic_bar:setHeight(oldW)
                    
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["width"] = generic_bar:getWidth()
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["height"] = generic_bar:getHeight()
                    
                    MinimalDisplayBarsB4220.io_persistence.store(
                        generic_bar.fileSaveLocation, 
                        MinimalDisplayBarsB4220.MOD_ID, 
                        MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                    
                    -- recreate MoveBarsTogether panel
                    MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                end
                return
            end
        )
        
        -- set color
        if generic_bar.idName ~= "temperature" then
            
            contextMenu:addOption(
                getText("ContextMenu_MinimalDisplayBars_Set_Color"),
                generic_bar,
                function(generic_bar)
                
                    setBarColor(generic_bar)
                    
                    return
                end)
        end
        
        -- set height / width
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Set_HeightWidth"),
            generic_bar,
            function(generic_bar)
            
                setHeightWidth(generic_bar)
                
                return
            end
        )
        
        -- hide
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Hide"),
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                generic_bar:setVisible(false)
                
                MinimalDisplayBarsB4220.configTables[generic_bar.coopNum][generic_bar.idName]["isVisible"] = false
                MinimalDisplayBarsB4220.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBarsB4220.MOD_ID, 
                    MinimalDisplayBarsB4220.configTables[generic_bar.coopNum])
                
                -- recreate MoveBarsTogether panel when hiding a display bar
                MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end
        )
        
    end
    
end


--=============================================
-- UI

local playerIndices = {} -- added for split-screen support

local function OnBootGame() 
    playerIndices = {}
end

local function OnLocalPlayerDisconnect(isoPlayer)
    if isoPlayer == nil or not isoPlayer:isLocalPlayer() then return end

    for k, v in pairs(playerIndices) do
        if playerIndices[k] == isoPlayer:getPlayerNum() + 1 then
            table.remove(playerIndices, k)
            break
        end
    end
end

-- Function that will create all of the display bars for a given ISOPlayer.
local function removeUiForRespawn(playerIndex)
    local menuBar = MinimalDisplayBarsB4220.displayBarMenus[playerIndex]
    if menuBar then menuBar:removeFromUIManager() end

    local moveBarsTogetherPanel = MinimalDisplayBarsB4220.moveBarsTogetherPanels[playerIndex]
    if moveBarsTogetherPanel then moveBarsTogetherPanel:removeFromUIManager() end

    local displayBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
    if displayBars then
        local hpBar = displayBars["hp"]
        if hpBar and hpBar.parent and hpBar.parent ~= moveBarsTogetherPanel then
            hpBar.parent:removeFromUIManager()
        end

        for _, bar in pairs(displayBars) do
            if bar then bar:removeFromUIManager() end
        end
    end

    MinimalDisplayBarsB4220.displayBarMenus[playerIndex] = nil
    MinimalDisplayBarsB4220.displayBars[playerIndex] = nil
    MinimalDisplayBarsB4220.moveBarsTogetherPanels[playerIndex] = nil
end

local function createUiFor(playerIndex, isoPlayer)
    
    -- Make sure this is a local player only.
    if isoPlayer == nil or not isoPlayer:isLocalPlayer() then return end

    -- Respawning creates a new IsoPlayer.  The old UI elements may already
    -- have been removed by the game, so discard their stale references and
    -- build a fresh set for the new character.
    local existingBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
    if existingBars then
        local existingHPBar = existingBars["hp"]
        if existingHPBar and existingHPBar.createdForPlayer == isoPlayer then
            return
        end
        removeUiForRespawn(playerIndex)
    end
    
    -- Split-screen support
    local xOffset = getPlayerScreenLeft(playerIndex)
    local yOffset = getPlayerScreenTop(playerIndex)
    
    local coopNum = playerIndex + 1
    
    local isAlreadySpawned = false
    for k, v in pairs(playerIndices) do
        if playerIndices[k] == (coopNum) then
            isAlreadySpawned = true
            break
        end
    end
    if not isAlreadySpawned then table.insert(playerIndices, coopNum) end
    
    if playerIndices[1] == coopNum then
        MinimalDisplayBarsB4220.configFileLocations[coopNum] = MinimalDisplayBarsB4220.configFileName
    elseif playerIndices[2] == coopNum then
        MinimalDisplayBarsB4220.configFileLocations[coopNum] = "MOD Config Options (".. MinimalDisplayBarsB4220.MOD_ID ..")B42 P2.cfg"
    elseif playerIndices[3] == coopNum then
        MinimalDisplayBarsB4220.configFileLocations[coopNum] = "MOD Config Options (".. MinimalDisplayBarsB4220.MOD_ID ..")B42 P3.cfg"
    elseif playerIndices[4] == coopNum then
        MinimalDisplayBarsB4220.configFileLocations[coopNum] = "MOD Config Options (".. MinimalDisplayBarsB4220.MOD_ID ..")B42 P4.cfg"
    else
        MinimalDisplayBarsB4220.configFileLocations[coopNum] = "MOD Config Options (".. MinimalDisplayBarsB4220.MOD_ID ..")B42 P_wildcard.cfg"
    end
    
    -- The in-script table is the single source of truth for defaults. The
    -- packaged legacy defaults file is retained for compatibility, but is
    -- never used as mutable state or written at runtime.
    MinimalDisplayBarsB4220.configTables[coopNum] = MinimalDisplayBarsB4220.deepcopy(DEFAULT_SETTINGS)
    
    --if isoPlayer:isLocalPlayer() then numOfLocalClients = numOfLocalClients + 1 end
    --numOfLocalClients = numOfLocalClients + 1
    --local coopNum = numOfLocalClients
    --local listOfPlayers = getPlayer():getPlayers()
    --print(type(listOfPlayers))
    --for k, v in ipairs(listOfPlayers) do
    --    numOfLocalClients = numOfLocalClients + 1
    --end
    --print(listOfPlayers)
    --numOfLocalClients = math.floor(listOfPlayers:size())
    
    
    -- MoodletThresholdTables
    local moodletThresholdTables = getMoodletThresholdTables()
    
    
    --===============================================================================
    -- Get/Setup all configuration settings from the config file.
    local t_restored = 
        MinimalDisplayBarsB4220.io_persistence.load(
            MinimalDisplayBarsB4220.configFileLocations[coopNum], 
            MinimalDisplayBarsB4220.MOD_ID)
    
    if t_restored then 
        local configWasMigrated = migrateHudLayerPriority(t_restored)
        if not MinimalDisplayBarsB4220.compare_and_insert(MinimalDisplayBarsB4220.configTables[coopNum], t_restored, true) then
            MinimalDisplayBarsB4220.io_persistence.store(
                MinimalDisplayBarsB4220.configFileLocations[coopNum],
                MinimalDisplayBarsB4220.MOD_ID,
                t_restored)
        end
        MinimalDisplayBarsB4220.configTables[coopNum] = t_restored
        if migrateB42MoodleImagePaths(MinimalDisplayBarsB4220.configTables[coopNum]) then
            configWasMigrated = true
        end
        if configWasMigrated then
            MinimalDisplayBarsB4220.io_persistence.store(
                MinimalDisplayBarsB4220.configFileLocations[coopNum],
                MinimalDisplayBarsB4220.MOD_ID,
                MinimalDisplayBarsB4220.configTables[coopNum])
        end
    else 
        -- First launch: build the user's .cfg from the validated in-memory
        -- defaults. This preserves the intended positions even if a packaged
        -- default file is unavailable or older than the current code.
        MinimalDisplayBarsB4220.configTables[coopNum] = recreateConfigFiles(
            coopNum,
            MinimalDisplayBarsB4220.configTables[coopNum])
    end
    
    -- Build the Menu bar separately so it always remains available.
    local menuBar = ISGenericMiniDisplayBarB4220:new(
        "menu",
        MinimalDisplayBarsB4220.configFileLocations[coopNum],
        playerIndex, isoPlayer, coopNum,
        MinimalDisplayBarsB4220.configTables[coopNum],
        xOffset, yOffset,
        nil,
        function(player)
            return player:isDead() and -1 or 1
        end,
        nil, false, nil)
    menuBar:initialise()
    menuBar:addToUIManager()
    MinimalDisplayBarsB4220.displayBarMenus[playerIndex] = menuBar

    -- Each definition owns one game value, its colour rule, and optional
    -- Moodle threshold lines. Adding a new bar now needs one table entry
    -- instead of duplicating the complete UI construction sequence.
    local barDefinitions = {
        {id = "hp", value = getHealth, color = getColorHealth},
        {id = "hunger", value = getHunger, color = getColorHunger, thresholds = true},
        {id = "thirst", value = getThirst, color = getColorThirst, thresholds = true},
        {id = "endurance", value = getEndurance, color = getColorEndurance, thresholds = true},
        {id = "fatigue", value = getFatigue, color = getColorFatigue, thresholds = true},
        {id = "boredomlevel", value = getBoredomLevel, color = getColorBoredomLevel, thresholds = true},
        {id = "unhappynesslevel", value = getUnhappynessLevel, color = getColorUnhappynessLevel, thresholds = true},
        {id = "temperature", value = getTemperature, color = getColorTemperature, thresholds = true},
        {id = "calorie", value = getCalorie, color = getColorCalorie},
        {id = "stress", value = getStress, color = getColorStress, thresholds = true},
        {id = "sickness", value = getSickness, color = getColorSickness, thresholds = true},
        {id = "carbohydrates", value = getCarbohydrates, color = getColorCarbohydrates},
        {id = "proteins", value = getProteins, color = getColorProteins},
        {id = "fats", value = getFats, color = getColorFats},
        {id = "corpse_sickness", value = getCorpseSickness, color = getColorCorpseSickness, thresholds = true},
        {id = "discomfort", value = getDiscomfort, color = getColorDiscomfort, thresholds = true},
    }

    local displayBars = {}
    for _, definition in ipairs(barDefinitions) do
        local bar = ISGenericMiniDisplayBarB4220:new(
            definition.id,
            MinimalDisplayBarsB4220.configFileLocations[coopNum],
            playerIndex, isoPlayer, coopNum,
            MinimalDisplayBarsB4220.configTables[coopNum],
            xOffset, yOffset,
            nil,
            definition.value,
            definition.color, true,
            definition.thresholds and moodletThresholdTables[definition.id] or nil)
        bar:initialise()
        bar:addToUIManager()
        displayBars[definition.id] = bar
    end

    MinimalDisplayBarsB4220.displayBars[playerIndex] = displayBars

    -- Keep shared interaction options aligned with the Health bar. Individual
    -- geometry, visibility, colours, and icon choices remain per-bar settings.
    for _, bar in pairs(MinimalDisplayBarsB4220.displayBars[playerIndex]) do
        if bar then
            local barHP = MinimalDisplayBarsB4220.displayBars[playerIndex]["hp"]
            if barHP.moveWithMouse ~= bar.moveWithMouse then
                toggleMovable(bar) end
            if barHP.resizeWithMouse ~= bar.resizeWithMouse then
                toggleResizeable(bar) end
            if barHP.alwaysBringToTop ~= bar.alwaysBringToTop then
                toggleAlwaysBringToTop(bar) end
            if barHP.showMoodletThresholdLines ~= bar.showMoodletThresholdLines then
                toggleMoodletThresholdLines(bar) end
            if barHP.isCompact ~= bar.isCompact then
                toggleCompact(bar) end
            if barHP.moveBarsTogether ~= bar.moveBarsTogether then
                toggleMoveBarsTogether(bar) end
            if barHP.showImage ~= bar.showImage then
                toggleShowImage(bar) end
        end
    end
    
    -- Create MoveBarsTogether Panel.
    MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(playerIndex)
    
end

-- OnCreatePlayer can occur before a multiplayer client's local player is
-- ready.  Retry briefly after joining so client-only display bars are created
-- reliably, without adding duplicates when the normal event already ran.
local mpUiRetryCount = 0
local function createUiForConnectedPlayer()
    local foundLocalPlayer = false

    for playerIndex = 0, 3 do
        local isoPlayer = getSpecificPlayer(playerIndex)
        if isoPlayer and isoPlayer:isLocalPlayer() then
            foundLocalPlayer = true
            createUiFor(playerIndex, isoPlayer)
        end
    end

    mpUiRetryCount = mpUiRetryCount + 1
    if foundLocalPlayer or mpUiRetryCount >= 600 then
        Events.OnTick.Remove(createUiForConnectedPlayer)
    end
end

local function queueConnectedPlayerUiCreation()
    mpUiRetryCount = 0
    Events.OnTick.Remove(createUiForConnectedPlayer)
    Events.OnTick.Add(createUiForConnectedPlayer)
end

-- Build 42 changes the global HUD state while the Escape menu is opened and
-- closed. Keep a short restore window around that transition so the temporary
-- UI coordinates and visibility can never replace the player's saved layout.
local escapeLayoutRestoreTicks = 0
local escapeLayoutSnapshots = {}
local pauseHudWasHidden = false
local escapePauseWasRequested = false
local globalUiWasVisible = true
local uiReturnRestoreTicks = 0
MinimalDisplayBarsB4220.isPauseLayoutTransition = false
local escapeLayoutKeys = {
    "x", "y", "width", "height", "isVertical", "isCompact",
    "isVisible", "isMovable", "isResizable", "alwaysBringToTop",
    "showMoodletThresholdLines", "l", "t", "r", "b"
}

local function captureEscapeSettings(settings)
    local snapshot = {}
    for _, key in ipairs(escapeLayoutKeys) do
        snapshot[key] = MinimalDisplayBarsB4220.deepcopy(settings[key])
    end
    return snapshot
end

local function copyEscapeSettings(target, source)
    if not target or not source then return false end

    local changed = false
    for key, value in pairs(source) do
        if target[key] ~= value then
            target[key] = MinimalDisplayBarsB4220.deepcopy(value)
            changed = true
        end
    end
    return changed
end

local function captureSavedLayoutBeforeEscape()
    for playerIndex = 0, 3 do
        local isoPlayer = getSpecificPlayer(playerIndex)
        if isoPlayer and isoPlayer:isLocalPlayer() then
            local coopNum = playerIndex + 1
            local playerConfig = MinimalDisplayBarsB4220.configTables[coopNum]
            if playerConfig then
                local snapshot = {
                    moveBarsTogether = playerConfig["moveBarsTogether"],
                    settings = {}
                }

                local displayBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
                if displayBars then
                    for _, bar in pairs(displayBars) do
                        local settings = bar and playerConfig[bar.idName]
                        if settings then
                            snapshot.settings[bar.idName] = captureEscapeSettings(settings)
                        end
                    end
                end

                local menuBar = MinimalDisplayBarsB4220.displayBarMenus[playerIndex]
                local menuSettings = menuBar and playerConfig[menuBar.idName]
                if menuSettings then
                    snapshot.settings[menuBar.idName] = captureEscapeSettings(menuSettings)
                end

                escapeLayoutSnapshots[coopNum] = snapshot
            end
        end
    end
end

local function restoreEscapeSnapshotForPlayer(playerIndex)
    local coopNum = playerIndex + 1
    local snapshot = escapeLayoutSnapshots[coopNum]
    local playerConfig = MinimalDisplayBarsB4220.configTables[coopNum]
    if not snapshot or not playerConfig then return false end

    local changed = false
    if playerConfig["moveBarsTogether"] ~= snapshot.moveBarsTogether then
        playerConfig["moveBarsTogether"] = snapshot.moveBarsTogether
        changed = true
    end

    for idName, savedSettings in pairs(snapshot.settings) do
        local settings = playerConfig[idName]
        if settings and copyEscapeSettings(settings, savedSettings) then
            changed = true
        end
    end

    return changed
end

local function restoreSavedLayoutForBar(bar, isoPlayer)
    if not bar then return end

    local playerConfig = MinimalDisplayBarsB4220.configTables[bar.coopNum]
    local settings = playerConfig and playerConfig[bar.idName]
    if not settings then return end

    local x = settings["x"] + bar.xOffset
    local y = settings["y"] + bar.yOffset
    if bar.x ~= x then bar:setX(x) end
    if bar.y ~= y then bar:setY(y) end
    if settings["width"] and bar.width ~= settings["width"] then bar:setWidth(settings["width"]) end
    if settings["height"] and bar.height ~= settings["height"] then bar:setHeight(settings["height"]) end

    -- Build 42 can alter UI panels while the Escape menu takes focus. Restore
    -- all layout-affecting runtime fields, not just X/Y, from the saved config.
    bar.isVertical = settings["isVertical"]
    bar.isCompact = settings["isCompact"]
    bar.moveWithMouse = settings["isMovable"]
    bar.resizeWithMouse = settings["isResizable"]
    bar.alwaysBringToTop = bar.idName == "menu" or settings["alwaysBringToTop"] == true
    if bar.applyLayerPriority then
        bar:applyLayerPriority()
    else
        bar:setAlwaysOnTop(bar.idName == "menu")
    end
    bar.showMoodletThresholdLines = settings["showMoodletThresholdLines"]
    bar.oldX = x
    bar.oldY = y
    bar.parentOldX = nil
    bar.parentOldY = nil

    -- Dead-player hiding is handled by the bar renderer. Do not show bars
    -- over the death screen, but otherwise restore each saved Show/Hide value.
    if not isoPlayer or not isoPlayer:isDead() then
        bar.hiddenForDeadPlayer = false
        bar:setVisible(settings["isVisible"] == true)
    end
end

-- Build 42 can remove custom UI elements from its UI manager while the game
-- window is inactive.  Reattaching only missing elements prevents duplicates
-- while allowing the HUD to recover after Alt+Tab or an overlay is closed.
local function isUiElementAttached(element)
    if not element or not UIManager or not UIManager.getUI then return true end

    local ui = UIManager.getUI()
    if not ui then return true end

    for i = 0, ui:size() - 1 do
        if ui:get(i) == element then return true end
    end
    return false
end

local function ensureUiElementAttached(element)
    if element and not isUiElementAttached(element) then
        element:addToUIManager()
    end
end

local function restoreSavedLayoutAfterEscape()
    for playerIndex = 0, 3 do
        local isoPlayer = getSpecificPlayer(playerIndex)
        if isoPlayer and isoPlayer:isLocalPlayer() then
            local displayBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
            local layoutWasChanged = restoreEscapeSnapshotForPlayer(playerIndex)
            if displayBars then
                for _, bar in pairs(displayBars) do
                    ensureUiElementAttached(bar)
                    bar.moveBarsTogether = MinimalDisplayBarsB4220.configTables[bar.coopNum]["moveBarsTogether"]
                    bar.temporarilyHiddenForPauseMenu = false
                    restoreSavedLayoutForBar(bar, isoPlayer)
                end
            end
            local menuBar = MinimalDisplayBarsB4220.displayBarMenus[playerIndex]
            if menuBar then
                ensureUiElementAttached(menuBar)
                menuBar.moveBarsTogether = MinimalDisplayBarsB4220.configTables[menuBar.coopNum]["moveBarsTogether"]
                menuBar.temporarilyHiddenForPauseMenu = false
                restoreSavedLayoutForBar(menuBar, isoPlayer)
            end

            -- Reattach bars to the retained group anchor after restoring the
            -- saved group state. This prevents Build 42 HUD transitions from
            -- leaving every bar at the anchor's temporary top-left position.
            MinimalDisplayBarsB4220.createMoveBarsTogetherPanel(playerIndex)
            MinimalDisplayBarsB4220.refreshMoveBarsTogetherAnchor(playerIndex)
            ensureUiElementAttached(MinimalDisplayBarsB4220.moveBarsTogetherPanels[playerIndex])

            if layoutWasChanged then
                MinimalDisplayBarsB4220.io_persistence.store(
                    MinimalDisplayBarsB4220.configFileLocations[playerIndex + 1],
                    MinimalDisplayBarsB4220.MOD_ID,
                    MinimalDisplayBarsB4220.configTables[playerIndex + 1])
            end
        end
    end
end

local function isGlobalUiVisible()
    return not UIManager or UIManager.visibleAllUi ~= false
end

local function isPauseHudHidden()
    if isGamePaused and isGamePaused() then return true end

    -- Dedicated servers do not pause simulation, but an Escape press still
    -- hides the HUD.  Do not treat every hidden-UI transition as a pause:
    -- Alt+Tab and overlays also toggle visibleAllUi and must not permanently
    -- change a display bar's own visibility.
    return escapePauseWasRequested and not isGlobalUiVisible()
end

local function updatePauseVisibilityForBar(bar, isoPlayer, hideForPause)
    if not bar then return end

    if hideForPause then
        if bar:isVisible() then
            bar.temporarilyHiddenForPauseMenu = true
            bar:setVisible(false)
        end
    elseif bar.temporarilyHiddenForPauseMenu then
        bar.temporarilyHiddenForPauseMenu = false
        restoreSavedLayoutForBar(bar, isoPlayer)
    end
end

local function updatePauseVisibility()
    local globalUiVisible = isGlobalUiVisible()
    if globalUiVisible and not globalUiWasVisible then
        -- Let Build 42 finish restoring its own HUD, then restore the mod's
        -- UI for several frames in case the inactive window removed it.
        uiReturnRestoreTicks = math.max(uiReturnRestoreTicks, 8)
    end
    globalUiWasVisible = globalUiVisible

    local hideForPause = isPauseHudHidden()

    -- Build 42 changes UI state on the first frame after Escape. Detect the
    -- actual HUD transition too, not only the key press, so controller/menu
    -- pauses receive the same protection and cannot scatter grouped bars.
    if hideForPause and not pauseHudWasHidden then
        captureSavedLayoutBeforeEscape()
        escapeLayoutRestoreTicks = math.max(escapeLayoutRestoreTicks, 6)
    elseif not hideForPause and pauseHudWasHidden then
        escapeLayoutRestoreTicks = math.max(escapeLayoutRestoreTicks, 6)
    end
    pauseHudWasHidden = hideForPause
    MinimalDisplayBarsB4220.isPauseLayoutTransition = hideForPause
        or escapeLayoutRestoreTicks > 0
        or uiReturnRestoreTicks > 0

    for playerIndex = 0, 3 do
        local isoPlayer = getSpecificPlayer(playerIndex)
        if isoPlayer and isoPlayer:isLocalPlayer() then
            local displayBars = MinimalDisplayBarsB4220.displayBars[playerIndex]
            if displayBars then
                for _, bar in pairs(displayBars) do
                    updatePauseVisibilityForBar(bar, isoPlayer, hideForPause)
                end
            end
            updatePauseVisibilityForBar(MinimalDisplayBarsB4220.displayBarMenus[playerIndex], isoPlayer, hideForPause)
        end
    end
    return hideForPause
end

local function protectSavedLayoutOnEscape(key)
    if key ~= Keyboard.KEY_ESCAPE then return end

    -- Keep an in-memory copy before Build 42 changes the HUD state. Any
    -- temporary movement, resize, or orientation reset during the transition
    -- is discarded instead of being persisted as the player's new layout.
    captureSavedLayoutBeforeEscape()
    escapePauseWasRequested = true
    escapeLayoutRestoreTicks = math.max(escapeLayoutRestoreTicks, 6)
    MinimalDisplayBarsB4220.isPauseLayoutTransition = true
end

local function restoreSavedLayoutDuringEscapeTransition()
    -- Hide all bars only while the game's pause/Escape HUD state is active.
    -- Once it closes, restore each bar according to the saved Show/Hide and
    -- position settings instead of leaving it permanently hidden.
    -- Pause visibility is updated from OnRenderTick so it continues to work
    -- while gameplay is paused. Reuse that state here instead of scanning all
    -- bars a second time on every normal game tick.
    if pauseHudWasHidden then return end

    if escapeLayoutRestoreTicks <= 0 and uiReturnRestoreTicks <= 0 then return end

    restoreSavedLayoutAfterEscape()

    if uiReturnRestoreTicks > 0 then
        uiReturnRestoreTicks = uiReturnRestoreTicks - 1
    end

    if escapeLayoutRestoreTicks > 0 then
        escapeLayoutRestoreTicks = escapeLayoutRestoreTicks - 1
    end

    if escapeLayoutRestoreTicks <= 0 then
        escapeLayoutSnapshots = {}
        escapePauseWasRequested = false
    end

    if escapeLayoutRestoreTicks <= 0 and uiReturnRestoreTicks <= 0 then
        MinimalDisplayBarsB4220.isPauseLayoutTransition = false
    end
end

Events.OnRenderTick.Add(preventContextCoverup)
Events.OnRenderTick.Add(updatePauseVisibility)

Events.OnRenderTick.Add(onTickHP)
Events.OnPlayerUpdate.Add(onPlayerUpdateCheckBodyDamage)

Events.OnGameBoot.Add(OnBootGame)
Events.OnDisconnect.Add(OnLocalPlayerDisconnect)
--Events.OnPlayerDeath.Add(OnLocalPlayerDeath)

Events.OnCreatePlayer.Add(createUiFor)
Events.OnGameStart.Add(queueConnectedPlayerUiCreation)
Events.OnConnected.Add(queueConnectedPlayerUiCreation)
Events.OnKeyPressed.Add(protectSavedLayoutOnEscape)
Events.OnTick.Add(restoreSavedLayoutDuringEscapeTransition)








