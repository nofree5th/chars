A game named Chars.

Written in assembly language (AT&T stynax).

Calling convention(fastcall liked): All registers can be used freely, and paramenters are passed through registers.

The environment relies on the Linux 32 bit protected mode, do not rely on libc.

How to play? Just make it.

Routine:

    Init
    GameLoop
        Render
        OnGameFrame
            ProcessUserInput
        OnLevelTimer
    Fini
