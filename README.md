# Telescope Words

Fuzzy find words and synonyms using Telescope.

## What is Telescope Words?

`telescope-words.nvim` is an extension for `telescope.nvim` that enables fast offline fuzzy-finding of words, and synonyms.

It uses Princeton University's [WordNet](https://wordnet.princeton.edu/) lexical database to provide definitions and lexical relations.

[video](https://github.com/user-attachments/assets/eedcfd7f-c8bc-471a-834a-456d6ef995cc)

## Getting Started

### Dependencies

- [Neovim](https://github.com/neovim/neovim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

### Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
{
  'nvim-telescope/telescope.nvim',
  dependencies = { 'archie-judd/telescope-words.nvim' },
},
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
use {
  'archie-judd/telescope-words.nvim',
  requires = { 'nvim-telescope/telescope.nvim' }
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
					-- Normal mode.
					n = {
						["<CR>"] = word_actions.replace_word_under_cursor,
					},
					-- Insert mode.
					i = {
						["<CR>"] = word_actions.replace_word_under_cursor,
					},
				},
				-- Default pointers define the lexical relations listed under each definition,
				-- see Pointer Symbols below. Default is as below ("antonyms", "similat to" and
				-- "also see").
				pointer_symbols = { "!", "&", "^" },
				-- Number of characters required before results are returned To avoid returning
				-- the whole dictionary there is a lower limit of 2. Default is three.
				char_search_threshold = 3,
				-- Choose the layout strategy.
				layout_strategy = "horizontal",
				-- And your layout config.
				layout_config = { height = 0.75, width = 0.75, preview_width = 0.65 },
			},
		},
	},
})

```

### Actions

One custom action is provided: `replace_word_under_cursor`. You can use it as above.

When invoked it will replace the word under the cursor with the selected entry. Default selection behaviour is to insert the word at the cursor.

### Pointer symbols

A WordNet definition looks like this:

<img width="1512" alt="Screenshot 2024-11-15 at 02 17 21" src="https://github.com/user-attachments/assets/8f1d555d-39a4-4b91-aa1d-be9ebdc07b53">

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

## Related projects

- [telescope-thesaurus](https://github.com/rafi/telescope-thesaurus.nvim)
- [thesaurus_query.vim](https://github.com/Ron89/thesaurus_query.vim)
