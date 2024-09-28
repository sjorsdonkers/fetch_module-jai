fetch :: (pkg: PathMod) {
    modules_dir :: "./modules";
    make_directory_if_it_does_not_exist(modules_dir);

    origin := parse_path(pkg.path);
    origin_name := origin.words[origin.words.count - 1];
    destination_path := tprint("%/%", modules_dir, origin_name);

    if is_directory(pkg.path) {
        copy_directory(pkg.path, destination_path);
    } else if file_exists(pkg.path) {
        copy_file(pkg.path, destination_path);
    } else {
        log_error("Module path `%` does not exist", pkg.path);
    }
}

fetch :: (pkg: GitMod) {
    origin := parse_path(pkg.url);
    origin_gitname := origin.words[origin.words.count - 1];
    found, origin_stem := split_from_right(origin_gitname, ".git");

    gitcache_dir := tprint("%/%", get_home_directory(), ".plutus/gitcache");
    cache_path := tprint("%/%", gitcache_dir, origin_stem);

    result: Process_Result;
    if !is_directory(cache_path) {
        make_directory_if_it_does_not_exist(gitcache_dir, true);
        result = run_command("git", "clone", pkg.url, working_directory = gitcache_dir, capture_and_return_output = true, print_captured_output = true);
    } else {
        result = run_command("git", "pull", working_directory = cache_path, capture_and_return_output = true, print_captured_output = true);
    }
    if result.exit_code != 0 {
        log_error("Git command failed for module `%`: %", origin_stem, result);
        return;
    }

    module_path := tprint("%/%", cache_path, pkg.path);
    fetch(PathMod.{path = module_path});
}

GitMod :: struct {
    url : string;
    path : string = "./"; // Points to dir with module.jai, or .jai file from the root of the repo
}
PathMod :: struct {
    path : string; // Points to dir with module.jai, or .jai file
}

#scope_file
#import "Basic";
#scope_file
#import "File_Utilities";
#scope_file
#import "File";
#scope_file
#import "System";
#scope_file
#import "String";
#scope_file
#import "Process";
