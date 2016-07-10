lappend auto_path /Library/Tcl/lib

package require TclOO
package require sqlite3 3.12

source util.tcl
source jbroo.tcl

proc constructor { class } {
    oo::define $class constructor { _primarykey } { set primarykey $_primarykey }
}

proc newmethod { class db } {
    # example creating new Character:
    #    newCharacter name Matt race Human room {North Tower}
    proc new$class { args } [subst -nocommands {
        set columns [join [odds  \$args] ", "]
        set vals    [join [evens \$args] ", "]

        set valuevars [varlist [len [split \$vals ,]]]
        lassign [evens \$args] {*}\$valuevars

        catch {$db eval [subst {insert into \\$class (\$columns) values ([join [dollarize \$valuevars] ", "])}]}
    }]
}

proc table_exists { tablename db } {
    expr { [$db eval {select name from sqlite_master
        where type = 'table' and name = $tablename}] ne "" }
}

proc create_table { name attrs db primarykey } {
    set insert_query {}
    foreach line [lrange [split $attrs \n] 1 end-1] {
        lassign $line type attr
        if { ! [info object isa object $type] } {
            set field  "$attr $type"
            if { $attr eq $primarykey } { append field " primary key" }
            lappend insert_query $field
        }
    }

    $db eval [subst {create table $name ([join $insert_query ", "])}]
}


# matt item -> select name from items where character = 'matt';
# matt item sword -> update items set character = 'matt' where name = 'sword';

proc managed_object { class primarykey attrs db } {
    if { ! [info object isa object $class] } {
        oo::class create $class {
            variable primarykey
            accessor primarykey
        }
    }

    if { ! [table_exists $class $db] } {
        create_table $class $attrs $db $primarykey
    }

    foreach line [lrange [split $attrs \n] 1 end-1] {
        dbind $line type getattr ... options

        # All these variables probably aren't necessary and maybe I'll
        # take the time to make this more elegant by getting rid of
        # the unnecessary ones.
        
        set setattr    $getattr
        set methodname $getattr
        set newval     \$args
        set getkey     $primarykey
        set setkey     $primarykey
        set val        \$primarykey

        # fix condset to work in this situation
        if {[info object isa object $type]} {
            set table $type
            set tmp    $newval
            set newval $val
            set val    $tmp
        } else {
            set table $class
        }
        
        iter op $options {
            switch $op {
                -get     {
                    set getattr [next]
                    set setkey  $getattr
                }
                -by      {
                    set getkey [next]
                    set setattr $getkey
                }
            }
        }

        oo::define $class method $methodname { args } [subst {
            if { \[null \$args\] } {
                $db eval {select $getattr from $table where $getkey = \$primarykey}
            } else {
                $db eval {update $table set $setattr = $newval where $setkey = $val}
            }
        }]
    }

    constructor $class
    newmethod   $class $db
}

sqlite3 ::GameDB gamedb.sql

set ManagedObjects { Character Item }

foreach obj $ManagedObjects {
    oo::class create $obj {
        variable primarykey
        accessor primarykey
    }
}

managed_object Character name {
    text name
    text race
    text room
    text armor
    Item item -get name -by character 
} ::GameDB

managed_object Item name {
     text  name
     int   pcs
     text  currency
     int   rolls
     int   sides
     real  weight
     text  mod
     text  character
} ::GameDB

managed_object Room name {
     text           name
     text           desc
     Character      people -get name -by room
     Item           item   -get name -by room
     Room           exits  -get name -by name
} ::GameDB

newCharacter name matt  race elf   room {North Tower}
newCharacter name alice race human room {North Tower}

newItem name sword
newItem name cloak

newRoom name tower desc {It's a tower}

# For now it's a bad idea to change the value of the primary key
# field.

Character create matt matt
matt item sword
matt item cloak

Character create alice alice

Room create tower tower

tower people matt
tower people alice
puts [tower people]

matt race elf

puts [matt item]
puts [matt race]
