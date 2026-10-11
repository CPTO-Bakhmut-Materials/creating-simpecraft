// Урок 1: модель RGB. Три «ліхтарики» (червоний, зелений, синій) світять на чорне
// тло й складаються, як світло; поруч — отриманий колір і той самий колір у
// записі LÖVE (числа 0..1) і у звичному записі 0..255.
// Вставляється в Markdown як <div class="rgb-mixer"></div>.
(function () {
    "use strict";

    const PRESETS = [
        ["небо уроку", [135, 191, 242]],
        ["земля уроку", [120, 84, 59]],
        ["червоний + зелений", [255, 255, 0]],
        ["зелений + синій", [0, 255, 255]],
        ["червоний + синій", [255, 0, 255]],
        ["усі три", [255, 255, 255]],
        ["жодного", [0, 0, 0]],
    ];
    const SVG_NS = "http://www.w3.org/2000/svg";

    function el(tag, cls, text) {
        const e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text !== undefined) e.textContent = text;
        return e;
    }

    function svg(tag, attrs) {
        const e = document.createElementNS(SVG_NS, tag);
        for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
        return e;
    }

    function build(host) {
        const rgb = [135, 191, 242];
        host.textContent = "";

        // Ліхтарики: три кола на чорному, mix-blend-mode: screen. Кожне коло має лише свій
        // канал, тож «screen» тут дає рівно суму каналів — як додавання світла.
        const pic = svg("svg", { viewBox: "0 0 240 210", class: "rgb-mixer-torches", role: "img",
            "aria-label": "Три кольорові кола, що накладаються" });
        pic.append(svg("rect", { width: 240, height: 210, rx: 8, fill: "#000" }));
        const circles = [[90, 80], [150, 80], [120, 132]].map(([cx, cy]) => {
            const c = svg("circle", { cx, cy, r: 58, style: "mix-blend-mode: screen" });
            pic.append(c);
            return c;
        });

        const swatch = el("div", "rgb-mixer-swatch");
        const code = el("div", "rgb-mixer-code");

        const sliders = ["R — червоний", "G — зелений", "B — синій"].map((label, i) => {
            const row = el("label", "rgb-mixer-row");
            const input = el("input");
            input.type = "range";
            input.min = 0;
            input.max = 255;
            input.value = rgb[i];
            input.className = "rgb-mixer-" + "rgb"[i];
            const out = el("output");
            input.addEventListener("input", () => { rgb[i] = Number(input.value); update(); });
            row.append(el("span", null, label), input, out);
            return { input, out };
        });

        const presets = el("div", "rgb-mixer-presets");
        for (const [label, value] of PRESETS) {
            const b = el("button", null, label);
            b.type = "button";
            b.addEventListener("click", () => {
                value.forEach((v, i) => { rgb[i] = v; sliders[i].input.value = v; });
                update();
            });
            presets.append(b);
        }

        const controls = el("div", "rgb-mixer-controls");
        controls.append(...sliders.map(s => s.input.parentElement), presets);
        const top = el("div", "rgb-mixer-top");
        const result = el("div", "rgb-mixer-result");
        result.append(swatch, code);
        top.append(pic, result);
        host.append(top, controls);

        function update() {
            const [r, g, b] = rgb;
            circles[0].setAttribute("fill", `rgb(${r}, 0, 0)`);
            circles[1].setAttribute("fill", `rgb(0, ${g}, 0)`);
            circles[2].setAttribute("fill", `rgb(0, 0, ${b})`);
            swatch.style.background = `rgb(${r}, ${g}, ${b})`;
            sliders.forEach((s, i) => { s.out.textContent = rgb[i]; });
            // 0..255 → 0..1 з двома знаками, без зайвих нулів: 1, 0.5, 0.53.
            const f = v => String(parseFloat((v / 255).toFixed(2)));
            code.innerHTML =
                "<div>LÖVE (0..1):</div><code>love.graphics.setColor(" + rgb.map(f).join(", ") + ")</code>" +
                "<div>0..255:</div><code>(" + rgb.join(", ") + ")</code>";
        }
        update();
    }

    function init() {
        for (const host of document.querySelectorAll(".rgb-mixer")) {
            if (!host.dataset.ready) {
                host.dataset.ready = "1";
                build(host);
            }
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
