import karax / [karaxdsl, vdom]
import sequtils, strutils

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

    Column* = object
        name*, title*: string
        cel_kind*: CelKind
        cel_affordance*: CelAffordance
        span, display_order*: int
    
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

proc to_string*(vnode: VNode): string =
    when defined(js):
        toString(vnode)
    else:
        $vnode

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
        tdiv:
            label(`for` = $name, id = $name & "_container"):
                select(id = $name):
                    if message.len > 0:
                        option(value = ""):
                            text $message
                    
                    for option in options:
                        if option == selected:
                            option(value = selected, selected = "selected"):
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
                        form_input.setAttr("increments", "1")
                        form_input.setAttr("value", $contents)
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Integer))

                of Text:
                    when contents is string:
                        let form_input = buildHtml(input(type = "text"))
                        form_input.setAttr("value", contents)
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Text))

                of TextArea:
                    when contents is string:
                        let form_input = buildHtml(input(type = "textarea"))
                        form_input.setAttr("value", contents)
                        result.contents.add(form_input)

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, TextArea))

                of FloatingPoint:
                    when contents is float:
                        let form_input = buildHtml(input(type = "number"))
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

                    else:
                        raise newException(ColumnCelDataMismatch, mismatch(result.column, contents, Dropdown))
                
                of Checkbox:
                    when contents is bool:
                        let form_input = buildHtml(input(type = "checkbox"))
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
            vnode.setAttr("value", $contents)
            vnode.setAttr("style", "display: none")
            result.contents = vnode


proc to_cels(obj: object | tuple, columns: seq[Column], table_style: TableStyle): seq[Cel] =

    # iterating with fieldPairs is sketchy, so I iterate over them with a custom data structure super fast.
    for column in columns:

        for key, val in obj.fieldPairs:
            
            if column.name == key:
                result.add(
                    val.cel(column, table_style)
                )


proc row*(obj: object | tuple, columns: seq[Column], table_style: TableStyle): VNode =
    result = buildHtml(tr(class = table_style.tr_class))

    for cel in obj.to_cels(columns, table_style):
        result.add(cel.contents)


proc render_table(rows: seq[object | tuple], columns: seq[Column], table_style: TableStyle): VNode =
    
    if rows.len > 0:
        result = buildHtml():
            tdiv:
                table(class = table_style.table_class, 
                        cellpadding = $table_style.cell_padding, 
                        cellspacing = $table_style.cell_spacing):

                    thead(class = table_style.thead_class):
                        for col in columns:
                            if col.cel_affordance != HiddenField:
                                th(class = table_style.th_class):
                                    text col.title
                    tbody(class = table_style.tbody_class):
                        for row_number, row in rows:
                            row.row(columns, table_style)

proc karax_table*(objs: seq[object | tuple], all_columns = ReadOnly, table_style = TableStyle()): VNode =

    render_table(objs, objs[0].column_headers(all_columns), table_style)

proc karax_table*(objs: seq[object | tuple], columns: seq[Column], table_style = TableStyle()): VNode =

    render_table(objs, columns.valid, table_style)
