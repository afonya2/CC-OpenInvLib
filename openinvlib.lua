local function loadFile(filename)
    local fa = fs.open(filename, "r")
    local fi = fa.readAll()
    fa.close()
    return textutils.unserialise(fi)
end
local function saveFile(filename, data)
    local fa = fs.open(filename, "w")
    fa.write(textutils.serialise(data))
    fa.close()
end
local function copy(tbl, deep)
    local out = {}
    for k, v in pairs(tbl) do
        if deep and type(v) == "table" then
            out[k] = copy(v, deep)
        else
            out[k] = v
        end
    end
    return out
end
local function includes(tbl, val)
    for k, v in pairs(tbl) do
        if v == val then return true, k end
    end
    return false
end
local function expect(fun, pos, arg, ...)
    local typs = { ... }
    for k, v in ipairs(typs) do
        if type(arg) == v then
            return
        end
    end
    error(fun .. ": bad argument #" .. pos .. " (expected " .. table.concat(typs, "/") .. ", got " .. type(arg) .. ")")
end
local function matchItem(itemA, itemB)
    if itemA.name == itemB.name and itemA.rawName == itemB.rawName and itemA.maxCount == itemB.maxCount and itemA.nbt == itemB.nbt and itemA.displayName == itemB.displayName then
        return true
    end
    return false
end
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
local function processQuery(query)
    local out = {}
    local ms1 = mysplit(query, "?")
    out.itemId = ms1[1]
    out.raw_query = ms1[2]
    out.query = {}
    local ms2 = mysplit(ms1[2] or "", "&")
    for k,v in ipairs(ms2) do
        local ms3 = mysplit(v, "=")
        if ms3[2] == nil then
            ms3[2] = true
        end
        out.query[ms3[1]] = ms3[2]
    end
    if ms1[2] == nil then
        out.query = nil
    end
    return out
end
local function matchItemQuery(item, query)
    local pq = processQuery(query)
    if item.name ~= pq.itemId then
        return false
    end
    if pq.query then
        local keyed = {}
        local function convertToKeys(tbl, prefix)
            local i = 1
            for k, v in pairs(tbl) do
                if type(v) == "table" then
                    keyed[prefix .. k] = convertToKeys(v, k .. ".")
                else
                    keyed[prefix .. k] = v
                end
                i = i + 1
                if i > 50 then
                    break
                end
            end
        end
        convertToKeys(item, "")
        for k, v in pairs(pq.query) do
            if keyed[k] ~= v then
                return false
            end
        end
    end
    return true
end
local function matchQueries(base, check)
    local q1 = processQuery(base)
    local q2 = processQuery(check)
    if q1.itemId ~= q2.itemId then
        return false
    end
    if q2.query then
        if not q1.query then
            return false
        end
        for k, v in pairs(q2.query) do
            if q1.query[k] ~= v then
                return false
            end
        end
    end
    return true
end
local function getItemQuery(item)
    local itemQuery = item.name
    if item.nbt then
        itemQuery = itemQuery .. "?nbt=" .. item.nbt
    end
    if item.displayName then
        if item.nbt then
            itemQuery = itemQuery .. "&displayName=" .. item.displayName
        else
            itemQuery = itemQuery .. "?displayName=" .. item.displayName
        end
    end
    return itemQuery
end
local compressionInfo = {
    ["minecraft:redstone_block?displayName=Block of Redstone"] = {
        item = "minecraft:redstone?displayName=Redstone Dust",
        ratio = 9,
        craft = {
            items = {
                x = "minecraft:redstone?displayName=Redstone Dust"
            },
            pattern = {
                {"x", "x", "x"},
                {"x", "x", "x"},
                {"x", "x", "x"}
            }
        },
        reverseCraft = {
            items = {
                x = "minecraft:redstone_block?displayName=Block of Redstone"
            },
            pattern = {
                {"x"}
            }
        }
    }
}

local storage = {}
local itemCache = {}
local noCache = true
if fs.exists("openinvlib_data/storage.txt") then
    storage = loadFile("openinvlib_data/storage.txt")
end
if fs.exists("openinvlib_data/item_cache.txt") then
    itemCache = loadFile("openinvlib_data/item_cache.txt")
    noCache = false
end
local turtleName = nil
if turtle then
    for k,v in ipairs({"top", "right", "left", "bottom", "behind", "front"}) do
        local t = peripheral.getType(v)
        local wrp = peripheral.wrap(v)
        if t == "modem" then
            if not wrp.isWireless() then
                turtleName = wrp.getNameLocal()
            end
        end
    end
end

local wrappedStorages = {}

local function scanStorages()
    for n, inv in pairs(wrappedStorages) do
        local size = inv.size()
        if not itemCache[n] then
            itemCache[n] = {
                items = {},
                lastScanned = os.epoch("utc"),
                size = size
            }
        end
        local list = inv.list()
        for i = 1, size do
            local itm = list[i]
            if itm then
                local detail = inv.getItemDetail(i)
                itemCache[n].items[i] = detail
            else
                itemCache[n].items[i] = nil
            end
        end
        itemCache[n].lastScanned = os.epoch("utc")
        itemCache[n].size = size
    end
    saveFile("openinvlib_data/item_cache.txt", itemCache)
end
local function scanStorage(strg)
    expect("scanStorage", 1, strg, "string")

    local inv = wrappedStorages[strg]
    if not inv then return end
    local size = inv.size()
    if not itemCache[strg] then
        itemCache[strg] = {
            items = {},
            lastScanned = os.epoch("utc"),
            size = size
        }
    end
    local list = inv.list()
    for i = 1, size do
        local itm = list[i]
        if itm then
            local detail = inv.getItemDetail(i)
            itemCache[strg].items[i] = detail
        else
            itemCache[strg].items[i] = nil
        end
    end
    itemCache[strg].lastScanned = os.epoch("utc")
    itemCache[strg].size = size
    saveFile("openinvlib_data/item_cache.txt", itemCache)
end

local function generateTurtleInvWrap(tid)
    local out = {}
    out.size = function()
        return 16
    end
    out.list = function()
        local llist = {}
        for i=1,16 do
            llist[i] = turtle.getItemDetail(i)
        end
        return llist
    end
    out.getItemDetail = function(slot)
        return turtle.getItemDetail(slot, true)
    end
    out.getItemLimit = function(slot)
        return turtle.getItemDetail(slot, true).maxCount
    end
    out.pushItems = function(toName, fromSlot, limit, toSlot)
        local wrap = wrappedStorages[toName]
        return wrap.pullItems(tid, fromSlot, limit, toSlot)
    end
    out.pullItems = function(fromName, fromSlot, limit, toSlot)
        local wrap = wrappedStorages[fromName]
        return wrap.pushItems(tid, fromSlot, limit, toSlot)
    end
    return out
end

local function scanPeripherals()
    local newWrapped = {}
    local periphs = peripheral.getNames()
    for _, n in pairs(periphs) do
        local t1, t2 = peripheral.getType(n)
        if t2 == "inventory" then
            newWrapped[n] = peripheral.wrap(n)
        end
    end
    if turtleName then
        newWrapped[turtleName] = generateTurtleInvWrap(turtleName)
    end
    wrappedStorages = newWrapped
end
scanPeripherals()

if noCache then
    scanStorages()
end
for k, v in pairs(wrappedStorages) do
    if itemCache[k] == nil then
        scanStorage(k)
    else
        local lastScanned = itemCache[k].lastScanned or 0
        if os.epoch("utc") - lastScanned > 60000 then
            scanStorage(k)
        end
    end
end

local function createStorage(name, strgs)
    expect("createStorage", 1, name, "string")
    expect("createStorage", 2, strgs, "table")

    for _, s in ipairs(storage) do
        for _, ss in ipairs(strgs) do
            if includes(s.storages, ss) then
                return nil, "A storage with one or more of these peripherals already exists"
            end
        end
    end
    for _, ss in ipairs(strgs) do
        if wrappedStorages[ss] == nil then
            return nil, "One or more of these peripherals do not exist"
        end
    end
    local newStorage = {
        name = name,
        storages = strgs,
        partitions = {}
    }
    table.insert(storage, newStorage)
    saveFile("openinvlib_data/storage.txt", storage)
    return #storage
end

local function getStorage(id)
    expect("getStorage", 1, id, "number")

    if storage[id] == nil then return nil, "Storage not found" end
    for _, strg in ipairs(storage[id].storages) do
        if wrappedStorages[strg] == nil then
            return nil, "Peripheral " .. strg .. " is not available"
        end
    end

    local strapi = {}
    strapi.getName = function()
        return storage[id].name
    end
    strapi.setName = function(newName)
        expect("setName", 1, newName, "string")
        storage[id].name = newName
        saveFile("openinvlib_data/storage.txt", storage)
    end
    strapi.getStorages = function()
        return copy(storage[id].storages, true)
    end
    strapi.addStorage = function(strg)
        expect("addStorage", 1, strg, "string")
        for _, s in ipairs(storage) do
            if includes(s.storages, strg) then
                return nil, "A storage with this peripheral already exists"
            end
        end
        if not wrappedStorages[strg] then
            return nil, "Peripheral does not exist"
        end
        table.insert(storage[id].storages, strg)
        saveFile("openinvlib_data/storage.txt", storage)
    end
    strapi.removeStorage = function(strg)
        expect("removeStorage", 1, strg, "string")
        local found, idx = includes(storage[id].storages, strg)
        if not found then
            return nil, "Peripheral not found in this storage"
        end
        table.remove(storage[id].storages, idx)
        saveFile("openinvlib_data/storage.txt", storage)
    end
    strapi.getSize = function()
        local size = 0
        for _, s in ipairs(storage[id].storages) do
            size = size + itemCache[s].size
        end
        return size
    end
    strapi.getPartitions = function()
        local out = {}
        local size = strapi.getSize()
        local freeS = 0
        local i = 1
        while i <= size do
            local used = false
            for _, p in ipairs(storage[id].partitions) do
                if i >= p.startPos and i <= p.endPos then
                    if freeS ~= 0 and freeS < i then
                        table.insert(out, {
                            name = "Unallocated",
                            startPos = freeS,
                            endPos = i - 1
                        })
                        freeS = 0
                    end
                    table.insert(out, {
                        name = p.name,
                        startPos = p.startPos,
                        endPos = p.endPos
                    })
                    used = true
                    i = p.endPos
                    break
                end
            end
            if (not used) and (freeS == 0) then
                freeS = i
            end
            i = i + 1
        end
        if freeS ~= 0 and freeS <= size then
            table.insert(out, {
                name = "Unallocated",
                startPos = freeS,
                endPos = size
            })
        end
        return out
    end
    strapi.createPartition = function(name, startPos, endPos, isCompressed)
        expect("createPartition", 1, name, "string")
        expect("createPartition", 2, startPos, "number")
        expect("createPartition", 3, endPos, "number")
        expect("createPartition", 4, isCompressed, "boolean", "nil")

        if startPos < 1 or endPos < 1 or startPos > endPos then
            return nil, "Invalid start or end position"
        end
        for _, p in ipairs(storage[id].partitions) do
            if not (endPos < p.startPos or startPos > p.endPos) then
                return nil, "This partition overlaps with an existing partition"
            end
        end
        local maxSize = strapi.getSize()
        if endPos > maxSize then
            return nil, "End position exceeds storage size (" .. maxSize .. ")"
        end
        table.insert(storage[id].partitions, {
            name = name,
            startPos = startPos,
            endPos = endPos,
            isCompressed = isCompressed or false
        })
        saveFile("openinvlib_data/storage.txt", storage)
        return #storage[id].partitions
    end
    strapi.getPartition = function(partId)
        expect("getPartition", 1, partId, "number")

        if not storage[id].partitions[partId] then
            return nil, "Partition not found"
        end
        local parapi = {}
        parapi.getName = function()
            return storage[id].partitions[partId].name
        end
        parapi.setName = function(newName)
            expect("setName", 1, newName, "string")
            storage[id].partitions[partId].name = newName
            saveFile("openinvlib_data/storage.txt", storage)
        end
        parapi.getSize = function()
            return storage[id].partitions[partId].endPos - storage[id].partitions[partId].startPos + 1
        end
        parapi.isCompressed = function()
            return storage[id].partitions[partId].isCompressed
        end
        parapi.move = function(newStart)
            expect("move", 1, newStart, "number")

            local partSize = parapi.getSize()
            local newEnd = newStart + partSize - 1
            if newStart < 1 or newEnd < 1 or newStart > newEnd then
                return nil, "Invalid start position"
            end
            for idx, p in ipairs(storage[id].partitions) do
                if idx ~= partId then
                    if not (newEnd < p.startPos or newStart > p.endPos) then
                        return nil, "This partition overlaps with an existing partition"
                    end
                end
            end
            local maxSize = strapi.getSize()
            if newEnd > maxSize then
                return nil, "End position exceeds storage size (" .. maxSize .. ")"
            end
            storage[id].partitions[partId].startPos = newStart
            storage[id].partitions[partId].endPos = newEnd
            saveFile("openinvlib_data/storage.txt", storage)
        end
        parapi.resize = function(newSize)
            expect("resize", 1, newSize, "number")
            if newSize < 1 then
                return nil, "Invalid size"
            end
            local newEnd = storage[id].partitions[partId].startPos + newSize - 1
            for idx, p in ipairs(storage[id].partitions) do
                if idx ~= partId then
                    if not (newEnd < p.startPos or storage[id].partitions[partId].startPos > p.endPos) then
                        return nil, "This partition overlaps with an existing partition"
                    end
                end
            end
            local maxSize = strapi.getSize()
            if newEnd > maxSize then
                return nil, "End position exceeds storage size (" .. maxSize .. ")"
            end
            storage[id].partitions[partId].endPos = newEnd
            saveFile("openinvlib_data/storage.txt", storage)
        end
        parapi.getPositions = function()
            return storage[id].partitions[partId].startPos, storage[id].partitions[partId].endPos
        end
        parapi.list = function()
            local base = strapi._internal.list()
            local out = {}
            for i = storage[id].partitions[partId].startPos, storage[id].partitions[partId].endPos do
                out[i - storage[id].partitions[partId].startPos + 1] = base[i]
            end
            return out
        end
        parapi.listItems = function(noUncompressed)
            expect("listItems", 1, noUncompressed, "boolean", "nil")

            local base = parapi.list()
            local out = {}
            for i = 1, parapi.getSize() do
                local item = base[i]
                if item then
                    local itemQuery = getItemQuery(item)
                    if out[itemQuery] == nil then
                        out[itemQuery] = copy(item)
                    else
                        out[itemQuery].count = out[itemQuery].count + item.count
                        for k,v in pairs(item) do
                            if out[itemQuery][k] == nil then
                                out[itemQuery][k] = v
                            end
                        end
                    end
                    if compressionInfo[itemQuery] and storage[id].partitions[partId].isCompressed then
                        if not noUncompressed then
                            local cInfo = compressionInfo[itemQuery]
                            if out[cInfo.item] == nil then
                                local proc = processQuery(cInfo.item)
                                out[cInfo.item] = {
                                    name = proc.itemId,
                                    count = item.count * cInfo.ratio,
                                    maxCount = item.maxCount,
                                    displayName = proc.query and proc.query.displayName or nil,
                                    nbt = proc.query and proc.query.nbt or nil,
                                    containsCompressed = true
                                }
                            else
                                out[cInfo.item].count = out[cInfo.item].count + (item.count * cInfo.ratio)
                                out[cInfo.item].containsCompressed = true
                            end
                        end
                    end
                end
            end
            return out
        end
        parapi.getItemInfo = function(query, noUncompressed)
            expect("getItemInfo", 1, query, "string")

            local list = parapi.listItems(noUncompressed)
            local out = {}
            for k, v in pairs(list) do
                if matchItemQuery(v, query) then
                    table.insert(out, copy(v))
                end
            end
            return out
        end
        parapi.getItemCount = function(query, noUncompressed)
            expect("getItemCount", 1, query, "string")

            local list = parapi.listItems(noUncompressed)
            local count = 0
            for k, v in pairs(list) do
                if matchItemQuery(v, query) then
                    count = count + v.count
                end
            end
            return count
        end
        parapi.getUsage = function()
            local out = {
                usedSlots = 0,
                totalSlots = parapi.getSize(),
                fullSlots = 0,
                totalItems = 0
            }
            local list = parapi.list()
            for k, v in pairs(list) do
                out.usedSlots = out.usedSlots + 1
                if v.count >= v.maxCount then
                    out.fullSlots = out.fullSlots + 1
                end
                out.totalItems = out.totalItems + v.count
            end
            return out
        end
        parapi.canImport = function(query, limit)
            expect("canImport", 1, query, "string")
            expect("canImport", 2, limit, "number", "nil")

            local list = parapi.list()
            local toTransfer = limit or (2^40)
            local transferred = 0
            for k=1,parapi.getSize() do
                local v = list[k]
                if v == nil then
                    toTransfer = math.max(0, toTransfer - 64)
                    transferred = math.min(limit, transferred + 64)
                    if toTransfer <= 0 then
                        return transferred
                    end
                elseif matchItemQuery(v, query) then
                    if v.count < v.maxCount then
                        toTransfer = math.max(0, toTransfer - (v.maxCount - v.count))
                        transferred = math.min(limit, transferred + (v.maxCount - v.count))
                        if toTransfer <= 0 then
                            return transferred
                        end
                    end
                end
            end
            return transferred
        end
        parapi.craft = function(key, pattern, outcome, outcomeCount, count)
            if (not turtle) or (not turtle.craft) then
                return nil, "Crafting is only supported on crafty turtles"
            end
            if not turtleName then
                return nil, "A wired modem must be placed around the turtle"
            end
            for i = 1, 16 do
                if turtle.getItemCount(i) > 0 then
                    return nil, "The turtle's inventory must be empty"
                end
            end
            expect("craft", 1, key, "table")
            expect("craft", 2, pattern, "table")
            expect("craft", 3, outcome, "string")
            expect("craft", 4, outcomeCount, "number")
            expect("craft", 5, count, "number", "nil")

            if (type(count) == "number") and (count == 0) then
                return true
            end
            count = count or 1

            if parapi.canImport(outcome, outcomeCount * count) < count then
                return nil, "Not enough space to import crafted items"
            end
            local neededItems = {}
            for i = 1, 3 do
                if pattern[i] then
                    for j = 1, 3 do
                        if pattern[i][j] then
                            local item = key[pattern[i][j]]
                            if not item then
                                return nil, "Missing crafting ingredient: " .. pattern[i][j]
                            end
                            if neededItems[item] then
                                neededItems[item] = neededItems[item] + count
                            else
                                neededItems[item] = count
                            end
                        end
                    end
                end
            end
            for k, v in pairs(neededItems) do
                local ic = parapi.getItemCount(k, true)
                if ic < v then
                    return nil, "Not enough of item: " .. k .. " (need " .. v-ic .. " more)"
                end
            end
            local craftSlots = {1,2,3,5,6,7,9,10,11}
            for i = 1, 3 do
                if pattern[i] then
                    for j = 1, 3 do
                        if pattern[i][j] then
                            local item = key[pattern[i][j]]
                            if not item then
                                return nil, "Missing crafting ingredient: " .. pattern[i][j]
                            end
                            local ok,err = parapi.exportItems(item, turtleName, count, true, craftSlots[(i-1)*3 + j])
                            if not ok then
                                return nil, err
                            end
                        end
                    end
                end
            end
            local ok, err = turtle.craft()
            if not ok then
                return nil, err
            end
            scanStorage(turtleName)
            local ok2,err2 = parapi.importItems(outcome, turtleName, outcomeCount * count, true)
            if not ok2 then
                return nil, err2
            end
            return true
        end
        parapi.exportItems = function(query, toName, limit, noCompression, toSlot)
            expect("exportItems", 1, query, "string")
            expect("exportItems", 2, toName, "string")
            expect("exportItems", 3, limit, "number", "nil")
            expect("exportItems", 4, noCompression, "boolean", "nil")
            expect("exportItems", 5, toSlot, "number", "nil")

            local toInv = wrappedStorages[toName]
            if not toInv then
                return nil, "Peripheral is not available"
            end
            local list = parapi.list()
            local toTransfer = limit or (2^40)
            local changed = 0
            for k, v in pairs(list) do
                if matchItemQuery(v, query) then
                    local change, err = parapi._internal.pushItems(toName, k, toTransfer, toSlot)
                    if change == nil then
                        return nil, err
                    end
                    toTransfer = toTransfer - change
                    changed = changed + change
                    if toTransfer < 1 then
                        break
                    end
                end
            end
            if (toTransfer > 0) and (not noCompression) and storage[id].partitions[partId].isCompressed then
                list = parapi.list()
                for k, v in pairs(list) do
                    if compressionInfo[getItemQuery(v)] then
                        local cInfo = compressionInfo[getItemQuery(v)]
                        if cInfo then
                            if matchQueries(cInfo.item, query) then
                                local crafty = math.min(parapi.getItemCount(getItemQuery(v), true), math.ceil(toTransfer / cInfo.ratio))
                                local ok,err = parapi.craft(cInfo.reverseCraft.items, cInfo.reverseCraft.pattern, cInfo.item, cInfo.ratio, crafty)
                                if ok then
                                    local c, err2 = parapi.exportItems(query, toName, toTransfer, true, toSlot)
                                    if not c then
                                        return nil, err2
                                    end
                                    toTransfer = toTransfer - c
                                    changed = changed + c
                                end
                                if toTransfer < 1 then
                                    break
                                end
                            end
                        end
                    end
                end
            end
            return changed
        end
        parapi.importItems = function(query, fromName, limit, noCompression, toSlot)
            expect("importItems", 1, query, "string")
            expect("importItems", 2, fromName, "string")
            expect("importItems", 3, limit, "number", "nil")
            expect("importItems", 4, noCompression, "boolean", "nil")
            expect("importItems", 5, toSlot, "number", "nil")

            local fromInv = wrappedStorages[fromName]
            if not fromInv then
                return nil, "Peripheral is not available"
            end
            local canImport = parapi.canImport(query, limit)
            local strList = parapi.list()
            local toTransfer = math.min(canImport, limit or (2^40))
            local changed = 0
            for k,v in pairs(itemCache[fromName].items) do
                if matchItemQuery(v, query) then
                    for kk, vv in pairs(strList) do
                        if matchItem(v, vv) and (vv.count < vv.maxCount) then
                            local change, err = parapi._internal.pullItems(fromName, k, toTransfer, toSlot or kk)
                            if change == nil then
                                return nil, err
                            end
                            toTransfer = toTransfer - change
                            changed = changed + change
                            if toTransfer < 1 then
                                break
                            end
                        end
                    end
                    if toTransfer < 1 then
                        break
                    end
                end
            end
            if toTransfer > 0 then
                strList = parapi.list()
                for k, v in pairs(itemCache[fromName].items) do
                    if matchItemQuery(v, query) then
                        local change, err = parapi._internal.pullItems(fromName, k, toTransfer, toSlot)
                        if change == nil then
                            return nil, err
                        end
                        toTransfer = toTransfer - change
                        changed = changed + change
                        if toTransfer < 1 then
                            break
                        end
                    end
                end
            end
            if (not noCompression) and storage[id].partitions[partId].isCompressed then
                parapi.autoCompress()
            end
            return changed
        end
        parapi.moveItems = function(query, toStorage, toPartition, limit, noCompression)
            expect("moveItems", 1, query, "string")
            expect("moveItems", 2, toStorage, "number")
            expect("moveItems", 3, toPartition, "number")
            expect("moveItems", 4, limit, "number", "nil")
            expect("moveItems", 5, noCompression, "boolean", "nil")

            local toStrg, err1 = getStorage(toStorage)
            if not toStrg then
                return nil, err1
            end
            local toPart, err2 = toStrg.getPartition(toPartition)
            if not toPart then
                return nil, err2
            end
            local toSize = toPart.getSize()
            local canImport = toPart.canImport(query, limit)
            local toTransfer = math.min(canImport, limit or (2^40))
            local changed = 0
            local list = parapi.list()
            for k, v in pairs(list) do
                if matchItemQuery(v, query) then
                    local chest, realFromSlot, slotInStorage = parapi._internal.getRealSlot(k)
                    local ls = toPart.list()
                    for kk, vv in pairs(ls) do
                        if matchItem(v, vv) and (vv.count < vv.maxCount) then
                            local change, err = toPart._internal.pullItems(chest, realFromSlot, toTransfer, kk)
                            if change == nil then
                                return nil, err
                            end
                            toTransfer = toTransfer - change
                            changed = changed + change
                            if toTransfer <= 0 then
                                break
                            end
                        end
                    end
                    if toTransfer <= 0 then
                        break
                    end
                end
            end
            if toTransfer > 0 then
                list = parapi.list()
                for k, v in pairs(list) do
                    if matchItemQuery(v, query) then
                        local chest, realFromSlot, slotInStorage = parapi._internal.getRealSlot(k)
                        local change, err = toPart._internal.pullItems(chest, realFromSlot, toTransfer)
                        if change == nil then
                            return nil, err
                        end
                        toTransfer = toTransfer - change
                        changed = changed + change
                        if toTransfer <= 0 then
                            break
                        end
                    end
                end
            end
            if (toTransfer > 0) and (not noCompression) and (storage[id].partitions[partId].isCompressed) then
                list = parapi.list()
                for k, v in pairs(list) do
                    if compressionInfo[getItemQuery(v)] then
                        local cInfo = compressionInfo[getItemQuery(v)]
                        if cInfo then
                            if matchQueries(cInfo.item, query) then
                                local crafty = math.min(parapi.getItemCount(getItemQuery(v), true), math.ceil(toTransfer / cInfo.ratio))
                                local ok,err = parapi.craft(cInfo.reverseCraft.items, cInfo.reverseCraft.pattern, cInfo.item, cInfo.ratio, crafty)
                                if ok then
                                    local c, err2 = parapi.moveItems(query, toStorage, toPartition, toTransfer, true)
                                    if not c then
                                        return nil, err2
                                    end
                                    toTransfer = toTransfer - c
                                    changed = changed + c
                                end
                            end
                        end
                    end
                end
            end
            if toPart.isCompressed() and (not noCompression) then
                toPart.autoCompress()
            end
            return changed
        end
        parapi.defragment = function()
            local list = parapi.list()
            local itemsMoved = 0
            local slotsFreed = 0
            for k, v in pairs(list) do
                if (v ~= nil) and (v.count > 0) then
                    if v.count < v.maxCount then
                        for kk = k + 1, parapi.getSize() do
                            local vv = list[kk]
                            if vv and matchItem(v, vv) and (v.count < v.maxCount) then
                                local oldVV = copy(vv)
                                local toMove = math.min(vv.count, v.maxCount - v.count)
                                local chest, realFromSlot, slotInStorage = parapi._internal.getRealSlot(k)
                                if not chest then
                                    break
                                end
                                local ok = parapi._internal.pushItems(chest, kk, toMove, k)
                                if ok then
                                    itemsMoved = itemsMoved + ok
                                    if oldVV.count <= ok then
                                        slotsFreed = slotsFreed + 1
                                    end
                                    if v.count >= v.maxCount then
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            list = parapi.list()
            for i=1, parapi.getSize() do
                local v = list[i]
                if v == nil then
                    for j = parapi.getSize(), 1, -1 do
                        local vv = list[j]
                        if vv ~= nil then
                            local chest, realFromSlot, slotInStorage = parapi._internal.getRealSlot(i)
                            if not chest then
                                break
                            end
                            local ok = parapi._internal.pushItems(chest, j, vv.count, i)
                            break
                        end
                    end
                end
            end
            return itemsMoved, slotsFreed
        end
        parapi.autoCompress = function()
            if not storage[id].partitions[partId].isCompressed then
                return nil, "This partition does not support compression"
            end
            local baseCount = 0
            local compCount = 0
            for k, v in pairs(compressionInfo) do
                local ic = parapi.getItemCount(v.item, true)
                local craftable = math.floor(ic / v.ratio)
                if craftable > 0 then
                    local ok = parapi.craft(v.craft.items, v.craft.pattern, k, 1, craftable)
                    if ok then
                        baseCount = baseCount + (craftable * v.ratio)
                        compCount = compCount + craftable
                    end
                end
            end
            return baseCount, compCount
        end
        parapi._internal = {}
        parapi._internal.size = function()
            return parapi.getSize()
        end
        parapi._internal.list = function()
            return parapi.list()
        end
        parapi._internal.getRealSlot = function(slot)
            expect("getRealSlot", 1, slot, "number")

            if slot < 1 or slot > parapi.getSize() then
                return nil, nil, nil, "Slot out of range"
            end
            local ret = {strapi._internal.getRealSlot(slot + storage[id].partitions[partId].startPos - 1)}
            if ret[3] ~= nil then
                return ret[1], ret[2], ret[3]
            end
            table.insert(ret, slot + storage[id].partitions[partId].startPos - 1)
            return table.unpack(ret)
        end
        parapi._internal.getItemDetail = function(slot)
            expect("getItemDetail", 1, slot, "number")

            local chest, realSlot, err = parapi._internal.getRealSlot(slot)
            if chest then
                return itemCache[chest].items[realSlot]
            else
                return nil, err
            end
        end
        parapi._internal.pushItems = function(toName, fromSlot, limit, toSlot)
            expect("pushItems", 1, toName, "string")
            expect("pushItems", 2, fromSlot, "number")
            expect("pushItems", 3, limit, "number", "nil")
            expect("pushItems", 4, toSlot, "number", "nil")

            local toInv = wrappedStorages[toName]
            if not toInv then
                return nil, "Peripheral is not available"
            end
            local chest, realFromSlot, slotInStorage, err = parapi._internal.getRealSlot(fromSlot)
            if chest then
                return strapi._internal.pushItems(toName, slotInStorage, limit, toSlot)
            else
                return nil, err
            end
        end
        parapi._internal.pullItems = function(fromName, fromSlot, limit, toSlot)
            expect("pullItems", 1, fromName, "string")
            expect("pullItems", 2, fromSlot, "number")
            expect("pullItems", 3, limit, "number", "nil")
            expect("pullItems", 4, toSlot, "number", "nil")

            local fromInv = wrappedStorages[fromName]
            if not fromInv then
                return nil, "Peripheral is not available"
            end
            local item = itemCache[fromName].items[fromSlot]
            if not item then
                return 0
            end
            item = copy(item)
            local baseToTransfer = math.min(limit or item.count, item.count)
            local toTransfer = math.min(limit or item.count, item.count)
            if toSlot then
                local chest, realToSlot, slotInStorage, err = parapi._internal.getRealSlot(toSlot)
                if chest then
                    return strapi._internal.pullItems(fromName, fromSlot, toTransfer, slotInStorage)
                else
                    return nil, err
                end
            end
            local ls = strapi._internal.list()
            for i = storage[id].partitions[partId].startPos, storage[id].partitions[partId].endPos do
                local titem = ls[i]
                if (titem == nil) or (matchItem(titem, item) and titem.count < titem.maxCount) then
                    local change = strapi._internal.pullItems(fromName, fromSlot, toTransfer, i)
                    toTransfer = toTransfer - change
                    if toTransfer <= 0 then
                        return baseToTransfer
                    end
                end
            end
            return baseToTransfer - toTransfer
        end
        parapi.delete = function()
            table.remove(storage[id].partitions, partId)
            saveFile("openinvlib_data/storage.txt", storage)
        end
        return parapi
    end
    strapi._internal = {}
    strapi._internal.list = function()
        local out = {}
        local offset = 0
        for _, s in ipairs(storage[id].storages) do
            for i = 1, itemCache[s].size do
                local itm = itemCache[s].items[i]
                out[offset + i] = itm
            end
            offset = offset + itemCache[s].size
        end
        return out
    end
    strapi._internal.getRealSlot = function(slot)
        expect("getRealSlot", 1, slot, "number")

        if slot < 1 or slot > strapi.getSize() then
            return nil, nil, "Slot out of range"
        end
        local offset = 0
        for _, s in ipairs(storage[id].storages) do
            if slot <= offset + itemCache[s].size then
                return s, slot - offset
            end
            offset = offset + itemCache[s].size
        end
        return nil, nil, "Slot out of range"
    end
    strapi._internal.getItemDetail = function(slot)
        expect("getItemDetail", 1, slot, "number")

        local chest, realSlot, err = strapi._internal.getRealSlot(slot)
        if chest then
            return itemCache[chest].items[realSlot]
        else
            return nil, err
        end
    end
    strapi._internal.pushItems = function(toName, fromSlot, limit, toSlot)
        expect("pushItems", 1, toName, "string")
        expect("pushItems", 2, fromSlot, "number")
        expect("pushItems", 3, limit, "number", "nil")
        expect("pushItems", 4, toSlot, "number", "nil")

        local toInv = wrappedStorages[toName]
        if not toInv then
            return nil, "Peripheral is not available"
        end
        local chest, realFromSlot, err = strapi._internal.getRealSlot(fromSlot)
        if chest then
            local wrappedFrom = wrappedStorages[chest]
            local item = itemCache[chest].items[realFromSlot]
            if not item then
                return 0
            end
            item = copy(item)
            if toSlot then
                local change = wrappedFrom.pushItems(toName, realFromSlot, limit, toSlot)
                if itemCache[toName].items[toSlot] == nil then
                    itemCache[toName].items[toSlot] = toInv.getItemDetail(toSlot)
                else
                    itemCache[toName].items[toSlot].count = itemCache[toName].items[toSlot].count + change
                end
                itemCache[chest].items[realFromSlot].count = itemCache[chest].items[realFromSlot].count - change
                if itemCache[chest].items[realFromSlot].count <= 0 then
                    itemCache[chest].items[realFromSlot] = nil
                end
                saveFile("openinvlib_data/item_cache.txt", itemCache)
                return change
            else
                local baseToTransfer = math.min(limit or item.count, item.count)
                local toTransfer = math.min(limit or item.count, item.count)
                for i = 1, itemCache[toName].size do
                    local titem = itemCache[toName].items[i]
                    if (titem == nil) or (matchItem(titem, item) and titem.count < titem.maxCount) then
                        local change = wrappedFrom.pushItems(toName, realFromSlot, toTransfer, i)
                        if itemCache[toName].items[i] == nil then
                            itemCache[toName].items[i] = toInv.getItemDetail(i)
                        else
                            itemCache[toName].items[i].count = itemCache[toName].items[i].count + change
                        end
                        itemCache[chest].items[realFromSlot].count = itemCache[chest].items[realFromSlot].count - change
                        if itemCache[chest].items[realFromSlot].count <= 0 then
                            itemCache[chest].items[realFromSlot] = nil
                        end
                        toTransfer = toTransfer - change
                        if toTransfer <= 0 then
                            saveFile("openinvlib_data/item_cache.txt", itemCache)
                            return baseToTransfer
                        end
                    end
                end
                saveFile("openinvlib_data/item_cache.txt", itemCache)
                return baseToTransfer - toTransfer
            end
        else
            return nil, err
        end
    end
    strapi._internal.pullItems = function(fromName, fromSlot, limit, toSlot)
        expect("pullItems", 1, fromName, "string")
        expect("pullItems", 2, fromSlot, "number")
        expect("pullItems", 3, limit, "number", "nil")
        expect("pullItems", 4, toSlot, "number", "nil")

        local fromInv = wrappedStorages[fromName]
        if not fromInv then
            return nil, "Peripheral is not available"
        end
        local item = itemCache[fromName].items[fromSlot]
        if not item then
            return 0
        end
        item = copy(item)
        local baseToTransfer = math.min(limit or item.count, item.count)
        local toTransfer = math.min(limit or item.count, item.count)
        if toSlot then
            local chest, realToSlot, err = strapi._internal.getRealSlot(toSlot)
            if chest then
                local wrappedTo = wrappedStorages[chest]
                local change = wrappedTo.pullItems(fromName, fromSlot, toTransfer, realToSlot)
                if itemCache[chest].items[realToSlot] == nil then
                    itemCache[chest].items[realToSlot] = wrappedTo.getItemDetail(realToSlot)
                else
                    itemCache[chest].items[realToSlot].count = itemCache[chest].items[realToSlot].count + change
                end
                itemCache[fromName].items[fromSlot].count = itemCache[fromName].items[fromSlot].count - change
                if itemCache[fromName].items[fromSlot].count <= 0 then
                    itemCache[fromName].items[fromSlot] = nil
                end
                saveFile("openinvlib_data/item_cache.txt", itemCache)
                return change
            else
                return nil, err
            end
        end
        for _, s in ipairs(storage[id].storages) do
            for i = 1, itemCache[s].size do
                local titem = itemCache[s].items[i]
                if (titem == nil) or (matchItem(titem, item) and titem.count < titem.maxCount) then
                    local wrappedTo = wrappedStorages[s]
                    local change = wrappedTo.pullItems(fromName, fromSlot, toTransfer, i)
                    if itemCache[s].items[i] == nil then
                        itemCache[s].items[i] = wrappedTo.getItemDetail(i)
                    else
                        itemCache[s].items[i].count = itemCache[s].items[i].count + change
                    end
                    itemCache[fromName].items[fromSlot].count = itemCache[fromName].items[fromSlot].count - change
                    if itemCache[fromName].items[fromSlot].count <= 0 then
                        itemCache[fromName].items[fromSlot] = nil
                    end
                    toTransfer = toTransfer - change
                    if toTransfer <= 0 then
                        saveFile("openinvlib_data/item_cache.txt", itemCache)
                        return baseToTransfer
                    end
                end
            end
        end
        saveFile("openinvlib_data/item_cache.txt", itemCache)
        return baseToTransfer - toTransfer
    end
    strapi.delete = function()
        table.remove(storage, id)
        saveFile("openinvlib_data/storage.txt", storage)
    end

    return strapi
end

_G.openInvLib = {
    scanStorages = scanStorages,
    scanStorage = scanStorage,
    createStorage = createStorage,
    scanPeripherals = scanPeripherals,
    getStorage = getStorage
}
