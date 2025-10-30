# Open Inventory Library (OIL)
A modern inventory library for the CC: Tweaked Minecraft mod.

## Installing
run `wget https://raw.githubusercontent.com/afonya2/CC-OpenInvLib/refs/heads/main/openinvlib.lua oil.lua` on a computer.

> [!NOTE]  
> OIL stores its configuration and cache in the `openinvlib_data` folder

## Definitions



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