"""Print routed metrics; flow completion is not timing closure."""
import json
import sys
from pathlib import Path
m = json.loads(Path(sys.argv[1]).read_text())
for label, key in {
    "Standard-cell area (um2)": "design__instance__area__stdcell",
    "Worst setup slack (ns)": "timing__setup__ws",
    "Worst hold slack (ns)": "timing__hold__ws",
    "Setup violations": "timing__setup_vio__count",
    "Hold violations": "timing__hold_vio__count",
    "Slew violations": "design__max_slew_violation__count",
    "Cap violations": "design__max_cap_violation__count",
    "Fanout violations": "design__max_fanout_violation__count",
    "Route DRC": "route__drc_errors",
    "Magic DRC": "magic__drc_error__count",
    "LVS errors": "design__lvs_error__count",
}.items():
    print(f"{label}: {m.get(key, 'MISSING')}")
