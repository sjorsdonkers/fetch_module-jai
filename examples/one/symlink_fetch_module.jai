#run {
    make_directory_if_it_does_not_exist("modules");
    file_link("modules/Fetch_Module.jai", "../../Fetch_Module.jai");

    set_build_options_dc(.{do_output=false});
}

#import "File";
#import "Compiler";
