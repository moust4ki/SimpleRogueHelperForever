# The languages: the same keys in all five (esMX is esES), the same %d / %s
# and colour codes as the English, every key the code uses there and every
# key there used; the client's language over English, English for the
# others. The TOC lists them before Core.lua; the files are UTF-8 without
# a byte order mark.
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env import new_game, done, read, toc_files, ROOT, TOC

LOCALES = ["enUS", "frFR", "deDE", "esES", "itIT"]

lua = new_game()
lua.execute('section("A  the same keys in the five languages")')
# Each file alone, in its own table, as the game would run it
tables = {}
for loc in LOCALES:
    ns = lua.eval("{}")
    fn = lua.eval('function(src, name, ns) local f = assert(loadstring(src, name)) f("SimpleRogueHelperForever", ns) return ns end')
    ns = fn(read(os.path.join(ROOT, "Locales", loc + ".lua")), loc, ns)
    t = ns.L if loc == "enUS" else ns.LOCALES[loc]
    tables[loc] = {k: v for k, v in t.items()}
    if loc == "esES":
        esmx_same = lua.eval("function(ns) return ns.LOCALES.esMX == ns.LOCALES.esES end")(ns)
check = lua.eval("check")
english = tables["enUS"]
for loc in LOCALES[1:]:
    keys = tables[loc]
    missing = sorted(set(english) - set(keys))
    extra = sorted(set(keys) - set(english))
    check(loc + " has every English key", ", ".join(missing), "")
    check(loc + " has no other key", ", ".join(extra), "")
check("esMX: the esES table", esmx_same, True)

lua.execute('section("B  the values: text, the same %d / %s and colour codes")')
spec = re.compile(r"%[-+ #0]*\d*(?:\.\d+)?[sdif]")
for loc in LOCALES:
    bad = []
    for key, value in tables[loc].items():
        if not isinstance(value, str) or not value.strip():
            bad.append(key + " empty")
            continue
        if spec.findall(value) != spec.findall(english.get(key, "")):
            bad.append(key + " %")
        if value.count("|c") != value.count("|r") or value.count("|c") != english.get(key, "").count("|c"):
            bad.append(key + " |c")
    check(loc + " values", ", ".join(sorted(bad)), "")

lua.execute('section("C  the keys the code uses: all there, none left unused")')
code = {name: read(os.path.join(ROOT, name)) for name in toc_files() if not name.startswith("Locales/")}
used = set()
for src in code.values():
    used |= set(re.findall(r"\bL\.([A-Z][A-Z0-9_]*)", src))
check("used by the code, missing in English", ", ".join(sorted(used - set(english))), "")
check("in English, used nowhere", ", ".join(sorted(set(english) - used)), "")

lua.execute('section("D  the client\'s language, English for the others")')
for client, expect in [("enUS", "enUS"), ("frFR", "frFR"), ("deDE", "deDE"), ("esES", "esES"), ("esMX", "esES"),
                       ("itIT", "itIT"), ("koKR", "enUS"), ("ptBR", "enUS")]:
    g = new_game(locale=client)
    got = g.eval("NS.L.MARKS_NAME .. ' | ' .. NS.L.V_CLOSE")
    check(client + ": " + expect + "'s texts", got, tables[expect]["MARKS_NAME"] + " | " + tables[expect]["V_CLOSE"])
    check(client + ": the other languages let go", g.eval("NS.LOCALES"), None)
    check(client + ": no error", g.eval("#errors"), 0)

lua.execute('section("E  the TOC and the files")')
toc = read(TOC)
files = toc_files()
check("Interface 16001", re.search(r"^## Interface: 16001$", toc, re.M) is not None, True)
check("saved per character", re.search(r"^## SavedVariablesPerCharacter: SimpleRogueHelperCharDB$", toc, re.M) is not None, True)
check("no other saved variables, no dependency", re.search(r"^## (SavedVariables|Dependencies|RequiredDeps|OptionalDeps|Dep\w*):", toc, re.M) is not None, False)
check("the five languages, then Core.lua", ",".join(files[:6]), ",".join("Locales/%s.lua" % l for l in LOCALES) + ",Core.lua")
check("every file listed is there", ", ".join(f for f in files if not os.path.isfile(os.path.join(ROOT, f))), "")
listed = set(files)
lua_files = set()
for d, _, names in os.walk(ROOT):
    if any(part.startswith(".") or part in ("tests", "tools", "dist") for part in os.path.relpath(d, ROOT).split(os.sep)):
        continue
    for n in names:
        if n.endswith(".lua"):
            lua_files.add(os.path.relpath(os.path.join(d, n), ROOT).replace(os.sep, "/"))
check("every Lua file of the addon listed", ", ".join(sorted(lua_files - listed)), "")
bom = []
for name in sorted(lua_files) + ["SimpleRogueHelperForever.toc", "Bindings.xml"]:
    raw = open(os.path.join(ROOT, name), "rb").read()
    try:
        raw.decode("utf-8")
    except UnicodeDecodeError:
        bom.append(name + " not UTF-8")
    if raw.startswith(b"\xef\xbb\xbf"):
        bom.append(name + " BOM")
check("UTF-8, no byte order mark", ", ".join(bom), "")
done(lua)
