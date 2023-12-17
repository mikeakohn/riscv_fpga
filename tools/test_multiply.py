#!/usr/bin/env python3

def show_value(v, f):
  n = 1

  if (v & 0x8000) != 0:
    v = ((v ^ 0xffff) + 1) & 0xffff
    n = -1

  d = v * n;
  print("decimal=%d   fixed=%04x" % (d, f))

def multiply(a, b):
  a = a & 0xffff
  b = b & 0xffff

  s = "%04x * %04x" % (a, b)

  print(" -- " + str(a) + " * " + str(b) + " -- " + s)
  show_value(a, a)
  show_value(b, b)

  v = 0

  for i in range(0, 16):
    if (a & 1) == 1:
      v = v + b

    a = a >> 1
    b = b << 1

  f = (v >> 10) & 0xffff
  v = v & 0xffff

  show_value(v, f)

# -------------------------- fold here ------------------------

multiply(-100, 150)
multiply(150, -100)
multiply(0xf800, 0xf800)
multiply(0xfc00, 0xfc00)

multiply(0xf800 + 0x600, 0xf800 + 0x600)
multiply(0xfc00 + 0x400, 0xfc00 + 0x400)
multiply(0xff00, 0xff00)

print("4 << 10 = %04x" % (4 << 10))

