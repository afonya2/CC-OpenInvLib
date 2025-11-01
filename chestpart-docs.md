# ChestPart
ChestPart is a command line utility for OIL.

## Installing
Run `wget https://raw.githubusercontent.com/afonya2/CC-OpenInvLib/refs/heads/main/chestpart.lua chestpart.lua` on a computer.

> [!NOTE]  
> Open Inventory Library must be already installed as `oil.lua`

## Definitions

- inventory: A peripheral that has an inventory (chest, furnace)
- storage: Multiple inventories joined together
- partition: A section of a storage, is capable of storing items

## Command syntax

- Commands are autocompleted as long as it can only mean 1 command: 
  - `lis sto` => `list storage`
  - `l s` => `list storage`
  - `l i` - Will result in Unknown command, because it can mean `list item` and `list inventory`
- Some commands require additonal arguments, while some doesn't
- Specifying less arguments than there are will be executed
- Specifying more arguments than there are will result in Unknown command
- For input arguments (ex. `<NAME>`), you can specify multi-word arguments by putting it between `"`s ex. `"this is a multi word argument"`

## Commands

### LIST
Display a list of storages or partitions.
```
STORAGE - Display a list of storages.
INVENTORY <NAME> - Display the inventories of the selected storage.
INVENTORY ALL - Display all connected inventories.
PARTITION - Display a list of partitions in the selected storage.
ITEMS - Display a list of items in the selected partition.
```

### SELECT
Select a storage or partition by ID.
```
STORAGE <ID> - Select a storage by ID.
PARTITION <ID> - Select a partition by ID in the selected storage.
```

### SCAN
Rescan the inventory, or peripherals.
```
INVENTORY (<NAME>/ALL) - Rescan an inventory.
PERIPHERALS - Rescan the peripherals.
ALL - Rescan both the inventory and peripherals.
```

### CREATE
Create a new storage or partition.
```
STORAGE <NAME> <PERIPHERALS> - Create a new storage. Peripherals separated by commas.
PARTITION <NAME> <START POS> <END POS> - Create a new partition.
PARTITION <NAME> <START POS> <END POS> COMPRESSED - Create a new compressed partition.
```

### RENAME
Rename a storage or partition.
```
RENAME STORAGE <NEW NAME> - Rename a storage.
RENAME PARTITION <NEW NAME> - Rename a partition.
```

### INVENTORY
Add or remove inventories to/from a storage.
```
ADD <NAME> - Add an inventory to the selected storage.
REMOVE <NAME> - Remove an inventory from the selected storage.
```

### DELETE
Delete a storage or partition.
```
STORAGE - Delete the selected storage.
PARTITION - Delete the selected partition.
```

### COMPRESS
Compress; enable or disable compression on the selected partition.
```
ENABLE - Enable compression on the selected partition.
DISABLE - Disable compression on the selected partition.
(ln) - Run auto compression on the selected partition.
```

### MAKE
Makes sure that there are enough uncompressed items available matching the query.
```
<QUERY> <LIMIT> - Makes sure that there are enough uncompressed items available matching the query.
```

### MOVE
Move a partition.
```
<NEW START POS> - Move the selected partition to a new start position.
```

### RESIZE
Resize a partition.
```
<NEW SIZE> - Resize the selected partition to a new size.
```

### ITEM
Import, export, and move items.
```
IMPORT <QUERY> <FROM NAME> <LIMIT> - Import items matching the query from the specified inventory.
EXPORT <QUERY> <TO NAME> <LIMIT> - Export items matching the query to the specified inventory.
MOVE <QUERY> <STORAGE ID> <PARTITION ID> <LIMIT> - Move items matching the query to the specified storage and partition.
```

### DEFRAGMENT
Defragment the selected partition.

### INFO
Display information about the selected partition.

### RESTART
Restart Open Inventory Library.