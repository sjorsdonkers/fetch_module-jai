#run {
    // --- Modocil ---
    #import "Modocil";
    args := get_build_options().compile_time_command_line;
    do_update := array_find(args, "update");
    fetch(GitModule.{name = "Do_A_Thing", url = "git@github.com:sjorsdonkers/modocil.git", path = "examples/assets/Do_A_Thing.jai"}, do_update);
    fetch(GitModule.{name = "Do_Other_Thing", url = "git@github.com:sjorsdonkers/modocil.git", commit = "21a0e57", path = "examples/assets/Do_Other_Thing"}, do_update);
    /// ---/Modocil ---

    space := compiler_create_workspace("Target Program");
    if !space {
        print("Workspace creation failed.\n");
        return;
    }

    target_options := get_build_options(space);
    target_options.output_executable_name = "main";
    set_build_options(target_options, space);

    compiler_begin_intercept(space);
    add_build_file(tprint("%/main.jai", #filepath), space);
    compiler_end_intercept(space);

    set_build_options_dc(.{do_output=false});
}

#import "Compiler";
#import "Basic";
