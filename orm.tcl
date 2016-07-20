lappend auto_path /Library/Tcl/lib

package require TclOO
package require sqlite3 3.12

source util.tcl
source jbroo.tcl

proc constructor { class } {
    oo::define $class constructor { _primarykey } { set primarykey $_primarykey }
}

proc destructor { class primarykey db } {
    oo::define $class destructor [subst {
        $db eval {delete from $class where $primarykey = \$primarykey}
    }]
}

proc insert { db table args } {
    set columns [join [odds $args] ", "]
    set vals    [evens $args]

    set valuevars [varlist [len $vals]]
    lassign $vals {*}$valuevars

    catch {$db eval [subst {insert into $table ($columns) values ([join [dollarize $valuevars] ", "])}]}
}

proc newmethod { class db } {
    proc new$class args [subst {insert $db $class {*}\$args}]
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

proc managed_object { class primarykey attrs db {constructive 0} } {
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
        set drop       {}

        # fix condset to work in this situation
        if {[info object isa object $type]} {
            set table $type
            swap val newval
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
                -drop {
                    set drop [subst -nocommands {elseif { \\[lindex \\\$args 0\\] eq "-drop" } {
                set todrop \\[lindex \\\$args 1\\]
                \$db eval {update \$table set \$getkey = "" where \$getattr = \\\$todrop }
            }}]
                }
            }
        }

        if { $constructive } {
            set setter [list insert $db $class \$args]
        } else {
            set setter [subst {$db eval {update $table set $setattr = $newval where $setkey = $val}}]
        }

        oo::define $class method $methodname { args } [subst {
            if { \[null \$args\] } {
                $db eval {select $getattr from $table where $getkey = \$primarykey}
            } [subst $drop] else {
                $setter
            }
        }]
    }

    constructor $class
    destructor  $class $primarykey $db
    newmethod   $class $db
}

proc ManagedObjects { objs } {
    foreach obj $objs {
        oo::class create $obj {
            variable primarykey
            accessor primarykey
        }
    }
}
