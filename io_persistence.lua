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
