import karax_tables

type
    PriceKind* = enum
        Unit
        Pound
        Kilo

    Product* = tuple
        name: string
        sku: int
        price: float
        price_per: PriceKind

var products: seq[Product]
var some_test: seq[tuple[name: string, age: int, hours_overtime_unpaid: float]]

some_test.add(
    (name: "Nim is awesome", age: 2, hours_overtime_unpaid: 4.00)
)

products.add(
    (name: "cabbage", sku: 1231, price: 2.10, price_per: Pound)
)

products.add(
    (name: "hamburger helper", sku: 23412, price: 5.00, price_per: Unit)
)

when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        result = buildHtml():
            products.karax_table

    setRenderer render
else:
    writeFile("stuff3.html", products.karax_table.to_string)