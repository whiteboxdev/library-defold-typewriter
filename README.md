# Defold Typewriter

Defold Typewriter provides text scrolling and styling in a Defold game engine project.

Visit my [Giphy](https://giphy.com/gifs/defold-0KrcP9rAA5DOlsgf1J) to see an animated gif of this extension working in a larger project.

Please click the "Star" button on GitHub if you find this asset to be useful!

![alt text](https://github.com/klaytonkowalski/library-defold-typewriter/blob/main/assets/thumbnail.png?raw=true)

## Installation

To install dtypewriter into your project, add one of the following links to your `game.project` dependencies:
  - https://github.com/klaytonkowalski/library-defold-typewriter/archive/main.zip
  - URL of a [specific release](https://github.com/klaytonkowalski/library-defold-typewriter/releases)

## Configuration

Import the dtypewriter module into your gui script like so:

```
local dtypewriter = require "dtypewriter.dtypewriter"
```

Initialize dtypewriter with `dtypewriter.init()`. This function requires several metrics to properly align text content inside a textbox. The following image outlines what each parameter refers to:

![alt text](https://github.com/klaytonkowalski/library-defold-typewriter/blob/main/assets/metrics.png?raw=true)

The more interesting parameters are outlined here:

1. `container_node_id`: Each character in a textbox is created as an individual gui node. These nodes are adopted by a parent container node, which defines the origin position of each character.
2. `text_area_x`: X offset of text content.
3. `text_area_y`: Y offset of text content.
4. `text_area_width`: Total width of text content, which dictates the point of line wrap.
5. `line_count_max`: Number of lines to display in a textbox before beginning a new paragraph.
6. `line_offset`: Number of spacing pixels between each line.

Text input must be parsed and loaded with `dtypewriter.load()` before being displayed with `dtypewriter.start()`. Text input should be formatted similarly to HTML elements. The following describes all element names and supported values:

| Name      | Description                                            | Values                                | Examples                                           |
|-----------|--------------------------------------------------------|---------------------------------------|----------------------------------------------------|
| line      | Wrap to next line.                                     | N/A                                   | \<line>                                            |
| paragraph | Stop typing and wait, then move onto next paragraph.   | N/A                                   | \<paragraph>                                       |
| color     | Set color of next characters.                          | "default", string                     | \<color=default>, \<color=green>                   |
| speed     | Set speed of next characters in characters per second. | "default", "instant", positive number | \<speed=default>, \<speed=instant>, \<speed=30>    |

The [example gif](https://giphy.com/gifs/defold-0KrcP9rAA5DOlsgf1J) was created by passing the following string into `dtypewriter.load()`:

```
"Just like the classic RPG dialog systems, <color=green>dtypewriter<color=default> is a fantastic dialog solution!<paragraph>It can do all kinds of neat things, like <color=green>colors<color=default>, <speed=3>speeds<speed=default>, and <speed=instant>instant text display<speed=default>, among other things!"
```

Instead of changing the alpha of each character from 0 to 255 instantly, a smoother and more gradual fade can be enabled with `dtypewriter.set_fade_delay()`. The default fade value is 0.

When a new paragraph is needed to continue displaying characters within the predefined textbox, characters will stop being typed and dtypewriter will wait until `dtypewriter.continue()` is called.

The programmer will receive a message in their `on_message()` function on significant state changes, such as waiting for a new paragraph or typing a character. See the [API: Properties](https://github.com/klaytonkowalski/library-defold-typewriter#dtypewritermessages) section for more information.

Once the loaded text is done being typed, the programmer should call `dtypewriter.clear()` to clear internal tracking variables and free dynamically allocated resources.

## API: Properties

### dtypewriter.messages

Table of messages that are passed to the `on_message()` function of your gui script.

```
dtypewriter.messages =
{
    start = hash("start"),
    restart = hash("restart"),
    type = hash("type"),
    wait = hash("wait"),
    continue = hash("continue"),
    complete = hash("complete"),
    clear = hash("clear")
}
```

1. `start`: Loaded text is starting to be typed.
2. `restart`: Typing is restarted from the beginning.
3. `type`: An individual character is typed.
4. `wait`: No more characters can be typed within the boundaries of the textbox and a new paragraph must be started.
5. `continue`: A new paragraph is started.
6. `complete`: Loaded text is done being typed.
7. `clear`: Text is unloaded and resources are freed.

## API: Functions

### dtypewriter.init(container_node_id, font_id, text_area_x, text_area_y, text_area_width, line_count_max, line_offset, messages_url)

Initialize dtypewriter. If dtypewriter was already initialized, call `dtypewriter.clear()` before reinitializing.

#### Parameters

1. `container_node_id`: Container node that defines the origin position of each character node.
2. `font_id`: Hashed id of the font to use.
3. `text_area_x`: X offset of text content.
4. `text_area_y`: Y offset of text content.
5. `text_area_width`: Total width of text content.
6. `line_count_max`: Number of lines before starting a new paragraph.
7. `line_offset`: Number of spacing pixels between lines.
8. `message_url`: URL to where [dtypewriter messages](https://github.com/klaytonkowalski/library-defold-typewriter#dtypewritermessages) are sent.

### dtypewriter.clear()

Clear internal tracking variables and free dynamically allocated resources. This function should be called when text is no longer desired on screen, likely after `dtypewriter.messages.complete` is received in the `on_message()` function.

### dtypewriter.load(text)

Load raw text to be parsed into formatted gui text nodes. Calls `dtypewriter.clear()` before performing any other tasks.

#### Parameters

1. `text`: Raw text. See the [Configuration](https://github.com/klaytonkowalski/library-defold-typewriter#configuration) section for information on how to insert styling elements.

### dtypewriter.start()

Start typing characters after loading text with `dtypewriter.load()`.

### dtypewriter.restart()

Restart typing characters after calling `dtypewriter.start()`.

### dtypewriter.continue()

Continue onto the next paragraph after the end of a paragraph has been reached.

### dtypewriter.skip()

Skip to the end of the current paragraph if characters are being typed.

### dtypewriter.add_color(name, color)

Add a custom color in the `<color=[color]>` element. If the color name already exists, it is overwriten.

#### Parameters

1. `name`: Name of the color.
2. `color`: The color itself `vector4`.

### dtypewriter.set_default_color(color)

Set a default color or in the `<color=default>` element.

#### Parameters

1. `color`: The color itself `vector4`.

### dtypewriter.clear_colors()

Clear all custom colors, excluding the default color.

### dtypewriter.set_fade_delay(delay)

Set the amount of time it takes for the alpha of an individual character to change from 0 to 255 when it is typed. The default value is 0.

#### Parameters

1. `delay`: Amount of seconds for a character to become completely opaque.

### dtypewriter.set_default_type_speed(speed)

Set the default type speed in characters per second in the `<speed=default>` element.

#### Parameters

1. `speed`: Type speed in characters per second.

### dtypewriter.is_clear()

Check if no text is loaded.

#### Returns

Returns `bool`.

### dtypewriter.is_loaded()

Check if text is loaded with `dtypewriter.load()`.

#### Returns

Returns `bool`.

### dtypewriter.is_typing()

Check if dtypewriter is actively typing.

#### Returns

Returns `bool`.

### dtypewriter.is_waiting()

Check if the end of a paragraph has been reached and dtypewriter is waiting to move onto the next paragraph with `dtypewriter.continue()`.

#### Returns

Returns `bool`.

### dtypewriter.is_complete()

Check if dtypewriter is done typing the loaded text, but has not yet been cleared with `dtypewriter.clear()`.

#### Returns

Returns `bool`.
