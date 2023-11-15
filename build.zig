const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const with_dynamic_assets = b.option(bool, "with_dynamic_assets", "Serve assets dynamically") orelse false;

    var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const cwd = try std.os.getcwd(&buf);
    const allocator = std.heap.page_allocator;
    var src_path = try allocator.alloc(u8, cwd.len + std.fs.path.sep_str.len + "htdocs".len);
    _ = try std.fmt.bufPrint(src_path, "{s}{s}htdocs", .{ cwd, std.fs.path.sep_str });

    const ympd = b.addExecutable(.{
        .name = "ympd",
        .target = target,
    });
    ympd.addCSourceFiles(.{
        .files = &.{
            "src/ympd.c",
            "src/assets.c",
            "src/http_server.c",
            "src/mpd_client.c",
            "src/mongoose.c",
            "src/json_encode.c",
        },
    });
    ympd.defineCMacro("YMPD_VERSION_MAJOR", "1");
    ympd.defineCMacro("YMPD_VERSION_MINOR", "2");
    ympd.defineCMacro("YMPD_VERSION_PATCH", "3");
    if (with_dynamic_assets == true) {
        ympd.defineCMacro("SRC_PATH", src_path);
    }
    ympd.defineCMacro("WITH_MPD_HOST_CHANGE", "");
    ympd.linkLibC();
    ympd.linkSystemLibrary("mpdclient");
    b.installArtifact(ympd);

    const mkdata = b.addExecutable(.{
        .name = "mkdata",
        .target = target,
    });
    mkdata.addCSourceFile(.{ .file = .{ .path = "tools/mkdata.c" }, .flags = &.{} });
    mkdata.linkLibC();
    b.installArtifact(mkdata);
}
