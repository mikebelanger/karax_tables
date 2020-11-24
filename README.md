(***WARNING - Very WIP - Subject to breaking changes, missing docs***)

# karax_tables
Nim objects/tuples -> HTML (VDom) Tables

Turn a sequence of [Nim](https://nim-lang.org/) objects/tuples into a dynamically-rendered HTML table - with minimal hassle.  Uses [Karax](https://github.com/pragmagic/karax).

### Why?

* Your project is written in Nim, and that uses Karax.  Probably a CRUD, enterprise-like web app (perhaps using [Ormin](https://github.com/Araq/ormin) or [Norm](https://github.com/moigagoo/norm)), or CSV parsing stuff (like [csvtools](https://github.com/unicredit/csvtools)).

* Your project has its data defined in objects/tuples, and is subject to lots of schema-changes.  Keeping your frontend's tables up-to-date with these schema changes is burning you out.

* Your project could use automatic:
    + Object instance -> table row.
    + Object field -> table column.
    + Object's data-types -> table's td `<input type>`s:
        * String -> text/textarea
        * Int/float -> input number
        * Boolean -> checkboxes
        * Enumerations -> option menus
        * Any data type -> hidden fields

### Why Not?

* Your project only has a few tables, and they don't change that frequently.

* Your project data structures aren't objects or tuples. Maybe the data is represtend by something homogenous, like [arraymancer](https://github.com/mratsim/Arraymancer) tensors.  Or the data is heterogeneous, but contained in a dataframe, such as [NimData](https://github.com/bluenote10/NimData).  Nothing wrong with these approaches, but this library isn't designed with these paradigms in mind.

### Simple Example

Let's say your project has an object defined, called `User`:
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


### Event Listeners

karax_tables supports listening to row and table updates.

To get updated row data, just define a function whose':
* name is based on the event [List of supported events here.](./documents/event_listeners.md)
* first parameter is the object that gets converted to a row
* second parameter is an Event object.  

For example, if we wanted to get an updated user everytime we changed a row, we'd do:

```nimrod
proc onchange(u: User, e: Event) =
    echo u # should print updated user to console
    echo e.currentTarget.querySelector("extra") # prints dom stuff of row

    # you have access to the global scope here, so you can modify
    # the original users array, make new ones, etc. 
```

To get the entire table, do the same as above, but make the first argument a `seq[User]` instead.


### Requirements

* Nim v.1.4.0
* Karax v.1.1.3

## Installing
1.  Ensure you have nim installed, with karax's *entire* source copied into your project directory.  Alternatively, you could put a `config.nims` file in your project dir, and just enter the path to wherever Karax is:
```
--path: "$HOME/.nimble/pkgs/karax-1.1.3"
```
*TODO*: Determine how this works in Windows.

2.  Navigate to your project directory, and clone this repo:
```
git clone https://github.com/mikebelanger/karax_tables.git
```

## Usage Guide

* ### Installing
* ### Creating tables
    + [With Objects](./documents/creating/with_objects.md)
    + [With Tuples](./documents/creating/with_tuples.md)
* ### Customizing
    + [Columns](./documents/columns.md)
        + Text/Textarea
        + Numbers
        + Drop-downs 
        + Check-boxes 
        + Hidden fields
    + [Styling](./documents/styling.md)
        + Headers
        + Rows

    + [Event Callbacks](./documents/event_handlers.md)
        + Row-updates
        + Table updates

    + [Pagination](./documents/pagination.md)

* ### Developing

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

* Styling

## Guides
[Client Side Usage Guide](./documents/client.md)