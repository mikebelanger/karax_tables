### Client-Side Usage

#### Basic

import karax_tables into whatever file you compile into JS.  Get your objects into a sequence, and call the `karax_table` function in the main render loop:
```nimrod
include karax/prelude
import karax / [karaxdsl, vdom]
import karax_tables

var users: seq[User]

## do stuff to populate users.  Compiled, AJAX requests, whatever.

proc render(): VNode = 
    result = buildHtml():
        users.karax_table

setRenderer render
```

After that...

1.  Compile that to js like `nim js the_file.nim`.  
2.  Make an html file (ensure there's a div with id=`ROOT`) and namespace it into the HTML file.

## Customizing

#### Column-titles

As a default, column titles are determined by object attribute names.  To overrwrite that, pass in a sequence of `Column` objects.
```nimrod
var columns: seq[Column]

columns.add(Column(
        name: "username", 
        title: "Name", 
        cel_kind: Text, 
        cel_affordance: ReadAndWrite,
        title_align: Left
    )
)
```
***Note***: Ensure the `name` field of the Column object matches the object/tuple field name. So in the above example, the `name` field has to be `"username"` in order for that to override the User object's username title into `"Name"`.

Then, pass in the `columns` array into the karax_table function call:

```nimrod
users.karax_table(columns = columns)
```

***Also note***: if you use the columns argument for karax_table, karax_table will render *only* the columns that correspond to the object attribtue.  It will ignore any other attributes that don't have columns specified.




