discard """
  action: "run"
"""

import ../../src/solstice/request
import tables

doAssert "{\"Hello\": \"World\"}".toJson() == newTable[string, string]([("Hello", "World")])