fetch :: (pkg: PathModule, update:= false, modules_dir:= default_modules_dir) {
    // Check if the module already exists
    target_dir := tprint("%/%", modules_dir, pkg.name);
    target_filepath := tprint("%/%.jai", modules_dir, pkg.name);
    if !update && (is_directory(target_dir) || file_exists(target_filepath)) {
        log("Module `%` already exists", pkg.name);
        return;
    }

    // Copy (override) the module
    make_directory_if_it_does_not_exist(modules_dir);
    if is_directory(pkg.path) {
        copy_directory(pkg.path, target_dir);
    } else if file_exists(pkg.path) {
        copy_file(pkg.path, target_filepath);
    } else {
        log_error("Module path `%` does not exist for module `%`", pkg.path, pkg.name);
    }
}

fetch :: (pkg: GitModule, update:= false, modules_dir:= default_modules_dir) {
    // Check if the module already exists
    target_dir := tprint("%/%", modules_dir, pkg.name);
    target_filepath := tprint("%/%.jai", modules_dir, pkg.name);
    if !update && (is_directory(target_dir) || file_exists(target_filepath)) {
        log("Module `%` already exists", pkg.name);
        return;
    }

    // Get the name of the repository
    origin := parse_path(pkg.url);
    origin_gitname := origin.words[origin.words.count - 1];
    found, origin_stem := split_from_right(origin_gitname, ".git");
    // Compose the cache paths
    gitcache_dir := tprint("%/%", get_home_directory(), ".plutus/gitcache");
    cache_path := tprint("%/%", gitcache_dir, origin_stem);

    // Create / update the cache
    result: Process_Result;
    if !is_directory(cache_path) {
        // The repository has not been cached yet
        make_directory_if_it_does_not_exist(gitcache_dir, true);
        result = run_command("git", "clone", pkg.url, working_directory = gitcache_dir, capture_and_return_output = true, print_captured_output = true);
    } else {
        // Pull in changes to see if there are any updates
        result = run_command("git", "pull", working_directory = cache_path, capture_and_return_output = true, print_captured_output = true);
    }
    if result.exit_code != 0 {
        log_error("Git command failed for module `%`: %", origin_stem, result);
        return;
    }

    // Copy (override) from cache to the modules directory
    module_path := tprint("%/%", cache_path, pkg.path);
    make_directory_if_it_does_not_exist(modules_dir);
    if is_directory(module_path) {
        copy_directory(module_path, target_dir);
    } else if file_exists(module_path) {
        copy_file(module_path, target_filepath);
    } else {
        log_error("Module path `%` does not exist for module `%`", module_path, pkg.name);
    }
}

PathModule :: struct {
    name : string;
    path : string; // Points to dir with module.jai, or .jai file
}
GitModule :: struct {
    name : string;
    url : string;
    path : string; // Points to dir with module.jai, or .jai file from the root of the repo
}


#scope_file
#import "Basic";
#import "File_Utilities";
#import "File";
#import "System";
#import "String";
#import "Process";

default_modules_dir :: "./modules";
