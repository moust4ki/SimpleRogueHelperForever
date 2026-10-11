# A game session for the tests: the simulation (sim.lua), the saved
# variables and anything else set before the addon loads (pre), the
# addon's files in the TOC's order, as the game loads them (its folder
# name and namespace as the chunk's arguments), then logged in.
import os
import sys
import lupa.lua51 as L51

TESTS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TESTS)
TOC = os.path.join(ROOT, "SimpleRogueHelperForever.toc")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def toc_files():
    # The game takes "\" or "/"; the files, here
    lines = [l.strip() for l in read(TOC).splitlines()]
    return [l.replace("\\", "/") for l in lines if l and not l.startswith("#")]


def new_game(pre="", locale="frFR", login=True):
    lua = L51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute('LOCALE = "%s"' % locale)
    lua.execute(read(os.path.join(TESTS, "sim.lua")))
    if pre:
        lua.execute(pre)
    lua.execute("watchGlobals()")
    loader = lua.eval('''function(src, name)
        local fn, err = loadstring(src, "@" .. ADDON .. "/" .. name)
        if not fn then return err end
        local ok, e = pcall(fn, ADDON, NS)
        if not ok then return e end
        return "ok"
    end''')
    for name in toc_files():
        res = loader(read(os.path.join(ROOT, name)), name)
        if res != "ok":
            print("LOAD", name, res)
            lua.execute('errors[#errors + 1] = "load ' + name + '"')
    if login:
        lua.execute('fire("ADDON_LOADED", ADDON) fire("PLAYER_LOGIN") fire("PLAYER_ENTERING_WORLD")')
    return lua


def done(lua):
    lua.execute("finish()")
    ok = lua.eval("fails == 0 and #errors == 0")
    sys.exit(0 if ok else 1)
