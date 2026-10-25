// Bundle the avatar renderer into dist/. The host (host/avatar_host.py) serves
// dist/ over 127.0.0.1, so wasm is fetched relative to main.js.
import { copyFileSync, mkdirSync } from "node:fs";
import * as esbuild from "esbuild";

const watch = process.argv.includes("--watch");
mkdirSync("dist", { recursive: true });
copyFileSync("web/index.html", "dist/index.html");
copyFileSync("web/style.css", "dist/style.css");
// babylon-mmd's wasm-bindgen glue resolves `new URL("index_bg.wasm", import.meta.url)`.
copyFileSync("node_modules/babylon-mmd/esm/Runtime/Optimized/wasm/spr/index_bg.wasm", "dist/index_bg.wasm");

const ctx = await esbuild.context({
    entryPoints: ["web/src/main.ts"],
    bundle: true,
    format: "esm",
    target: "es2022",
    outfile: "dist/main.js",
    sourcemap: true,
    minify: !watch,
    logLevel: "info",
});

if (watch) {
    await ctx.watch();
} else {
    await ctx.rebuild();
    await ctx.dispose();
}
