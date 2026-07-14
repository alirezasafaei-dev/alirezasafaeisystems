import json, sys
c = json.load(open(sys.argv[1]))
if sys.argv[2] == "set":
    parts = sys.argv[3].split("=", 1)
    c[parts[0]] = json.loads(parts[1]) if parts[1].startswith("{") or parts[1].startswith("[") or parts[1].startswith("null") or parts[1].startswith("true") or parts[1].startswith("false") else parts[1]
json.dump(c, open(sys.argv[1], "w"), indent=2)
print("OK")
