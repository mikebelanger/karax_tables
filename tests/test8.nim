import karax_tables
import karax / [karaxdsl, vdom, vstyles]
import sequtils, json, sugar, strutils
import random

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
var columns: seq[Column]

columns.add(Column(
        name: "username", 
        title: "Name", 
        cel_kind: Text, 
        cel_affordance: ReadAndWrite,
        title_align: Left
    )
)

columns.add(Column(
        name: "id",
        title: "ID",
        cel_kind: Integer, 
        cel_affordance: HiddenField
    )
)

columns.add(Column(
        name: "user_kind", 
        cel_kind: Dropdown, 
        cel_affordance: ReadAndWrite, 
        title: "Kind of user", 
        title_align: Right
    )
)

columns.add(Column(
        name: "delete",
        cel_kind: Checkbox,
        cel_affordance: ReadAndWrite,
        title: "Delete",
        title_align: Right,
        column_kind: RowAction
    )
)

users.add(User(username: "mnike", id: 0))
users.add(User(username: "another_user", id: 2))
users.add(User(username: "third user", id: 4, user_kind: Admin))

const custom_style = 
    TableStyle(
        cell_padding: 14,
        table_class: "custom_table",
        thead_class: "custom_thead",
        tbody_class: "custom_tbody",
        th_class: "custom_th",
        tr_class: "custom_tr",
        td_class: "custom_td"
    )

proc random_name(): string =
    result = ""

    var possible_letters: seq[string]
    for letter in 'a'..'z':
        possible_letters.add($letter)

    let vowels = ['a', 'o', 'e', 'u', 'y', 'w', 'i']

    for x in 6 .. rand(10 .. 15):
        if x == 6:
            result.add(possible_letters.sample.toUpper)

        elif x mod 2 == 0:
            result.add(vowels.sample)

        else:
            result.add(possible_letters.sample)


when defined(js):
    include karax/prelude
    import karax/[kdom]

    var updated_users: seq[User]
    var to_delete: seq[User]
    
    proc onchange(u: User, e: Event) =
        echo u
        #check if this is marked as delete
        if e.currentTarget.querySelector(".delete").checked:
            to_delete.add(u)
        else:
            to_delete = to_delete.filterIt(it.id != u.id)

        updated_users = users.filterIt(it.id == u.id)
        updated_users.add(u)

    proc add_random_user() =
        let new_user = User(
            username: random_name(),
            id: rand(20),
            user_kind: rand(UserKind.low..UserKind.high)
        )

        users.add(new_user)


    proc oncontextmenu(table_users: seq[User], e: Event) =
        echo "right hand click"
        echo table_users
        for index, user in users:
            users[index] = User(
                username: random_name(),
                id: rand(100),
                user_kind: rand(UserKind.low..UserKind.high)
            )

    proc delete_users() =
        for d_user in to_delete:
            users = users.filterIt(it.id != d_user.id)

    proc render(): VNode = 
        result = buildHtml():
            tdiv:
                # users.karax_table(table_style = custom_style, all_columns = ReadAndWrite)
                users.karax_table(table_style = custom_style, columns = columns)

                tdiv:
                    for u in updated_users:
                        p:
                            text $(u.id)
                        p:
                            text u.username
                        p:
                            text $u.user_kind

                button(onclick = () => echo updated_users):
                    text "what are users now?"

                button(onclick = () => add_random_user()):
                    text "Add random user"
                
                button(onclick = () => delete_users()):
                    text "Delete Selected Users"

    setRenderer render
else:
    let vnode = 
        buildHtml():
            tdiv:
                head:
                    link(href = "./css/table_style.css", rel="stylesheet")
                body:
                    users.karax_table(table_style = custom_style, columns = columns)

    writeFile("./tests/stuff8.html", $vnode.to_string)