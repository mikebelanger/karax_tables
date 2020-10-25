import karax / [karaxdsl, vdom]
import sequtils

type
    CelKind* = enum
        Text
        Dropdown
        TextArea
        Number

    Column* = object
        name: string
        data_type: CelKind
        width: int

proc to_string*(vnode: VNode): string =
    $vnode

proc column_headers*(obj: object): seq[Column] =
    for key, value in obj.fieldPairs:
        var col = Column(name: $key, width: 100)

        when value.typeof is int or value.typeof is float:
            col.data_type = Number
        
        when value.typeof is enum:
            col.data_type = Dropdown
        
        result.add(col)

proc row(obj: object): VNode =
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

proc table*(objs: seq[object]): VNode =
    if objs.len > 0:
        let columns = objs[0].column_headers

        result = buildHtml():
            tdiv:
                table:
                    thead:
                        for col in columns:
                            thead:
                                text col.name
                    tbody:
                        for ob in objs:
                            ob.row