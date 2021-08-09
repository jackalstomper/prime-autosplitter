state("Dolphin", "0-00")
{
    // 0xC4DC70 is the pointer to GC memory in the dolphin process in Dolphin-14344.
    // Likely changes very often between builds.
    // All in-game memory addresses are as they would appear in dolphin memory engine minus 0x80000000
    uint beGameStatePtr: 0xC4DC70, 0x4578CC;
}

init
{
    version = "0-00";
}

startup
{
    vars.byteSwap32 = (Func<uint, uint>)((value) => {
        return ((value & 0x000000ff) << 24) +
            ((value & 0x0000ff00) << 8) +
            ((value & 0x00ff0000) >> 8) +
            ((value & 0xff000000) >> 24);
    });

    vars.byteSwapf64 = (Func<double, double>)((value) => {
        byte[] bytes = BitConverter.GetBytes(value);
        Array.Reverse(bytes);
        return BitConverter.ToDouble(bytes, 0);
    });

    vars.gcMemoryRoot = null;
}

update
{
    // prime IGT is stored in a pointer in the gamestate object. So we need to dereference it.
    // Livesplit can't do this for us automatically because the pointer is big endian.
    // We must read the value as an uint32, byte swap it, add the offset, and read that memory.

    uint leGameStatePtrAddr = vars.byteSwap32(current.beGameStatePtr);
    uint igtPtrAddr = (leGameStatePtrAddr - 0x80000000) + 0xA0;

    if (vars.gcMemoryRoot == null) {
        vars.gcMemoryRoot = (IntPtr)(new DeepPointer("Dolphin.exe", 0xC4DC70).Deref<ulong>(game));
    }

    double beTimer = memory.ReadValue<double>((IntPtr)vars.gcMemoryRoot + (int)igtPtrAddr);

    // Convert big endian double to little endian
    current.time = vars.byteSwapf64(beTimer);
    return true;
}

gameTime
{
    return TimeSpan.FromSeconds(current.time);
}

isLoading
{
    // Always returning true lets the timer be a memory display for primes IGT
    return true;
}