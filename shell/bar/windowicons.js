.pragma library

// Workspace window glyphs, ported from JaKooLit's waybar `hyprland/workspaces#rw`
// window-rewrite table. As in waybar, each key is a case-insensitive regex searched
// in "class<CLASS> title<TITLE>", title rules win over class rules, and ties go to
// the first key in sorted order. Glyphs keep waybar's trailing spaces; they are
// part of each button's width.

const fallback = "\uf059 ";

const rules = [
    ["class<.virt-manager-wrapped>", "\ueb7b "],
    ["class<Chromium|Thorium|[Cc]hrome>", "\uf268 "],
    ["class<Cider>", "\udb80\udf86 "],
    ["class<Gparted>", "\uf0c7"],
    ["class<Plex>", "\udb81\udeba "],
    ["class<PrusaSlicer|UltiMaker-Cura|OrcaSlicer>", "\udb83\ude5b"],
    ["class<VSCode|code-url-handler|code-oss|codium|codium-url-handler|VSCodium>", "\udb82\ude1e "],
    ["class<[Pp]avucontrol|org.pulseaudio.pavucontrol>", "\udb86\udc6b "],
    ["class<[Ss]potify>", "\uf1bc "],
    ["class<[Tt]elegram-desktop|org.telegram.desktop|io.github.tdesktop_x64.TDesktop>", "\ue217 "],
    ["class<[Tt]hunderbird|[Tt]hunderbird-esr>", "\uf370 "],
    ["class<android-studio>", "\uf17b "],
    ["class<brave-browser>", "\ud83e\udd81 "],
    ["class<celluloid|Zoom>", "\uf03d "],
    ["class<codeblocks>", "\udb80\udd69 "],
    ["class<com.mitchellh.ghostty>", " \ue795"],
    ["class<dev.zed.Zed>", "\udb83\udd41"],
    ["class<discord|[Ww]ebcord|Vesktop>", "\uf1ff "],
    ["class<emulator>", "\ud83d\udcf1 "],
    ["class<eu.betterbird.Betterbird>", "\uf370 "],
    ["class<firefox-developer-edition>", "\ud83e\udd8a "],
    ["class<firefox|org.mozilla.firefox|librewolf|floorp|mercury-browser|[Cc]achy-browser>", "\ue745 "],
    ["class<gimp>", "\uf338 "],
    ["class<jetbrains-idea>", "\ue7b5 "],
    ["class<kitty-dropterm>", "\uf120 "],
    ["class<kitty|konsole>", "\uebc6 "],
    ["class<libreoffice-calc>", "\uf37b "],
    ["class<libreoffice-startcenter>", "\udb80\udfc6 "],
    ["class<libreoffice-writer>", "\ue6a5 "],
    ["class<localsend>", "\uf1e0"],
    ["class<microsoft-edge>", "\uf282 "],
    ["class<mousepad>", "\uf15c "],
    ["class<mpv>", "\uf36e "],
    ["class<nwg-look>", "\ueb52 "],
    ["class<obs|com.obsproject.Studio>", "\ueba7 "],
    ["class<org.pipewire.Helvum>", "\udb81\udcc3"],
    ["class<org.wezfurlong.wezterm>", " \uea85"],
    ["class<polkit-gnome-authentication-agent-1>", "\udb81\udc83 "],
    ["class<remmina>", "\ud83d\udda5\ufe0f "],
    ["class<slack>", "\uf198 "],
    ["class<steam>", "\uf1b6 "],
    ["class<subl>", "\udb80\udd73 "],
    ["class<thunar|nemo>", "\udb81\udf70 "],
    ["class<tor browser>", "\uf371 "],
    ["class<virt-manager>", "\ueb7b "],
    ["class<virtualbox manager>", "\ud83d\udcbd "],
    ["class<vlc>", "\udb81\udd7c "],
    ["class<waterfox|waterfox-bin>", "\uee93 "],
    ["class<zen>", "\udb83\udc37 "],
    ["title<.*ChatGPT.*>", "\udb81\udea9 "],
    ["title<.*Picture-in-Picture.*>", "\uf52c "],
    ["title<.*amazon.*>", "\uf270 "],
    ["title<.*cmus.*>", "\uf001 "],
    ["title<.*deepseek.*>", "\udb81\udea9 "],
    ["title<.*facebook.*>", "\uf09a "],
    ["title<.*figma.*>", "\uef47 "],
    ["title<.*github.*>", "\uf113 "],
    ["title<.*gmail.*>", "\udb80\udeab "],
    ["title<.*jira.*>", "\ue75c "],
    ["title<.*messenger.*>", "\uf25f "],
    ["title<.*nvim ~.*>", "\uf36f "],
    ["title<.*nvim.*>", "\ue7c5 "],
    ["title<.*qwen.*>", "\udb81\udea9 "],
    ["title<.*reddit.*>", "\uf281 "],
    ["title<.*vim.*>", "\ue7c5 "],
    ["title<.*whatsapp.*>", "\uf232 "],
    ["title<.*youtube.*>", "\uf16a "],
    ["title<.*zapzap.*>", "\uf232 "],
    ["title<virtualbox>", "\ud83d\udcbd "],
].map(([key, glyph]) => ({ key, glyph, re: new RegExp(key, "i") }));
const ordered = rules.filter(r => r.key.includes("title")).concat(rules.filter(r => !r.key.includes("title")));

function glyphFor(cls, title) {
    const window = `class<${cls}> title<${title}>`;
    for (const rule of ordered)
        if (rule.re.test(window))
            return rule.glyph;
    return fallback;
}
