/*
  Sum_Type - Basic sum type / tagged union with compile-time-checked match macro
*/

// Example usage

Thing :: struct {
  a: int;
}

Bing :: struct {
  b: string;
}

Sum :: Sum_Type(Thing, *Thing, Bing, [] Bing);

#run {
  s: Sum;
  t: Thing = .{3};
  tp := *t;
  set(*s, t);

  x := 3;

  Sum.match(*s,
    Thing,   #code { print("a is: %. x is: %\n", it.a, `x); }, // Have to use backticks to use local variables... Argh.
    *Thing,  #code { print("a is: %, the pointer is: %\n", (<<it).a, it); },
    Bing,    #code { print("b is: %\n", it.b); },
    [] Bing, #code { print("the first b is: %\n", (<<it)[0].b); },
  );

  Sum.match_one(*s,
    Bing,      #code { print("It's a Bing, everybody!\n"); },
    /* else */ #code { print("Oof guys, it's not a Bing... but instead it's a % with value %!\n", type_of(<<it), <<it); }
  );
}

////////////////////////

Sum_Type :: struct(value_types: ..Type) {
  // Generate fields
  #insert -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    print_to_builder(*builder, "Tag_Type :: enum u8 {\n");

    for 0..value_types.count-1 {
      print_to_builder(*builder, "  TYPE_%;\n", it);
    }

    print_to_builder(*builder, "}\n");
    print_to_builder(*builder, "tag: Tag_Type;\n");
    print_to_builder(*builder, "data: union {\n");

    for value_types {
      print_to_builder(*builder, "  value_%: %;\n", it_index, it);
    }

    print_to_builder(*builder, "}\n");
    result := builder_to_string(*builder);
    // print(result);
    return result;
  }

  // Generate macro called "match", to be used like:
  // Your_Sum_Type.match(*sum_type_variable,
  //   int,    #code { /* ... */ },
  //   float,  #code { /* ... */ },
  //   string, #code { /* ... */ },
  // );
  // Inside each of the #code blocks will have declared a local called "it" that's a pointer of the type to the left of
  // the code block. The type cases can be specified in any order, and you'll be nagged if you have a missing or
  // duplicate case!
  #insert -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    print_to_builder(*builder, "match :: (sum: *Sum_Type,\n");
    for 0..value_types.count-1 {
      print_to_builder(*builder, "  $type_%: Type,\n", it);
      print_to_builder(*builder, "  code_%: Code%\n", it,  ifx it == value_types.count-1 then "" else ",");
    }
    print_to_builder(*builder, ") #expand {\n");

    for value_types {
      print_to_builder(*builder, "  field_id_% :: #run check_type_in_sum(type_of(<<sum), type_%);\n", it_index, it_index);
    }

    print_to_builder(*builder, "  if #complete sum.tag == {\n");
    for 0..value_types.count-1 {
      print_to_builder(*builder, "    case #run cast(type_of(sum.tag)) field_id_%;\n", it);
      print_to_builder(*builder, "      it := #insert #run tprint(\"*sum.data.value_%%;\", field_id_%);\n", it);
      print_to_builder(*builder, "      #insert,scope() code_%;\n", it);
    }
    print_to_builder(*builder, "  }\n");

    print_to_builder(*builder, "}\n");

    result := builder_to_string(*builder);
    // print(result);
    return result;
  }

  // To be used like:
  // Your_Sum_Type.match_one(*sum_type_variable,
  //   int,       #code { /* ... */ },
  //   /* else */ #code { /* ... */ },
  // );
  // You use this one if you only mean to handle one case but don't care about the rest, even if another type were to
  // be added to the sum type down the road. The "else" case will have declared "it" that's a pointer to the current
  // value's type.
  match_one :: (sum: *Sum_Type, $type: Type, type_case: Code, else_case: Code) #expand {
    field_id :: #run check_type_in_sum(type_of(<<sum), type);

    // @CompileSpeed: This must necessarily generate new code on every invocation. Is this bad?
    #insert -> string {
      builder: String_Builder;
      init_string_builder(*builder);

      print_to_builder(*builder, "  if #complete sum.tag == {\n");
      print_to_builder(*builder, "    case .TYPE_%;\n", field_id);
      print_to_builder(*builder, "      it := *sum.data.value_%;\n", field_id);
      print_to_builder(*builder, "      #insert,scope() type_case;\n");
      for 0..value_types.count-1 {
        if it == field_id continue;
        print_to_builder(*builder, "    case .TYPE_%;\n", it);
        print_to_builder(*builder, "      it := *sum.data.value_%;\n", it);
        print_to_builder(*builder, "      #insert,scope() else_case;\n");
      }
      print_to_builder(*builder, "  }\n");
      result := builder_to_string(*builder);
      // print(result);
      return result;
    }
  }
}

set :: inline (sum: *Sum_Type, value: $T) {
  field_id :: #run check_type_in_sum(type_of(<<sum), T);

  #insert #run tprint("sum.tag = .TYPE_%; sum.data.value_% = value;", field_id, field_id);
}

isa :: inline (sum: Sum_Type, $T: Type) -> *T {
  field_id :: #run check_type_in_sum(type_of(sum), T);

  #insert #run tprint("return ifx sum.tag == .TYPE_% then *sum.data.value_% else null;", field_id, field_id);
}

operator == :: inline (sum: Sum_Type, value: $T) -> bool #symmetric {
  field_id :: #run check_type_in_sum(type_of(sum), T);

  #insert #run tprint("return sum.tag == .TYPE_% && sum.data.value_% == value;", field_id, field_id);
}

#scope_file

#import "Basic";

type_field_in_sum :: ($sum_type: Type, $value_type: Type) -> int {
  result :: #run -> int {
    for sum_type.value_types {
      if it == value_type  return it_index;
    }
    return -1;
  }

  return result;
}

check_type_in_sum :: ($sum_type: Type, value_type: Type) -> int #expand {
  field_id :: #run type_field_in_sum(sum_type, value_type);
  #insert #run tprint("#assert (field_id != -1) \"Sum type `%` doesn't include the type `%`!\";", sum_type, value_type);
  return field_id;
}
