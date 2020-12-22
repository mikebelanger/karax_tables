import karax / [karaxdsl, vdom, vstyles]
import sequtils, strutils, json, sugar
import macros
import random
import typeinfo

proc optionsMenu(name, message, id: cstring, selected = "", options: seq[string], disabled = false): VNode =
    ## generate a drop-down menu.
    ## name plugs into label wrapper around drop-down menu, and select id
    ## message is what you first see selected on the dropdown.
    ## selected is just which of the options is selected (if you don't want a message)
    ## options are just the other options

    result = buildHtml():
        label(`for` = $name, id = $id):
            if disabled:
                select(id = $name, disabled = ""):
                    if message.len > 0:
                        option(value = ""):
                            text $message

                    for index, option in options:
                        if option == selected:
                            option(value = selected, selected = "selected"):
                                text selected
                        else:
                            option(value = option):
                                text option

            else:
                select(id = $name):
                    if message.len > 0:
                        option(value = ""):
                            text $message

                    for index, option in options:
                        if option == selected:
                            option(value = selected, selected = "selected"):
                                text selected
                        else:
                            option(value = option):
                                text option

proc matches*[T](obj: T, search_str: string): bool =
    if search_str == "":
        return true

    else:
        when obj is object:
            for field, val in obj.fieldPairs:
                when val is int:
                    if ($val).contains(search_str.toLowerAscii):
                        return true

                when val is float:
                    if ($val).contains(search_str):
                        return true
                
                when val is string:
                    if ($val.toLowerAscii).contains(search_str.toLowerAscii):
                        return true

                when val is enum:
                    if (($val).toLowerAscii).contains(search_str.toLowerAscii):
                        return true
            
                when val is object:
                    return val.matches(search_str)

            return false

        elif obj is ref:
            for field, val in obj[].fieldPairs:
                when val is int:
                    if ($val).contains(search_str.toLowerAscii):
                        return true

                when val is float:
                    if ($val).contains(search_str):
                        return true
                
                when val is string:
                    if ($val.toLowerAscii).contains(search_str.toLowerAscii):
                        return true

                when val is enum:
                    if (($val).toLowerAscii).contains(search_str.toLowerAscii):
                        return true
            
                when val is object:
                    return val.matches(search_str)

            return false

when defined(js):
    include karax/prelude
    import karax / [kdom]

    proc id_seed(vnode: VNode, seed:int = 20): VNode =
        result = vnode
        result.setAttr("id", $(0..seed).toSeq.sample)
        return result

    proc heading*(headings: varargs[string]): VNode =
        result = buildHtml(thead()).id_seed

        for heading in headings:
            result.add(
                buildHtml(
                    th(
                        text heading
                    )
                ).id_seed
            )

    proc row*(seed: int = 200): VNode =
        result = buildHtml(tr()).id_seed

    proc row*(seed: int = 200, event: EventKind, cb: EventHandler): VNode =
        result = buildHtml(tr())
        result.events.add((event, cb, nil))

    iterator show*[T](all: seq[T], matching = ""): T =
        var 
            i = 0
            length = len(all)
        
        while i < length:
            if all[i].matches(matching):
                yield(all[i])
            
            inc(i)

    ### Read and Write
    proc readandwrite*(elem: bool): VNode =
        result = buildHtml(input(`type` = "checkbox")).id_seed
        
        if elem:
            result.setAttr("checked", "true")

    proc readandwrite*(elem: bool, id: string | int): VNode =
        result = buildHtml(td(input(`type` = "checkbox", id = id)))
        
        if elem:
            result.setAttr("checked", "true")

    proc readandwrite*(elem: string, textarea = false): VNode =
        if textarea:
            buildHtml(td(textarea(type = "text", value = elem)))
        else:
            buildHtml(td(input(type = "text", value = elem)))

    proc readandwrite*(elem: string, textarea = false, id: string | int): VNode =
        if textarea:
            buildHtml(td(textarea(type = "text", value = elem, id = $id)))
        else:
            buildHtml(td(input(type = "text", value = elem, id = $id)))

    proc readandwrite*(elem: int): VNode =
        buildHtml(td(input(type = "number", value = $elem)))

    proc readandwrite*(elem: int, id: string): VNode =
        buildHtml(td(input(type = "number", value = $elem, id = $id)))

    proc readandwrite*(elem: enum): VNode =
        let 
            options = (elem.typeof.low..elem.typeof.high).mapIt($it)

        result = buildHtml(td(optionsMenu(name = $elem.typeof, 
                            message = "", 
                            id = $(0..options.len).toSeq.sample,
                            selected = $elem, 
                            options = options))
        )

    proc readandwrite*(elem: enum, id: string | int): VNode =
        result = readandwrite(elem, id)

    ### Read only
    proc readonly*(elem: bool): VNode =
        result = buildHtml(td(input(`type` = "checkbox", disabled="disabled")))
        
        if elem:
            result.setAttr("checked", "true")

    proc readonly*(elem: bool, id: string | int): VNode =
        result = readandwrite(elem, id)
        result.setAttr("disabled", "disabled")

    proc readonly*(elem: VNode): VNode =
        buildHtml(td(elem))
    
    proc readonly*(elem: string | int | float): VNode =
        buildHtml(td(text(elem)))

    proc readonly*(elem: VNode, id: string | string): VNode =
        buildHtml(td(elem, id = $id))

    proc readonly*[T](elem: string | int | float, id: string | int): VNode =
        buildHtml(td(text(elem), id = $id))

    proc readonly*(elem: enum): VNode =
        let options = (elem.typeof.low..elem.typeof.high).mapIt($it)

        result = buildHtml(td(optionsMenu(name = $elem.typeof, 
                            message = "", 
                            id = $(0..options.len).toSeq.sample,
                            selected = $elem, 
                            options = options,
                            disabled = true))
        )

    proc readonly*(elem: enum, id: string | int): VNode =
        let options = (elem.typeof.low..elem.typeof.high).mapIt($it)

        result = buildHtml(td(optionsMenu(name = $elem.typeof, 
                            message = "", 
                            id = $id,
                            selected = $elem, 
                            options = options,
                            disabled = true))
        )

    proc readonly_row*[T](elems: varargs[T, readonly], id: string): VNode =
        result = buildHtml(tr(id = $id))
        for elem in elems:
            result.add(elem)

    proc readandwrite_row*[T](elems: varargs[T, readandwrite], id: string): VNode =
        result = buildHtml(tr(id = $id))
        for elem in elems:
            result.add(elem)

    ### Hidden
    proc hidden*(hidden: int | string, id: string): VNode =
        result =
            buildHtml(
                input(`type` = "hidden", value = $hidden)
            )
