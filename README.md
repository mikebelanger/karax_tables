```
Making HTML tables are fun and intellectually satisfying!
```

--*Nobody, ever.*

# karax_tables

(***WARNING - Very WIP - Subject to breaking changes, missing docs***)

Some functions and an iterator to help make/maintain dynamically rendered tables, with the help of [Nim](https://nim-lang.org/) and [Karax](https://github.com/pragmagic/karax).

### Why?

* Your project is using Nim and Karax.  You have lots of tables to make.  While this isn't hard with normal karaxhtml, its tedious.

* Your data is already defined as objects/tuples, and you'd like something relatively simple to convert those objects/tuples to rows.

* You'd like a searchable table that isn't tedious to write.

### Why Not?

* Your project data structures aren't objects or tuples. Maybe the data is represented by something homogenous, like [arraymancer](https://github.com/mratsim/Arraymancer) tensors.  Or the data is heterogeneous, but contained in a dataframe, such as [NimData](https://github.com/bluenote10/NimData).  Nothing wrong with these approaches, but this library isn't designed with these paradigms in mind.

* Your looking for full-out spreadsheet functionality, like [JExcel](https://bossanova.uk/jexcel/v3/)

### Simple Example

Let's say your project has an object defined, called `User`:

```
type
    User* = object
        first_name*, last_name*: string
        email_address*: Email
```

To render this into a table, add this to your frontend file (somewhere in the karax render function).

```nimrod
table:
    heading("First name", "Last name", "Email", "Select")

    tbody:
        for index, u in users.show(matching = search_filter):
            index.row:
                readandwrite(u.first_name, id = $u.id)
                readandwrite(u.last_name)
                readandwrite(u.email_address.address)
                readonly(false)
```
Adding cel data is done with any of three functions:

    * readonly
    * readandwrite
    * hidden

Notice `readandwrite` and `readonly` will automatically produce an `<input>` tag with the right type (text, number, etc.).  No need to remember the exact tag name!  It just makes sense.

Also notice the `show` iterator.  Pass in a global variable with a search string, and show will filter out the objects matching the search string.  Note this goes through the entire object, not just what you present.

If all your data is all readonly, all readandwrite then you could do this instead:

```nimrod
for index, u in users.show(matching = search_filter):
    readandwrite_row(u.first_name, u.last_name, u.email_address.address, id = $u.id)
```

### IMPORTANT: Always insert unique IDs

its important to pass in a unique identifier to the `id` argument of the functions.  If you just pass in something constant, karax itself might get confused and update the table weirdly. 

### Event listeners

To get an event listener on a row, just write a normal event handler that karax would accept in a row:

```nimrodw
# previous table data

tbody:
    for index, u in users.show(matching = search_filter):
        tr(id = $u.id):
            readandwrite(u.first_name, id = $u.id)
            readandwrite(u.last_name)
            readandwrite(u.email_address.address)
            readonly(false)

        proc onchange(e: Event, n: VNode) =
            let this_id = e.currentTarget.id

            # etc
```
Those kinds of event handlers have access to the global scope of your app, making applicaiton state easy to sync up.

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