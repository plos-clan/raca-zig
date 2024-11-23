const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const launcher_target = b.standardTargetOptions(.{});

    var target_query: std.Target.Query = .{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    };

    const Feature = std.Target.x86.Feature;

    target_query.cpu_features_add.addFeature(@intFromEnum(Feature.soft_float));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.mmx));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.sse));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.sse2));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.avx));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.avx2));

    const target = b.resolveTargetQuery(target_query);
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "racaOS",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .kernel,
    });
    
    kernel.addLibraryPath(b.path("lib"));
    kernel.linkSystemLibrary("alloc");
    kernel.linkSystemLibrary("os_terminal");

    kernel.setLinkerScript(b.path("linker.ld"));

    kernel.want_lto = false;

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(kernel);

    const launcher = b.addExecutable(.{
        .name = "racaOS-launcher",
        .root_source_file = b.path("launcher/main.zig"),
        .target = launcher_target,
        .optimize = optimize,
    });

    var launcher_install = b.addInstallArtifact(launcher,.{});
    launcher_install.step.dependOn(b.getInstallStep());

    const run_launcher = b.addRunArtifact(launcher);
    run_launcher.step.dependOn(&launcher_install.step);

    if (b.args) |args| {
        run_launcher.addArgs(args);
    }

    const run_step = b.step("run", "Run the OS");
    run_step.dependOn(&run_launcher.step);
}
