const std = @import("std");
const Allocator = std.mem.Allocator;

pub const c = @cImport({
    @cInclude("binaryen-c.h");
});

pub const Index = c.BinaryenIndex;
pub const Op = c.BinaryenOp;

pub const Type = struct {
    pub const BasicType = enum(usize) {
        none,
        unreachable_,
        i32,
        i64,
        f32,
        f64,
        v128,
    };

    id: usize,

    pub fn fromEnum(basic_type: BasicType) Type {
        return .{ .id = @intFromEnum(basic_type) };
    }

    pub fn fromC(binaryen_type: c.BinaryenType) Type {
        return .{ .id = binaryen_type };
    }

    pub fn toC(self: Type) c.BinaryenType {
        return self.id;
    }

    pub fn sliceToC(slice: ?[]Type) [*c]c.BinaryenType {
        return if (slice) |s| @ptrCast(s.ptr) else null;
    }

    pub fn auto() Type {
        return fromC(c.BinaryenTypeAuto());
    }

    pub fn int32() Type {
        return fromC(c.BinaryenTypeInt32());
    }

    pub fn float32() Type {
        return fromC(c.BinaryenTypeFloat32());
    }

    pub fn create(value_types: []Type) Type {
        return fromC(c.BinaryenTypeCreate(sliceToC(value_types), @intCast(value_types.len)));
    }
};

pub fn gtSInt32() Op {
    return c.BinaryenGtSInt32();
}

pub fn ltSInt32() Op {
    return c.BinaryenLtSInt32();
}

pub fn eqInt32() Op {
    return c.BinaryenEqInt32();
}

pub fn addInt32() Op {
    return c.BinaryenAddInt32();
}

pub fn subInt32() Op {
    return c.BinaryenSubInt32();
}

pub fn mulInt32() Op {
    return c.BinaryenMulInt32();
}

pub fn gtFloat32() Op {
    return c.BinaryenGtFloat32();
}

pub fn ltFloat32() Op {
    return c.BinaryenLtFloat32();
}

pub fn eqFloat32() Op {
    return c.BinaryenEqFloat32();
}

pub fn addFloat32() Op {
    return c.BinaryenAddFloat32();
}

pub fn subFloat32() Op {
    return c.BinaryenSubFloat32();
}

pub fn mulFloat32() Op {
    return c.BinaryenMulFloat32();
}

pub fn divFloat32() Op {
    return c.BinaryenDivFloat32();
}

pub const Module = opaque {
    pub fn fromC(module: c.BinaryenModuleRef) *Module {
        return @ptrCast(module);
    }

    pub fn toC(self: *Module) c.BinaryenModuleRef {
        return @ptrCast(self);
    }

    pub fn init() *Module {
        return fromC(c.BinaryenModuleCreate());
    }

    pub fn deinit(self: *Module) void {
        c.BinaryenModuleDispose(self.toC());
    }

    pub fn addFunction(self: *Module, name: []const u8, params: Type, results: Type, var_types: ?[]Type, body: *Expression) *Function {
        return Function.fromC(c.BinaryenAddFunction(
            self.toC(),
            name.ptr,
            params.toC(),
            results.toC(),
            Type.sliceToC(var_types),
            if (var_types) |v| @intCast(v.len) else 0,
            body.toC(),
        ));
    }

    pub fn addFunctionExport(self: *Module, internal_name: []const u8, external_name: []const u8) *Export {
        return Export.fromC(c.BinaryenAddFunctionExport(
            self.toC(),
            internal_name.ptr,
            external_name.ptr,
        ));
    }

    pub fn print(self: *Module) void {
        c.BinaryenModulePrint(self.toC());
    }

    pub fn makeLocalGet(self: *Module, index: Index, type_: Type) *Expression {
        return Expression.fromC(c.BinaryenLocalGet(self.toC(), index, type_.toC()));
    }

    pub fn makeNop(self: *Module) *Expression {
        return Expression.fromC(c.BinaryenNop(self.toC()));
    }

    pub fn makeBinary(self: *Module, op: Op, left: *Expression, right: *Expression) *Expression {
        return Expression.fromC(c.BinaryenBinary(self.toC(), op, left.toC(), right.toC()));
    }

    pub fn makeConst(self: *Module, value: Literal) *Expression {
        return Expression.fromC(c.BinaryenConst(self.toC(), value.toC()));
    }

    pub fn makeBlock(self: *Module, name: ?[]const u8, children: []*Expression, type_: Type) *Expression {
        return Expression.fromC(c.BinaryenBlock(
            self.toC(),
            if (name) |n| n.ptr else null,
            @ptrCast(children.ptr),
            @intCast(children.len),
            type_.toC(),
        ));
    }

    pub fn makeCall(self: *Module, target: []const u8, operands: []*Expression, return_type: Type) *Expression {
        return Expression.fromC(c.BinaryenCall(
            self.toC(),
            target.ptr,
            @ptrCast(operands.ptr),
            @intCast(operands.len),
            return_type.toC(),
        ));
    }

    pub fn makeIf(self: *Module, condition: *Expression, if_true: *Expression, if_false: ?*Expression) *Expression {
        return Expression.fromC(c.BinaryenIf(
            self.toC(),
            condition.toC(),
            if_true.toC(),
            if (if_false) |expr| expr.toC() else null,
        ));
    }

    pub fn write(self: *Module, buffer: []u8) usize {
        return c.BinaryenModuleWrite(self.toC(), buffer.ptr, buffer.len);
    }

    pub fn writeAlloc(self: *Module, allocator: Allocator, max_size: ?usize) ![]u8 {
        const buffer = try allocator.alloc(u8, max_size orelse 2 << 11); // 4Kib
        const size = self.write(buffer);
        return allocator.realloc(buffer, size);
    }
};

pub const Expression = opaque {
    pub fn fromC(expression: c.BinaryenExpressionRef) *Expression {
        return @ptrCast(expression);
    }

    pub fn toC(self: *Expression) c.BinaryenExpressionRef {
        return @ptrCast(self);
    }
};

pub const Function = opaque {
    pub fn fromC(function: c.BinaryenFunctionRef) *Function {
        return @ptrCast(function);
    }

    pub fn toC(self: *Function) c.BinaryenFunctionRef {
        return @ptrCast(self);
    }
};

pub const Export = opaque {
    pub fn fromC(export_ref: c.BinaryenExportRef) *Export {
        return @ptrCast(export_ref);
    }

    pub fn toC(self: *Export) c.BinaryenExportRef {
        return @ptrCast(self);
    }
};

pub const Literal = struct {
    pub const TypeTag = enum(usize) {
        none,
        unreachable_,
        i32,
        i64,
        f32,
        f64,
        v128,
    };
    tag: TypeTag,
    // data: extern union {
    //     i32: i32,
    //     i64: i64,
    //     f32: f32,
    //     f64: f64,
    //     v128: [16]u8,
    //     func: [*c]const u8,
    // },
    data: std.meta.fieldInfo(c.BinaryenLiteral, .unnamed_0).field_type,

    pub fn int32(x: i32) Literal {
        return .{
            .tag = .i32,
            .data = .{ .i32 = x },
        };
    }

    pub fn float32(x: f32) Literal {
        return .{
            .tag = .f32,
            .data = .{ .f32 = x },
        };
    }

    fn toC(self: Literal) c.BinaryenLiteral {
        return .{ .type = @intFromEnum(self.tag), .unnamed_0 = self.data };
    }
};
