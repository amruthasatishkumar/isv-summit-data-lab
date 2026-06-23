// Print mode helpers - keeps the page clean when exporting to PDF
window.addEventListener("beforeprint", () => {
    document.querySelectorAll("details").forEach(d => d.setAttribute("open", ""));
});

// =============================================================
// Lab nav - sticky sidebar, injected on every page
// =============================================================
const LAB_NAV = [
    { group: "Start",              items: [
        { href: "index.html",                              label: "Overview",                  badge: "Home" },
    ]},
    { group: "Setup",              items: [
        { href: "module-0-setup.html",                     label: "Setup & Environment",       badge: "M0" },
        { href: "module-1-workspace-tour.html",            label: "Workspace Tour",            badge: "M1" },
    ]},
    { group: "Goal 1 · Ingest",        items: [
        { href: "module-2-lakehouse-mirror.html",          label: "Data Ingestion",            badge: "M2" },
        { href: "module-3-streaming.html",                 label: "Streaming Ingest",          badge: "M3" },
    ]},
    { group: "Goal 2 · Transform",     items: [
        { href: "module-4-transform.html",                 label: "Transform for Analytics",   badge: "M4" },
    ]},
    { group: "Goal 3 · Build Report",  items: [
        { href: "module-5-kql-dashboard.html",             label: "Live Dashboard",            badge: "M5" },
        { href: "module-6-direct-lake.html",               label: "Direct Lake + Power BI",    badge: "M6" },
    ]},
    { group: "Goal 4 · Apply AI",      items: [
        { href: "module-7-ontologies.html",                label: "Fabric Ontologies",         badge: "M7" },
        { href: "module-8-data-agents.html",               label: "Fabric Data Agent",         badge: "M8" },
        { href: "module-9-multi-agent.html",               label: "Multi-Agent Catalog",       badge: "M9" },
        { href: "module-10-foundry-orchestrator.html",     label: "Foundry Orchestrator",      badge: "M10" },
    ]},
    { group: "Goal 5 · Source Control", items: [
        { href: "module-11-git-integration.html",          label: "Azure DevOps + Git",        badge: "M11" },
    ]},
    { group: "Wrap-up",            items: [
        { href: "closing.html",                            label: "Closing",                   badge: "End" },
    ]},
    { group: "Appendices",         items: [
        { href: "appendix-learn-links.html",               label: "MS Reference Links",        badge: "A" },
        { href: "appendix-data-setup.html",                label: "Data Setup",                badge: "B" },
    ]},
];

document.addEventListener("DOMContentLoaded", () => {
    // ---- Build the sidebar ----
    const here = location.pathname.split("/").pop() || "index.html";

    const aside = document.createElement("aside");
    aside.className = "lab-nav";
    aside.setAttribute("aria-label", "Lab navigation");

    const headerBlock = document.createElement("div");
    headerBlock.className = "lab-nav-header";
    headerBlock.innerHTML = `
        <div class="lab-nav-eyebrow">UrbanPulse Data Lab</div>
        <div class="lab-nav-title">UrbanPulse</div>
    `;
    aside.appendChild(headerBlock);

    LAB_NAV.forEach(group => {
        const g = document.createElement("div");
        g.className = "lab-nav-group";

        const gh = document.createElement("div");
        gh.className = "lab-nav-group-title";
        gh.textContent = group.group;
        g.appendChild(gh);

        group.items.forEach(item => {
            const a = document.createElement("a");
            a.href = item.href;
            a.className = "lab-nav-link";
            if (item.href === here) a.classList.add("active");
            a.innerHTML = `
                <span class="lab-nav-badge">${item.badge}</span>
                <span class="lab-nav-label">${item.label}</span>
            `;
            g.appendChild(a);
        });

        aside.appendChild(g);
    });

    // Mobile-toggle button
    const toggle = document.createElement("button");
    toggle.className = "lab-nav-toggle";
    toggle.setAttribute("aria-label", "Toggle navigation");
    toggle.innerHTML = "☰ Lab navigation";
    toggle.addEventListener("click", () => {
        document.body.classList.toggle("lab-nav-open");
    });

    document.body.appendChild(toggle);
    document.body.appendChild(aside);
    document.body.classList.add("has-lab-nav");

    // ---- Smooth-scroll active highlight for in-page TOCs (kept) ----
    const tocLinks = document.querySelectorAll(".toc a[href^='#']");
    if (tocLinks.length) {
        const observer = new IntersectionObserver(entries => {
            entries.forEach(e => {
                if (e.isIntersecting) {
                    tocLinks.forEach(l => l.classList.toggle(
                        "active", l.getAttribute("href") === `#${e.target.id}`
                    ));
                }
            });
        }, { rootMargin: "-40% 0px -55% 0px" });
        document.querySelectorAll("section[id]").forEach(s => observer.observe(s));
    }

    // ---- Copy buttons on every code block ----
    document.querySelectorAll(".code-block").forEach(block => {
        const codeEl = block.querySelector("pre code, pre");
        if (!codeEl) return;
        if (block.querySelector(".copy-btn")) return;

        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "copy-btn";
        btn.setAttribute("aria-label", "Copy code");
        btn.innerHTML = "<span class='copy-icon'>📋</span><span class='copy-label'>Copy</span>";

        btn.addEventListener("click", async () => {
            const text = codeEl.innerText;
            try {
                await navigator.clipboard.writeText(text);
                btn.classList.add("copied");
                btn.querySelector(".copy-label").textContent = "Copied";
                setTimeout(() => {
                    btn.classList.remove("copied");
                    btn.querySelector(".copy-label").textContent = "Copy";
                }, 1500);
            } catch (err) {
                btn.querySelector(".copy-label").textContent = "Failed";
                setTimeout(() => {
                    btn.querySelector(".copy-label").textContent = "Copy";
                }, 1500);
            }
        });

        block.appendChild(btn);
    });

    // ---- Render screenshots: any .screenshot.placeholder whose target file
    //      exists on disk gets swapped for an <img>. No upload, no paste -- just
    //      "show the screenshot if it's there." ----
    (function renderScreenshots() {
        const SCREENSHOT_BASE = "assets/images/screenshots/";
        const placeholders = document.querySelectorAll(".screenshot.placeholder");
        placeholders.forEach(ph => {
            const metaEl = ph.querySelector(".ph-meta");
            if (!metaEl) return;
            const relPath = (metaEl.textContent || "").trim();
            if (!relPath) return;

            const captionText = (ph.querySelector(".placeholder-body > div:last-child")?.textContent || "").trim();
            const probe = new Image();
            probe.onload = () => {
                ph.classList.remove("placeholder");
                ph.classList.add("rendered");
                ph.innerHTML = "";
                const img = document.createElement("img");
                img.src = SCREENSHOT_BASE + relPath;
                img.alt = captionText || relPath;
                img.loading = "lazy";
                ph.appendChild(img);
                if (captionText) {
                    const cap = document.createElement("div");
                    cap.className = "caption";
                    cap.textContent = captionText;
                    ph.appendChild(cap);
                }
            };
            probe.onerror = () => { /* leave the placeholder visible */ };
            probe.src = SCREENSHOT_BASE + relPath;
        });
    })();
});
