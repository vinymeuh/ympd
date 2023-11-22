const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const with_dynamic_assets = b.option(bool, "with_dynamic_assets", "Serve assets dynamically") orelse false;

    // Build mkdata
    const mkdata = b.addExecutable(.{
        .name = "mkdata",
        .target = target,
    });
    mkdata.addCSourceFile(.{ .file = .{ .path = "tools/mkdata.c" }, .flags = &.{} });
    mkdata.linkLibC();

    // Run mkdata to create assets.c
    const mkdata_step = b.addRunArtifact(mkdata);
    mkdata_step.addArgs(&.{
        "htdocs/assets/favicon.ico",
        "htdocs/css/bootstrap-theme.css",
        "htdocs/css/bootstrap.css",
        "htdocs/css/mpd.css",
        "htdocs/fonts/glyphicons-halflings-regular.eot",
        "htdocs/fonts/glyphicons-halflings-regular.svg",
        "htdocs/fonts/glyphicons-halflings-regular.ttf",
        "htdocs/fonts/glyphicons-halflings-regular.woff",
        "htdocs/index.html",
        "htdocs/js/bootstrap-notify.js",
        "htdocs/js/bootstrap-slider.js",
        "htdocs/js/bootstrap.js",
        "htdocs/js/bootstrap.min.js",
        "htdocs/js/jquery-1.10.2.js",
        "htdocs/js/jquery-1.10.2.min.js",
        "htdocs/js/jquery-ui-sortable.min.js",
        "htdocs/js/jquery.cookie.js",
        "htdocs/js/modernizr-custom.js",
        "htdocs/js/mpd.js",
        "htdocs/js/sammy.js",
    });
    const output = mkdata_step.captureStdOut();
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(output, .prefix, "src/assets.c").step); // should not go in zig-out, it's a build dependency

    // Build ympd
    const ympd = b.addExecutable(.{
        .name = "ympd",
        .target = target,
    });
    ympd.addCSourceFiles(.{
        .files = &.{
            "src/ympd.c",
            "zig-out/src/assets.c", // hardcoded
            "src/http_server.c",
            "src/mpd_client.c",
            "src/mongoose.c",
            "src/json_encode.c",
        },
    });
    ympd.addIncludePath(.{ .cwd_relative = "" }); // see assets.c
    ympd.defineCMacro("YMPD_VERSION_MAJOR", "1");
    ympd.defineCMacro("YMPD_VERSION_MINOR", "2");
    ympd.defineCMacro("YMPD_VERSION_PATCH", "3");
    if (with_dynamic_assets == true) {
        var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        const cwd = try std.os.getcwd(&buf);
        const allocator = std.heap.page_allocator;
        var src_path = try allocator.alloc(u8, cwd.len + std.fs.path.sep_str.len + "htdocs".len);
        _ = try std.fmt.bufPrint(src_path, "{s}{s}htdocs", .{ cwd, std.fs.path.sep_str });
        ympd.defineCMacro("SRC_PATH", src_path);
    }
    ympd.defineCMacro("WITH_MPD_HOST_CHANGE", "");
    ympd.linkLibC();
    ympd.linkSystemLibrary("mpdclient");
    const install_artifact = b.addInstallArtifact(ympd, .{
        .dest_dir = .{ .override = .prefix },
    });
    b.getInstallStep().dependOn(&install_artifact.step);
}
