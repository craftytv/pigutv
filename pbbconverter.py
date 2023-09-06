# Python code to convert an image to ASCII image.
import math
from math import sqrt

from PIL import Image

import numpy as np
import cv2

import json
import os
import ntpath

bitdepth = 4

def convertImage(filename, size):
    img = Image.open(filename).convert('RGB')
    img = img.convert("P", palette = Image.ADAPTIVE, colors = 2**bitdepth).resize(size, resample=0)

    COLORS = img.getpalette()
    COLORS = [COLORS[n:n+3] for n in range(0, len(COLORS), 3)][:2**bitdepth]

    ##COLORS = ( #in minecraft wool order
    ##    (240, 240, 240), #white
    ##    (242, 178, 51), #orange
    ##    (229, 127, 216), #magenta
    ##    (153, 178, 242), #light blue
    ##    (222, 222, 108), #yellow
    ##    (127, 204, 25), #light green
    ##    (242, 178, 204), #pink
    ##    (76, 76, 76), #gray
    ##    (153, 153, 153), #light gray
    ##    (76, 153, 178), #cyan
    ##    (178, 102, 229), #purple
    ##    (51, 102, 204), #blue
    ##    (127, 102, 76), #brown
    ##    (87, 166, 78), #dark green
    ##    (204, 76, 76), #red
    ##    (17, 17, 17) #black
    ##)

    def closest_color(rgb):
        r, g, b = rgb
        color_diffs = []
        for color in COLORS:
            cr, cg, cb = color
            color_diff = sqrt((r - cr)**2 + (g - cg)**2 + (b - cb)**2)
            color_diffs.append((color_diff, color))
        return min(color_diffs)[1]

    img = Image.open(filename).convert('RGB')
    img = img.resize(size, resample=0) 

    W, H = img.size[0], img.size[1]
    indexlist = []

    indexlist.append(int(W/2**8))
    indexlist.append(int(W%2**8))

    indexlist.append(int(H/2**8))
    indexlist.append(int(H%2**8))

    indexlist.append(bitdepth*2**4 + 2)

    for x in range(0,len(COLORS)):
        indexlist.append(COLORS[x][0])
        indexlist.append(COLORS[x][1])
        indexlist.append(COLORS[x][2])

    print(len(indexlist))
    print(8/bitdepth)

    for y in range(0, H):
        for x in range(0, W, int(8/bitdepth)):
            gindex = 0
            for z in range(0,int(8/bitdepth)):
                if (x+z-1>=W):
                    rgb = (0,0,0)
                else:
                    rgb = img.getpixel((x+z-1, y))
                    
                gindex += COLORS.index(closest_color(rgb))*2**(bitdepth*(8/bitdepth-z-1))

            indexlist.append(int(gindex))

    print(W, H)
    f = open("out/"+os.path.splitext(ntpath.basename(filename))[0]+".pbb", "wb")
    f.write(bytes(indexlist))
    f.close()
    #print([bin(byte) for byte in bytes(indexlist)])
    print("Converted " + os.path.splitext(ntpath.basename(filename))[0])

# list to store files
res = []

dir_path = "in/"
for file_path in os.listdir(dir_path):
    if os.path.isfile(os.path.join(dir_path, file_path)):
        print(file_path)
        convertImage(os.path.join(dir_path, file_path), (60, 60))

