import karax / [karaxdsl, vdom, vstyles]
import sequtils, strutils, json
import macros

type
    InvalidColumn* = object of ValueError
    ColumnCelDataMismatch* = object of ValueError

    CelAffordance* = enum
        ReadOnly
        ReadAndWrite
        HiddenField

    CelKind* = enum
        UnspecifiedCelKind
        Text
        Dropdown
        TextArea
        Integer
        FloatingPoint
        Checkbox
        CustomVDom
    
    AlignContent* = enum
        Left
        Center
        Right

    ColumnKind* = enum
        ObjectAttr
        RowAction

    Column* = object
        name*, title*: string
        cel_kind*: CelKind
        cel_affordance*: CelAffordance
        title_align*, cel_content_align*: AlignContent
        column_kind*: ColumnKind
    
    Cel* = object
        column*: Column
        contents: VNode

    TableStyle* = object
        cell_padding*, cell_spacing*: int
        table_class*, thead_class*, th_class*, tbody_class*, tr_class*, td_class*: string

const 
    cel_kinds = (CelKind.low..CelKind.high).mapIt($it).filterIt(it != "UnspecifiedCelKind").join(", ")

proc missing(column: Column, missing: string): string =
    result = 
        "Column: \n" & $column & "\n is missing a " & missing

proc missing(column: Column, missing, suggestion: string): string =
    result =
        "Column: \n" & $column & "\n is missing a " & $missing & ".\n" & " such as: \n" &
        suggestion

proc mismatch(column: Column, contents: string | bool | int | float | enum, suggested_column_type: CelKind): string =
    result = 
        "Cel and Column schema mismatch for: \n" & 
            column.title & "\ncel content type is: " & 
            $contents.typeof & "\n but column type is: \n" & 
            $column.cel_kind &
            "Either change your column type to: " & $suggested_column_type & "\n" &
            "or examine your object/tuple's " & $column.name & " fields."

proc valid(columns: seq[Column]): seq[Column] =
    for column in columns:
        let
            missing_title = column.title.len == 0
            missing_name = column.name.len == 0
            missing_kind = column.cel_kind == UnspecifiedCelKind
        
        if missing_title:
            raise newException(InvalidColumn, missing(column, "title"))
        
        elif missing_name:
            raise newException(InvalidColumn, missing(column, "name"))
        
        elif missing_kind:
            raise newException(InvalidColumn, missing(column, "cel kind", suggestion = cel_kinds)
            )

        else:
    
            result.add(column)
        


proc column_headers(obj: object | tuple, affordance: CelAffordance = ReadOnly): seq[Column] =

    for key, value in obj.fieldPairs:
        var col = Column(name: $key)

        when value.typeof is string:
            col.cel_kind = Text

        when value.typeof is int:
            col.cel_kind = Integer

        when value.typeof is float:
            col.cel_kind = FloatingPoint
        
        when value.typeof is enum:
            col.cel_kind = Dropdown

        when value.typeof is bool:
            col.cel_kind = Checkbox
        
        when value.typeof is VNode:
            col.cel_kind = CustomVDom
        
        col.title = key
        col.cel_affordance = affordance
        result.add(col)

proc optionsMenu(name, message: cstring, selected = "", options: seq[string]): VNode =

    result = buildHtml():
        label(`for` = $name, id = $name & "_container"):
            select(id = $name):
                if message.len > 0:
                    option(value = ""):
                        text $message
                
                for option in options:
                    if option == selected:
                        option(value = selected, selected = "selected", id = $name):
                            text selected
                    else:
                        option(value = option):
                            text option

proc cel(contents: string | int | float | enum | bool, column: Column, table_style: TableStyle): Cel =
    result = 
        Cel(
            column: column,
            contents: buildHtml(td(class = table_style.td_class))
        )
    
    # Nim's type-checker will throw type errors if I don't specify the type in the 'when'
    # clause here.
    case column.cel_affordance:

        of ReadOnly:
            case column.cel_kind:
                of Checkbox:
                    when contents is bool:
                        let form_input = buildHtml(input(type = "checkbox"))
                        form_input.setAttr("class", column.name)
                        form_input.setAttr("value", "active")

                        if contents:
                            form_input.setAttr("checked", "")
                        
                        form_input.setAttr("disabled", "disabled")
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Checkbox))
                
                else:
                    result.contents.add(text($contents))

        of ReadAndWrite:
            case column.cel_kind:
                
                of UnspecifiedCelKind:
                    raise newException(InvalidColumn, missing(column, "cel_kind"))

                of Integer:
                    when contents is int:
                        let form_input = buildHtml(input(type = "number"))
                        form_input.setAttr("class", column.name)
                        form_input.setAttr("increments", "1")
                        form_input.setAttr("value", $contents)
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Integer))

                of Text:
                    when contents is string:
                        let form_input = buildHtml(input(type = "text"))
                        form_input.setAttr("class", column.name)
                        form_input.setAttr("value", contents)
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Text))

                of TextArea:
                    when contents is string:
                        let form_input = buildHtml(input(type = "textarea"))
                        form_input.setAttr("class", column.name)
                        form_input.setAttr("value", contents)
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, TextArea))

                of FloatingPoint:
                    when contents is float:
                        let form_input = buildHtml(input(type = "number"))
                        form_input.setAttr("class", column.name)
                        form_input.setAttr("value", $contents)
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, FloatingPoint))

                of Dropdown:
                    when contents is enum:
                        let options = (contents.typeof.low..contents.typeof.high).mapIt($it)
                        result.contents =
                                buildHtml(
                                    td(optionsMenu(name = $column.name, 
                                        message = "", 
                                        selected = $contents, 
                                        options = options))
                                )

                        result.contents.setAttr("class", column.name)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Dropdown))
                
                of Checkbox:
                    when contents is bool:
                        let form_input = buildHtml(input(type = "checkbox"))
                        form_input.setAttr("class", column.name)
                        form_input.setAttr("value", "active")

                        if contents:
                            form_input.setAttr("checked", "")
                        
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Checkbox))

                of CustomVDom:
                    when contents is VNode:
                        result.contents = contents
                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, CustomVDom))

        of HiddenField:
            let vnode = buildHtml(input(type = "hidden"))
            vnode.setAttr("class", column.name)
            vnode.setAttr("value", $contents)
            vnode.setAttr("style", "display: none")
            result.contents = vnode


proc to_cels(obj: object | tuple, columns: seq[Column], table_style: TableStyle): seq[Cel] =

    # iterating with fieldPairs is sketchy, so I iterate over them with a custom data structure super fast.
    for column in columns:
        if column.column_kind == ObjectAttr:

            for key, val in obj.fieldPairs:
                
                if column.name == key:
                    result.add(
                        val.cel(column, table_style)
                    )

        elif column.column_kind == RowAction:
            case column.cel_kind:
                of Integer:
                    result.add(
                        0.cel(column, table_style)
                    )
                
                of FloatingPoint:
                    result.add(
                        (0.0).cel(column, table_style)
                    )
                
                of Text, TextArea:
                    result.add(
                        "".cel(column, table_style)
                    )

                of Checkbox:
                    result.add(
                        false.cel(column, table_style)
                    )
                
                else:
                    continue

        else:
            continue

proc row*(obj: object | tuple, columns: seq[Column], table_style: TableStyle): VNode =
    result = buildHtml(tr(class = table_style.tr_class))

    for cel in obj.to_cels(columns, table_style):
        result.add(cel.contents)


    # yeah...I hate this part too
    # TODO: Find a less verbose way of testing for these procs
    # without sacrifcing intuitiveness.
    when compiles(obj.onclick(Event())):
        result.addEventListener(EventKind.onclick, proc(e: Event, v: VNode) =
            e.updated(obj).onclick(e)
        )

    when compiles(obj.oncontextmenu(Event())):
        result.addEventListener(EventKind.oncontextmenu, proc(e: Event, v: VNode) =
            e.updated(obj).oncontextmenu(e)
        )

    when compiles(obj.ondblclick(Event())):
        result.addEventListener(EventKind.ondblclick, proc(e: Event, v: VNode) =
            e.updated(obj).ondblclick(e)
        )

    when compiles(obj.onkeyup(Event())):
        result.addEventListener(EventKind.onkeyup, proc(e: Event, v: VNode) =
            e.updated(obj).onkeyup(e)
        )

    when compiles(obj.onkeydown(Event())):
        result.addEventListener(EventKind.onkeydown, proc(e: Event, v: VNode) =
            e.updated(obj).onkeydown(e)
        )

    when compiles(obj.onkeypressed(Event())):
        result.addEventListener(EventKind.onkeypressed, proc(e: Event, v: VNode) =
            e.updated(obj).onkeypressed(e)
        )

    when compiles(obj.onfocus(Event())):
        result.addEventListener(EventKind.onfocus, proc(e: Event, v: VNode) =
            e.updated(obj).onfocus(e)
        )

    when compiles(obj.onblur(Event())):
        result.addEventListener(EventKind.onblur, proc(e: Event, v: VNode) =
            e.updated(obj).onblur(e)
        )

    when compiles(obj.onchange(Event())):
        result.addEventListener(EventKind.onchange, proc(e: Event, v: VNode) =
            e.updated(obj).onchange(e)
        )

    when compiles(obj.onscroll(Event())):
        result.addEventListener(EventKind.onscroll, proc(e: Event, v: VNode) =
            e.updated(obj).onscroll(e)
        )

    when compiles(obj.onmousedown(Event())):
        result.addEventListener(EventKind.onmousedown, proc(e: Event, v: VNode) =
            e.updated(obj).onmousedown(e)
        )

    when compiles(obj.onmouseleave(Event())):
        result.addEventListener(EventKind.onmouseleave, proc(e: Event, v: VNode) =
            e.updated(obj).onmouseleave(e)
        )

    when compiles(obj.onmousemove(Event())):
        result.addEventListener(EventKind.onmousemove, proc(e: Event, v: VNode) =
            e.updated(obj).onmousemove(e)
        )

    when compiles(obj.onmouseout(Event())):
        result.addEventListener(EventKind.onmouseout, proc(e: Event, v: VNode) =
            e.updated(obj).onmouseout(e)
        )

    when compiles(obj.onmouseover(Event())):
        result.addEventListener(EventKind.onmouseover, proc(e: Event, v: VNode) =
            e.updated(obj).onmouseover(e)
        )

    when compiles(obj.onmouseup(Event())):
        result.addEventListener(EventKind.onmouseup, proc(e: Event, v: VNode) =
            e.updated(obj).onmouseup(e)
        )

    when compiles(obj.ondrag(Event())):
        result.addEventListener(EventKind.ondrag, proc(e: Event, v: VNode) =
            e.updated(obj).ondrag(e)
        )

    when compiles(obj.ondragend(Event())):
        result.addEventListener(EventKind.ondragend, proc(e: Event, v: VNode) =
            e.updated(obj).ondragend(e)
        )

    when compiles(obj.ondragenter(Event())):
        result.addEventListener(EventKind.ondragenter, proc(e: Event, v: VNode) =
            e.updated(obj).ondragenter(e)
        )

    when compiles(obj.ondragleave(Event())):
        result.addEventListener(EventKind.ondragleave, proc(e: Event, v: VNode) =
            e.updated(obj).ondragleave(e)
        )

    when compiles(obj.ondragover(Event())):
        result.addEventListener(EventKind.ondragover, proc(e: Event, v: VNode) =
            e.updated(obj).ondragover(e)
        )

    when compiles(obj.ondragstart(Event())):
        result.addEventListener(EventKind.ondragstart, proc(e: Event, v: VNode) =
            e.updated(obj).ondragstart(e)
        )

    when compiles(obj.ondrop(Event())):
        result.addEventListener(EventKind.ondrop, proc(e: Event, v: VNode) =
            e.updated(obj).ondrop(e)
        )

    when compiles(obj.onsubmit(Event())):
        result.addEventListener(EventKind.onsubmit, proc(e: Event, v: VNode) =
            e.updated(obj).onsubmit(e)
        )

    when compiles(obj.oninput(Event())):
        result.addEventListener(EventKind.oninput, proc(e: Event, v: VNode) =
            e.updated(obj).oninput(e)
        )

    when compiles(obj.onanimationstart(Event())):
        result.addEventListener(EventKind.onanimationstart, proc(e: Event, v: VNode) =
            e.updated(obj).onanimationstart(e)
        )

    when compiles(obj.onanimationend(Event())):
        result.addEventListener(EventKind.onanimationend, proc(e: Event, v: VNode) =
            e.updated(obj).onanimationstart(e)
        )

    when compiles(obj.onanimationiteration(Event())):
        result.addEventListener(EventKind.onanimationiteration, proc(e: Event, v: VNode) =
            e.updated(obj).onanimationiteration(e)
        )

    when compiles(obj.onkeyupenter(Event())):
        result.addEventListener(EventKind.onkeyupenter, proc(e: Event, v: VNode) =
            e.updated(obj).onkeyupenter(e)
        )

    when compiles(obj.onkeyuplater(Event())):
        result.addEventListener(EventKind.onkeyuplater, proc(e: Event, v: VNode) =
            e.updated(obj).onkeyuplater(e)
        )

    when compiles(obj.onload(Event())):
        result.addEventListener(EventKind.onload, proc(e: Event, v: VNode) =
            e.updated(obj).onload(e)
        )

    when compiles(obj.ontransitioncancel(Event())):
        result.addEventListener(EventKind.ontransitioncancel, proc(e: Event, v: VNode) =
            e.updated(obj).ontransitioncancel(e)
        )

    when compiles(obj.ontransitionend(Event())):
        result.addEventListener(EventKind.ontransitionend, proc(e: Event, v: VNode) =
            e.updated(obj).ontransitionend(e)
        )

    when compiles(obj.ontransitionrun(Event())):
        result.addEventListener(EventKind.ontransitionrun, proc(e: Event, v: VNode) =
            e.updated(obj).ontransitionrun(e)
        )

    when compiles(obj.ontransitionstart(Event())):
        result.addEventListener(EventKind.ontransitionstart, proc(e: Event, v: VNode) =
            e.updated(obj).ontransitionstart(e)
        )

    when compiles(obj.onchange(Event())):
        result.addEventListener(EventKind.onchange, proc(e: Event, v: VNode) =
            e.updated(obj).onchange(e)
        )

proc to_string*(vnode: VNode): string =
    when defined(js):
        toString(vnode)
    else:
        $vnode

when defined(js):
    import karax / [kdom]

    proc get_tr_values_for*(node: kdom.Node, key: string): string =

        if node.nodeType == ElementNode:

            if (node.hasAttribute("class")) and (node.hasAttribute("value")):
                if node.class == key:
                    return $node.value

            elif node.nodeName == "SELECT":
                return $(node.children.mapIt($it.value))

    proc updated*(event: kdom.Event, obj: object): object =
        var json_vals = parseJson("{}")

        for key, val in obj.fieldPairs:

            if val.typeof is enum:
                json_vals{key}= %*($(event.currentTarget.querySelector("." & key).querySelector("select").value))

            elif val.typeof is int:
                json_vals{key}= event.currentTarget.querySelector("." & key).get_tr_values_for(key).parseInt.newJInt

            elif val.typeof is float:
                json_vals{key}= event.currentTarget.querySelector("." & key).get_tr_values_for(key).parseFloat.newJFloat

            elif val.typeof is bool:
                json_vals{key}= event.currentTarget.querySelector("." & key).get_tr_values_for(key).parseBool.newJBool

            else:
                json_vals{key}= %*($(event.currentTarget.querySelector("." & key).get_tr_values_for(key)))

        return json_vals.to(obj.typedesc)

proc render_table(objs: seq[object | tuple], columns: seq[Column], table_style: TableStyle): VNode =
    
    result = buildHtml():
        table(class = table_style.table_class, 
                cellpadding = $table_style.cell_padding, 
                cellspacing = $table_style.cell_spacing):

            thead(class = table_style.thead_class):
                for col in columns:
                    if col.cel_affordance != HiddenField:
                        th(class = table_style.th_class, style = style(StyleAttr.text_align, $col.title_align)):
                            text col.title
            tbody(class = table_style.tbody_class):
                if objs.len > 0:
                    for number, obj in objs:
                        obj.row(columns, table_style)


proc karax_table*(objs: seq[object | tuple], all_columns = ReadOnly, table_style = TableStyle()): VNode =

    render_table(objs, objs[0].column_headers(all_columns), table_style)

proc karax_table*(objs: seq[object | tuple], columns: seq[Column], table_style = TableStyle()): VNode =

    render_table(objs, columns.valid, table_style)
