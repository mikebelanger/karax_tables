import ../../src/karax_tables
import karax / [karaxdsl, vdom, vstyles, kajax]
import app_types, sugar, json

when defined(js):
    include karax/prelude
    import karax/[kdom]

    var 
        foods: seq[Food]
        filtered_foods: seq[Food]
        search_filter = ""

    proc search_foods() =
        search_filter = $(document.querySelector("#search").value)
        filtered_foods = foods.search(search_filter)

    proc load_food() =
        ajaxGet("/all_foods.json", headers = @[], proc(httpStatus: int, result: cstring) =
            for json_food in ($result).parseJson:
                foods.add(
                    json_food.to(Food)
                )
        )

    proc render(): VNode =
        result = 
            buildHtml():
                tdiv:
                    input(`type` = "text", id = "search", onkeyup = () => search_foods(), placeholder = "search table")

                    # if search box is empty - show all rows
                    if search_filter == "":
                        foods.karax_table(all_columns = ReadAndWrite)

                    # otherwise, show filtered results
                    else:
                        filtered_foods.karax_table(all_columns = ReadAndWrite)

                    button(onclick = () => load_food()):
                        text "Load food"

    setRenderer render