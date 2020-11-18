import karax / [karaxdsl, vdom, vstyles]
import sequtils, strutils, json
import macros
import random

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

proc mismatch(column: Column, contents: string | bool | int | float | enum | object, suggested_column_type: CelKind): string =
    result = 
        "Cel and Column schema mismatch for: \n" & 
            column.title & "\ncel content type is: " & 
            $contents.typeof & "\n but column type is: \n" & 
            $column.cel_kind &
            "Either change your column type to: " & $suggested_column_type & "\n" &
            "or examine your object/tuple's " & $column.name & " fields."

proc valid(columns: seq[Column]): seq[Column] =
    ## Determine which columns are completed and which aren't.2
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
    ## For auto-inferring column headers from an object's fields
    for key, value in obj.fieldPairs:
        var col = Column(name: $key)

        when value.typeof is object:
            result.add(value.column_headers(affordance))
        
        else:

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
    ## generate a drop-down menu.
    ## name plugs into label wrapper around drop-down menu, and select id
    ## message is what you first see selected on the dropdown.
    ## selected is just which of the options is selected (if you don't want a message)
    ## options are just the other options

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

proc cel(contents: string | int | float | enum | bool, id: int, column: Column, table_style: TableStyle): Cel =
    ## generates cel based on an object/tuples's value
    let the_id = $id & "_" & $(500.rand)
    result = 
        Cel(
            column: column,
            contents: buildHtml(td(class = table_style.td_class, id = the_id))
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

                        if contents:
                            form_input.setAttr("checked", "")
                        
                        form_input.setAttr("disabled", "disabled")
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Checkbox))
                
                else:
                    let form = buildHtml(tdiv(text($contents)))
                    form.setAttr("class", column.name)
                    form.setAttr("value", $contents)
                    result.contents.add(form)

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
                        let form_input = buildHtml(input(`type` = "checkbox", id = $id & "_checkmark"))
                        form_input.setAttr("class", column.name)
                        form_input.setAttr("value", "active")

                        # echo "contents: ", contents
                        # echo "for"
                        # echo column.name
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

    # if a column is just based on the object fields themselves.
    for key, val in obj.fieldPairs:
        
        when val is object:

            result.add(val.to_cels(columns, table_style))


    # we have to iterate twice over the object fieldPairs so we iterate
    # through columns in the outermost loop
    # this is to preserve the column order inside the <tr>
    for column in columns:
        var idx = 0

        for key, val in obj.fieldPairs:

            when (val is int) or (val is float) or (val is enum) or (val is string) or (val is bool):

                if column.name == key:

                    result.add(
                        val.cel(idx, column, table_style)
                    )

        idx.inc

proc add_any_listeners[T](vnode: VNode, thing: T): VNode =
    ## any procs named after js event listeners whose first argument type is
    ## the object being converted into a row get detected here.

    # yeah...I hate this part too
    # TODO: Find a less verbose way of testing for these procs
    # without sacrifcing intuitiveness.
    result = vnode
    when compiles(thing.onclick(Event())):
        result.addEventHandler(EventKind.onclick, proc(e: Event, v: VNode) =
            e.updated(thing).onclick(e)
        )

    when compiles(thing.oncontextmenu(Event())):
        result.addEventHandler(EventKind.oncontextmenu, proc(e: Event, v: VNode) =
            e.updated(thing).oncontextmenu(e)
        )

    when compiles(thing.ondblclick(Event())):
        result.addEventHandler(EventKind.ondblclick, proc(e: Event, v: VNode) =
            e.updated(thing).ondblclick(e)
        )

    when compiles(thing.onkeyup(Event())):
        result.addEventHandler(EventKind.onkeyup, proc(e: Event, v: VNode) =
            e.updated(thing).onkeyup(e)
        )

    when compiles(thing.onkeydown(Event())):
        result.addEventHandler(EventKind.onkeydown, proc(e: Event, v: VNode) =
            e.updated(thing).onkeydown(e)
        )

    when compiles(thing.onkeypressed(Event())):
        result.addEventHandler(EventKind.onkeypressed, proc(e: Event, v: VNode) =
            e.updated(thing).onkeypressed(e)
        )

    when compiles(thing.onfocus(Event())):
        result.addEventHandler(EventKind.onfocus, proc(e: Event, v: VNode) =
            e.updated(thing).onfocus(e)
        )

    when compiles(thing.onblur(Event())):
        result.addEventHandler(EventKind.onblur, proc(e: Event, v: VNode) =
            e.updated(thing).onblur(e)
        )

    when compiles(thing.onchange(Event())):
        result.addEventHandler(EventKind.onchange, proc(e: Event, v: VNode) =
            e.updated(thing).onchange(e)
        )

    when compiles(thing.onscroll(Event())):
        result.addEventHandler(EventKind.onscroll, proc(e: Event, v: VNode) =
            e.updated(thing).onscroll(e)
        )

    when compiles(thing.onmousedown(Event())):
        result.addEventHandler(EventKind.onmousedown, proc(e: Event, v: VNode) =
            e.updated(thing).onmousedown(e)
        )

    when compiles(thing.onmouseleave(Event())):
        result.addEventHandler(EventKind.onmouseleave, proc(e: Event, v: VNode) =
            e.updated(thing).onmouseleave(e)
        )

    when compiles(thing.onmousemove(Event())):
        result.addEventHandler(EventKind.onmousemove, proc(e: Event, v: VNode) =
            e.updated(thing).onmousemove(e)
        )

    when compiles(thing.onmouseout(Event())):
        result.addEventHandler(EventKind.onmouseout, proc(e: Event, v: VNode) =
            e.updated(thing).onmouseout(e)
        )

    when compiles(thing.onmouseover(Event())):
        result.addEventHandler(EventKind.onmouseover, proc(e: Event, v: VNode) =
            e.updated(thing).onmouseover(e)
        )

    when compiles(thing.onmouseup(Event())):
        result.addEventHandler(EventKind.onmouseup, proc(e: Event, v: VNode) =
            e.updated(thing).onmouseup(e)
        )

    when compiles(thing.ondrag(Event())):
        result.addEventHandler(EventKind.ondrag, proc(e: Event, v: VNode) =
            e.updated(thing).ondrag(e)
        )

    when compiles(thing.ondragend(Event())):
        result.addEventHandler(EventKind.ondragend, proc(e: Event, v: VNode) =
            e.updated(thing).ondragend(e)
        )

    when compiles(thing.ondragenter(Event())):
        result.addEventHandler(EventKind.ondragenter, proc(e: Event, v: VNode) =
            e.updated(thing).ondragenter(e)
        )

    when compiles(thing.ondragleave(Event())):
        result.addEventHandler(EventKind.ondragleave, proc(e: Event, v: VNode) =
            e.updated(thing).ondragleave(e)
        )

    when compiles(thing.ondragover(Event())):
        result.addEventHandler(EventKind.ondragover, proc(e: Event, v: VNode) =
            e.updated(thing).ondragover(e)
        )

    when compiles(thing.ondragstart(Event())):
        result.addEventHandler(EventKind.ondragstart, proc(e: Event, v: VNode) =
            e.updated(thing).ondragstart(e)
        )

    when compiles(thing.ondrop(Event())):
        result.addEventHandler(EventKind.ondrop, proc(e: Event, v: VNode) =
            e.updated(thing).ondrop(e)
        )

    when compiles(thing.onsubmit(Event())):
        result.addEventHandler(EventKind.onsubmit, proc(e: Event, v: VNode) =
            e.updated(thing).onsubmit(e)
        )

    when compiles(thing.oninput(Event())):
        result.addEventHandler(EventKind.oninput, proc(e: Event, v: VNode) =
            e.updated(thing).oninput(e)
        )

    when compiles(thing.onanimationstart(Event())):
        result.addEventHandler(EventKind.onanimationstart, proc(e: Event, v: VNode) =
            e.updated(thing).onanimationstart(e)
        )

    when compiles(thing.onanimationend(Event())):
        result.addEventHandler(EventKind.onanimationend, proc(e: Event, v: VNode) =
            e.updated(thing).onanimationstart(e)
        )

    when compiles(thing.onanimationiteration(Event())):
        result.addEventHandler(EventKind.onanimationiteration, proc(e: Event, v: VNode) =
            e.updated(thing).onanimationiteration(e)
        )

    when compiles(thing.onkeyupenter(Event())):
        result.addEventHandler(EventKind.onkeyupenter, proc(e: Event, v: VNode) =
            e.updated(thing).onkeyupenter(e)
        )

    when compiles(thing.onkeyuplater(Event())):
        result.addEventHandler(EventKind.onkeyuplater, proc(e: Event, v: VNode) =
            e.updated(thing).onkeyuplater(e)
        )

    when compiles(thing.onload(Event())):
        result.addEventHandler(EventKind.onload, proc(e: Event, v: VNode) =
            e.updated(thing).onload(e)
        )

    when compiles(thing.ontransitioncancel(Event())):
        result.addEventHandler(EventKind.ontransitioncancel, proc(e: Event, v: VNode) =
            e.updated(thing).ontransitioncancel(e)
        )

    when compiles(thing.ontransitionend(Event())):
        result.addEventHandler(EventKind.ontransitionend, proc(e: Event, v: VNode) =
            e.updated(thing).ontransitionend(e)
        )

    when compiles(thing.ontransitionrun(Event())):
        result.addEventHandler(EventKind.ontransitionrun, proc(e: Event, v: VNode) =
            e.updated(thing).ontransitionrun(e)
        )

    when compiles(thing.ontransitionstart(Event())):
        result.addEventHandler(EventKind.ontransitionstart, proc(e: Event, v: VNode) =
            e.updated(thing).ontransitionstart(e)
        )

    when compiles(thing.onchange(Event())):
        result.addEventHandler(EventKind.onchange, proc(e: Event, v: VNode) =
            e.updated(thing).onchange(e)
        )

    return result

proc row*(obj: object | tuple, columns: seq[Column], index: int, table_style: TableStyle): VNode =
    ## Generates a single row from an object/tuple.
    
    result = buildHtml(tr(class = table_style.tr_class, id = $index))

    for cel in obj.to_cels(columns, table_style):
        result.add(cel.contents)

    # now add any event listeners
    return result.add_any_listeners(obj)

proc to_string*(vnode: VNode): string =
    when defined(js):
        toString(vnode)
    else:
        $vnode

when defined(js):
    import karax / [kdom]

    proc get_tr_values_for*(node: kdom.Node, key: string): string =
        ## Get information from a single row generated by karax_tables
        ## node is the tr node, key is the name of the class who'se value you want.
        if node.nodeType == ElementNode:

            if node.nodeName == "input":
                if (node.hasAttribute("class")) and (node.hasAttribute("value")):

                    if node.class == key:

                        return $node.value

                elif node.nodeName == "SELECT":
                    return $(node.children.mapIt($it.value))

            else:
                if node.hasAttribute("class") and node.class == key:
                    return $node.textContent

    proc get_tr_for_object(obj: object | tuple, event: kdom.Event): JsonNode =
        ## this is for getting a table row from a clicked event
        ## and creating a JSON modelled after obj's Typedesc
        var json_vals = parseJson("{}")

        for key, val in obj.fieldPairs:
            when val.typeof is object:
                json_vals{key}= event.tr_to_json(val)

            when val.typeof is string:
                json_vals{key}= event.currentTarget.querySelector("." & key).get_tr_values_for(key).newJString

            when val.typeof is enum:
                if event.currentTarget.querySelector("." & key).hasAttribute("select"):
                    json_vals{key}= %*($(event.currentTarget.querySelector("." & key).querySelector("select").value))
                else:
                    json_vals{key}= event.currentTarget.querySelector("." & key).get_tr_values_for(key).newJString

            when val.typeof is int:
                json_vals{key}= event.currentTarget.querySelector("." & key).get_tr_values_for(key).parseInt.newJInt

            when val.typeof is float:
                json_vals{key}= event.currentTarget.querySelector("." & key).get_tr_values_for(key).parseFloat.newJFloat

            when val is bool:
                json_vals{key}= event.currentTarget.querySelector("." & key).checked.newJBool

        return json_vals


    proc tr_to_json*[T](event: kdom.Event, obj: T): JsonNode =
        ## Get updated object/seq[object | tuple] (T) from a table-row or table

        when obj is object:
            return obj.get_tr_for_object(event)

        when obj is seq[object]:
            var return_json = parseJson("[]")
            
            for o in obj:
                return_json.add(o.get_tr_for_object(event))

            return return_json

    proc updated*[T](event: kdom.Event, obj: T): T =
        return event.tr_to_json(obj).to(obj.typedesc)


proc render_table(objs: seq[object | tuple], columns: seq[Column], table_style: TableStyle): VNode =
    ## renders table based on sequence of objects/tuples and Columns.

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
                        obj.row(columns, number, table_style)
    if objs.len > 0:
        return result.add_any_listeners(objs)
    else:
        return result

proc karax_table*(objs: seq[object | tuple], all_columns = ReadOnly, table_style = TableStyle()): VNode =
    ## render table with default column names and attributes
    runnableExamples:
        some_object_array.karax_table
        some_object_array.karax_table(all_columns = ReadAndWrite)

    render_table(objs, objs[0].column_headers(all_columns), table_style)

proc karax_table*(objs: seq[object | tuple], columns: seq[Column], table_style = TableStyle()): VNode =
    ## render table with custom columns names and attributes
    runnableExamples:
        some_object_array.karax_table(columns = @[Column(title: "My Column", name: "my_column")])

    render_table(objs, columns.valid, table_style)
