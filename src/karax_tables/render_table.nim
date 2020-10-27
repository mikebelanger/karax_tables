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
        Number

    Column* = object
        name*, title*: string
        cel_kind*: CelKind
        cel_affordance*: CelAffordance
        width*: int

proc to_string*(vnode: VNode): string =
    when defined(js):
        toString(vnode)
    else:
        $vnode

proc column_headers*(obj: object): seq[Column] =
    for key, value in obj.fieldPairs:
        var col = Column(name: $key, width: 100)

        when value.typeof is int or value.typeof is float:
            col.cel_kind = Number
        
        when value.typeof is enum:
            col.cel_kind = Dropdown
        
        result.add(col)

proc get_fields*(obj: object): seq[string] =

    for key, val in obj.fieldPairs:
        result.add($(val.typedesc))

proc default_row(obj: object): VNode =
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

proc row(obj: object, columns: seq[Column]): VNode =
    result = buildHtml(tr())

    for c in columns:
        
        for key, val in obj.fieldPairs:
        
            if c.name == key:
                case c.cel_affordance:
                    of ReadOnly:
                        result.add(
                            buildHtml(td(text($val)))
                        )

                    of ReadAndWrite:
                        case c.cel_kind:
                            of Text:
                                let form_input = buildHtml(input(type = "text"))
                                form_input.setAttr("value", $val)
                                result.add(buildHtml(td(form_input)))

                            of Number:
                                let form_input = buildHtml(input(type = "number"))
                                form_input.setAttr("increments", "1")
                                form_input.setAttr("value", $val)
                                result.add(buildHtml(td(form_input)))

                            of Dropdown:
                                when val is enum:
                                    let options = (val.typeof.low..val.typeof.high).mapIt($it)
                                    result.add(
                                            buildHtml(
                                                td(optionsMenu(name = $key, message = "", selected = $val, options = options))
                                            )
                                    )
                            
                            of TextArea:
                                let form_input = buildHtml(input(type = "textarea"))
                                form_input.setAttr("value", $val)
                                result.add(buildHtml(td(form_input)))

                    
                    of Hidden:
                        let vnode = buildHtml(td())
                        vnode.setAttr("value", $val)
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

proc default_table*(objs: seq[object]): VNode =
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

proc table*(objs: seq[object], columns: seq[Column]): VNode =

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