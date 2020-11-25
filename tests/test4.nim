import karax_tables

### using custom table with varients
type
    DataQuality* = enum
        Corrupt
        Incomplete
        Valid

    WeatherPointError* = enum
        ImproperDateTime
        UnusualCoordinates
        MissingSensorData

    RoadWeatherPoint = object
        path_order: int
        case integrity: DataQuality            
            of Valid:
                longitude, latitude, unix_time: float
                raining: bool
            else:
                error: WeatherPointError

var points: seq[RoadWeatherPoint]
var columns: seq[ColumnHeader]

points.add(RoadWeatherPoint(
    path_order: 1,
    longitude: -45.000,
    latitude: -75.3443,
    unix_time: 1603821902.00,
    raining: true,
    integrity: Valid
))

points.add(RoadWeatherPoint(
    path_order: 2,
    longitude: -45.001,
    latitude: -75.3442,
    raining: true,
    unix_time: 1603821903.00,
    integrity: Valid
))

points.add(RoadWeatherPoint(
    path_order: 3,
    integrity: Incomplete
))

columns.add(ColumnHeader(
    name: "path_order",
    cel_kind: TextArea,
    cel_affordance: ReadOnly,
    title: "Point number"
))

columns.add(ColumnHeader(
    name: "unix_time",
    title: "Time"
))

when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        try:
            result = buildHtml():
                points.karax_table(columns = columns)
        except InvalidColumnHeader:
            result = buildHtml():
                tdiv:
                    p:
                        text "succesfully caught invalid column"

                
    setRenderer render
else:
    try:
        writeFile("./tests/stuff4.html", points.karax_table(columns = columns).to_string)
    except InvalidColumnHeader:
        echo "succesfully caught invalid column"