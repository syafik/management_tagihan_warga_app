# frozen_string_literal: true

# Pagy initializer file

# Instance variables
# See https://ddnexus.github.io/pagy/how-to#global-variables
# All the Pagy::DEFAULT are set for all the Pagy instances but can be overridden by the single instance by just passing them to Pagy.new or the helpers

# Collection: how many items per page
Pagy::DEFAULT[:items] = 20

# Controls: how many page links to show  
# In Pagy 9+, the :size format has changed
Pagy::DEFAULT[:size] = 7

# Features: List of extra features to enable
# See https://ddnexus.github.io/pagy/extras#features
require 'pagy/extras/overflow'

# Overflow extra: Allow for easy handling of overflowing pages
# See https://ddnexus.github.io/pagy/extras/overflow
Pagy::DEFAULT[:overflow] = :last_page