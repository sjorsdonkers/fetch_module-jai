fetch :: (pkg: PathModule, update:= false) {
    if !update && is_module(pkg.name, default_modules_dir) {
        log("Module % already exists", pkg.name);
        return;
    }

    make_directory_if_it_does_not_exist(default_modules_dir);
    copy_module(pkg.path, pkg.name, default_modules_dir);
}

fetch :: (pkg: GitModule, update:= false) {
    if !update && is_module(pkg.name, default_modules_dir) {
        log("Module % already exists", pkg.name);
        return;
    }

    cache_path := sync_gitcache(pkg.url, pkg.branch, pkg.commit);
    module_path := tprint("%/%", cache_path, pkg.path);

    make_directory_if_it_does_not_exist(default_modules_dir);
    copy_module(module_path, pkg.name, default_modules_dir);
}

PathModule :: struct {
    name : string; // User-defined local name of the dependency to import
    path : string; // Points to dir with module.jai, or .jai file
}
GitModule :: struct {
    name : string; // User-defined local name of the dependency to import
    url : string;  // URL of the git repository (git@github.com:my_org/my_repo.git)
    branch : string = "main"; // Branch to checkout
    commit : string = ""; // Commit to checkout
    path : string; // Points to dir with module.jai, or .jai file from the root of the repository
}

#scope_file

is_module :: (name: string, modules_dir: string) -> bool {
    filemodule_filepath := tprint("%/%.jai", modules_dir, name);
    if file_exists(filemodule_filepath) return true;

    dirmodule_filepath := tprint("%/%/module.jai", modules_dir, name);
    if file_exists(dirmodule_filepath) return true;
    return false;
}

copy_module :: (source_path: string, target_module_name: string, modules_dir: string) {
    log("Copying module %", target_module_name);
    if is_directory(source_path) {
        target_dir := tprint("%/%", modules_dir, target_module_name);
        if is_directory(target_dir) delete_directory(target_dir);
        copy_directory(source_path, target_dir);
    } else if file_exists(source_path) {
        target_filepath := tprint("%/%.jai", modules_dir, target_module_name);
        if  !copy_file(source_path, target_filepath) exit(1);
    } else {
        log_error("Cannot copy module. Source % does not exist, for module %", source_path, target_module_name);
        exit(1);
    }
}

sync_gitcache :: (git_url: string, branch: string, commit: string) -> string {
    log("Syncing gitcache: %", git_url);
    // Get the name of the repository
    origin := parse_path(git_url);
    origin_gitname := origin.words[origin.words.count - 1];
    found, origin_stem := split_from_right(origin_gitname, ".git");
    if !found {
        log_error("git url % does not end in .git", git_url);
        exit(1);
    }
    // Compose the cache paths
    gitcache_dir := tprint("%/%", get_home_directory(), ".plutus/gitcache");
    cache_path := tprint("%/%", gitcache_dir, origin_stem);

    // Convenience procedure for running git commands
    run :: (args : ..string, working_directory: string) {
        result := run_command(..args, working_directory = working_directory, capture_and_return_output = true, print_captured_output = true);
        if result.exit_code != 0 {
            log_error("Git command failed for syncing module: %", result);
            exit(1);
        }
    }

    // Create / update the cache
    is_new := !is_directory(cache_path);
    if is_new {
        // The repository has not been cached yet
        make_directory_if_it_does_not_exist(gitcache_dir, true);
        run("git", "clone", git_url, working_directory = gitcache_dir);
    } else {
        // Pull in changes to see if there are any updates
        run("git", "fetch", working_directory = cache_path);
    }
    if commit != "" {
        // Checkout the commit as a detachedHEAD (this ignores the branch)
        run("git", "checkout", "--quiet", commit, working_directory = cache_path);
        log("Switched to commit '%'", commit);
    } else {
        // Checkout/update the branch
        run("git", "checkout", branch, working_directory = cache_path);
        if !is_new run("git", "pull", working_directory = cache_path);
    }

    return cache_path;
}

default_modules_dir :: "./modules";

#import "Basic";
#import "File_Utilities";
#import "File";
#import "System";
#import "String";
#import "Process";
