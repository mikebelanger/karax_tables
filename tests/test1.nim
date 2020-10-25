# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import karax_tables

type
    User = object
        username: string
        id: int

var users: seq[User]

users.add(User(username: "mnike", id: 0))
users.add(User(username: "another_user", id: 2))
users.add(User(username: "third user", id: 4))


let html_output = users.to_table

writeFile("stuff.html", html_output)