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
        age: int

var users: seq[User]
let 
    name_column = Column(
        name: "username", 
        title: "Name", 
        cel_kind: Text, 
        cel_affordance: ReadAndWrite, 
        width: 100
    )

    id_column = Column(
        name: "id", 
        cel_kind: Number, 
        cel_affordance: Hidden, 
        width: 200
    )

    user_kind_column = Column(
        name: "user_kind", 
        cel_kind: Dropdown, 
        cel_affordance: ReadAndWrite, 
        title: "Kind of user", 
        width: 100
    )
    
    age = Column(
        name: "age",
        cel_kind: Number,
        cel_affordance: ReadAndWrite,
        title: "Age"
    )
users.add(User(username: "mnike", id: 0, age: 36))
users.add(User(username: "another_user", id: 2, age: 22))
users.add(User(username: "third user", id: 4, user_kind: Admin, age: 52))

when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        result = buildHtml():
            users.table(id_column, name_column, user_kind_column, age)

    setRenderer render
else:
    writeFile("stuff2.html", users.table(id_column, user_kind_column, name_column, age).to_string)