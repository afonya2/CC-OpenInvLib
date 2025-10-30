if openInvLib == nil then
    shell.run("oil.lua")
end

print("ChestPart (Open Inventory Library)\n\n")
local oil = openInvLib
local function mysplit(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
local function makeTable(rows)
    -- TODO: rework this
    local colSizes = {}
    for i=1,#rows do
        for j=1,#rows[i] do
            colSizes[j] = math.max(colSizes[j] or 0, #tostring(rows[i][j]))
        end
    end
    table.insert(rows, 2, {})
    for k,v in pairs(colSizes) do
        rows[2][k] = string.rep("-", v)
    end
    for i=1,#rows do
        local str = ""
        for j=1,#rows[i] do
            local missing = math.max(0, colSizes[j] - #tostring(rows[i][j]))
            str = str..tostring(rows[i][j])..string.rep(" ", missing+2)
        end
        print(str)
        if i > 3 then
            io.read()
        end
    end
end
local selectedStorage = nil
local selectedPartition = nil

local function onCommand(command, args)
    if command == "list" then
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
    elseif command == "select" then
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