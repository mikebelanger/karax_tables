import karax_tables

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

let user_table = users.karax_table(all_columns = ReadAndWrite)
writeFile("./tests/stuff5.html", user_table.to_string)