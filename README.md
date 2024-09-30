# Plutus
A compile-time **Jai Module Manager** for accumulating and distributing a wealth of Jai modules.

Plutus is a Jai module that aims to make it more convenient to define external dependency versions and keep up-to-date in the project.
Plutus contains normal Jai procedures meant to be called from a build workspace before the main library or application.

## Requirements
For GitModules `git` needs to be installed and available in the PATH.

## Usage
1. Place `Plutus.jai` inside the modules directory.
1. Add a fetch statement to the **build workspace** for each dependency module.
   >NOTE: If you do not already have a build workspace you'll need to create one, see [example: one](./examples/one/first.jai).
   ```jai
   #run {
       #import "Plutus";
       do_update:= false;
       fetch(GitModule.{
               name = "Do_A_Thing",
               url = "git@github.com:sjorsdonkers/plutus.git",
               path = "./examples/assets/Do_A_Thing.jai"},
           do_update);
       ...
   }
   ```
1. [recommended] Only update modules when the `- update` given. Like: `jai .\first.jai - update`
   ```jai
   args := get_build_options().compile_time_command_line;
   do_update := array_find(args, "update");
   ```
1. [optional] Enable Plutus to update itself by adding it as a dependency.
   >NOTE: Does not work if Plutus is placed in the global modules dir.
   ```jai
   fetch(GitModule.{
            name = "Plutus",
            url = "git@github.com:sjorsdonkers/plutus.git",
            path = "Plutus.jai"}, 
        do_update);
   ```

### Limitations:
- Plutus cannot fetch dependency modules for the workspace it itself is in.
