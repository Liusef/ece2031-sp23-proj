import wave
import struct
import math
import csv
import os
from typing import List

rootpath: str = 'C:/users/josep/Stuff/CS/gatech-sp23/ece2031/ece2031-sp23-proj/py/'

def read_wave(fname: str) -> List[int]:
    wav: wave.Wave_read
    with wave.open(f'{rootpath}audio/{fname}', 'r') as wav:
        nf: int = wav.getnframes()
        data: List[int] = []
        for i in range(nf):
            buf = wav.readframes(1)
            vals = struct.unpack("<2h", buf)
            data.append((vals[0] + vals[1]) // 2)

    return data

def mov_avg(fname: str) -> bool:
    stream = read_wave(f"{fname}.wav")

    # fn consts
    amp_thresh: int = 0x400
    dur_thresh: int = 0xE00
    alen: int = 8

    # derived
    alen_lb2: int = int(math.log2(alen))
    
    #vars
    mov: List[int] = [0] * alen
    amp_on: bool = False  # weird name, basically just if the moving avg is above thresh
    dur_count: int = 0

    mavg_stream = []

    clap_detected: bool = False

    for b in stream:
        # mavg calc
        b = abs(b)
        mov.insert(0, b)
        mov.pop(alen)
        mavg: int = sum(mov) >> alen_lb2
        mavg_stream.append(mavg)

        if (mavg > amp_thresh):
            amp_on = True
            dur_count += 1

        if (amp_on and mavg < amp_thresh):
            if dur_count < dur_thresh: clap_detected = True
            amp_on = False 
            dur_count = 0

    nfname = f'{rootpath}csv/{fname}.csv'
    mode = 'w' if os.path.isfile(nfname) else 'x'
    with open(nfname, mode, newline='') as f:
        w = csv.writer(f)
        w.writerow(['Raw', 'Moving Average', 'Thresh'])
        for i in range(min(len(stream), len(mavg_stream))):
            w.writerow([stream[i], mavg_stream[i], amp_thresh])

    return clap_detected

def writeToFile(fname, stream, pstream, arr):
    nfname = f'{rootpath}csv/{fname}.csv'
    mode = 'w' if os.path.isfile(nfname) else 'x'
    with open(nfname, mode, newline='') as f:
        w = csv.writer(f)
        w.writerow(['Raw', 'Moving Average', 'count'])
        for i in range(min(len(stream), len(pstream))):
            w.writerow([stream[i], pstream[i], arr[i]])

def writeToFile(fname, stream, pstream, arr):
    nfname = f'{rootpath}csv/{fname}.csv'
    mode = 'w' if os.path.isfile(nfname) else 'x'
    with open(nfname, mode, newline='') as f:
        w = csv.writer(f)
        w.writerow(['Raw', 'Moving Average', 'count'])
        for i in range(min(len(stream), len(pstream))):
            w.writerow([stream[i], pstream[i], arr[i]])


def oscillationFilter(fname: str):
    
    #Read Audio File
    stream = read_wave(f"{fname}.wav")

    #Constants
    threshold = 0x4ff
    aboveTime = 0x3a00
    delayTime = 0x100

    #States 
    state = "idle"
    states = ["idle", "high", "buffer", "end"]

    #variables
    count = 0
    aboveTimer = 0
    delayTimer = 0

    #data
    currentState = []
    countArr = []

    for b in stream:
        
        countArr.append(count * 10000)
        currentState.append(states.index(state) * 15000)

        if state == "idle":
            aboveTimer = 0
            delayTimer = 0
            if b > threshold:
                state = "high"

        elif state == "high":
            aboveTimer += 1
            delayTimer = 0
            if b < threshold:
                state = "buffer"
                
        elif state == "buffer":
            delayTimer += 1
            aboveTimer += 1

            if b > threshold:
                state = "high"

            elif delayTimer > delayTime:
                state = "end"
            
        elif state == "end":
            if aboveTimer < aboveTime:
                count += 1

            state = "idle"

    writeToFile(fname, stream, currentState, countArr)
    return count

# Defining main function
def main() -> None:
    # print(f"Clap: {mov_avg('clap')}")
    # print(f"Snap: {mov_avg('snap')}")
    # print(f"Ahhh: {mov_avg('ah')}")
    # print(f"Richard: {mov_avg('richard')}")

    print(f"Clap:    {oscillationFilter('clap')}")
    print(f"Snap:    {oscillationFilter('snap')}")
    print(f"Ahhh:    {oscillationFilter('ah')}")
    print(f"Richard: {oscillationFilter('richard')}")
    # print(f"Comp:    {oscillationFilter('comprehensive')}")


if __name__=="__main__":
    main()