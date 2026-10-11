// Self-hosted Shadertoy-style fragment shaders (embedding shadertoy.com fails: its Cloudflare
// challenge page is served with X-Frame-Options: SAMEORIGIN, so browsers block the iframe).
// Markup:
//   <script type="x-shader/x-fragment" id="my-shader"> void mainImage(out vec4 c, in vec2 p) {...} </script>
//   <div class="glsl-demo" data-shader="my-shader" data-start="10"></div>
// Supports the iTime and iResolution uniforms. The animation runs only while the canvas is
// on screen; time pauses (not resets) while it is scrolled away.
// Visible labels are Ukrainian on purpose: readers of the book see them.
(function () {
    "use strict";

    const VERTEX = "attribute vec2 pos; void main() { gl_Position = vec4(pos, 0.0, 1.0); }";
    const PREFIX = "precision highp float;\nuniform float iTime;\nuniform vec3 iResolution;\n";
    const SUFFIX = "\nvoid main() { vec4 c = vec4(0.0); mainImage(c, gl_FragCoord.xy); gl_FragColor = vec4(c.rgb, 1.0); }\n";

    function compile(gl, type, src) {
        const s = gl.createShader(type);
        gl.shaderSource(s, src);
        gl.compileShader(s);
        if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s));
        return s;
    }

    function build(host) {
        const srcEl = document.getElementById(host.dataset.shader);
        if (!srcEl) return;
        const source = srcEl.textContent.trim();
        const canvas = document.createElement("canvas");
        canvas.className = "glsl-demo-canvas";
        host.append(canvas);

        // The shader source, for readers who want to see the "formula".
        const more = document.createElement("details");
        more.className = "more";
        const summary = document.createElement("summary");
        summary.textContent = "Код шейдера (GLSL)";
        const pre = document.createElement("pre");
        const code = document.createElement("code");
        code.className = "language-glsl";
        code.textContent = source;
        pre.append(code);
        more.append(summary, pre);
        host.after(more);

        const gl = canvas.getContext("webgl", { alpha: false, antialias: false });
        let prog;
        try {
            if (!gl) throw new Error("WebGL недоступний");
            prog = gl.createProgram();
            gl.attachShader(prog, compile(gl, gl.VERTEX_SHADER, VERTEX));
            gl.attachShader(prog, compile(gl, gl.FRAGMENT_SHADER, PREFIX + source + SUFFIX));
            gl.linkProgram(prog);
            if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(prog));
        } catch (e) {
            console.warn("glsl-demo:", e);
            host.classList.add("glsl-demo-failed");
            host.textContent = "Браузер не зміг запустити шейдер (потрібен WebGL).";
            return;
        }
        gl.useProgram(prog);
        // One triangle that covers the whole screen.
        gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
        const loc = gl.getAttribLocation(prog, "pos");
        gl.enableVertexAttribArray(loc);
        gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
        const uTime = gl.getUniformLocation(prog, "iTime");
        const uRes = gl.getUniformLocation(prog, "iResolution");

        let time = Number(host.dataset.start || 0);
        let last = null;
        let visible = false;

        function frame(now) {
            if (!visible) { last = null; return; }
            if (last !== null) time += Math.min((now - last) / 1000, 0.1);
            last = now;
            const dpr = Math.min(window.devicePixelRatio || 1, 2);
            const w = Math.round(canvas.clientWidth * dpr), h = Math.round(canvas.clientHeight * dpr);
            if (canvas.width !== w || canvas.height !== h) { canvas.width = w; canvas.height = h; }
            gl.viewport(0, 0, w, h);
            gl.uniform1f(uTime, time);
            gl.uniform3f(uRes, w, h, 1);
            gl.drawArrays(gl.TRIANGLES, 0, 3);
            requestAnimationFrame(frame);
        }

        if ("IntersectionObserver" in window) {
            new IntersectionObserver(entries => {
                const was = visible;
                visible = entries[entries.length - 1].isIntersecting;
                if (visible && !was) requestAnimationFrame(frame);
            }).observe(canvas);
        } else {
            visible = true;
            requestAnimationFrame(frame);
        }
    }

    function init() {
        for (const host of document.querySelectorAll(".glsl-demo")) {
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
