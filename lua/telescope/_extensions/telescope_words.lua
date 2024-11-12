local telescope = require("telescope")
local telescope_words = require("telescope-words")
local telescope_words_config = require("telescope-words.config")

return telescope.register_extension({
	setup = telescope_words_config.setup,
	exports = {
		search_dictionary = telescope_words.search_dictionary,
		search_thesaurus = telescope_words.search_thesaurus,
		search_dictionary_for_word_under_cursor = telescope_words.search_dictionary_for_word_under_cursor,
		search_thesaurus_for_word_under_cursor = telescope_words.search_thesaurus_for_word_under_cursor,
	},
})
