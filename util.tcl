proc id        x    { set x }
proc len       list { llength $list }
proc flat      list { string map {\{ "" \} ""} $list }
proc dollarize vars { flat [lmap x $vars {set x $$x}] }

proc forindex { var list body } {
    set len [llength $list]
    set script [subst {for {set $var 0} {$$var < $len} {incr $var} {$body}}]

    uplevel $script
}


proc varlist { n } {
    set vars {}
    set base x
    set count 0

    while { $count < $n } {
        lappend vars ${base}${count}
        incr count
    }
    return $vars
}

proc rem { list {f null} } {
    set res {}
    foreach x $list {
        if { ! [$f $x] } { lappend res $x }
    }
    return $res
}

proc tuples { list {n 2} } {
    set vars [varlist $n]
    lmap $vars $list { rem [list {*}[subst [dollarize $vars]]] }
}

proc odds  { list } { lmap { x y } $list { id $x } }
proc evens { list } { lmap { x y } $list { id $y } }

if { $tcl_version < 8.6 } {
    proc lmap { var list script } {
        set res {}
        foreach el $list {
            uplevel [list set $var $el]
            lappend res [uplevel $script]
        }
        return $res
    }
}

proc condset { var pairs } {
    foreach { cond expr } $pairs {
        if { $cond eq "else" || [uplevel [list expr $cond]] } {
            uplevel [subst -nocommands {set $var [eval $expr]}]
            break
        }
    }
}

proc dbind { list args } {
    forindex i $args {
        set names [nth $args $i]
        set el    [nth $list $i]

        condset script {{ [len $names] > 1 } { list dbind [list $el] {*}$names }
                        { $names eq "..." }  { list set [nth $args $i+1] [list [lrange $list $i end]] }
                        else                 { list set $names $el }}

        if { $names eq "..." } { incr i }

        uplevel $script
    }
}

proc art { noun } {
    set vowels {aeiouAEIOU}
    set c [string index $noun 0]

    if { [string first $c $vowels] == -1 } {
        set article an
    } else {
        set article an
    }

    return "$article $noun"
}

proc fwrite { file data } {
    set fd [open $file w]
    puts $fd $data
    close $fd
}

proc K { x y } { set x }

proc fread { fname } { K [read [set fd [open $fname]]] [close $fd] }

proc domenu { menu } {
    set n [maxstrlen $menu]
    set fmt "%-${n}s %s"

    forindex i $menu {
        puts [format $fmt "[++ $i]." [lindex $menu $i]]
    }

    set start  1
    set end    [llength $menu]
    set choice [prompt "Choose an option \[${start}-$end\]: "]
    while { $choice ne "break" } {
        if { [string is int $choice] } {
            if { $choice > 0 && $choice <= $end } { break }
        }
        set choice [prompt "Choose an option \[${start}-$end\]: "]
    }

    lindex $menu $choice-1
}

proc prompt { msg } {
    puts -nonewline $msg
    flush stdout
    gets stdin
}

proc forindex { var list body } {
    set len [llength $list]
    set script [subst {for {set $var 0} {$$var < $len} {incr $var} {$body}}]

    uplevel $script
}

proc ++ { i {n 1} } { expr { $i + $n } }
proc -- { i {n 1} } { expr { $i - $n } }

proc maxstrlen { strings } { lindex [lsort [lmap x $strings { string length $x }]] end }

proc numbrd { list } {
    forindex i $list {
        puts "[++ $i]. [lindex $list $i]"
    }
}

proc named { names list } {
    set fmt "%-[maxstrlen $names]s - %s"
    forindex i $names  {
        puts [format $fmt [lindex $names $i] [lindex $list $i]]
    }
}

proc randint1 { max } {
    return [expr {int(rand()*$max) + 1}]
}

proc roll { n } {
    randint1 $n
}

proc in { itm list } {
    expr { [lsearch $list $itm] != -1 }
}

proc range { from to } {
    set res {}
    for {set i $from} {$i<$to} {incr i} {
        lappend res $i
    }
    return $res
}

proc n-of { n script } { lmap x [range 0 $n] { uplevel $script } }

proc nth { list i } { lindex $list $i }

proc fincr { var {val 1} } {
    upvar $var v
    set v [expr { $v + $val }]
}

# arc.tcl
#

proc pr  { string } { puts -nonewline $string }
proc prn { string } { puts $string }


proc car { list } {
    if { [atom $list] } { error "Can't take car of $list" }
    lindex $list 0
}

proc cdr { list } {
    if { [atom $list] } { error "Can't take cdr of $list" }
    lrange $list 1 end
}

proc cons { x y } { list $x {*}$y }
proc caar { list } { car [car $list] }
proc cadr { list } { car [cdr $list] }
proc cddr { list } { cdr [cdr $list] }
proc null { list } { string equal $list {} }

proc firstn { n list } { lrange $list 0 $n }
proc nthcdr { n list } { lrange $list $n end }
proc last   { list   } { lindex $list end }

proc len { list } { llength $list }

proc atom { x } { expr { [len $x] == 1 } }

proc rev { list } { lreverse $list }

proc intersperse { x list } {
    set res {}
    forindex i [lrange $list 0 end-1] {
        lappend res [lindex $list $i]
        lappend res $x
    }
    lappend res [last $list]
}

proc reduce { f init list } {
    set res $init
    foreach x $list {
        set res [$f $res $x]
    }
    return $res
}

proc sub { x y } { expr { $x - $y } }
proc add { x y } { expr { $x + $y } }

proc -  { args } { reduce sub [lindex $args 0] [lrange $args 1 end] }
proc +  { args } { reduce add 0 {*}$args }

proc <  { x y } { expr { $x <  $y } }
proc <= { x y } { expr { $x <= $y } }

proc slice { list pos } {
    if { $pos < 0 } { set pos [+ [len $list] $pos] }
    if { $pos <= [len $list] } {
        list [lrange $list 0 $pos-1] [lrange $list $pos end]
    }
}

proc rem { list {f null} } {
    set res {}
    foreach x $list {
        if { ! [$f $x] } { lappend res $x }
    }
    return $res
}

proc pair { list {f {}} } {
    if { ! [null $f] } {
        set script { $f [rem [list $x $y]] }
    } else {
        set script { rem [list $x $y] }
    }

    lmap {x y} $list $script
}

proc varlist { n } {
    set vars {}
    set base x
    set count 0

    while { $count < $n } {
        lappend vars ${base}${count}
        incr count
    }
    return $vars
}

proc max2 { x y } { if { $x > $y } { set x }; set y }

proc max { list } { reduce max2 [lindex $list 0] $list }

proc tuples { list {n 2} } {
    set vars [varlist $n]
    lmap $vars $list { rem [list {*}[subst [dollarize $vars]]] }
}

proc iso { x y } { string equal $x $y }

proc adjoin { elt list {test iso} } {
    foreach x $list {
        if { [$test $elt $x] } { return $list }
    }
    cons $elt $list
}

proc interleave {args} {
    if {[llength $args] == 0} {return {}}

    set data {}
    set idx  0
    set head {}
    set body "lappend data"

    foreach arg $args {
        lappend head v$idx $arg
        append  body " \$v$idx"
        incr idx
    }

    eval foreach $head [list $body]
    return $data
} ;# AMG

proc nums-only? { args } {
    foreach x $args {
        if { ! [string is integer $x] } { return 0 }
    }
    return 1
}

proc log { lvl msg } {
    if { ! [info exists ::Logp] } { return }
    if { $lvl <= $::Logp } {
        prn $msg
    }
}


proc iter { var list body } {
    coroutine next apply [subst {{} {
        yield
        foreach x {$list} { yield \$x }
        return -code break
    }}]

    while 1 {
        uplevel [list set $var [next]]
        uplevel $body
    }
}

proc swap { x y } {
    uplevel [subst { set tmp $$x; set $x $$y; set $y \$tmp }]
}
