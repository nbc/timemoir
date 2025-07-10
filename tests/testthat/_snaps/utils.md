# convert_memory works

    Code
      convert_memory(0)
    Output
      [1] "0.00 Ko"

---

    Code
      convert_memory(1024)
    Output
      [1] "1.00 Mo"

---

    Code
      convert_memory(1024 * 1024)
    Output
      [1] "1.00 Go"

---

    Code
      convert_memory(1024 * 1024 * 1024)
    Output
      [1] "1.00 To"

