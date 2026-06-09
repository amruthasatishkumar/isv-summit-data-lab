# Editable Diagram Sources

The published lab guide uses **inline SVG** for all diagrams (in `lab-guide/assets/images/`). They're hand-tuned for the brand palette and render perfectly in print.

If you need to **edit** a diagram, you have two options:

## Option 1: Edit the SVG directly
The SVGs are intentionally human-readable. Open them in VS Code, change colors / labels / boxes, save. Fastest path for small tweaks.

| File | What it shows |
| --- | --- |
| `lab-guide/assets/images/architecture-overview.svg` | The 4-layer end-to-end architecture (cover page) |
| `lab-guide/assets/images/streaming-pipeline.svg` | Module 3 fan-in: 4 simulators → 4 Eventstreams → 4 KQL tables |
| `lab-guide/assets/images/orchestrator.svg` | Module 6 multi-agent orchestrator pattern |

## Option 2: Re-create in Excalidraw (for major restructuring)
1. Open <https://aka.ms/excalidraw>
2. Drag any of the SVGs into the canvas (Excalidraw imports SVG)
3. Edit visually, then export back to SVG
4. Replace the file in `lab-guide/assets/images/`

If you want versioned editable sources here, save the `.excalidraw` JSON files alongside this README so the next coach can iterate without starting from scratch.

## Diagrams referenced inline (per module)

Several modules also include **inline SVG markup directly inside the HTML** instead of as a separate file:

- Module 0 - Cloud PC window layout
- Module 1 - Medallion slice (hot path + warm path)
- Module 2 - Three ingest patterns
- Module 4 - RTI Dashboard layout mock
- Module 5 - Anatomy of a Fabric Data Agent
- Module 6 - Three-tenant ISV product picture

To edit those, search the relevant `module-*.html` file for `<svg`.
