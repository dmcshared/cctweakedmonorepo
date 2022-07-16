local out = {
    black = 32768,
    red = 16384,
    green = 8192,
    yellow = 4096,
    blue = 2048,
    magenta = 1024,
    cyan = 512,
    white = 256,
    brightBlack = 128,
    brightRed = 64,
    brightGreen = 32,
    brightYellow = 16,
    brightBlue = 8,
    brightMagenta = 4,
    brightCyan = 2,
    brightWhite = 1
}

term.setPaletteColor(out.black, 0x1d1f21)
term.setPaletteColor(out.red, 0xcc6666)
term.setPaletteColor(out.green, 0xb5bd68)
term.setPaletteColor(out.yellow, 0xf0c674)
term.setPaletteColor(out.blue, 0x81a2be)
term.setPaletteColor(out.magenta, 0xb294bb)
term.setPaletteColor(out.cyan, 0x8abeb7)
term.setPaletteColor(out.white, 0xc5c8c6)
term.setPaletteColor(out.brightBlack, 0x666666)
term.setPaletteColor(out.brightRed, 0xd54e53)
term.setPaletteColor(out.brightGreen, 0xb9ca4a)
term.setPaletteColor(out.brightYellow, 0xe7c547)
term.setPaletteColor(out.brightBlue, 0x7aa6da)
term.setPaletteColor(out.brightMagenta, 0xc397d8)
term.setPaletteColor(out.brightCyan, 0x70c0b1)
term.setPaletteColor(out.brightWhite, 0xeaeaea)

return out
