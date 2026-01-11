# Load all core extensions for Price
#
# These are opt-in. To use them:
#
#   require "superfeature/core_ext"
#
#   10.to_price           # => Price(10)
#   "49.99".to_price      # => Price(49.99)
#
require "superfeature/core_ext/numeric"
require "superfeature/core_ext/string"
