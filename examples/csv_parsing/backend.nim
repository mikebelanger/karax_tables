import csvtools, strutils, jester, json
import app_types

routes:

    get "/all_foods.json":

        var da_foods: seq[Food]

        for food in csv[FoodInput]("./csv/generic-food.csv", skip_header = true):
            da_foods.add(Food(
                    name: food.FOOD_NAME,
                    scientific_name: food.SCIENTIFIC_NAME,
                    food_group: parseEnum[FoodGroup](food.GROUP),
                )
            )

        resp %*da_foods