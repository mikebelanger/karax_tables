import karax_tables
import karax / [karaxdsl, vdom, vstyles]
import sequtils, json, sugar, strutils
import random, stats

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
        age: float
        user_kind: UserKind

    UserRow = object
        user: User
        to_delete: bool

var users: seq[UserRow]
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
        name: "age", 
        cel_kind: FloatingPoint, 
        cel_affordance: ReadAndWrite, 
        title: "Age", 
        title_align: Left
    )
)

columns.add(Column(
        name: "to_delete",
        cel_kind: Checkbox,
        cel_affordance: ReadAndWrite,
        title: "Delete",
        title_align: Right,
        column_kind: RowAction
    )
)

users.add(UserRow(user: User(username: "mnike", id: 0, age: 37.0)))
users.add(UserRow(user: User(username: "another_user", id: 2, age: 25.0)))
users.add(UserRow(user: User(username: "third user", id: 4, user_kind: Admin, age: 55.0)))

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

    var updated_users: seq[UserRow]
    var to_delete: seq[int]

    proc mode(es: seq[UserKind]): enum =

        # make nested arrays of how often a user kind is there
        let user_kind_freqs = 
            (UserKind.low..UserKind.high)
            .toSeq
            .map((ukind) => es.filter((each_user_kind) => each_user_kind == ukind))
        
        # get index of nested array that's the longest - therefore the most frequent enum
        let most_frequent_index = user_kind_freqs.map((user_kinds) => user_kinds.len).maxIndex

        # return the most frequent based on thefrequent index.
        return user_kind_freqs[most_frequent_index][0]

    proc onchange(u: UserRow, e: Event) =
        # echo u
        echo u
        #check if this is marked as delete
        for index, user_row in users:
            if user_row.user.id == u.user.id:
                users[index] = u

    proc add_random_user() =
        let new_user = User(
            username: random_name(),
            id: rand(20),
            age: rand(100).toFloat,
            user_kind: rand(UserKind.low..UserKind.high)
        )

        users.add(UserRow(user: new_user))


    # proc ondblclick(table_users: seq[UserRow], e: Event) =
    #     echo "double click"
    #     echo table_users
    #     echo e.currentTarget.querySelector("#username").innerHtml
        # for index, user in users:
        #     users[index] = UserRow(
        #         user: User(
        #             username: random_name(),
        #             id: rand(100),
        #             age: rand(100.00),
        #             user_kind: rand(UserKind.low..UserKind.high)
        #         )
        #     )
    proc ondblclick(c: Column, e: Event) =
        echo "ondbl click"
        if c.name == "age":
            echo "clicked on age"


    proc delete_users() =
        updated_users = @[]
        for index, user_row in users:
            if not user_row.to_delete:
                updated_users.add(user_row)
        
        users = updated_users

    proc render(): VNode = 
        result = buildHtml():
            tdiv:
                # users.karax_table(table_style = custom_style, all_columns = ReadAndWrite)
                users.karax_table(columns = columns, table_style = custom_style)

                tdiv:
                    p: text "Most common kind of user: " & $(users
                                                            .map((user_row) => user_row.user.user_kind)
                                                            .mode)

                tdiv:
                    p: text "Average age: " & $(users.map((user_row) => user_row.user.age).mean)

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