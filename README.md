# karax_tables
Nim objects -> HTML Tables

Turn a sequence of [Nim](https://nim-lang.org/) objects/tuples into an HTML table - with minimal hassle.  Inspired by [Datatables](https://datatables.net/) and [JExcel](https://bossanova.uk/jexcel/v3/).  Uses [Karax](https://github.com/pragmagic/karax).

### Why?

You're writing lots of enterprise-like CRUD web apps, or maybe some internal CSV processing tool.  Either way, the time comes to display this tabular data.  Your app already has a plethora of objects, which have been defined for some other reason.  Maybe to load a row using [csvtools](https://github.com/unicredit/csvtools) or even something from an ORM, such as [Ormin](https://github.com/Araq/ormin) or [Norm](https://github.com/moigagoo/norm).
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
users.add(User(username: "david", id: 2, user_kind: Supervisor))
users.add(User(username: "rob", id: 4, user_kind: Admin))
```

You could just write the HTML table yourself, with the help of Karax.  While writing an HTML table isn't the hardest thing in the world, you have lots of tables - and its getting tedious and error prone.  Furthermore, your database/objects schema are growing, making revisions/maitenence a source of burnout.  

### Simple Example

Taking the above code, we could render out an HTML like so:

```nimrod
let user_table = users.karax_table(all_columns = ReadAndWrite)
writeFile("./tests/user_table.html", user_table.to_string)
```

Which would render something looking like this:

![Simple HTML Table](tests/html_table.png)

Note that while the above renders using the c backend, most of karax_tables' functionality is targeted for client-side (js) rendering.

### Why Not?

karax_tables is not for everyone.  For starters, if you only have a few tables - it may make more sense to just write with 'plain' Karax.  Slightly more verbose, but easier to see how it works.

Another reason to look elsewhere is if your data is something other than an object/tuple.  Either something with homogenous data such as an [arraymancer](https://github.com/mratsim/Arraymancer) tensor, or a heterogeneous pandas dataframe-like structure, such as in [NimData](https://github.com/bluenote10/NimData).  Nothing wrong with these approaches, but this library doesn't target them.

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

import karax_tables into whatever file you compile into JS.  Get your objects into a sequence, and call the `karax_table` function in the main render loop:
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