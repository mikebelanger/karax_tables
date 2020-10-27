# karax_tables
Nim objects -> HTML Tables

Turn a sequence of [Nim](https://nim-lang.org/) objects/tuples into an HTML table - with minimal hassle.  Inspired by [Datatables](https://datatables.net/) and [JExcel](https://bossanova.uk/jexcel/v3/).  Uses [Karax](https://github.com/pragmagic/karax).

### Usage case

You have a bunch of data as Nim objects/tuples.  Maybe loaded using [csvtools](https://github.com/unicredit/csvtools) or even something from an ORM, such as [Ormin](https://github.com/Araq/ormin) or [Norm](https://github.com/moigagoo/norm).
```nimrod
type
    UserKind = enum
        Unconfirmed
        Admin
        Worker
        Supervisor

    User = object
        username: string
        id: int
        user_kind: UserKind

var users: seq[User]
users.add(User(username: "mike", id: 0))
users.add(User(username: "jim", id: 2))
users.add(User(username: "rob", id: 4, user_kind: Admin))
```

You want to render them out to a an HTML table, with minimal hassle.  Like this:

```nimrod
when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        result = buildHtml():
            users.karax_table

    setRenderer render
else:
    writeFile("output_file.html", users.karax_table.to_string)
```

karax_tables primarily operates with client-side (js) rendering.  However some parts of it can be ported to server-side (c) rendering as well.

### Non-Usage case

Your data is something other than an object/tuple.  Either something with homogenous data such as an [arraymancer](https://github.com/mratsim/Arraymancer) tensor, or a heterogeneous pandas dataframe-like structure, such as in [NimData](https://github.com/bluenote10/NimData).  Nothing wrong with these approaches, but this library doesn't target these.

### Requirements

* Nim v.1.4.0
* Karax v.1.1.3

## Installing

Ensure you have nim installed, with karax's *entire* source copied into your project directory.  Alternatively, you could put a `config.nims` file in your project dir, and just enter the path to wherever Karax is:
```
--path: "$HOME/.nimble/pkgs/karax-1.1.3"
```

## Using

#### Client-Side

import karax_tables into whatever file you compile into JS.  Get your objects into a sequence, and call the `.karax_table` function in the main render loop:
```nimrod
include karax/prelude
import karax / [karaxdsl, vdom]
import karax_tables

var users: seq[User]

## do stuff to populate users

proc render(): VNode = 
    result = buildHtml():
        users.karax_table

setRenderer render
```

#### Server Side
TODO: Determine the above works with Windows.