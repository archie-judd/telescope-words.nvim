# Telescope Words

Fuzzy find words and synonyms using Telescope.

## What is Telescope Words?

`telescope-words.nvim` is an extension for `telescope.nvim` that enables fast offline fuzzy-finding of words, and synonyms.

It uses Princeton University's [WordNet](https://wordnet.princeton.edu/) lexical database to provide definitions and lexical relations.


[video](https://github.com/user-attachments/assets/e6b0c134-ec22-4bcf-b466-68eafb751de7)

## Getting Started

### Dependencies

- [Neovim](https://github.com/neovim/neovim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

### Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'archie-judd/telescope-words.nvim',
  requires = { 'nvim-telescope/telescope.nvim' }
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'nvim-telescope/telescope.nvim',
  dependencies = { 'archie-judd/telescope-words.nvim' }
}
```

## Usage

You can check the extension is installed from the command line:
`:Telescope telescope_words search_dictionary`

And you can set mappings for invoking the dictionary or thesaurus pickers like so:

```lua
local telescope = require("telescope")
vim.keymap.set(
    "n",
    "<Leader>fd",
    telescope.extensions.telescope_words.search_dictionary
    { desc = "Telescope: search dictionary" }
)
vim.keymap.set(
    "n",
    "<Leader>ft",
    telescope.extensions.telescope_words.search_thesaurus
    { desc = "Telescope: search thesaurus" }
)
```

There are four available commands:

| Command                                   | Description                                             |
| ----------------------------------------- | ------------------------------------------------------- |
| `search_dictionary`                       | Returns all fuzzy matches for the word entered          |
| `search_thesaurus`                        | Returns similar words to the word entered in the finder |
| `search_dictionary_for_word_under_cursor` | Returns all fuzzy matches for the word under the cursor |
| `search_thesaurus_for_word_under_cursor`  | Returns similar words to the word under the cursor      |

## Customization

You can customise the extension in telescope's setup function:

```lua
local telescope = require("telescope")
local word_actions = require("telescope_words.actions")

telescope.setup({
    defaults = {
        -- ...
        extensions = {

            -- This configuration only affects this extension.
            telescope_words = {

                -- Define custom mappings. Default mappings are {} (empty).
                mappings = {
                    n = {
                        ["<CR>"] = word_actions.replace_word_under_cursor,
                    },
                    i = {
                        ["<CR>"] = word_actions.replace_word_under_cursor,
                    },

                },

                -- Default pointers define the lexical relations listed under each definition,
                -- see Pointer Symbols below.
                -- Default is as below ("antonyms", "similar to" and "also see").
                pointer_symbols = { "!", "&", "^" },

                -- The number of characters entered before fuzzy searching is used. Raise this
                -- if results are slow. Default is 3.
                fzy_char_threshold = 3,

                -- Choose the layout strategy. Default is as below.
                layout_strategy = "horizontal",

                -- And your layout config. Default is as below.
                layout_config = { height = 0.75, width = 0.75, preview_width = 0.65 },
            },
        },
    },
})

```

### Actions

One custom action is provided: `replace_word_under_cursor`. You can use it as above.

When invoked it will replace the word under the cursor with the selected entry. Default selection behaviour is to insert the word at the cursor.

### Fuzzy matching

Fuzzy matching is used to provide good results in the case of miss-spelt user queries. The character threshold at which fuzzy-searching kicks in can be set using the option `fzy_char_threshold`, as above. For queries with fewer characters than this value, only exact matches are returned.

If either the dictionary or thesaurus search functions are slow, raising the value of `fzy_char_threshold` will improve performance.

### Pointer symbols

A WordNet definition looks like this:

<img width="1131" alt="Screenshot 2025-01-02 at 10 24 06" src="https://github.com/user-attachments/assets/24974be4-caf3-4b44-bda8-2ef08077b063" />


Beneath each definition are _pointers_. A _pointer_ is a lexical relation between words, for example _antonyms_. You can
define which pointers are shown by providing a list of pointer symbols.

See [here](https://wordnet.princeton.edu/documentation/wninput5wn) for more information on pointers. The complete list of pointer symbols is given here:

| Symbol | Meaning                        |
| ------ | ------------------------------ |
| `!`    | Antonym                        |
| `@`    | Hypernym                       |
| `@i`   | Instance Hypernym              |
| `~`    | Hyponym                        |
| `^`    | Also see                       |
| `~i`   | Instance Hyponym               |
| `#m`   | Member holonym                 |
| `#s`   | Substance holonym              |
| `#p`   | Part holonym                   |
| `%m`   | Member meronym                 |
| `%s`   | Substance meronym              |
| `%p`   | Part meronym                   |
| `=`    | Attribute                      |
| `*`    | Entailment                     |
| `$`    | Verb Group                     |
| `+`    | Derivationally related form    |
| `;c`   | Domain of synset - TOPIC       |
| `-c`   | Member of this domain - TOPIC  |
| `;r`   | Domain of synset - REGION      |
| `-r`   | Member of this domain - REGION |
| `;u`   | Domain of synset - USAGE       |
| `-u`   | Member of this domain - USAGE  |
| `>`    | Cause                          |
| `&`    | Similar to                     |
| `<`    | Participle of verb             |
| `\\`   | Derived from adjective         |

## Acknowledgements

This plugin includes the [fzy-lua](https://github.com/swarn/fzy-lua) library by [swarn](https://github.com/swarn), licensed under the MIT License.
The license can be found in `luarocks/LICENSE.fzy`. The library is a Lua port of [fzy](https://github.com/jhawthorn/fzy)'s fuzzy string matching algorithm.

## Related projects

- [telescope-thesaurus](https://github.com/rafi/telescope-thesaurus.nvim)
- [thesaurus_query.vim](https://github.com/Ron89/thesaurus_query.vim)
