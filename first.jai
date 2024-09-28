#run {
    fetch(.{path = "./assets/Do_A_Thing.jai"});

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
#import "Plutus";
