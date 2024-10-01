// Places a Jai module at a Path in the project's modules directory
// License files are places in the project's licenses directory
// - mod: Definition of the modules source
// - update: Wheter to overwrite the module if it already exists
fetch :: (mod: PathModule, update:= false) {
    if !update && is_module(mod.name, default_modules_dir) {
        log("Module % already exists", mod.name);
        return;
    }
    path_overwrite_separators(mod.path, #char "/");

    copy_module(mod.path, mod.name, default_modules_dir);
    copy_license_maybe(mod.path, mod.name, default_licenses_dir, 4);
}

// Places a Jai module on Git in the project's modules directory
// License files are places in the project's licenses directory
// - mod: Definition of the modules source
// - update: Wheter to overwrite the module if it already exists
fetch :: (mod: GitModule, update:= false) {
    if !update && is_module(mod.name, default_modules_dir) {
        log("Module % already exists", mod.name);
        return;
    }
    path_overwrite_separators(mod.path, #char "/");
    path_depth := parse_path(mod.path).words.count;

    cache_path := sync_gitcache(mod.url, mod.branch, mod.commit);
    module_path := tprint("%/%", cache_path, mod.path);

    copy_module(module_path, mod.name, default_modules_dir);
    copy_license_maybe(module_path, mod.name, default_licenses_dir, path_depth);
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
    make_directory_if_it_does_not_exist(modules_dir);
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

copy_license_maybe :: (module_path: string, target_module_name: string, licenses_dir: string, path_depth: int) {
    log("Copying module %'s license", target_module_name);
    found, license_filepaths:= find_licenses(module_path, path_depth);
    if !found {
        log("No license found for module: %", target_module_name);
        return;
    }

    make_directory_if_it_does_not_exist(licenses_dir);
    for license_filepath: license_filepaths {
        license_filepath_path := parse_path(license_filepath);
        filename := license_filepath_path.words[license_filepath_path.words.count - 1];
        has_license := copy_file(license_filepath, tprint("%/%_%", licenses_dir, target_module_name, filename));
        if !has_license {
            log("Failed to copy license for module: %", target_module_name);
        }
    }
}

find_licenses :: (module_path: string, max_search_depth: int) -> found:bool, license_filepaths: [..]string {
    // Set `dir` to the module dir or the dir containing the file module
    dir: string;
    if is_directory(module_path) {
        dir = module_path;
    } else if file_exists(module_path) {
        module_path_path := parse_path(module_path);
        dir = path_to_string(module_path_path, module_path_path.words.count - 1);
        max_search_depth -= 1;
    }
    max_search_depth = max(0, max_search_depth);

    // Loop into parent dirs to find a license file
    dir_path := parse_path(dir);
    for < dir_path.words.count..max(1, dir_path.words.count - max_search_depth) {
        current_dir := path_to_string(dir_path, it);
        found, license_filepaths := contains_license_files(current_dir);
        if found {
            return true, license_filepaths;
        }
    }
    empty_array: [..] string;
    return false, empty_array;
}

contains_license_files :: (directory: string) -> found:bool, license_filepaths: [..]string {
    license_filepaths : [..]string;;
    visitor :: (info: *File_Visit_Info, license_filepaths: *[..]string) {
        if begins_with(info.short_name, "LICENSE")
        || begins_with(info.short_name, "COPYING")
        || begins_with(info.short_name, "COPYRIGHT") {
            array_add(license_filepaths, info.full_name);
        }
    }
    visit_files(
        dir_name=directory,
        recursive=false,
        user_data=*license_filepaths,
        proc=visitor,
    );
    return license_filepaths.count>0, license_filepaths;
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

    path_overwrite_separators(cache_path, #char "/");
    return cache_path;
}

default_modules_dir :: "./modules";
default_licenses_dir :: "./licenses";

#import "Basic";
#import "File_Utilities";
#import "File";
#import "System";
#import "String";
#import "Process";
