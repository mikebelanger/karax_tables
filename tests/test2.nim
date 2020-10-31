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

var users: seq[User]
let 
    name_column = Column(
        name: "username", 
        title: "Name", 
        cel_kind: Text, 
        cel_affordance: ReadAndWrite, 
    )

    id_column = Column(
        name: "id", 
        cel_kind: Integer, 
        cel_affordance: Hidden, 
    )

    user_kind_column = Column(
        name: "user_kind", 
        cel_kind: Dropdown, 
        cel_affordance: ReadAndWrite, 
        title: "Kind of user", 
    )
    
    age = Column(
        name: "age",
        cel_kind: Integer,
        cel_affordance: ReadAndWrite,
        title: "Age"
    )

    columns = @[id_column, name_column, user_kind_column, age]

users.add(User(username: "mnike", id: 0, age: 36))
users.add(User(username: "another_user", id: 2, age: 22))
users.add(User(username: "third user", id: 4, user_kind: Admin, age: 52))

when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        result = buildHtml():
            users.karax_table(columns = columns)

    setRenderer render
else:
    writeFile("stuff2.html", users.karax_table(columns = columns).to_string)