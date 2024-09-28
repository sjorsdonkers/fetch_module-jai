#import "Compiler";
#import "Basic";
#import "Plutus";

// User code
#run build();
build :: () {
    path_pkg(.{path = "./assets/sum_type/Sum_Type.jai"});
    gather(path_packages);

    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    target_options := get_build_options(w);
    target_options.output_executable_name = "main";
    set_build_options(target_options, w);

    compiler_begin_intercept(w);
    add_build_file(tprint("%/main.jai", #filepath), w);  // @Cleanup: Fix this to not require #filepath.
    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});
}
