# Tcl Object Relational Management

This package provides an extremely simple [Object Relational
Mapping](https://en.wikipedia.org/wiki/Object-relational_mapping)
interface for Tcl and sqlite3. It supports primitive types on objects
(eg text, real, int) and lists of other types of objects (eg a
Character can have a list of Item). See usage examples below.

# Files

<b>orm.tcl</b>    - This is the main file containing the ORM logic.

<b>util.tcl</b>   - This file contains several helpers for processing
lists, strings, etc.

<b>jbroo.tcl</b> - This file has some code that I consider a must
have when using TclOO. Essentially obviates the need for using [my]
and [self]. The code originates from [here](http://wiki.tcl.tk/36957).

# Usage

I may get around to making a package index or a module. For now I'm
just sourcing the file.

    # orm_example.tcl

    source orm.tcl

    sqlite3 ::GameDB gamedb.sql

    ManagedObjects { Character Item }

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