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
            else:
                error: WeatherPointError

var points: seq[RoadWeatherPoint]
var columns: seq[Column]

points.add(RoadWeatherPoint(
    path_order: 1,
    longitude: -45.000,
    latitude: -75.3443,
    unix_time: 1603821902.00,
    integrity: Valid
))

points.add(RoadWeatherPoint(
    path_order: 2,
    longitude: -45.001,
    latitude: -75.3442,
    unix_time: 1603821903.00,
    integrity: Valid
))

points.add(RoadWeatherPoint(
    path_order: 3,
    integrity: Incomplete
))

columns.add(Column(
    name: "path_order",
    cel_kind: Number,
    cel_affordance: ReadOnly,
    title: "Point number"
))

when defined(js):
    include karax/prelude
    import karax / [karaxdsl, vdom]

    proc render(): VNode = 
        result = buildHtml():
            try:
                points.table(columns = columns)
            except InconsistentRows:
                echo "successfully found object variant and halted"
                tdiv:
                    p:
                        text "Inconsistent rows.  Please examine your objects and try again."
                
    setRenderer render
else:
    try:
        writeFile("stuff3.html", points.table(columns = columns).to_string)
    except InconsistentRows:
        echo "successfully found object variant and halted"