import asyncio, os, argparse, datetime
from collections import deque
from pathlib import Path
from PIL import Image
os.system("")

parser = argparse.ArgumentParser(description="Process Icons")
parser.add_argument("--processes", type=int, action="store",
                    help="number of processes to use", default=10)
parser.add_argument("--dont-skip", action="store_false",
                    default=True,
                    help="don't skip files even if they exist")
parser.add_argument("--quality", action="store", type=float,
                    default=0.3,
                    help="quality of exported image 1-100")
args = parser.parse_args()

if not os.path.exists("./icons/"):
    os.mkdir("./icons/")
if not os.path.exists("./export/"):
    os.mkdir("./export/")

processes = args.__dict__["processes"]
skipExisting = args.__dict__["dont_skip"]
quality = args.__dict__["quality"]

async def main():
    global processes, skipExisting, quality
    loop = asyncio.get_running_loop()
    files = tuple(filter(lambda x: x.startswith("file_type_"), os.listdir("./vscode-icons/icons/")))
    command = "inkscape/bin/inkscape.com"
    lock = asyncio.Lock()
    processed = 0
    requiredFiles = len(files)
    print(f"Queueing {requiredFiles} icons")
    print(f"Using {processes} instances to execute task")
    print(f"Exporting as PNG")

    async def process(f, to):
        nonlocal processed
        global skipExisting
        for file in files[f:to]:
            if skipExisting:
                if await loop.run_in_executor(None, os.path.isfile, Path("./export/", file).with_suffix(".png")):
                    async with lock:
                        processed += 1
                    continue
            await (await asyncio.create_subprocess_exec(
                command,
                Path("./vscode-icons/icons/", file),
                "-o", Path("./export/", file).with_suffix(".png"),
                "-w", "1024",
                "-h", "1024",
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.STDOUT
            )).wait()
            async with lock:
                processed += 1

    intervals = requiredFiles // processes
    remaining = requiredFiles % processes

    offset = 0
    for count in range(processes - 1):
        asyncio.create_task(process(offset, offset+intervals))
        offset += intervals
    asyncio.create_task(process(offset, offset+intervals+remaining))

    processingAmt = deque([1 for x in range(10)], maxlen=10)
    lastProcessedAmt = 0
    while True:
        if processed >= requiredFiles:
            break
        if lastProcessedAmt == 0:
            lastProcessedAmt = processed
        size = os.get_terminal_size().columns
        text = f"Processed {processed} out of {requiredFiles}: "
        percentage = f" {(processed/requiredFiles) * 100:.2f}%"
        processingSpeed = f" {sum(processingAmt)/10}/s"
        
        timeTaken = sum(processingAmt)
        if timeTaken != 0:
            timeTaken = datetime.timedelta(seconds=(requiredFiles-processed) // (timeTaken/10))
        else:
            timeTaken = "suspended"
        eta = f" ETA: {timeTaken}"

        bar = size - (len(text)+2) - 1 - len(percentage) - len(processingSpeed) - len(eta)
        progress = int((processed / requiredFiles) * bar)
        shown = ("=" * (progress - 1)) + ">"
        empty = " " * (bar - len(shown))
        print(f"{text}[{shown}{empty}]{processingSpeed}{eta}{percentage}\x1B[0G", end="", flush=True)
        processingAmt.append(processed - lastProcessedAmt)
        lastProcessedAmt = processed
        await asyncio.sleep(1)

    processed = 0
    class Proto:
        def __init__(self, *args, **kwargs) -> None:
            self.args = args
            self.kwargs = kwargs

        async def __aenter__(self):
            self.file = await loop.run_in_executor(None, lambda: Image.open(*self.args, **self.kwargs))
            return self.file

        async def __aexit__(self, ty, val, tb):
            await loop.run_in_executor(None, self.file.close)
            if val:
                raise val

    async def reduce(f, to, quality):
        nonlocal processed
        for file in files[f:to]:
            ps = Path("./icons/", file).with_suffix(".webp")
            if skipExisting:
                if await loop.run_in_executor(None, os.path.isfile, ps):
                    async with lock:
                        processed += 1
                    continue
            p = Path("./export/", file).with_suffix(".png")
            async with Proto(p) as f:
                await loop.run_in_executor(None, lambda: f.save(ps, "WEBP", optimize=True, quality=quality))

                await loop.run_in_executor(None, f.close)
                async with lock:
                    processed += 1

    print("\nConverting to WEBP ...")

    offset = 0
    for count in range(processes - 1):
        asyncio.create_task(reduce(offset, offset+intervals, quality))
        offset += intervals
    asyncio.create_task(reduce(offset, offset+intervals+remaining, quality))

    processingAmt = deque([1 for x in range(10)], maxlen=10)
    lastProcessedAmt = 0
    while True:
        if processed >= requiredFiles:
            break
        if lastProcessedAmt == 0:
            lastProcessedAmt = processed
        size = os.get_terminal_size().columns
        text = f"Processed {processed} out of {requiredFiles}: "
        percentage = f" {(processed/requiredFiles) * 100:.2f}%"
        processingSpeed = f" {sum(processingAmt)/10}/s"
        
        timeTaken = sum(processingAmt)
        if timeTaken != 0:
            timeTaken = datetime.timedelta(seconds=(requiredFiles-processed) // (timeTaken/10))
        else:
            timeTaken = "suspended"
        eta = f" ETA: {timeTaken}"

        bar = size - (len(text)+2) - 1 - len(percentage) - len(processingSpeed) - len(eta)
        progress = int((processed / requiredFiles) * bar)
        shown = ("=" * (progress - 1)) + ">"
        empty = " " * (bar - len(shown))
        print(f"{text}[{shown}{empty}]{processingSpeed}{eta}{percentage}\x1B[0G", end="", flush=True)
        processingAmt.append(processed - lastProcessedAmt)
        lastProcessedAmt = processed
        await asyncio.sleep(1)

asyncio.run(main())