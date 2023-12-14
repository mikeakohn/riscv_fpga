#!/usr/bin/env python3

def show_value(v):
  n = 1

  if (v & 0x8000) != 0:
    v = ((v ^ 0xffff) + 1) & 0xffff
    n = -1

  print(v * n)

def multiply(a, b)
  a = a & 0xffff
  b = b & 0xffff

  print(" -- " + str(a) + " * " + str(b) " --")
  show_value(a)
  show_value(b)

  v = 0

  for i in range(0, 16):
    if (a & 1) == 1:
      v = v + b

    a = a >> 1
    b = b << 1

  v = v & 0xffff

  show_value(v)

# -------------------------- fold here ------------------------

multiply(-100, 150)
multiply(150, -100)

