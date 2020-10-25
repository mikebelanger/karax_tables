import karax / [karaxdsl, vdom]

type
    CelKind* = enum
        String
        Dropdown
        TextArea
        Number

    Column* = object
        name: string
        data_type: CelKind
        width: int

proc column_headers*(obj: object): seq[Column] =
    for key, value in obj.fieldPairs:
        var col = Column(name: $key, width: 100)

        when value.typeof is int or value.typeof is float:
            col.data_type = Number
        
        when value.typeof is enum:
            col.data_type = Dropdown
        
        result.add(col)

proc get_row(obj: object): VNode =
    result = buildHtml(tr())

    for key, val in obj.fieldPairs:
        
        result.add(buildHtml(td(text($val))))


when defined(js):
    include karax/prelude

    proc optionsMenu*(name, message: cstring, selected = "", options: seq[string]): VNode =

        result = buildHtml():
            tdiv:
                label(`for` = name, id = name & "_container"):
                    select(id = name):
                        if message.len > 0:
                            option(value = ""):
                                text message
                        
                        for option in options:
                            if option == selected:
                                option(value = selected, selected = "selected"):
                                    text selected
                            else:
                                option(value = option):
                                    text option

else:

    proc optionsMenu*(name, message: string, selected = "", options: seq[string]): string =

        let vnode = buildHtml():
            tdiv:
                label(`for` = name, id = name & "_container"):
                    select(id = name):
                        if message.len > 0:
                            option(value = ""):
                                text message
                        
                        for option in options:
                            if option == selected:
                                option(value = selected, selected = "selected"):
                                    text selected
                            else:
                                option(value = option):
                                    text option

        return $vnode

    proc to_table*(objs: seq[object]): string =
        if objs.len > 0:
            let columns = objs[0].column_headers

            let vnode = buildHtml():
                tdiv:
                    table:
                        thead:
                            for col in columns:
                                thead:
                                    text col.name
                        tbody:
                            for ob in objs:
                                ob.get_row

            result = $vnode