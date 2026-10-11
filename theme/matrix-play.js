// Lesson 3: interactive matrices.
//   <div class="matrix-play" data-mode="2d"></div>    3×3 homogeneous matrix acting on a 2D shape
//   <div class="matrix-play" data-mode="3d"></div>    4×4 matrix acting on a wireframe cube
//   <div class="matrix-play" data-mode="order"></div> A·B vs B·A for a rotation and a translation
// Matrices are stored by rows, like Mat4 in the lesson code: m[row][col].
// Visible labels are Ukrainian on purpose: readers of the book see them.
(function () {
    "use strict";

    const RED = "#d64545", GREEN = "#3a9a4e", BLUE = "#2f6fdb", ORANGE = "#e8833a";

    function el(tag, cls, text) {
        const e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text !== undefined) e.textContent = text;
        return e;
    }

    function identity(n) {
        return Array.from({ length: n }, (_, r) => Array.from({ length: n }, (_, c) => (r === c ? 1 : 0)));
    }

    function mul(a, b) {
        const n = a.length;
        return a.map((row, r) => row.map((_, c) => {
            let s = 0;
            for (let k = 0; k < n; k++) s += a[r][k] * b[k][c];
            return s;
        }));
    }

    function apply(m, v) {
        return m.map(row => row.reduce((s, x, i) => s + x * v[i], 0));
    }

    function fmt(x) {
        const r = Math.round(x * 100) / 100;
        return (Object.is(r, -0) ? 0 : r).toString().replace(".", ",").replace("-", "−");
    }

    function themeColors() {
        const s = getComputedStyle(document.documentElement);
        return {
            fg: s.getPropertyValue("--fg").trim() || "#1f2933",
            grid: s.getPropertyValue("--table-border-color").trim() || "#d5dde8",
        };
    }

    // A canvas that keeps its pixel size in sync with its CSS size; returns a 2D context
    // in CSS pixels and the logical size.
    function fitCanvas(canvas, h) {
        const dpr = window.devicePixelRatio || 1;
        const w = canvas.clientWidth;
        if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(h * dpr)) {
            canvas.width = Math.round(w * dpr);
            canvas.height = Math.round(h * dpr);
            canvas.style.height = h + "px";
        }
        const ctx = canvas.getContext("2d");
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        ctx.clearRect(0, 0, w, h);
        return { ctx, w, h };
    }

    function arrow(ctx, x1, y1, x2, y2, color, width) {
        const a = Math.atan2(y2 - y1, x2 - x1), len = Math.hypot(x2 - x1, y2 - y1);
        if (len < 1) return;
        const head = Math.min(10, len * 0.4);
        ctx.strokeStyle = ctx.fillStyle = color;
        ctx.lineWidth = width || 2.5;
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2 - Math.cos(a) * head * 0.8, y2 - Math.sin(a) * head * 0.8);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x2, y2);
        ctx.lineTo(x2 - head * Math.cos(a - 0.4), y2 - head * Math.sin(a - 0.4));
        ctx.lineTo(x2 - head * Math.cos(a + 0.4), y2 - head * Math.sin(a + 0.4));
        ctx.closePath();
        ctx.fill();
    }

    // Matrix editor: a grid of number inputs. `locked` rows are shown but read-only.
    function matrixEditor(n, onChange, opts) {
        opts = opts || {};
        const wrap = el("div", "matrix-play-matrix");
        wrap.style.gridTemplateColumns = `repeat(${n}, 4.2em)`;
        const cells = [];
        for (let r = 0; r < n; r++) {
            cells.push([]);
            for (let c = 0; c < n; c++) {
                const input = el("input");
                input.type = "number";
                input.step = "0.1";
                if (opts.cellClass) input.className = opts.cellClass(r, c) || "";
                if (opts.locked && opts.locked(r, c)) input.readOnly = true;
                input.addEventListener("input", () => {
                    const v = parseFloat(input.value);
                    if (Number.isFinite(v)) onChange(r, c, v);
                });
                wrap.append(input);
                cells[r].push(input);
            }
        }
        return {
            el: wrap,
            set(m) {
                for (let r = 0; r < n; r++) {
                    for (let c = 0; c < n; c++) {
                        if (document.activeElement !== cells[r][c]) {
                            cells[r][c].value = Math.round(m[r][c] * 100) / 100;
                        }
                    }
                }
            },
        };
    }

    function presetButtons(list, onPick) {
        const row = el("div", "matrix-play-buttons");
        const buttons = list.map(p => {
            const b = el("button", null, p.name);
            b.type = "button";
            b.addEventListener("click", () => onPick(p, b));
            row.append(b);
            return b;
        });
        return { el: row, buttons };
    }

    function slider(label, min, max, step, value, onInput) {
        const row = el("label", "matrix-play-slider");
        const input = el("input");
        input.type = "range";
        input.min = min;
        input.max = max;
        input.step = step;
        input.value = value;
        const out = el("output");
        row.append(el("span", null, label), input, out);
        input.addEventListener("input", () => onInput(Number(input.value)));
        return { el: row, input, out };
    }

    function rot2(deg) {
        const a = deg * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
        return [[c, -s, 0], [s, c, 0], [0, 0, 1]];
    }

    // The letter F: lopsided on purpose, so rotations and mirroring are easy to tell apart.
    const F_SHAPE = [[0, 0], [0.5, 0], [0.5, 0.9], [1.1, 0.9], [1.1, 1.4], [0.5, 1.4], [0.5, 1.9],
        [1.4, 1.9], [1.4, 2.4], [0, 2.4]];

    // Draws grid, the original F (ghost) and the F transformed by the 3×3 matrix m.
    function draw2d(ctx, w, h, m, colors, opts) {
        opts = opts || {};
        const S = opts.scale || 36, cx = opts.cx !== undefined ? opts.cx : w / 2, cy = opts.cy !== undefined ? opts.cy : h / 2;
        const scr = p => [cx + p[0] * S, cy - p[1] * S];
        const T = p => apply(m, [p[0], p[1], 1]);
        ctx.lineWidth = 1;
        ctx.strokeStyle = colors.grid;
        for (let i = -12; i <= 12; i++) {
            ctx.beginPath(); ctx.moveTo(...scr([i, -12])); ctx.lineTo(...scr([i, 12])); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(...scr([-12, i])); ctx.lineTo(...scr([12, i])); ctx.stroke();
        }
        // The transformed grid: shows how the whole plane moves, not just the shape.
        if (opts.warpedGrid) {
            ctx.strokeStyle = BLUE;
            ctx.globalAlpha = 0.18;
            for (let i = -8; i <= 8; i++) {
                ctx.beginPath(); ctx.moveTo(...scr(T([i, -8]))); ctx.lineTo(...scr(T([i, 8]))); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(...scr(T([-8, i]))); ctx.lineTo(...scr(T([8, i]))); ctx.stroke();
            }
            ctx.globalAlpha = 1;
        }
        ctx.strokeStyle = colors.fg;
        ctx.globalAlpha = 0.45;
        ctx.beginPath(); ctx.moveTo(...scr([-12, 0])); ctx.lineTo(...scr([12, 0])); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(...scr([0, -12])); ctx.lineTo(...scr([0, 12])); ctx.stroke();
        ctx.globalAlpha = 1;

        const poly = (pts, fill, stroke, dash) => {
            ctx.setLineDash(dash || []);
            ctx.beginPath();
            pts.forEach((p, i) => (i ? ctx.lineTo(...scr(p)) : ctx.moveTo(...scr(p))));
            ctx.closePath();
            if (fill) { ctx.fillStyle = fill; ctx.fill(); }
            ctx.strokeStyle = stroke;
            ctx.lineWidth = 1.5;
            ctx.stroke();
            ctx.setLineDash([]);
        };
        poly(F_SHAPE, null, colors.fg, [4, 4]);
        for (const [k, mid] of (opts.steps || []).entries()) {
            poly(F_SHAPE.map(p => apply(mid, [p[0], p[1], 1])), null, ORANGE, [6, 3]);
            if (k === 0 && opts.stepLabel) {
                const p = scr(apply(mid, [0.7, 2.4, 1]));
                ctx.fillStyle = ORANGE;
                ctx.font = "12px sans-serif";
                ctx.fillText(opts.stepLabel, p[0] + 6, p[1] - 6);
            }
        }
        poly(F_SHAPE.map(T), "rgba(47,111,219,0.25)", BLUE);

        if (opts.basis !== false) {
            const o = scr(T([0, 0])), ex = scr(T([1, 0])), ey = scr(T([0, 1]));
            arrow(ctx, ...o, ...ex, RED);
            arrow(ctx, ...o, ...ey, GREEN);
            ctx.fillStyle = colors.fg;
            ctx.beginPath(); ctx.arc(...o, 3.5, 0, Math.PI * 2); ctx.fill();
        }
    }

    // ---------------------------------------------------------------- 2D: 3×3 homogeneous
    function build2d(host) {
        let m = identity(3);
        let anim = null; // { from, to, t0 }
        const canvas = el("canvas", "matrix-play-canvas");
        const editor = matrixEditor(3, (r, c, v) => { m[r][c] = v; current = null; render(); }, {
            locked: r => r === 2,
            cellClass: (r, c) => (r === 2 ? "mp-w" : c === 2 ? "mp-t" : c === 0 ? "mp-x" : "mp-y"),
        });
        const presets = [
            { name: "Одинична", m: () => identity(3) },
            { name: "Поворот", m: a => rot2(a), angle: true },
            { name: "Масштаб ×1,5", m: () => [[1.5, 0, 0], [0, 1.5, 0], [0, 0, 1]] },
            { name: "Розтяг по X", m: () => [[2, 0, 0], [0, 1, 0], [0, 0, 1]] },
            { name: "Скіс", m: () => [[1, 0.6, 0], [0, 1, 0], [0, 0, 1]] },
            { name: "Дзеркало", m: () => [[-1, 0, 0], [0, 1, 0], [0, 0, 1]] },
            { name: "Зсув (2, −1)", m: () => [[1, 0, 2], [0, 1, -1], [0, 0, 1]] },
            { name: "Поворот і зсув", m: a => { const r = rot2(a); r[0][2] = 2; r[1][2] = -1; return r; }, angle: true },
        ];
        let current = presets[0];
        let angle = 30;
        const angleSlider = slider("Кут повороту:", -180, 180, 5, angle, v => {
            angle = v;
            if (current && current.angle) { m = current.m(angle); render(); }
            angleSlider.out.textContent = angle + "°";
        });
        angleSlider.out.textContent = angle + "°";
        const pb = presetButtons(presets, p => {
            current = p;
            const target = p.m(angle);
            anim = { from: identity(3), to: target, t0: performance.now() };
            m = target;
            requestAnimationFrame(tick);
        });
        const replay = el("button", null, "▶ Показати перехід з одиничної");
        replay.type = "button";
        replay.addEventListener("click", () => {
            anim = { from: identity(3), to: m.map(r => r.slice()), t0: performance.now() };
            requestAnimationFrame(tick);
        });
        pb.el.append(replay);

        const legend = el("div", "matrix-play-legend");
        const calc = el("div", "matrix-play-calc");
        const top = el("div", "matrix-play-top");
        top.append(editor.el, legend);
        legend.innerHTML =
            '<div><span class="mp-sw" style="background:' + RED + '"></span>1-й стовпець — куди потрапляє вісь X</div>' +
            '<div><span class="mp-sw" style="background:' + GREEN + '"></span>2-й стовпець — куди потрапляє вісь Y</div>' +
            '<div><span class="mp-sw mp-sw-t"></span>3-й стовпець — зсув (працює лише завдяки «1» у точці)</div>' +
            '<div><span class="mp-sw mp-sw-w"></span>нижній рядок 0 0 1 не змінюємо</div>';
        host.append(top, pb.el, angleSlider.el, canvas, calc);

        function shown() {
            if (!anim) return m;
            const t = Math.min(1, (performance.now() - anim.t0) / 900);
            const e = t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
            return anim.from.map((row, r) => row.map((x, c) => x + (anim.to[r][c] - x) * e));
        }

        function tick() {
            render();
            if (anim && performance.now() - anim.t0 < 900) requestAnimationFrame(tick);
            else { anim = null; render(); }
        }

        function render() {
            const shownM = shown();
            editor.set(shownM);
            const { ctx, w, h } = fitCanvas(canvas, 340);
            draw2d(ctx, w, h, shownM, themeColors(), { warpedGrid: true, cx: w / 2 - 20, cy: h / 2 + 40 });
            const p = [1.4, 2.4, 1], q = apply(shownM, p);
            calc.innerHTML = "Кут F <b>(1,4; 2,4)</b> → допишемо 1 → " +
                `(${fmt(shownM[0][0])}·1,4 + ${fmt(shownM[0][1])}·2,4 + ${fmt(shownM[0][2])}·<b>1</b>, ` +
                `${fmt(shownM[1][0])}·1,4 + ${fmt(shownM[1][1])}·2,4 + ${fmt(shownM[1][2])}·<b>1</b>) = ` +
                `<b>(${fmt(q[0])}; ${fmt(q[1])})</b>`;
            angleSlider.el.classList.toggle("mp-disabled", !(current && current.angle));
        }

        new ResizeObserver(render).observe(canvas);
        render();
    }

    // ---------------------------------------------------------------- 3D: 4×4 on a cube
    function build3d(host) {
        let m = identity(4);
        let divide = true;
        const canvas = el("canvas", "matrix-play-canvas");
        const editor = matrixEditor(4, (r, c, v) => { m[r][c] = v; current = null; render(); }, {
            cellClass: (r, c) => (r === 3 ? "mp-w" : c === 3 ? "mp-t" : ["mp-x", "mp-y", "mp-z"][c]),
        });
        const rotZ = a => { const c = Math.cos(a), s = Math.sin(a); return [[c, -s, 0, 0], [s, c, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]; };
        const rotX = a => { const c = Math.cos(a), s = Math.sin(a); return [[1, 0, 0, 0], [0, c, -s, 0], [0, s, c, 0], [0, 0, 0, 1]]; };
        const rad = d => d * Math.PI / 180;
        const presets = [
            { name: "Одинична", m: () => identity(4) },
            { name: "Поворот навколо Z", m: a => rotZ(rad(a)), angle: true },
            { name: "Поворот навколо X", m: a => rotX(rad(a)), angle: true },
            { name: "Масштаб (2; 1; 0,5)", m: () => [[2, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0.5, 0], [0, 0, 0, 1]] },
            { name: "Зсув (1; 0; 0,5)", m: () => [[1, 0, 0, 1], [0, 1, 0, 0], [0, 0, 1, 0.5], [0, 0, 0, 1]] },
            { name: "Поворот і зсув", m: a => { const r = rotZ(rad(a)); r[0][3] = 1; r[2][3] = 0.5; return r; }, angle: true },
            { name: "w = 1 + 0,6·y", m: () => [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0.6, 0, 1]] },
        ];
        let current = presets[0];
        let angle = 30;
        const angleSlider = slider("Кут повороту:", -180, 180, 5, angle, v => {
            angle = v;
            angleSlider.out.textContent = angle + "°";
            if (current && current.angle) { m = current.m(angle); render(); }
        });
        angleSlider.out.textContent = angle + "°";
        const pb = presetButtons(presets, p => { current = p; m = p.m(angle); render(); });
        const divLabel = el("label", "matrix-play-check");
        const divBox = el("input");
        divBox.type = "checkbox";
        divBox.checked = true;
        divBox.addEventListener("change", () => { divide = divBox.checked; render(); });
        divLabel.append(divBox, " ділити x, y, z на w (так робить відеокарта)");

        const legend = el("div", "matrix-play-legend");
        legend.innerHTML =
            '<div><span class="mp-sw" style="background:' + RED + '"></span>1-й стовпець — куди йде вісь X</div>' +
            '<div><span class="mp-sw" style="background:' + GREEN + '"></span>2-й стовпець — вісь Y</div>' +
            '<div><span class="mp-sw" style="background:' + BLUE + '"></span>3-й стовпець — вісь Z</div>' +
            '<div><span class="mp-sw mp-sw-t"></span>4-й стовпець — зсув</div>' +
            '<div><span class="mp-sw mp-sw-w"></span>нижній рядок — w (для перспективи)</div>';
        const top = el("div", "matrix-play-top");
        top.append(editor.el, legend);
        const note = el("div", "matrix-play-calc");
        host.append(top, pb.el, angleSlider.el, divLabel, canvas, note);

        // A fixed view of the scene: Z up, looking from the front-right and a little above.
        function viewer(w, h) {
            const yaw = rad(-35), pitch = rad(22), D = 7, S = Math.min(w, 560) / 5.5;
            const cy0 = Math.cos(yaw), sy0 = Math.sin(yaw), cp = Math.cos(pitch), sp = Math.sin(pitch);
            return p => {
                const x1 = p[0] * cy0 - p[1] * sy0, y1 = p[0] * sy0 + p[1] * cy0;
                const depth = y1 * cp + p[2] * sp, up = p[2] * cp - y1 * sp;
                const k = D / (D + depth);
                return [w / 2 + x1 * k * S, h * 0.6 - up * k * S];
            };
        }

        const corners = [];
        for (let i = 0; i < 8; i++) corners.push([i & 1 ? 0.5 : -0.5, i & 2 ? 0.5 : -0.5, i & 4 ? 0.5 : -0.5]);
        const edges = [];
        for (let a = 0; a < 8; a++) for (let b = a + 1; b < 8; b++) {
            const d = a ^ b;
            if (d === 1 || d === 2 || d === 4) edges.push([a, b, d === 1 ? 0 : d === 2 ? 1 : 2]);
        }

        function render() {
            editor.set(m);
            const { ctx, w, h } = fitCanvas(canvas, 360);
            const colors = themeColors();
            const V = viewer(w, h);
            const T = p => {
                const q = apply(m, [p[0], p[1], p[2], 1]);
                return divide && Math.abs(q[3]) > 1e-6 ? [q[0] / q[3], q[1] / q[3], q[2] / q[3], q[3]] : q;
            };
            // Ground grid (z = 0) and the world axes.
            ctx.strokeStyle = colors.grid;
            ctx.lineWidth = 1;
            for (let i = -3; i <= 3; i++) {
                ctx.beginPath(); ctx.moveTo(...V([i, -3, 0])); ctx.lineTo(...V([i, 3, 0])); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(...V([-3, i, 0])); ctx.lineTo(...V([3, i, 0])); ctx.stroke();
            }
            [[[2.6, 0, 0], RED, "X"], [[0, 2.6, 0], GREEN, "Y"], [[0, 0, 2.2], BLUE, "Z"]].forEach(([p, c, n]) => {
                ctx.globalAlpha = 0.45;
                arrow(ctx, ...V([0, 0, 0]), ...V(p), c, 1.2);
                ctx.globalAlpha = 1;
                ctx.fillStyle = c;
                ctx.font = "bold 13px sans-serif";
                const s = V(p);
                ctx.fillText(n, s[0] + 6, s[1] - 4);
            });
            // Original cube (ghost) and the transformed one, edges coloured by their axis.
            ctx.setLineDash([4, 4]);
            ctx.strokeStyle = colors.fg;
            ctx.globalAlpha = 0.35;
            for (const [a, b] of edges) {
                ctx.beginPath(); ctx.moveTo(...V(corners[a])); ctx.lineTo(...V(corners[b])); ctx.stroke();
            }
            ctx.setLineDash([]);
            ctx.globalAlpha = 1;
            const tc = corners.map(T);
            let behind = false;
            for (const [a, b, axis] of edges) {
                if (divide && (tc[a][3] <= 0 || tc[b][3] <= 0)) { behind = true; continue; }
                ctx.strokeStyle = [RED, GREEN, BLUE][axis];
                ctx.lineWidth = 2.5;
                ctx.beginPath(); ctx.moveTo(...V(tc[a])); ctx.lineTo(...V(tc[b])); ctx.stroke();
            }
            const o = T([0, 0, 0]);
            ctx.fillStyle = colors.fg;
            ctx.beginPath(); ctx.arc(...V(o), 3.5, 0, Math.PI * 2); ctx.fill();
            const ws = corners.map(p => apply(m, [p[0], p[1], p[2], 1])[3]);
            const wMin = Math.min(...ws), wMax = Math.max(...ws);
            note.innerHTML = behind
                ? "<b>w ≤ 0</b> для частини вершин: така точка «за камерою», відеокарта її відсікає."
                : Math.abs(wMax - 1) < 1e-6 && Math.abs(wMin - 1) < 1e-6
                    ? "У всіх вершин w = 1: ділити нема чого, нижній рядок (0 0 0 1) нічого не змінює."
                    : `w у вершин від <b>${fmt(wMin)}</b> до <b>${fmt(wMax)}</b>. ` +
                      (divide ? "Після ділення на w вершини з більшим w стискаються до центру — так працює перспектива."
                          : "Без ділення w ні на що не впливає. Увімкніть ділення.");
            angleSlider.el.classList.toggle("mp-disabled", !(current && current.angle));
        }

        new ResizeObserver(render).observe(canvas);
        render();
    }

    // ---------------------------------------------------------------- order: A·B vs B·A
    function buildOrder(host) {
        let angle = 45, shift = 3;
        const canvas = el("canvas", "matrix-play-canvas");
        const a = slider("Поворот R на кут:", -180, 180, 5, angle, v => { angle = v; render(); });
        const t = slider("Зсув T по X на:", -4, 4, 0.5, shift, v => { shift = v; render(); });
        const mats = el("div", "matrix-play-order");
        host.append(a.el, t.el, canvas, mats);

        function show(m) {
            return '<span class="matrix-play-mini">' +
                m.map(r => r.map(x => `<span>${fmt(x)}</span>`).join("")).join("") + "</span>";
        }

        function render() {
            a.out.textContent = angle + "°";
            t.out.textContent = fmt(shift);
            const R = rot2(angle), T = [[1, 0, shift], [0, 1, 0], [0, 0, 1]];
            const RT = mul(R, T), TR = mul(T, R);
            const { ctx, w, h } = fitCanvas(canvas, 300);
            const colors = themeColors();
            const half = w / 2;
            const S = Math.max(14, Math.min(26, half / 12));
            for (const [k, m, step, title, stepName] of [
                [0, RT, T, "R · T: спочатку зсув, потім поворот", "після T"],
                [1, TR, R, "T · R: спочатку поворот, потім зсув", "після R"],
            ]) {
                ctx.save();
                ctx.beginPath();
                ctx.rect(k * half, 0, half, h);
                ctx.clip();
                draw2d(ctx, w, h, m, colors, { scale: S, cx: k * half + half / 2, cy: h / 2 + 30, steps: [step], stepLabel: stepName, basis: false });
                ctx.restore();
                ctx.fillStyle = colors.fg;
                ctx.font = "bold 13px sans-serif";
                ctx.textAlign = "center";
                ctx.fillText(title, k * half + half / 2, 18);
                ctx.textAlign = "start";
            }
            ctx.strokeStyle = colors.grid;
            ctx.lineWidth = 2;
            ctx.beginPath(); ctx.moveTo(half, 0); ctx.lineTo(half, h); ctx.stroke();
            mats.innerHTML =
                `<div>R · T = ${show(RT)}</div><div>T · R = ${show(TR)}</div>`;
        }

        new ResizeObserver(render).observe(canvas);
        render();
    }

    function init() {
        for (const host of document.querySelectorAll(".matrix-play")) {
            if (host.dataset.ready) continue;
            host.dataset.ready = "1";
            const mode = host.dataset.mode;
            if (mode === "3d") build3d(host);
            else if (mode === "order") buildOrder(host);
            else build2d(host);
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
