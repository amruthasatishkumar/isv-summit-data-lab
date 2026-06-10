// Print mode helpers - keeps the page clean when exporting to PDF
window.addEventListener("beforeprint", () => {
    document.querySelectorAll("details").forEach(d => d.setAttribute("open", ""));
});

// =============================================================
// Lab nav - sticky sidebar, injected on every page
// =============================================================
const LAB_NAV = [
    { group: "Start",      items: [
        { href: "index.html",                              label: "Cover · Agenda",            badge: "Home" },
    ]},
    { group: "Modules",    items: [
        { href: "module-0-setup.html",                     label: "Setup & Environment",       badge: "M0" },
        { href: "module-1-workspace-tour.html",            label: "Workspace Tour",            badge: "M1" },
        { href: "module-2-lakehouse-mirror.html",          label: "Lakehouse + Mirror",        badge: "M2" },
        { href: "module-3-streaming.html",                 label: "Streaming Ingest",          badge: "M3" },
        { href: "module-4-kql-dashboard.html",             label: "KQL + Dashboard",           badge: "M4" },
        { href: "module-5-direct-lake.html",               label: "Direct Lake + Power BI",    badge: "M5" },
        { href: "module-6-ontologies.html",                label: "Fabric Ontologies",         badge: "M6" },
        { href: "module-7-data-agents.html",               label: "Data Agent → Copilot",      badge: "M7" },
        { href: "module-8-multi-agent.html",               label: "Multi-Agent Catalog ★",    badge: "M8" },
        { href: "module-9-foundry-orchestrator.html",      label: "Foundry Orchestrator ★",   badge: "M9" },
    ]},
    { group: "Appendices", items: [
        { href: "appendix-env-vars.html",                  label: "Lab Credentials",           badge: "A" },
        { href: "appendix-kql-cookbook.html",              label: "KQL Cookbook",              badge: "B" },
        { href: "appendix-prompt-library.html",            label: "Prompt Library",            badge: "C" },
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
        <div class="lab-nav-eyebrow">Day 2 Lab</div>
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
});
