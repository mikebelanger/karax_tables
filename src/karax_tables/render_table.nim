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

    Column* = object
        name*, title*: string
        cel_kind*: CelKind
        cel_affordance*: CelAffordance
        span, display_order*: int
    
    Cel* = object
        column*: Column
        case cel_kind: CelKind:
            of UnspecifiedCelKind:
                unspecified: string
            of Text:
                text: string
            of Dropdown:
                chosen: string
                options: seq[string]
            of TextArea:
                textarea: string
            of Integer:
                integer: int
            of FloatingPoint:
                floating_point: float

const 
    cel_kinds = (CelKind.low..CelKind.high).mapIt($it).filterIt(it != "UnspecifiedCelKind").join(", ")

proc missing(column: Column, missing: string): string =
    result = 
        "Column: \n" & $column & "\n is missing a " & missing

proc missing(column: Column, missing, suggestion: string): string =
    result =
        "Column: \n" & $column & "\n is missing a " & $missing & ".\n" & " such as: \n" &
        suggestion

proc mismatch_warning(column: Column, contents: string | bool | int | float | enum, suggested_column_type: CelKind): string =
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
        if column.cel_affordance != HiddenField:
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


proc column_headers(obj: object | tuple): seq[Column] =
    for key, value in obj.fieldPairs:
        var col = Column(name: $key)

        when value.typeof is int:
            col.cel_kind = Integer

        when value.typeof is float:
            col.cel_kind = FloatingPoint
        
        when value.typeof is enum:
            col.cel_kind = Dropdown
        
        result.add(col)

proc cel(contents: string | int | float | enum, column: Column): Cel =
    result = 
        Cel(
            column: column,
            cel_kind: column.cel_kind
        )
    
    # Nim's type-checker will throw type errors if I don't specify the type in the 'when'
    # clause here.
    
    case result.cel_kind:
        of UnspecifiedCelKind:
            result.unspecified = ""

        of Integer:
            when contents is int:
                result.integer = contents

            else:
                raise newException(ColumnCelDataMismatch, mismatch_warning(result.column, contents, Integer))

        of Text:
            when contents is string:
                result.text = contents

            else:
                raise newException(ColumnCelDataMismatch, mismatch_warning(result.column, contents, Text))

        of TextArea:
            when contents is string:
                result.textarea = contents

            else:
                raise newException(ColumnCelDataMismatch, mismatch_warning(result.column, contents, TextArea))

        of FloatingPoint:
            when contents is float:
                result.floating_point = contents

            else:
                raise newException(ColumnCelDataMismatch, mismatch_warning(result.column, contents, FloatingPoint))

        of Dropdown:
            when contents is enum:
                result.options = (contents.typeof.low..contents.typeof.high).mapIt($it)
                result.chosen = $contents

            else:
                raise newException(ColumnCelDataMismatch, mismatch_warning(result.column, contents, Dropdown))

proc contents(cel: Cel): string =
    case cel.cel_kind:
        of UnspecifiedCelKind:
            return ""
        of Text:
            return $cel.text
        of TextArea:
            return $cel.textarea
        of Integer:
            return $cel.integer
        of FloatingPoint:
            return $cel.floating_point
        of Dropdown:
            return $cel.chosen

proc to_cels(obj: object | tuple, columns: seq[Column]): seq[Cel] =

    # iterating with fieldPairs is sketchy, so I iterate over them with a custom data structure super fast.
    for key, val in obj.fieldPairs:

        for column in columns:

            if column.name == key:
                result.add(
                    val.cel(column)
                )

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


proc row*(obj: object | tuple, columns: seq[Column]): VNode =
    result = buildHtml(tr())

    for cel in obj.to_cels(columns):
            
        case cel.column.cel_affordance:
            of ReadOnly:
                result.add(
                    buildHtml(td(text(cel.contents)))
                )

            of ReadAndWrite:
                case cel.column.cel_kind:

                    of UnspecifiedCelKind:
                        result.add(buildHtml(td(text(""))))

                    of Text:
                        let form_input = buildHtml(input(type = "text"))
                        form_input.setAttr("value", cel.contents)
                        result.add(buildHtml(td(form_input)))

                    of FloatingPoint, Integer:
                        let form_input = buildHtml(input(type = "number"))
                        form_input.setAttr("increments", "1")
                        form_input.setAttr("value", cel.contents)
                        result.add(buildHtml(td(form_input)))

                    of Dropdown:

                        result.add(
                                buildHtml(
                                    td(optionsMenu(name = $cel.column.name, message = "", selected = cel.contents, options = cel.options))
                                )
                        )
                    
                    of TextArea:
                        let form_input = buildHtml(input(type = "textarea"))
                        form_input.setAttr("value", cel.contents)
                        result.add(buildHtml(td(form_input)))

            of HiddenField:
                let vnode = buildHtml(td())
                vnode.setAttr("value", cel.contents)
                vnode.setAttr("style", "display: none")
                result.add(vnode)


proc render_table(rows: seq[object | tuple], columns: seq[Column]): VNode =
    
    if rows.len > 0:
        result = buildHtml():
            tdiv:
                table:
                    thead:
                        for col in columns:
                            if col.cel_affordance != HiddenField:
                                th:
                                    text col.name
                    tbody:
                        for row_number, row in rows:
                            row.row(columns)

proc karax_table*(objs: seq[object | tuple]): VNode =

    render_table(objs, objs[0].column_headers)

proc karax_table*(objs: seq[object | tuple], columns: seq[Column]): VNode =

    render_table(objs, columns.valid)
