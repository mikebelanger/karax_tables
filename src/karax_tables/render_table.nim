import karax / [karaxdsl, vdom]
import sequtils

type
    InconsistentRows* = object of ValueError

    CelAffordance* = enum
        ReadOnly
        ReadAndWrite
        Hidden

    CelKind* = enum
        Text
        Dropdown
        TextArea
        Integer
        Floating

    Column* = object
        name*, title*: string
        cel_kind*: CelKind
        cel_affordance*: CelAffordance
        span, display_order*: int
    
    Cel* = object
        column*: Column
        case cel_kind: CelKind:
            of Text:
                text: string
            of Dropdown:
                chosen: string
                options: seq[string]
            of TextArea:
                textarea: string
            of Integer:
                integer: int
            of Floating:
                floating: float

proc to_string*(vnode: VNode): string =
    when defined(js):
        toString(vnode)
    else:
        $vnode

proc column_headers*(obj: object | tuple): seq[Column] =
    for key, value in obj.fieldPairs:
        var col = Column(name: $key)

        when value.typeof is int:
            col.cel_kind = Integer

        when value.typeof is float:
            col.cel_kind = Floating
        
        when value.typeof is enum:
            col.cel_kind = Dropdown
        
        result.add(col)

proc get_fields*(obj: object | tuple): seq[string] =

    for key, val in obj.fieldPairs:
        result.add($(val.typedesc))

proc cel(contents: string | int | float | enum, column: Column): Cel =
    result = 
        Cel(
            column: column,
            cel_kind: column.cel_kind
        )
    
    # Nim's type-checker will throw type errors if I don't specify the type in the outer
    # clause here

    when contents is string:

        case result.cel_kind:
            of Text:
                result.text = contents
            of TextArea:
                result.textarea = contents
            else:
                echo "mismatch of case: " & $contents.typeof & " vs: " & $result.cel_kind

    when contents is int:
        case result.cel_kind:
            of Integer:
                result.integer = contents
            else:
                echo "mismatch of case: " & $contents.typeof & " vs: " & $result.cel_kind

    when contents is float:
        case result.cel_kind:
            of Floating:
                result.floating = contents
            else:
                echo "mismatch of case: " & $contents.typeof & " vs: " & $result.cel_kind

    when contents is enum:
        case result.cel_kind:
            of Dropdown:
                result.options = (contents.typeof.low..contents.typeof.high).mapIt($it)
                result.chosen = $contents
            else:
                echo "mismatch of case: " & $contents.typeof & " vs: " & $result.cel_kind

proc contents(cel: Cel): string =
    case cel.cel_kind:
        of Text:
            return $cel.text
        of TextArea:
            return $cel.textarea
        of Integer:
            return $cel.integer
        of Floating:
            return $cel.floating
        of Dropdown:
            return $cel.chosen

proc to_cels(obj: object, columns: seq[Column]): seq[Cel] =

    # iterating with fieldPairs is sketchy, so I iterate over them with a custom data structure super fast.
    for key, val in obj.fieldPairs:

        for column in columns:

            if column.name == key:
                result.add(
                    val.cel(column)
                )

proc default_row(obj: object | tuple): VNode =
    result = buildHtml(tr())

    for key, val in obj.fieldPairs:
        
        when val is enum:
            let options = (val.typeof.low .. val.typeof.high).mapIt($it)
            result.add(buildHtml(
                td(optionsMenu(name = $key, message = "", selected = $val, options = options))
                )
            )
        else:
            result.add(buildHtml(td(text($val))))

proc row(obj: object | tuple, columns: seq[Column]): VNode =
    result = buildHtml(tr())

    for cel in obj.to_cels(columns):
                
        case cel.column.cel_affordance:
            of ReadOnly:
                result.add(
                    buildHtml(td(text(cel.contents)))
                )

            of ReadAndWrite:
                case cel.column.cel_kind:
                    of Text:
                        let form_input = buildHtml(input(type = "text"))
                        form_input.setAttr("value", cel.contents)
                        result.add(buildHtml(td(form_input)))

                    of Floating, Integer:
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

            
            of Hidden:
                let vnode = buildHtml(td())
                vnode.setAttr("value", cel.contents)
                vnode.setAttr("style", "display: none")
                result.add(vnode)


proc optionsMenu*(name, message: cstring, selected = "", options: seq[string]): VNode =

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

proc karax_table*(objs: seq[object | tuple]): VNode =
    if objs.len > 0:
        let 
            number_of_fields = objs[0].get_fields.len
            columns = objs[0].column_headers

        result = buildHtml():
            tdiv:
                table:
                    thead:
                        for col in columns:
                            th:
                                text col.name
                    tbody:
                        for row_number, ob in objs:
                            if ob.get_fields.len == number_of_fields:
                                ob.default_row
                            else:
                                raise newException(InconsistentRows, 
                                "row number " & $row_number & " has " & $(ob.get_fields.len) & " columns, but the first row has " & $number_of_fields)

proc karax_table*(objs: seq[object | tuple], columns: seq[Column]): VNode =

    if objs.len > 0:
        let number_of_fields = objs[0].get_fields.len

        result = buildHtml():
            tdiv:
                table:
                    thead:
                        for col in columns:
                            if not (col.cel_affordance == Hidden):
                                if col.title.len > 0:
                                    th:
                                        text col.title
                                else:
                                    th:
                                        text col.name

                    tbody:
                        for row_number, ob in objs:
                            if ob.get_fields.len == number_of_fields:
                                ob.row(columns)
                            else:
                                raise newException(InconsistentRows, 
                                "row number " & $row_number & " has " & $(ob.get_fields.len) & " columns, but the first row has " & $number_of_fields)