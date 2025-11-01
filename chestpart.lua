-- ChestPart command line utility for Open Inventory Library (OIL)
-- Source: https://github.com/afonya2/CC-OpenInvLib
-- Made by: Afonya (afonya2 on github)
-- Last Updated: 2025-11-01 18:30 UTC
-- License: MIT, you must include the above text into every copies of this file
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
local function endsWith(str, ending)
    return str:sub(-#ending) == ending
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
                    if (colPos[j-1] and colPos[j-1].y or 1) > 1 then
                        str = str .. " "
                    end
                    for l = 1, j-1 do
                        str = str .. string.rep("-", colSizes[l]) .. "  "
                    end
                    alp = j
                end
                str = str .. "\n "
            end
            str = str .. tostring(rows[i][j]) .. string.rep(" ", missing + 2)
        end
        if i == 1 then
            str = str .. "\n"
            if colPos[#colPos].y > 1 then
                str = str .. " "
            end
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
                { "inventory", "all" },
                { "partition" },
                { "items" }
            }
        },
        onRun = function(command, args)
            if #args < 1 then
                print("STORAGE - Display a list of storages.")
                print("INVENTORY <NAME> - Display the inventories of the selected storage.")
                print("INVENTORY ALL - Display all connected inventories.")
                print("PARTITION - Display a list of partitions in the selected storage.")
                print("ITEMS - Display a list of items in the selected partition.")
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
            elseif subcmd == "inventory" then
                if #args < 2 then
                    if selectedStorage == nil then
                        print("No storage selected.")
                        return
                    end
                    local ok, err = oil.getStorage(selectedStorage)
                    if not ok then
                        print("Error: "..err)
                        return
                    end
                    local inventories = ok.getStorages()
                    local rows = {
                        {"Name"}
                    }
                    for _, inv in pairs(inventories) do
                        table.insert(rows, {inv})
                    end
                    makeTable(rows)
                else
                    local rows = {
                        {"Name", "Used"}
                    }
                    local usedStrs = {}
                    for i=1,2^16 do
                        local ok,err = oil.getStorage(i)
                        if ok then
                            for k,v in ipairs(ok.getStorages()) do
                                usedStrs[v] = true
                            end
                        else
                            if err == "Storage not found" then
                                break
                            end
                        end
                    end
                    local periphs = peripheral.getNames()
                    for _, n in pairs(periphs) do
                        local t1, t2 = peripheral.getType(n)
                        if t2 == "inventory" then
                            table.insert(rows, {n, (usedStrs[n] and "*" or "")})
                        end
                    end
                    makeTable(rows)
                end
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
                local id = 1
                for _, part in pairs(partitions) do
                    table.insert(rows, { (not part.isUnallocated and "Part "..id or "Unl"), part.name or "Unknown", part.startPos, part.endPos, (part.endPos - part.startPos + 1).." slots", part.isCompressed and "*" or "" })
                    if not part.isUnallocated then
                        id = id + 1
                    end
                end
                makeTable(rows)
            elseif subcmd == "items" then
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                if selectedPartition == nil then
                    print("No partition selected.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error: "..err)
                    return
                end
                local ok2, err2 = ok.getPartition(selectedPartition)
                if not ok2 then
                    print("Error: "..err2)
                    return
                end
                local rows = {
                    {"Name", "Display Name", "Count", "Max Stack", "Nbt"}
                }
                local items = ok2.listItems()
                for k,v in pairs(items) do
                    table.insert(rows, {v.name or "Unknown", v.displayName or "Unknown", v.count or 0, v.maxCount or 0, (v.nbt and v.nbt:sub(1, 5).."..." or "")})
                end
                makeTable(rows)
            else
                print("STORAGE - Display a list of storages.")
                print("INVENTORY <NAME> - Display the inventories of the selected storage.")
                print("INVENTORY ALL - Display all connected inventories.")
                print("PARTITION - Display a list of partitions in the selected storage.")
                print("ITEMS - Display a list of items in the selected partition.")
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
    {
        name = "scan",
        description = "Rescan the inventory, or peripherals.",
        usage = {
            {
                { "inventory", "<name>" },
                { "peripherals" },
                { "all" }
            }
        },
        onRun = function(command, args)
            if #args < 1 then
                print("INVENTORY (<NAME>/ALL) - Rescan an inventory.")
                print("PERIPHERALS - Rescan the peripherals.")
                print("ALL - Rescan both the inventory and peripherals.")
                return
            end
            local target = args[1]:lower()
            if target == "inventory" then
                if #args < 2 then
                    print("Please specify a peripheral name or 'all'.")
                    return
                end
                if startsWith("all", args[2]) then
                    oil.scanStorages()
                elseif args[2] ~= nil then
                    oil.scanStorage(args[2])
                else
                    print("Please specify a peripheral name or 'all'.")
                    return
                end
                print("Inventory rescanned.")
            elseif target == "peripherals" then
                oil.scanPeripherals()
                print("Peripherals rescanned.")
            elseif target == "all" then
                oil.scanPeripherals()
                oil.scanStorages()
                print("Inventory and peripherals rescanned.")
            else
                print("INVENTORY <NAME> - Rescan the inventory.")
                print("INVENTORY ALL - Rescan all inventories.")
                print("PERIPHERALS - Rescan the peripherals.")
                print("ALL - Rescan both the inventory and peripherals.")
                return
            end
        end
    },
    {
        name = "create",
        description = "Create a new storage or partition.",
        usage = {
            {
                { "storage", "<name>", "<peripherals>" },
                { "partition", "<name>", "<start pos>", "<end pos>", "compressed" },
            }
        },
        onRun = function(command, args)
            if #args < 1 then
                print("STORAGE <NAME> <PERIPHERALS> - Create a new storage. Peripherals separated by commas.")
                print("PARTITION <NAME> <START POS> <END POS> - Create a new partition.")
                print("PARTITION <NAME> <START POS> <END POS> COMPRESSED - Create a new compressed partition.")
                return
            end
            local mode = args[1]:lower()
            if mode == "storage" then
                if #args < 3 then
                    print("STORAGE <NAME> <PERIPHERALS> - Create a new storage. Peripherals separated by commas.")
                    return
                end
                local name = args[2]
                local peripherals = mysplit(args[3], ",")
                local ok, err = oil.createStorage(name, peripherals)
                if not ok then
                    print("Error creating storage: "..err)
                    return
                end
                print("Storage created successfully with ID "..ok..".")
            elseif mode == "partition" then
                if #args < 4 then
                    print("PARTITION <NAME> <START POS> <END POS> - Create a new partition.")
                    print("PARTITION <NAME> <START POS> <END POS> COMPRESSED - Create a new compressed partition.")
                    return
                end
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                local name = args[2]
                local startPos = tonumber(args[3])
                local endPos = tonumber(args[4])
                local isCompressed = false
                if #args >= 5 and args[5]:lower() == "compressed" then
                    isCompressed = true
                end
                if startPos == nil or endPos == nil then
                    print("Invalid start or end position.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error creating partition: "..err)
                    return
                end
                local ok2, err2 = ok.createPartition(name, startPos, endPos, isCompressed)
                if not ok2 then
                    print("Error creating partition: "..err2)
                    return
                end
                print("Partition created successfully with ID "..ok2..".")
            else
                print("STORAGE <NAME> <PERIPHERALS> - Create a new storage. Peripherals separated by commas.")
                print("PARTITION <NAME> <START POS> <END POS> - Create a new partition.")
                print("PARTITION <NAME> <START POS> <END POS> COMPRESSED - Create a new compressed partition.")
                return
            end
        end
    },
    {
        name = "rename",
        description = "Rename a storage or partition.",
        usage = {
            {
                { "storage" },
                { "partition" }
            },
            "<new name>"
        },
        onRun = function(command, args)
            if #args < 2 then
                print("RENAME STORAGE <NEW NAME> - Rename a storage.")
                print("RENAME PARTITION <NEW NAME> - Rename a partition.")
                return
            end
            local type = args[1]:lower()
            local newName = args[2]
            if type == "storage" then
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error: "..err)
                    return
                end
                ok.setName(newName)
                print("Storage renamed successfully.")
            elseif type == "partition" then
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                if selectedPartition == nil then
                    print("No partition selected.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error: "..err)
                    return
                end
                local ok2, err2 = ok.getPartition(selectedPartition)
                if not ok2 then
                    print("Error: "..err2)
                    return
                end
                ok2.setName(newName)
                print("Partition renamed successfully.")
            end
        end
    },
    {
        name = "inventory",
        description = "Add or remove inventories to/from a storage.",
        usage = {
            {
                { "add" },
                { "remove" }
            },
            "<name>"
        },
        onRun = function(command, args)
            if #args < 2 then
                print("ADD <NAME> - Add an inventory to the selected storage.")
                print("REMOVE <NAME> - Remove an inventory from the selected storage.")
                return
            end
            if selectedStorage == nil then
                print("No storage selected.")
                return
            end
            local action = args[1]:lower()
            local name = args[2]
            local ok, err = oil.getStorage(selectedStorage)
            if not ok then
                print("Error: "..err)
                return
            end
            if action == "add" then
                local ok2, err2 = ok.addStorage(name)
                if not ok2 then
                    print("Error adding inventory: "..err2)
                    return
                end
                print("Inventory added successfully.")
            elseif action == "remove" then
                print("Removing an inventory will result in partitions and items moving around.")
                term.write("Continue? (y/n): ")
                local resp = io.read()
                if not startsWith("yes", resp:lower()) then
                    print("Operation cancelled.")
                    return
                end
                local ok2, err2 = ok.removeStorage(name)
                if not ok2 then
                    print("Error removing inventory: "..err2)
                    return
                end
                print("Inventory removed successfully.")
            else
                print("ADD <NAME> - Add an inventory to the selected storage.")
                print("REMOVE <NAME> - Remove an inventory from the selected storage.")
                return
            end
        end
    },
    {
        name = "delete",
        description = "Delete a storage or partition.",
        usage = {
            {
                { "storage" },
                { "partition" }
            },
        },
        onRun = function(command, args)
            if #args < 1 then
                print("STORAGE - Delete the selected storage.")
                print("PARTITION - Delete the selected partition.")
                return
            end
            local type = args[1]:lower()
            if type == "storage" then
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                print("Deleting a storage will delete all partitions and make items within it unaccessible.")
                print("Furthermore, it will cause ID changes for other storages.")
                term.write("Continue? (y/n): ")
                local resp = io.read()
                if not startsWith("yes", resp:lower()) then
                    print("Operation cancelled.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error deleting storage: "..err)
                    return
                end
                local ok2, err2 = ok.delete()
                if not ok2 then
                    print(err2)
                    term.write("Continue anyways? (y/n): ")
                    local resp2 = io.read()
                    if not startsWith("yes", resp2:lower()) then
                        print("Operation cancelled.")
                        return
                    end
                    ok.delete(true)
                end
                selectedStorage = nil
                selectedPartition = nil
                print("Storage deleted successfully.")
            elseif type == "partition" then
                if selectedStorage == nil then
                    print("No storage selected.")
                    return
                end
                if selectedPartition == nil then
                    print("No partition selected.")
                    return
                end
                print("Deleting a partition will make items unaccessible.")
                print("Furthermore, it will cause ID changes for other partitions.")
                term.write("Continue? (y/n): ")
                local resp = io.read()
                if not startsWith("yes", resp:lower()) then
                    print("Operation cancelled.")
                    return
                end
                local ok, err = oil.getStorage(selectedStorage)
                if not ok then
                    print("Error deleting partition: "..err)
                    return
                end
                local ok2, err2 = ok.getPartition(selectedPartition)
                if not ok2 then
                    print("Error deleting partition: "..err2)
                    return
                end
                local ok3, err3 = ok2.delete()
                if not ok3 then
                    print(err3)
                    term.write("Continue anyways? (y/n): ")
                    local resp2 = io.read()
                    if not startsWith("yes", resp2:lower()) then
                        print("Operation cancelled.")
                        return
                    end
                    ok2.delete(true)
                end
                selectedPartition = nil
                print("Partition deleted successfully.")
            else
                print("STORAGE - Delete the selected storage.")
                print("PARTITION - Delete the selected partition.")
                return
            end
        end
    },
    {
        name = "compress",
        description = "Compress; enable or disable compression on the selected partition.",
        usage = {
            {
                { "enable" },
                { "disable" }
            }
        },
        onRun = function(command, args)
            if selectedStorage == nil then
                print("No storage selected.")
                return
            end
            if selectedPartition == nil then
                print("No partition selected.")
                return
            end
            local ok, err = oil.getStorage(selectedStorage)
            if not ok then
                print("Error deleting partition: "..err)
                return
            end
            local ok2, err2 = ok.getPartition(selectedPartition)
            if not ok2 then
                print("Error deleting partition: "..err2)
                return
            end
            if #args < 1 then
                if not ok2.isCompressed() then
                    print("Compression is not enabled for the selected partition.")
                    return
                end
                local before, after, err = ok2.autoCompress()
                if not before then
                    print("Error during compression: "..err)
                    return
                end
                print("Compression successful. " .. before .. " items compressed into " .. after .. " items.")
            else
                local action = args[1]:lower()
                if action == "enable" then
                    if ok2.isCompressed() then
                        print("Compression is already enabled for the selected partition.")
                        return
                    end
                    ok2.setCompressed(true)
                    print("Compression enabled for the selected partition.")
                elseif action == "disable" then
                    if not ok2.isCompressed() then
                        print("Compression is already disabled for the selected partition.")
                        return
                    end
                    ok2.setCompressed(false)
                    print("Compression disabled for the selected partition.")
                end
            end
        end
    },
    {
        name = "move",
        description = "Move a partition.",
        usage = {
            "<new start pos>"
        },
        onRun = function(command, args)
            if #args < 1 then
                print("<NEW START POS> - Move the selected partition to a new start position.")
                return
            end
            if selectedStorage == nil then
                print("No storage selected.")
                return
            end
            if selectedPartition == nil then
                print("No partition selected.")
                return
            end
            local ok, err = oil.getStorage(selectedStorage)
            if not ok then
                print("Error moving partition: "..err)
                return
            end
            local ok2, err2 = ok.getPartition(selectedPartition)
            if not ok2 then
                print("Error moving partition: "..err2)
                return
            end
            local newStartPos = tonumber(args[1])
            if newStartPos == nil then
                print("Invalid new start position.")
                return
            end
            local ok3, err3 = ok2.move(newStartPos)
            if not ok3 then
                print("Error moving partition: "..err3)
                return
            end
            print("Partition moved successfully.")
        end
    },
    {
        name = "resize",
        description = "Resize a partition.",
        usage = {
            "<new size>"
        },
        onRun = function(command, args)
            if #args < 1 then
                print("<NEW SIZE> - Resize the selected partition to a new size.")
                return
            end
            if selectedStorage == nil then
                print("No storage selected.")
                return
            end
            if selectedPartition == nil then
                print("No partition selected.")
                return
            end
            local ok, err = oil.getStorage(selectedStorage)
            if not ok then
                print("Error resizing partition: "..err)
                return
            end
            local ok2, err2 = ok.getPartition(selectedPartition)
            if not ok2 then
                print("Error resizing partition: "..err2)
                return
            end
            local newSize = tonumber(args[1])
            if newSize == nil then
                print("Invalid new size.")
                return
            end
            local ok3, err3 = ok2.resize(newSize)
            if not ok3 then
                if err3 == "Cannot safely resize partition, items would be lost" then
                    print("Resizing this partition will result in item loss.")
                    term.write("Continue? (y/n): ")
                    local resp = io.read()
                    if not startsWith("yes", resp:lower()) then
                        print("Operation cancelled.")
                        return
                    end
                    local ok4, err4 = ok2.resize(newSize, true)
                    if not ok4 then
                        print("Error resizing partition: "..err4)
                        return
                    end
                else
                    print("Error resizing partition: "..err3)
                    return
                end
            end
            print("Partition resized successfully.")
        end
    },
    {
        name = "item",
        description = "Import, export, and move items.",
        usage = {
            {
                { "import", "<query>", "<from name>", "<limit>" },
                { "export", "<query>", "<to name>", "<limit>" },
                { "move", "<query>", "<storage id>", "<partition id>", "<limit>" }
            },
        },
        onRun = function(command, args)
            if #args < 4 then
                print("IMPORT <QUERY> <FROM NAME> <LIMIT> - Import items matching the query from the specified inventory.")
                print("EXPORT <QUERY> <TO NAME> <LIMIT> - Export items matching the query to the specified inventory.")
                print("MOVE <QUERY> <STORAGE ID> <PARTITION ID> <LIMIT> - Move items matching the query to the specified storage and partition.")
                return
            end
            if selectedStorage == nil then
                print("No storage selected.")
                return
            end
            if selectedPartition == nil then
                print("No partition selected.")
                return
            end
            local ok, err = oil.getStorage(selectedStorage)
            if not ok then
                print("Error resizing partition: "..err)
                return
            end
            local ok2, err2 = ok.getPartition(selectedPartition)
            if not ok2 then
                print("Error resizing partition: "..err2)
                return
            end
            local action = args[1]:lower()
            local query = args[2]
            if action == "import" then
                local fromName = args[3]
                local limit = tonumber(args[4])
                if limit == nil then
                    print("Invalid limit.")
                    return
                end
                local ok3, err3 = ok2.importItems(query, fromName, limit)
                if not ok3 then
                    print("Error importing items: "..err3)
                    return
                end
                print("Imported "..ok3.." items.")
            elseif action == "export" then
                local toName = args[3]
                local limit = tonumber(args[4])
                if limit == nil then
                    print("Invalid limit.")
                    return
                end
                local ok3, err3 = ok2.exportItems(query, toName, limit)
                if not ok3 then
                    print("Error exporting items: "..err3)
                    return
                end
                print("Exported "..ok3.." items.")
            elseif action == "move" then
                if #args < 5 then
                    print("MOVE <QUERY> <STORAGE ID> <PARTITION ID> <LIMIT> - Move items matching the query to the specified storage and partition.")
                    return
                end
                local storageId = tonumber(args[3])
                if storageId == nil then
                    print("Invalid storage ID.")
                    return
                end
                local partitionId = tonumber(args[4])
                if partitionId == nil then
                    print("Invalid partition ID.")
                    return
                end
                local limit = tonumber(args[5])
                if limit == nil then
                    print("Invalid limit.")
                    return
                end
                local ok3, err3 = ok2.moveItems(query, storageId, partitionId, limit)
                if not ok3 then
                    print("Error moving items: "..err3)
                    return
                end
                print("Moved "..ok3.." items.")
            end
        end
    },
    {
        name = "defragment",
        description = "Defragment the selected partition.",
        usage = {},
        onRun = function(command, args)
            if selectedStorage == nil then
                print("No storage selected.")
                return
            end
            if selectedPartition == nil then
                print("No partition selected.")
                return
            end
            local ok, err = oil.getStorage(selectedStorage)
            if not ok then
                print("Error resizing partition: "..err)
                return
            end
            local ok2, err2 = ok.getPartition(selectedPartition)
            if not ok2 then
                print("Error resizing partition: "..err2)
                return
            end
            local moved, freed = ok2.defragment()
            print("Defragmentation complete. "..moved.." items moved, "..freed.." slots freed.")
        end
    },
    {
        name = "info",
        description = "Display information about the selected partition.",
        usage = {},
        onRun = function(command, args)
            if selectedStorage == nil then
                print("No storage selected.")
                return
            end
            if selectedPartition == nil then
                print("No partition selected.")
                return
            end
            local ok, err = oil.getStorage(selectedStorage)
            if not ok then
                print("Error resizing partition: "..err)
                return
            end
            local ok2, err2 = ok.getPartition(selectedPartition)
            if not ok2 then
                print("Error resizing partition: "..err2)
                return
            end
            local data = ok2.getUsage()
            local rows = {
                {"Key", "Value"},
                {"Storage Name", ok.getName() or "Unknown"},
                {"Partition Name", ok2.getName() or "Unknown"},
                {"Total Items", data.totalItems},
                {"Full Slots", data.fullSlots},
                {"Used Slots", data.usedSlots},
                {"Total Slots", data.totalSlots},
                {"Compression", ok2.isCompressed() and "*" or ""},
                {"Storage ID", selectedStorage},
                {"Partition ID", selectedPartition}
            }
            makeTable(rows)
        end
    },
    {
        name = "restart",
        description = "Restart Open Inventory Library.",
        usage = {},
        onRun = function(command, args)
            shell.run("oil.lua")
            oil = openInvLib
            print("Open Inventory Library restarted.")
        end
    }
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
            if #stack == 0 then
                print("Unknown command.")
                return
            end
            local compare = stack[#stack].value[stack[#stack].check]
            if compare ~= nil then
                stack[#stack].check = stack[#stack].check + 1
                if type(compare) == "string" then
                    if startsWith(compare, "<") then
                        if startsWith(v, '"') then
                            local val = v:sub(2)
                            while (not endsWith(v, '"')) or endsWith(v, '\\"') do
                                if endsWith(v, '\\"') then
                                    val = val:sub(1, -3) .. '"'
                                end
                                k = k + 1
                                if k > #args then
                                    print("Unclosed quotation mark.")
                                    return
                                end
                                v = args[k]
                                val = val .. " " .. v
                            end
                            table.insert(newArgs, val:sub(1, -2))
                        else
                            table.insert(newArgs, v)
                        end
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
        if command:lower() == "exit" then
            break
        end
        print()
        onCommand(command, args)
        print()
    end
end