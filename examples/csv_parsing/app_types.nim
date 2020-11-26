type
    FoodGroup* = enum
        Unclassified = "Unclassified"
        HerbsAndSpices = "Herbs and Spices"
        Vegetables = "Vegetables"
        Fruits = "Fruits"
        Nuts = "Nuts"
        CerealsAndCerealProducts = "Cereals and cereal products"
        Pulses = "Pulses"
        Teas = "Teas"
        Gourds = "Gourds"
        CoffeeAndCoffeeProducts = "Coffee and coffee products"
        Soy = "Soy"
        CocoaAndCocoaProducts = "Cocoa and cocoa products"
        Beverages = "Beverages"
        AquaticFoods = "Aquatic foods"
        AnimalFoods = "Animal foods"
        MilkAndMilkProducts = "Milk and milk products"
        Eggs = "Eggs"
        Confectionaries = "Confectioneries"
        BakingGoods = "Baking goods"
        Dishes = "Dishes"
        SnackFoods = "Snack foods"
        BabyFoods = "Baby foods"
        FatsAndOils = "Fats and oils"
        # HerbsAndspices = "Herbs and spices"

    FoodInput* = object
        FOOD_NAME*, SCIENTIFIC_NAME*, GROUP*, SUB_GROUP*: string

    Food* = object
        name*, scientific_name*: string
        food_group*: FoodGroup
