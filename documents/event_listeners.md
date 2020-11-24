## Event Listeners

karax_tables allows event listeners for rows, column headers or an entire table.  This is done by defining procs that are named one of the event listeners (listed below), and whose' first parameter is either the object that represents a row (for a row listener) or a Column (for a column header), or a sequence of the row object (for the entire table).  The second parameter is always an `Event` object.Details listed below

### Row Event Listeners

Suppose you're rows are derived from a `User` object, and you want an event process to grab the updated `User` object whenever it changes.  That could be defined as so:

```nimrod
proc onchange(u: User, e: Event) =
    echo u # should print updated user to console
    echo e.currentTarget.querySelector("extra") # prints dom stuff of row WARNING: may not find anything.

    # you have access to the global scope here, so you can modify
    # the original users array, make new ones, etc. 
```

That one will listen to an individual row, and print out the updated row (a user) to the console.

#### Column Header Event Listeners

If you'd like some functionality added to clicking on a header (think double-clicking one to sort), then a proc can be named as an event (listed below) that takes in `Column` and `Event`

#### Supported Event Listeners

If you write a function whose:
* first param is whatever object you use a row
* second param is an Event object
* name is named after Karax' [available EventKinds](https://github.com/pragmagic/karax/blob/40daae64e339da00b81ddd5972b16de9f8ef35aa/karax/vdom.nim#L53)
```nimrod
    onclick, ## An element is clicked.
    oncontextmenu, ## An element is right-clicked.
    ondblclick, ## An element is double clicked.
    onkeyup, ## A key was released.
    onkeydown, ## A key is pressed.
    onkeypressed, # A key was pressed.
    onfocus, ## An element got the focus.
    onblur, ## An element lost the focus.
    onchange, ## The selected value of an element was changed.
    onscroll, ## The user scrolled within an element.

    onmousedown, ## A pointing device button (usually a mouse) is pressed
                 ## on an element.
    onmouseenter, ## A pointing device is moved onto the element that
                  ## has the listener attached.
    onmouseleave, ## A pointing device is moved off the element that
                  ## has the listener attached.
    onmousemove, ## A pointing device is moved over an element.
    onmouseout, ## A pointing device is moved off the element that
                ## has the listener attached or off one of its children.
    onmouseover, ## A pointing device is moved onto the element that has
                 ## the listener attached or onto one of its children.
    onmouseup, ## A pointing device button is released over an element.

    ondrag,  ## An element or text selection is being dragged (every 350ms).
    ondragend, ## A drag operation is being ended (by releasing a mouse button
               ## or hitting the escape key).
    ondragenter, ## A dragged element or text selection enters a valid drop target.
    ondragleave, ## A dragged element or text selection leaves a valid drop target.
    ondragover, ## An element or text selection is being dragged over a valid
                ## drop target (every 350ms).
    ondragstart, ## The user starts dragging an element or text selection.
    ondrop, ## An element is dropped on a valid drop target.

    onsubmit, ## A form is submitted
    oninput, ## An input value changes

    onanimationstart,
    onanimationend,
    onanimationiteration,

    onkeyupenter, ## vdom extension: an input field received the ENTER key press
    onkeyuplater,  ## vdom extension: a key was pressed and some time
                  ## passed (useful for on-the-fly text completions)
    onload, # img

    ontransitioncancel,
    ontransitionend,
    ontransitionrun,
    ontransitionstart
```

Then you got yourself an event listener!  Here's an example:

If you'd like to listen to the whole table, basically just change the first parameter from `User` to `seq[User]`:

```nimrod
proc onchange(usrs: seq[User], e: Event) =
    echo usrs # should print each user to the console.
    echo e.currentTarget.querySelector("extra") # prints dom stuff of row.  WARNING: may not find anything.

    # you have access to the global scope here, so you can modify
    # the original users array, make new ones, etc. 
```