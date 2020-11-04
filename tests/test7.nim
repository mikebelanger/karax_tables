import karax_tables
import karax / [karaxdsl, vdom, kdom, vstyles]
import sequtils

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

    proc row_events(u: User, row: VNode): VNode =

        row.addEventListener(EventKind.onchange, proc(e: Event, v: VNode) =
            echo "works!"
            echo u
            echo e.currentTarget.class
            echo e.currentTarget.children.mapIt(@[it.class, it.value, $it.nodeType, it.innerText, it.nodeName])
            echo e.currentTarget.children.mapIt(it.children.mapIt(@[it.class, it.value, $it.nodeType, it.innerText, it.nodeName]))
        )

        return row

    proc render(): VNode = 
        result = buildHtml():
            users.karax_table(table_style = custom_style, columns = columns)

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