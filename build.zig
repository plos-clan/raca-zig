const std = @import("std");
const Feature = @import("std").Target.loongarch.Feature;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const launcher_target = b.standardTargetOptions(.{});
    const la64_cpu = @import("std").Target.loongarch.cpu.generic_la64;

    const target_query: std.Target.Query = .{
        .cpu_arch = .loongarch64,
        .os_tag = .freestanding,
        .abi = .muslsf,
        .cpu_model = .{ .explicit = &la64_cpu },
    };
    const target = b.resolveTargetQuery(target_query);

    const optimize = b.standardOptimizeOption(.{});

    const kernel_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .medium,
        .unwind_tables = .sync,
        .red_zone = false,
        .link_libc = false,
        .stack_check = false,
        .stack_protector = false,
        .link_libcpp = false,
        .pic = false,
    });

    const kernel = b.addExecutable(.{
        .name = "raca",
        .root_module = kernel_module,
        .use_llvm = true,
        .use_lld = true,
    });

    kernel.addLibraryPath(b.path("lib"));
    kernel.linkSystemLibrary("alloc");
    kernel.setLinkerScript(b.path("linker.ld"));
    kernel.lto = .none;

    b.installArtifact(kernel);

    const launcher = b.addExecutable(.{
        .name = "raca-launcher",
        .root_module = b.createModule(.{
            .root_source_file = b.path("launcher/main.zig"),
            .target = launcher_target,
            .optimize = optimize,
        }),
    });

    var launcher_install = b.addInstallArtifact(launcher, .{});
    launcher_install.step.dependOn(b.getInstallStep());

    const run_launcher = b.addRunArtifact(launcher);
    run_launcher.step.dependOn(&launcher_install.step);

    if (b.args) |args| {
        run_launcher.addArgs(args);
    }

    const run_step = b.step("run", "Run the OS");
    run_step.dependOn(&run_launcher.step);
}
