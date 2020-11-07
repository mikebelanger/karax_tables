import karax_tables
import karax / [karaxdsl, vdom, kdom, vstyles]
import sequtils, json

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


when defined(js):
    include karax/prelude

    var updated_users: seq[User]

    proc row_events(u: User, row: VNode): VNode =

        row.addEventListener(EventKind.onchange, proc(e: Event, v: VNode) =
            let updated = e.get_json_for(u)

            updated_users = updated_users.filterIt(it.id != updated.id)
            updated_users.add(updated)

            echo updated_users
        )

        return row

    proc render(): VNode = 
        result = buildHtml():
            tdiv:
                users.karax_table(table_style = custom_style, columns = columns)

                tdiv:
                    for u in updated_users:
                        p:
                            text $(u.id)
                        p:
                            text u.username

    setRenderer render
else:
    let vnode = 
        buildHtml():
            tdiv:
                head:
                    link(href = "./css/table_style.css", rel="stylesheet")
                body:
                    users.karax_table(table_style = custom_style, columns = columns)

    writeFile("./tests/stuff7.html", vnode.to_string)