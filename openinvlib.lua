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
    for k,v in pairs(tbl) do
        if deep and type(v) == "table" then
            out[k] = copy(v, deep)
        else
            out[k] = v
        end
    end
    return out
end

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

local wrappedStorages = {}

local function scanStorages()
    for n, inv in pairs(wrappedStorages) do
        if not itemCache[n] then
            itemCache[n] = {
                items = {},
                lastScanned = os.epoch("utc")
            }
        end
        local list = inv.list()
        local size = inv.size()
        for i=1, size do
            local itm = list[i]
            if itm then
                local detail = inv.getItemDetail(i)
                itemCache[n].items[i] = detail
            end
        end
        itemCache[n].lastScanned = os.epoch("utc")
    end
    saveFile("openinvlib_data/item_cache.txt", itemCache)
end

local function scanStorage(strg)
    local inv = wrappedStorages[strg]
    if not inv then return end
    if not itemCache[strg] then
        itemCache[strg] = {
            items = {},
            lastScanned = os.epoch("utc")
        }
    end
    local list = inv.list()
    local size = inv.size()
    for i=1, size do
        local itm = list[i]
        if itm then
            local detail = inv.getItemDetail(i)
            itemCache[strg].items[i] = detail
        end
    end
    itemCache[strg].lastScanned = os.epoch("utc")
    saveFile("openinvlib_data/item_cache.txt", itemCache)
end

local periphs = peripheral.getNames()
for _, n in pairs(periphs) do
    local t1, t2 = peripheral.getType(n)
    if t2 == "inventory" then
        wrappedStorages[n] = peripheral.wrap(n)
    end
end

if noCache then
    scanStorages()
end
for k, v in pairs(wrappedStorages) do
    if itemCache[k] == nil then
        scanStorage(k)
    end
end