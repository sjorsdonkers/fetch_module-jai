#import "Basic";
#import "File_Utilities";
#import "File";

gather :: (path_packages: []PathPackage) {
    for path_packages {
        make_directory_if_it_does_not_exist("./modules");

        origin := parse_path(it.path);
        origin_name := origin.words[origin.words.count - 1];
        destination_path := sprint("%/%", "./modules", origin_name);

        if is_directory(it.path) {
            copy_directory(it.path, destination_path);
        } else if file_exists(it.path) {
            copy_file(it.path, destination_path);
        }
    }
}

GitPackage :: struct {
    url : string;
    path : string = "./"; // Points to dir with module.jai or file=
}
git_packages: [..]GitPackage; // TODO Remove from runtime
git_pkg :: (package: GitPackage) {
    array_add(*git_packages, package);
}

PathPackage :: struct {
    path : string;
}
path_packages: [..]PathPackage; // TODO Remove from runtime
path_pkg :: (package: PathPackage) {
    array_add(*path_packages, package);
}
