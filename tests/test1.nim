# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import karax_tables

### using default table

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

users.add(User(username: "mnike", id: 0))
users.add(User(username: "another_user", id: 2))
users.add(User(username: "third user", id: 4, user_kind: Admin))

when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        result = buildHtml():
            users.karax_table

    setRenderer render
else:
    writeFile("./tests/stuff.html", users.karax_table.to_string)