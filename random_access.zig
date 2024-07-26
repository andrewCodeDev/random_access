
const std = @import("std");

pub fn init(ptr: anytype) Address(@TypeOf(ptr)) {
    return Address(@TypeOf(ptr)){ .value = @intFromPtr(ptr) };
}

/// creates a runtime address from a given pointer
pub fn Address(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Size = PointerSize(T);
        pub const Child = PointerChild(T);
        pub const Const = isConst(T);
        
        value: usize,

        /// inplace addition to current address by n * sizeof T
        pub fn add(self: *Self, n: usize) void {
            self.value += n * @sizeOf(Child);
        }
        /// inplace subtraction to current address by n * sizeof T
        pub fn sub(self: *Self, n: usize) void {
            self.value -= n * @sizeOf(Child);
        }
        /// returns pointer of original type and sets address to zero.
        pub fn release(self: *Self) T {
            defer self.value = 0;
            return @ptrFromInt(self.value);
        }
        /// returns one-item pointer
        pub fn one(self: Self) One(Child, Const) {
            return @ptrFromInt(self.value);
        }
        /// returns many-item pointer
        pub fn many(self: Self) Multi(Child, Const) {
            return @ptrFromInt(self.value);
        }
        /// check if pointer is equal to zero.
        pub fn isZero(self: Address) bool {
            return self.value == 0;
        }
        /// check current is equal to other
        pub fn eql(self: Self, other: Self) bool {
            return self.value == other.value;
        }
        /// check current is less than other
        pub fn lt(self: Self, other: Self) bool {
            return self.value < other.value;
        }
        /// check current is greater than other
        pub fn gt(self: Self, other: Self) bool {
            return self.value > other.value;
        }
        /// check current is less than or equal to other
        pub fn lte(self: Self, other: Self) bool {
            return self.value <= other.value;
        }
        /// check current is greater than or equal to other
        pub fn gte(self: Self, other: Self) bool {
            return self.value >= other.value;
        }
    };
}

fn One(comptime T: type, comptime is_const: bool) type {
    return if (is_const) *const T else *T;
}

fn Multi(comptime T: type, comptime is_const: bool) type {
    return if (is_const) [*]const T else [*]T;
}

fn isConst(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .Pointer => |p| p.is_const,
        else => @compileError("Requires pointer type, recieved: " ++ @typeName(T))
    };
}

fn PointerSize(comptime T: type) std.builtin.Type.Pointer.Size {
    return switch (@typeInfo(T)) {
        .Pointer => |p| blk: {
            if (p.size == .Slice) {
                @compileError("Address object requires direct pointer, not slice. Considering using slice.ptr instead.");
            }
            break :blk p.size;
        },
        else => @compileError("Requires pointer type, recieved: " ++ @typeName(T))
    };
}

fn PointerChild(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Pointer => |p| p.child,
        else => @compileError("Requires pointer type, recieved: " ++ @typeName(T))
    };
}

///////////////////////////////////////
//             Testing               //
///////////////////////////////////////

// simulaties an import
const ra = @This();

test "slice check addresses" {

    const slice = try std.testing.allocator.alloc(i32, 100);
        defer std.testing.allocator.free(slice);    

    @memset(slice, 42);
    
    // create address at beginning of array
    var addr = ra.init(slice.ptr);

    // loop over slice and check every address
    for (slice) |*value| {
        const n: usize = @intFromPtr(value);
        try std.testing.expect(addr.value == n);
        addr.add(1);
    }

    std.debug.print("\n\n", .{});
}

test "slice iterate" {

    const slice = try std.testing.allocator.alloc(i32, 100);
    defer std.testing.allocator.free(slice);
    
    @memset(slice, 42);
    
    // create address at beginning of array
    var addr = ra.init(slice.ptr);

    // create address at one past end of array
    const end = ra.init(slice.ptr + slice.len);

    // iterate until we reach the end
    while (addr.lt(end)) : (addr.add(1)) {
        try std.testing.expectEqual(42, addr.one().*);
    }

    try std.testing.expect(addr.eql(end));
}

test "slice set values" {

    const slice = try std.testing.allocator.alloc(i32, 100);
    defer std.testing.allocator.free(slice);
    
    @memset(slice, 42);
    
    // create address at beginning of array
    var addr = ra.init(slice.ptr);

    // create address at one past end of array
    const end = ra.init(slice.ptr + slice.len);

    while (addr.lt(end)) : (addr.add(1)) {
        addr.one().* = 43;
    }

    try std.testing.expect(addr.eql(end));

    for (slice) |value| {
        try std.testing.expectEqual(43, value);
    }
}

test "slice check addresses reverse" {

    const slice = try std.testing.allocator.alloc(i32, 100);
    defer std.testing.allocator.free(slice);
    
    @memset(slice, 42);
    
    // create address at one past end of array
    var addr = ra.init(slice.ptr + slice.len);

    var i: usize = slice.len;

    // loop in reverse and check every address
    while (i != 0) {
        i -= 1;
        addr.sub(1);
        const n: usize = @intFromPtr(&slice[i]);
        try std.testing.expect(addr.value == n);
    }
}

test "slice set values reverse" {

    const slice = try std.testing.allocator.alloc(i32, 100);
    defer std.testing.allocator.free(slice);
    
    @memset(slice, 42);
    
    // create address to last element of array
    var addr = ra.init(slice.ptr + (slice.len - 1));

    // create address to first element of array
    const end = ra.init(slice.ptr);

    // iterate until we are one past the beginning
    while (addr.gte(end)) : (addr.sub(1)) {
        addr.one().* = 55;
    }

    for (slice) |value| {
        try std.testing.expectEqual(55, value);
    }
}
