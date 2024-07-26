This is a simple type that enables pointer arithmetic on raw addresses in a type safe way.

Use file as direct import:

```zig
const ra = @import("random_access.zig");
  
```

Create address objects from pointers:

```zig
// requires one-item, multi-item, or c-style pointers
var addr = ra.init(slice.ptr);

// move up by one element
addr.add(1);

// move back by one element
addr.sub(1);


// get one-item pointer:
const ptr = addr.one();

// set value with one-item ptr:
addr.one().* = 42;

// get multi-item pointer:
const mptr = addr.multi();

// pointer comparisons:
addr1.lt(addr2);  // less than
addr1.gt(addr2);  // greater than
addr1.lte(addr2); // less than or equal to
addr1.gte(addr2); // greater than or equal to
addr1.eql(addr2); // equal to

// use with loops:
while (addr1.lt(addr2)) : (addr1.add(1)) {
  // ...
}
```
