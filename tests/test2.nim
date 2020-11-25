import karax_tables

### using custom table

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
        age: int
        active: bool

var users: seq[User]
let 
    name_column = ColumnHeader(
        name: "username", 
        title: "Name", 
        cel_kind: Text, 
        cel_affordance: ReadAndWrite, 
    )

    id_column = ColumnHeader(
        name: "id",
        title: "ID",
        cel_kind: Integer, 
        cel_affordance: HiddenField
    )

    user_kind_column = ColumnHeader(
        name: "user_kind", 
        cel_kind: Dropdown, 
        cel_affordance: ReadAndWrite, 
        title: "Kind of user", 
    )
    
    age = ColumnHeader(
        name: "age",
        cel_kind: Integer,
        cel_affordance: ReadAndWrite,
        title: "Age"
    )

    active = ColumnHeader(
        name: "active",
        cel_kind: Checkbox,
        cel_affordance: ReadAndWrite,
        title: "Currently Active",
    )

    columns = @[id_column, active, age, name_column, user_kind_column]

users.add(User(username: "mnike", id: 0, age: 36, active: false))
users.add(User(username: "another_user", id: 2, age: 22, active: true))
users.add(User(username: "third user", id: 4, user_kind: Admin, age: 52, active: true))

when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        result = buildHtml():
            users.karax_table(columns = columns)

    setRenderer render
else:
    writeFile("./tests/stuff2.html", users.karax_table(columns = columns).to_string)