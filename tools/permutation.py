#!/usr/bin/env python3

def permutate(data):
  out = { }

  for i in range(0, 32):
    out[i] = -1

  bit = 31

  for d in data:
    if len(d) > 1 and d[1] == -1:
      bit -= d[0]
      continue

    if len(d) == 1:
      out[d[0]] = bit
      bit -= 1
      continue

    i = d[0]
    while i >= d[1]:
      out[i] = bit
      i -= 1
      bit -= 1

  print(len(out))

  c = -2
  count = 0
  ranges = [ ]
  seq = -1

  for i in range(31, -1, -1):
    value = out[i]
    print(str(value) + " ", end="")

    if value == -1 and c == -1:
      count += 1
      continue

    if c == -1:
      ranges.append(str(count) + "'b" + ("0" * count))
      count = 0
      c = -2

    while True:
      if (c == -2):
        c = value
        seq = value
        break
      else:
        if value != seq - 1:
          if c == seq:
            ranges.append("[" + str(c) + "]")
          else:
            ranges.append("[" + str(c) + ":" + str(seq) + "]")
          c = -2
          continue

        seq -= 1
        break

  if c != -2: 
    if c == -1:
      ranges.append(str(count) + "'b" + ("0" * count))
    else:
      ranges.append("[" + str(c) + ":" + str(seq) + "]")
 
  print()

  print(ranges)

print("jal")
permutate([ [20], [10,1], [11], [19,12], [12,-1] ])

print("jalr")
permutate([ [11,0], [20,-1] ])

print("branch")
permutate([ [12], [10,5], [13,-1], [4,1], [11], [7,-1] ])

