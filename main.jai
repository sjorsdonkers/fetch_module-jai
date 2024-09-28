#import "Basic";
#import "File_Utilities";

// #run deps();

main :: () {
    #import "Sum_Type";

    Thing :: struct {
    a: int;
    }

    Bing :: struct {
        b: string;
    }

    Sum :: Sum_Type(Thing, *Thing, Bing, [] Bing);
}

// deps :: () {
//     git_pkg(.{url = "http://example.com"});
//     git_pkg(.{url = "http://example.org"});
//     git_pkg(.{url = "http://example.net"});

//     path_pkg(.{path = "./assets/sum_type/Sum_Type.jai"});
// }
