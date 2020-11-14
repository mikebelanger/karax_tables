# karax_tables
Nim objects/tuples -> HTML (VDom) Tables

Turn a sequence of [Nim](https://nim-lang.org/) objects/tuples into an HTML table - with minimal hassle.  Inspired by [Datatables](https://datatables.net/) and [JExcel](https://bossanova.uk/jexcel/v3/).  Uses [Karax](https://github.com/pragmagic/karax).

### Why?

* Your project is written in Nim, and with it, Karax.  Probably a CRUD, enterprise-like web app (perhaps using [Ormin](https://github.com/Araq/ormin) or [Norm](https://github.com/moigagoo/norm)), or a something parsing a big CSV (like [csvtools](https://github.com/unicredit/csvtools)).

* Your project already has its data defined as objects/tuples.

* Your project is subject to lots of schema-changes, and updating your table code is burning you out.

### Why Not?

* You only have a few tables, and they don't change that frequently.

* Your data is stored in a more all-encompassing data-structure.  Either something with homogenous data like [arraymancer](https://github.com/mratsim/Arraymancer) tensors, heterogeneous, Pandas dataframe-like structure, such as in [NimData](https://github.com/bluenote10/NimData).  Nothing wrong with these approaches, but this library doesn't target them.


### Simple Example

Let's say you have some user objects:
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
Taking the above code, we could render out an HTML like so:

```nimrod
let user_table = users.karax_table(all_columns = ReadAndWrite)
writeFile("./tests/user_table.html", user_table.to_string)
```

Which would render something looking like this:

![Simple HTML Table](tests/html_table.png)

Note that while the above renders using the c backend, most of karax_tables' functionality is targeted for client-side (js) rendering.

### Supported Input Types

* text/textarea
* numbers
* drop-down menus 
* check-boxes 
* hidden fields

### Supported Event Listeners

karax_tables supports listening to row and table updates.

To get updated row data, just define a function whose':
* name is based on the event (List of supported events here) 
* first parameter is the object that gets converted to a row
* second parameter is an Event object.  

For example, if we wanted to get an updated user everytime we changed a row, we'd do:

```nimrod
proc onchange(u: User, e: Event) =
    echo u # should print updated user to console
    echo e.currentTarget.querySelector("extra") # prints dom stuff of row
```

To get the entire table, do the same as above, but make the first argument a `seq[User]` instead.


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

## Other Features


## Guides
[Client Side Usage Guide](./documents/client.md)

#### Server Side
TODO: Determine the above works with Windows.