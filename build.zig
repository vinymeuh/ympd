const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

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
    ympd.defineCMacro("SRC_PATH", "/home/viny/Work4Me/ZIG/ympd/htdocs");
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
