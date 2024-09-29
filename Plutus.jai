fetch :: (pkg: PathModule, update:= false, modules_dir:= default_modules_dir) {
    if !update && is_module(pkg.name, modules_dir) {
        log("Module % already exists", pkg.name);
        return;
    }

    make_directory_if_it_does_not_exist(modules_dir);
    copy_module(pkg.path, pkg.name, modules_dir);
}

fetch :: (pkg: GitModule, update:= false, modules_dir:= default_modules_dir) {
    if !update && is_module(pkg.name, modules_dir) {
        log("Module % already exists", pkg.name);
        return;
    }

    log("Syncing module %'s git cache: %", pkg.name, pkg.url);
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
        log_error("Git command failed for module %: %", origin_stem, result);
        return;
    }

    module_path := tprint("%/%", cache_path, pkg.path);
    make_directory_if_it_does_not_exist(modules_dir);
    copy_module(module_path, pkg.name, modules_dir);
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

is_module :: (name: string, modules_dir:= default_modules_dir) -> bool {
    filemodule_filepath := tprint("%/%.jai", modules_dir, name);
    if file_exists(filemodule_filepath) return true;

    dirmodule_filepath := tprint("%/%/module.jai", modules_dir, name);
    if file_exists(dirmodule_filepath) return true;

    return false;
}

copy_module :: (source_path: string, target_module_name: string, modules_dir:= default_modules_dir) -> bool {
    log("Copying module %", target_module_name);
    if is_directory(source_path) {
        target_dir := tprint("%/%", modules_dir, target_module_name);
        copy_directory(source_path, target_dir);
        return true;
    } else if file_exists(source_path) {
        target_filepath := tprint("%/%.jai", modules_dir, target_module_name);
        return copy_file(source_path, target_filepath);
    } else {
        log_error("Cannot copy module. Source % does not exist, for module %", source_path, target_module_name);
        return false;
    }
}
