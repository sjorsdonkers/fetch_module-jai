fetch :: (pkg: PathPackage) {
    modules_dir :: "./modules";
    make_directory_if_it_does_not_exist(modules_dir);

    origin := parse_path(pkg.path);
    origin_name := origin.words[origin.words.count - 1];
    destination_path := sprint("%/%", modules_dir, origin_name);

    if is_directory(pkg.path) {
        copy_directory(pkg.path, destination_path);
    } else if file_exists(pkg.path) {
        copy_file(pkg.path, destination_path);
    }
}

GitPackage :: struct {
    url : string;
    path : string = "./"; // Points to dir with module.jai, or .jai file
}
PathPackage :: struct {
    path : string;
}

#scope_file
#import "Basic";
#scope_file
#import "File_Utilities";
#scope_file
#import "File";
