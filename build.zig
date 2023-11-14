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
    //ympd.addIncludePath(.{ .path = "build" });
    ympd.linkLibC();
    ympd.linkSystemLibrary("mpdclient");
    b.installArtifact(ympd);
}
