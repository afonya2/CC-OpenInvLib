# Open Inventory Library (OIL)
A modern inventory library for the CC: Tweaked Minecraft mod.

## Installing
run `wget https://raw.githubusercontent.com/afonya2/CC-OpenInvLib/refs/heads/main/openinvlib.lua oil.lua` on a computer.

> [!NOTE]  
> OIL stores its configuration and cache in the `openinvlib_data` folder

## Definitions

- inventory: A peripheral that has an inventory (chest, furnace)
- storage: Multiple inventories joined together
- partition: A section of a storage, is capable of storing items

## Documentation
> [!WARNING]  
> At a time, only 1 instance should run to prevent any cache issues. Because of this OIL can be accessed from the global enviroment instead of importing it.

Starting it from lua:
```lua
shell.run("oil.lua")
```
After starting it, it can be accessed from anywhere by using the `openInvLib` global.

### scanStorages
Scans the storages and updates the item cache

**Parameters**

**Returns**

### scanStorage
Scans a specific storage and updates the item cache

**Parameters**

- storage: string: The peripheral name of the storage

**Returns**

### scanPeripherals
Scans the connected peripherals for inventories

**Parameters**

**Returns**

### createStorage
Creates a new storage

**Parameters**

- name: string: The name of the new storage
- storages: table: A list of the peripheral names for this storage

**Returns**

> [!WARNING]  
> The ID of a storage and the ID of a partition can change over time, if a storage/partition is deleted.
- number: The ID of the new storage

or

- nil
- string: Explaining the error

### getStorage
Returns a storage object

**Parameters**

- id: number: The ID of the storage

**Returns**

- table: A storage object

## Storage object
An object that represents a storage.

### getName
Returns the name of the storage

**Parameters**

**Returns**

- string: The name of the storage

### setName
Sets the name of the storage

**Parameters**

- name: string: The new name of the storage

**Returns**

### getStorages
Returns the storages of the storage

**Parameters**

**Returns**

- table: The list of the inventories used by this storage

### addStorage
Adds an inventory to the storage

**Parameters**

- storage: string: The peripheral name of the inventory

**Returns**

- boolean: If the operation succeded

or

- nil
- string: Explaining the error

### removeStorage
Removes a storage from the storage
> [!CAUTION]
> Removing an inventory will cause the partitions to move around and thus shouldn't be used.

**Parameters**

- storage: string: The peripheral name of the inventory

**Returns**

- boolean: If the operation succeded

or

- nil
- string: Explaining the error

### getSize
Returns the total size of the storage

**Parameters**

**Returns**

- number: The size of the storage

### getPartitions
Returns the partition table of the storage

**Parameters**

**Returns**

- table: The partition table of the storage
```lua
{
  {
    isCompressed = false,
    endPos = 4,
    name = "test1",
    startPos = 1,
  },
  {
    endPos = 7,
    name = "Unallocated",
    isUnallocated = true,
    startPos = 5,
    isCompressed = false,
  },
  {
    isCompressed = false,
    endPos = 10,
    name = "test2",
    startPos = 8,
  },
  {
    endPos = 54,
    name = "Unallocated",
    startPos = 11,
  },
}
```

### createPartition
Creates a partition

**Parameters**

- name: string: The name of the partition
- startPos: number: The start position of the partition
- endPos: number The end position of the partition
- isCompressed: boolean|nil: If the partition is compressed or not

**Returns**

> [!WARNING]  
> The ID of a storage and the ID of a partition can change over time, if a storage/partition is deleted.
- number: The ID of the partition

or

- nil
- string: Explaining the error

### getPartition
Returns a partition object

**Parameters**

- partitionId: number: The ID of the partition

**Returns**

- table: A partition object

### delete
Deletes the storage

**Parameters**

- force?: boolean: If it should care about partitions or not

**Returns**

- boolean: If the operation succeded

or

- nil
- string: Explaining the error

## Partition object
An object that represents a partition.

### getName
Returns the name of the partition

**Parameters**

**Returns**

- string: The name of the partition

### setName
Sets the name of the partition

**Parameters**

- name: string: The new name of the partition

**Returns**

### getSize
Returns the size of the partition

**Parameters**

**Returns**

- number: The size of the partition

### isCompressed
Returns if the partition is compressed

**Parameters**

**Returns**

- boolean: If the partition is compressed

### setCompressed
Sets if the partition is compressed

**Parameters**

- compressed: boolean: If the partition should be compressed or not

**Returns**

### move
Moves the partition to a new start position
> [!TIP]
> This function ensures that items won't get out of the partition. Thus it's safe to use!

**Parameters**

- newStart: number: The new start position of the partition

**Returns**

- boolean: If the operation succeded

or

- nil
- string: Explaining the error

### resize
Resizes the partition
> [!TIP]
> This function ensures that items won't get out of the partition unless `force` is true. Thus it's safe to use!

**Parameters**

- newSize: number: The new size of the partition
- force?: boolean: If it should care about the items or not

**Returns**

- boolean: If the operation succeded

or

- nil
- string: Explaining the error

### getPositions
Returns the start and end positions of the partition

**Parameters**

**Returns**

- number: The start position of the partition
- number: The end position of the partition

### list
Lists all items in the partition, slot based

**Parameters**

**Returns**

- table: The items in the partition, with details

### listItems
Lists all unique items in the partition

**Parameters**

- noUncompressed?: boolean: If compression shouldn't be considered

**Returns**

- table: The unique items in the partition, with details
```lua
{
  [ "minecraft:redstone_block?displayName=Block of Redstone" ] = {
    itemGroups = {},
    name = "minecraft:redstone_block",
    tags = {
      [ "c:redstone_blocks" ] = true,
      [ "c:storage_blocks" ] = true,
    },
    rawName = "block.minecraft.redstone_block",
    count = 1,
    maxCount = 64,
    displayName = "Block of Redstone",
  },
  [ "minecraft:redstone?displayName=Redstone Dust" ] = {
    itemGroups = {},
    containsCompressed = true,
    name = "minecraft:redstone",
    tags = {
      [ "c:dusts" ] = true,
      [ "c:redstone_dusts" ] = true,
      [ "minecraft:trim_materials" ] = true,
      [ "c:dusts/redstone" ] = true,
    },
    rawName = "item.minecraft.redstone",
    count = 32,
    maxCount = 64,
    displayName = "Redstone Dust",
  },
}
```

### getItemInfo
Gets information about items matching the query
> [!NOTE]  
> This function uses the `listItems` function, so the results are similar

**Parameters**

- query: string: The item query
- noUncompressed?: boolean: If compression shouldn't be considered

**Returns**

- table: Returns the information of the item

### getItemCount
Gets the total count of items matching the query

**Parameters**

- query: string: The item query
- noUncompressed?: boolean: If compression shouldn't be considered

**Returns**

- number: The amount of items matching the query

### getUsage
Gets usage information about the partition

**Parameters**

**Returns**

- table: The usage information of the partition
```lua
{
  totalItems = 24,
  fullSlots = 0,
  usedSlots = 2,
  totalSlots = 4,
}
```

### canImport
Checks how many items matching the query can be imported

**Parameters**

- query: string: The item query
- limit?: number: The limit or `2^40`

**Returns**

- number: The amount of items that can be imported

### craft
Crafts items using a crafty turtle

**Parameters**

- key: table: The crafting key
```lua
{
    x = "minecraft:redstone?displayName=Redstone Dust"
}
```
- pattern: table: The crafting pattern
```lua
{
    {"x", "x", "x"},
    {"x", "x", "x"},
    {"x", "x", "x"}
}
```
- outcome: string: The query of the outcome
- outcomeCount: number: The amount of items that get produced
- count?: number: The amount of items wanted or `1`

**Returns**

- boolean: If the operation succeded

or

- nil
- string: Explaining the error

### exportItems
Exports items matching the query to another inventory

**Parameters**

- query: string: The item query
- toName: string: The peripheral name of the target inventory
- limit?: number: The amount of items to be transferred
- noCompression?: boolean: If compression shouldn't be done
- toSlot?: number: The target slot for the item

**Returns**

- number: The amount of items transferred

or

- nil
- string: Explaining the error

### importItems
Imports items matching the query from another inventory

**Parameters**

- query: string: The item query
- fromName: string: The peripheral name of the source inventory
- limit?: number: The amount of items to be transferred
- noCompression?: boolean: If compression shouldn't be done

**Returns**

- number: The amount of items transferred

or

- nil
- string: Explaining the error

### moveItems
Moves items matching the query to another partition

**Parameters**

- query: string: The item query
- toStorage: number: The ID of the target storage
- toPartition: number: The ID of the target partition
- limit?: number: The amount of items to be transferred
- noCompression?: boolean: If compression shouldn't be done

**Returns**

- number: The amount of items transferred

or

- nil
- string: Explaining the error

### defragment
Defragments the partition

**Parameters**

**Returns**

- number: The amount of items that were moved
- number: The amount of slots that have been freed

### autoCompress
Automatically compresses items in the partition if possible

**Parameters**

**Returns**

- number: The amount of items that were there before
- number: The amount of items that are there now

### delete
Deletes the partition

**Parameters**

- force?: boolean: If it should care about partitions or not

**Returns**

- boolean: If the operation succeded

or

- nil
- string: Explaining the error