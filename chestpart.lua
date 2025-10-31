if openInvLib == nil then
    shell.run("oil.lua")
end

print("ChestPart (Open Inventory Library)\n\n")
local oil = openInvLib
local function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end
local function startsWith(str, start)
    return str:sub(1, #start) == start
end
local function makeTable(rows)
    local colSizes = {}
    for i = 1, #rows do
        for j = 1, #rows[i] do
            colSizes[j] = math.max(colSizes[j] or 0, #tostring(rows[i][j]))
        end
    end
    local colPos = {}
    local w,h = term.getSize()
    local x = 1
    local y = 1
    for k, v in ipairs(colSizes) do
        if x + v + 2 > w then
            x = 1
            y = y + 1
        end
        colPos[k] = {
            x = x,
            y = y
        }
        x = x + v + 2
    end
    for i = 1, #rows do
        local str = ""
        local alp = 1
        for j = 1, #rows[i] do
            local missing = math.max(0, colSizes[j] - #tostring(rows[i][j]))
            if colPos[j].y > (colPos[j-1] and colPos[j-1].y or 1) then
                if i == 1 then
                    str = str .. "\n"
                    for l = 1, j-1 do
                        str = str .. string.rep("-", colSizes[l]) .. "  "
                    end
                    alp = j
                end
                str = str .. "\n"
            end
            str = str .. tostring(rows[i][j]) .. string.rep(" ", missing + 2)
        end
        if i == 1 then
            str = str .. "\n"
            for l = alp, #rows[i] do
                str = str .. string.rep("-", colSizes[l]) .. "  "
            end
        end
        print(str)
        if i > 3 then
            io.read()
            local cx, cy = term.getCursorPos()
            term.setCursorPos(1, cy - 1)
        end
    end
end
local selectedStorage = nil
local selectedPartition = nil
local commands = {
    {
        name = "list",
        description = "Display a list of storages or partitions.",
        usage = {
            {
                { "storage" },
                { "partition" }
            }
        },
        onRun = function(command, args)
            if #args < 1 then
                print("STORAGE - Display a list of storages.")
                print("PARTITION - Display a list of partitions in the selected storage.")
                return
            end
            local subcmd = args[1]:lower()
            if subcmd == "storage" then
                local rows = {
                    {"###", "Name", "Status", "Size"}
                }
                for i=1,2^16 do
                    local ok,err = oil.getStorage(i)
                    if ok then
                        table.insert(rows, {"Str "..i, ok.getName() or "Unknown", "Online", ok.getSize().." slots"})
                    else
                        if err == "Storage not found" then
                            break
                        else
                            table.insert(rows, {"Str "..i, "Unknown", "Offline", "Unknown slots"})
                        end
                    end
                end
                makeTable(rows)
            elseif subcmd == "partition" then
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error: "..err)
                    return
                end
                local rows = {
                    {"###", "Name", "Start", "End", "Size", "Compressed"}
                }
                local partitions = ok.getPartitions()
                for id, part in pairs(partitions) do
                    table.insert(rows, { "Part "..id, part.name or "Unknown", part.startPos, part.endPos, (part.endPos - part.startPos).." slots", part.isCompressed and "*" or "" })
                end
                makeTable(rows)
            else
                print("STORAGE - Display a list of storages.")
                print("PARTITION - Display a list of partitions in the selected storage.")
                return
            end
        end
    },
    {
        name = "select",
        description = "Select a storage or partition by ID.",
        usage = {
            {
                { "storage" },
                { "partition" }
            }, "<ID>"
        },
        onRun = function(command, args)
            if #args < 2 then
                print("STORAGE <ID> - Select a storage by ID.")
                print("PARTITION <ID> - Select a partition by ID in the selected storage.")
                return
            end
            local subcmd = args[1]:lower()
            if subcmd == "storage" then
                local id = tonumber(args[2])
                if id == nil then
                    print("Invalid storage ID.")
                    return
                end
                local ok, err = oil.getStorage(id)
                if not ok then
                    print("Error selecting storage: "..err)
                    return
                end
                selectedStorage = id
                selectedPartition = nil
                print("Storage "..id.." is now the selected storage.")
            elseif subcmd == "partition" then
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                local id = tonumber(args[2])
                if id == nil then
                    print("Invalid partition ID.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error selecting partition: "..err)
                    return
                end
                local ok2, err2 = ok.getPartition(id)
                if not ok2 then
                    print("Error selecting partition: "..err2)
                    return
                end
                selectedPartition = id
                print("Partition "..id.." is now the selected partition.")
            else
                print("STORAGE <ID> - Select a storage by ID.")
                print("PARTITION <ID> - Select a partition by ID in the selected storage.")
                return
            end
        end
    },
}

local function onCommand(command, args)
    local foundCmd = 0
    for k, v in pairs(commands) do
        if startsWith(v.name:lower(), command:lower()) then
            if foundCmd ~= 0 then
                print("Unknown command.")
                return
            end
            foundCmd = k
        end
    end
    if foundCmd ~= 0 then
        local realCommand = commands[foundCmd].name
        local newArgs = {}
        local stack = {
            {
                value = commands[foundCmd].usage,
                check = 1
            }
        }
        local k = 1
        while k <= #args do
            local v = args[k]
            local compare = stack[#stack].value[stack[#stack].check]
            if compare ~= nil then
                stack[#stack].check = stack[#stack].check + 1
                if type(compare) == "string" then
                    if startsWith(compare, "<") then
                        table.insert(newArgs, v)
                    elseif startsWith(compare:lower(), v:lower()) then
                        table.insert(newArgs, compare)
                    else
                        print("Unknown command.")
                        return
                    end
                elseif type(compare) == "table" then
                    local found = false
                    for kk, vv in ipairs(compare) do
                        if startsWith(vv[1]:lower(), v:lower()) then
                            table.insert(stack, {
                                value = vv,
                                check = 1
                            })
                            if found then
                                print("Unknown command.")
                                return
                            end
                            found = true
                        end
                    end
                    if not found then
                        print("Unknown command.")
                        return
                    else
                        k = k - 1
                    end
                end
            else
                table.remove(stack, #stack)
                k = k - 1
            end
            k = k + 1
        end
        commands[foundCmd].onRun(realCommand, newArgs)
    else
        print("Unknown command.")
    end
end

while true do
    term.write("CHESTPART> ")
    local rawCmd = io.read()
    local args = mysplit(rawCmd)
    if #args > 0 then
        local command = args[1]:lower()
        table.remove(args, 1)
        print()
        onCommand(command, args)
        print()
    end
end
