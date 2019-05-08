use "itertools"

primitive Flatten
  fun apply(listing: Array[String]): String =>
    "".join(Iter[String](listing.values()))
