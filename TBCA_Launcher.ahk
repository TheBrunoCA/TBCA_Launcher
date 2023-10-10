#SingleInstance Force
#Requires AutoHotkey v2.0
#Warn All, StdOut

#Include ..\..\Repositorios\
#Include GithubReleases\GithubReleases.ahk
#Include Bruno-Functions\bruno-functions.ahk
#Include Bruno-Functions\GreatGui.ahk
#Include Bruno-Functions\Ini.ahk

;==========Globals==========;
VERSION := "1.0.0"
USER := "TheBrunoCA"
REPO := "TBCA_Launcher"
GITHUB := GithubReleases(USER, REPO, true)
INSTALL_DIR := A_AppData "\" USER "\" REPO
EXE_PATH := INSTALL_DIR "\" REPO ".exe"
VERSION_PATH := INSTALL_DIR "\version"
CONFIG_INI := Ini(INSTALL_DIR "\CONFIG.ini")
MAIN_GUI_TITLE := "TBCA_Launcher MainGui"

BUSCAPMC_USER := "TheBrunoCA"
BUSCAPMC_REPO := "BuscaPMC"

COUPON_GENERATOR_USER := "TheBrunoCA"
COUPON_GENERATOR_REPO := "Coupon-Generator"

FP_EXTRA_USER := "TheBrunoCA"
FP_EXTRA_REPO := "FP-Extra"

;==========Apps==========;

Global APPS := AppsClass()
APPS.AddApp(BUSCAPMC_USER, BUSCAPMC_REPO)
APPS.AddApp(COUPON_GENERATOR_USER, COUPON_GENERATOR_REPO)
APPS.AddApp(FP_EXTRA_USER, FP_EXTRA_REPO)

;==========File Installs==========;
;==========Icons==========;
FileInstall("C:\Repositorios\Icons\BuscaPMC.ico", APPS.GetApp(BUSCAPMC_REPO).icon, true)
FileInstall("C:\Repositorios\Icons\Coupon-Generator.ico", APPS.GetApp(COUPON_GENERATOR_REPO).icon, true)
FileInstall("C:\Repositorios\Icons\FP-Extra.ico", APPS.GetApp(FP_EXTRA_REPO).icon, true)

;==========Functions==========;

LauncherAutoUpdate(){
    if CONFIG_INI["auto-update", "next", 0] > A_Now
        return
    CONFIG_INI["auto-update", "next"] := DateAdd(A_Now, CONFIG_INI["auto-update", "interval", 10], "Minutes")
    GITHUB.GetInfo()
    if GITHUB.IsUpToDate(VERSION, , true)
        return

    local answer := MsgBox("Atualizacao encontrada para o Launcher.`nDeseja atualizar?", , "0x4")
    if answer == "Yes"
        GITHUB.UpdateItself(A_ScriptFullPath)
}

CanCheckAppsUpdates(){
    local next_check := CONFIG_INI["apps", "next_check", 0]
    if next_check > A_Now
        return false
    return true
}

SetNextCheckUpdate(){
    CONFIG_INI["apps", "next_check"] := DateAdd(A_Now, CONFIG_INI["apps", "check_interval", 10], "Minutes")
}

DisableHotkeys(){
    Hotkey(CONFIG_INI[BUSCAPMC_REPO, "open_hotkey", "^+a"], "Off")
    Hotkey(CONFIG_INI[COUPON_GENERATOR_REPO, "open_hotkey", "^+c"], "Off")
    Hotkey(CONFIG_INI[FP_EXTRA_REPO, "open_hotkey", "^+f"], "Off")
    Hotkey(CONFIG_INI["Launcher", "open_hotkey", "^+m"], "Off")
}

EnableHotkeys(){
    Hotkey(CONFIG_INI[BUSCAPMC_REPO, "open_hotkey", "^+a"], HotkeyOpenBuscaPMC, "On")
    Hotkey(CONFIG_INI[COUPON_GENERATOR_REPO, "open_hotkey", "^+c"], HotkeyOpenCouponGenerator, "On")
    Hotkey(CONFIG_INI[FP_EXTRA_REPO, "open_hotkey", "^+f"], HotkeyOpenFPExtra, "On")
    Hotkey(CONFIG_INI["Launcher", "open_hotkey", "^+m"], HotkeyOpenLauncher, "Off")
}

HotkeyOpenBuscaPMC(args*){
    local app := APPS.GetApp(BUSCAPMC_REPO)
    app.OpenApp(true)
    return
}

HotkeyOpenCouponGenerator(args*){
    local app := APPS.GetApp(BUSCAPMC_REPO)
    app.OpenApp(true)
    return
}

HotkeyOpenFPExtra(args*){
    local app := APPS.GetApp(BUSCAPMC_REPO)
    app.OpenApp(true)
    return
}

HotkeyOpenLauncher(args*){
    if WinActive(MAIN_GUI_TITLE)
        _MainGuiShow(false)
    else{
        _MainGuiShow(true)
        WinActivate(MAIN_GUI_TITLE)
    }
    return
}

;==========Guis==========;

AppGui(app) {
    while WinExist("TBCA_Launcher " app.repo)
        WinClose("TBCA_Launcher " app.repo)

    app_gui := Gui(, "TBCA_Launcher " app.repo)
    app_gui.AddPicture("h150 w-1", app.icon)
    app_gui.SetFont("s12")
    app_gui.AddText("ys", app.repo)
    app_gui.SetFont("s8")
    if app.IsInstalled()
        app_gui.AddText(, "Versao atual: " app.GetVersion())
    app_gui.AddText(, "Versao disponivel: " app.GetLatestVersion())
    if app.IsInstalled() {
        inst_btn := app_gui.AddButton(, "Desinstalar")
        inst_btn.OnEvent("Click", _Uninstall)
        if app.IsUpToDate() {
            upd_btn := app_gui.AddButton(, "Checar por atualizacoes")
            upd_btn.OnEvent("Click", _CheckForUpdates)
        } else {
            upd_btn := app_gui.AddButton(, "Atualizar")
            upd_btn.OnEvent("Click", _Update)
        }
    } else {
        inst_btn := app_gui.AddButton(, "Instalar")
        inst_btn.OnEvent("Click", _Install)
    }

    app_gui.Show()


    _Uninstall(GuiCtrlObj, Info, Href?) {
        app.UninstallApp()
        _Reset()
    }

    _Install(GuiCtrlObj, Info, Href?) {
        app.InstallApp()
        _Reset()
    }

    _CheckForUpdates(GuiCtrlObj, Info, Href?) {
        app.IsUpToDate(true)
        _Reset()
    }

    _Update(GuiCtrlObj, Info, Href?) {
        app.UpdateApp()
        _Reset()
    }

    _Reset() {
        _MainGuiReloadAppsList()
        AppGui(app)
    }
}


;==========Classes==========;

Class AppClass {
    __New(user, repo) {
        this.user := user
        this.repo := repo
        this.git := GithubReleases(this.user, this.repo, true)
        this.latest_release := this.git.GetLatestRelease()
        this.dir := NewDir(A_AppData "\" this.user "\" this.repo)
        this.exe := this.latest_release["exe_name"]
        this.full_path := this.dir "\" this.exe
        this.icon := this.dir "\" this.repo ".ico"
        this._version := this.dir "\version"
    }

    CloseApp(timeout_ms := 1000) {
        local end := A_TickCount + timeout_ms

        while ProcessExist(this.exe) and end > A_TickCount
            try ProcessClose(this.exe)

        return true
    }

    OpenApp(overwrite := false) {
        if not overwrite {
            if ProcessExist(this.exe)
                return
        } else {
            while ProcessExist(this.exe)
                ProcessClose(this.exe)
        }
        Run(this.exe)
        return
    }

    UpdateApp(&progress_var?, &progress_text?) {
        this.CloseApp()
        this.UninstallApp(false)
        this.git.UpdateApp(this.full_path, this.latest_release, &progress_var, &progress_text)
        FileOverwrite(this.latest_release["tag_name"], this._version)
        return this.latest_release["tag_name"]
    }

    InstallApp(&progress_var?, &progress_text?) {
        if FileExist(this.full_path) {
            this.UninstallApp(false)
        }
        return this.UpdateApp(&progress_var?, &progress_text?)
    }

    UninstallApp(clean_all := true) {
        this.CloseApp()
        if clean_all {
            try FileDelete(this.dir "\*.exe")
            try FileDelete(this.dir "\*.ini")
            try FileDelete(this.dir "\*.txt")
        }

        try FileDelete(this.full_path)
        try FileDelete(this._version)
        return true
    }

    IsInstalled() {
        return FileExist(this.full_path)
    }

    GetVersion() {
        try {
            return FileRead(this._version)
        }
        return ""
    }

    GetLatestVersion() {
        return this.git.GetLatestReleaseVersion()
    }

    IsUpToDate(reload_git := false) {
        if reload_git
            this.git.GetInfo()
        return this.git.IsUpToDate(this.GetVersion())
    }
}


Class AppsClass {
    __New() {
        this._apps := []
    }

    GetAppsArray() {
        return this._apps
    }

    GetAppsAmount() {
        return this._apps.Length
    }

    IsEmpty() {
        return not this.GetAppsArray().Has(1)
    }

    AddApp(user, repo) {
        if this.HasApp(repo)
            return false

        local a := AppClass(user, repo)
        this._apps.Push(a)
    }

    RemoveApp(repo) {
        if this.IsEmpty()
            return false

        for i, app in this.GetAppsArray() {
            if app.repo == repo {
                this._apps.RemoveAt(i)
                return true
            }
        }
        return false
    }

    GetApp(repo) {
        if this.IsEmpty()
            return false

        for i, app in this.GetAppsArray() {
            if app.repo == repo {
                return this.GetAppsArray()[i]
            }
        }
        return false
    }

    HasApp(repo) {
        if this.IsEmpty()
            return false

        for i, app in this.GetAppsArray() {
            if app.repo == repo
                return true
        }
        return false
    }
}


;==========Execution==========;

if A_IsCompiled{
    FileOverwrite(VERSION, VERSION_PATH)
    if A_ScriptFullPath != EXE_PATH
        try FileCopy(A_ScriptFullPath, EXE_PATH, true)
    
    LauncherAutoUpdate()
}

EnableHotkeys()

;==========MainGui==========;
main_gui := GreatGui("Resize", MAIN_GUI_TITLE)
main_gui.OnEvent("Close", _OnClose)
_OnClose(GuiObj){
    _MainGuiShow(false)
    return
}
main_gui.OnEvent("Size", _MainGuiOnResize)

main_gui_tabs := main_gui.AddTab3(, ["Aplicativos", "Atalhos"])


main_gui_tabs.UseTab(1)

main_gui_lv_apps := main_gui.AddListView("w400 h200", ["Nome", "Autor", "Situacao", "Versao atual", "Ultima versao"])
main_gui_lv_apps.OnEvent("ContextMenu", _MainGuiOnContextMenu)
main_gui_lv_apps.OnEvent("DoubleClick", _MainGuiOnDoubleClick)


_MainGuiLoadApps()
main_gui_ckupd_btn_disabled := "Disabled"
if CanCheckAppsUpdates()
    main_gui_ckupd_btn_disabled := ""

main_gui_ckupd_btn := main_gui.AddButton("xp " main_gui_ckupd_btn_disabled, "Checar por atualizacoes dos aplicativos")
main_gui_ckupd_btn.OnEvent("Click", _MainGuiCheckAppsUpdates)
main_gui_upd_btn := main_gui.AddButton("yp x+5", "Atualizar todos os aplicativos")
main_gui_upd_btn.OnEvent("Click", _MainGuiUpdateAllApps)
main_gui_close_btn := main_gui.AddButton("xm+10 y+10", "Fechar Launcher")
main_gui_close_btn.OnEvent("Click", _MainGuiCloseLauncher)

_MainGuiShow(true)

_MainGuiOnResize(GuiObj, MinMax, Width, Height){
    if MinMax == -1
        return
    main_gui_tabs.Move(, , Width*0.95, Height*0.95)
    local w := Width*0.90
    local x := (Width*0.50) - (w/2)
    main_gui_lv_apps.Move(x, , w)
    local x := (Width*0.05)
    main_gui_ckupd_btn.Move(x)
    local x := (Width*0.55)
    main_gui_upd_btn.Move(x)
    local x := (Width*0.05)
    main_gui_close_btn.Move(x)
}

_MainGuiOnContextMenu(GuiCtrlObj, Item, IsRightClick, X, Y) {
    local a := APPS.GetApp(GuiCtrlObj.GetText(Item))
    while WinExist("TBCA_Launcher " a.repo)
        WinClose("TBCA_Launcher " a.repo)
    AppGui(a)
    return
}

_MainGuiOnDoubleClick(GuiCtrlObj, Info) {
    local a := APPS.GetApp(GuiCtrlObj.GetText(Info))
    if not a.IsInstalled() {
        while WinExist("TBCA_Launcher " a.repo)
            WinClose("TBCA_Launcher " a.repo)
        AppGui(a)
        return
    }
    a.OpenApp(true)
}

_MainGuiCheckAppsUpdates(GuiCtrlObj, Info, Href?){
    if not CanCheckAppsUpdates()
        return

    for a in APPS.GetAppsArray()
        a.IsUpToDate(true)
    SetNextCheckUpdate()
    main_gui_ckupd_btn.Opt("Disabled")
    _MainGuiReloadAppsList()
}

_MainGuiUpdateAllApps(GuiCtrlObj, Info, Href?){
    for a in APPS.GetAppsArray(){
        if a.IsUpToDate()
            continue
        a.UpdateApp()
    }
    _MainGuiReloadAppsList()
}

_MainGuiCloseLauncher(GuiCtrlObj, Info, Href?){
    ExitApp(1000) ;TODO: Exit codes
}

_MainGuiLoadApps() {
    for app in APPS.GetAppsArray() {
        local is_installed := app.IsInstalled() ? "Instalado" : "Nao instalado"

        main_gui_lv_apps.Add(, app.repo, app.user, is_installed, app.GetVersion(), app.GetLatestVersion())
    }
    main_gui_lv_apps.ModifyCol(1)
    main_gui_lv_apps.ModifyCol(2)
    main_gui_lv_apps.ModifyCol(3)
}

_MainGuiReloadAppsList() {
    main_gui_lv_apps.Delete
    _MainGuiLoadApps()
}

_MainGuiShow(state){
    if state
        main_gui.Show("h320 w420")
    else 
        main_gui.Hide()
}


main_gui_tabs.UseTab(2)
main_gui.SetFont("s12")
main_gui.AddText(, "Abrir " BUSCAPMC_REPO ": ")
main_gui.SetFont("s10")
main_gui_BuscaPMC_open := main_gui.AddHotkey("y+2 Limit15", CONFIG_INI[BUSCAPMC_REPO, "open_hotkey", "^+a"])
main_gui.SetFont("s12")
main_gui.AddText(, "Abrir " COUPON_GENERATOR_REPO ": ")
main_gui.SetFont("s10")
main_gui_Coupon_Generator_open := main_gui.AddHotkey("y+2 Limit15", CONFIG_INI[COUPON_GENERATOR_REPO, "open_hotkey", "^+c"])
main_gui.SetFont("s12")
main_gui.AddText(, "Abrir " FP_EXTRA_REPO ": ")
main_gui.SetFont("s10")
main_gui_FP_Extra_open := main_gui.AddHotkey("y+2 Limit15", CONFIG_INI[FP_EXTRA_REPO, "open_hotkey", "^+f"])
main_gui.SetFont("s12")
main_gui.AddText(, "Abrir Launcher: ")
main_gui.SetFont("s10")
main_gui_Launcher_open := main_gui.AddHotkey("y+2 Limit15", CONFIG_INI["Launcher", "open_hotkey", "^+m"])

main_gui_hotkey_save := main_gui.AddButton("y+30", "Salvar")
main_gui_hotkey_save.OnEvent("Click", _MainGuiOnSaveHotkey)

_MainGuiOnSaveHotkey(GuiCtrlObj, Info, Href?){

    DisableHotkeys()

    CONFIG_INI[BUSCAPMC_REPO, "open_hotkey"] := main_gui_BuscaPMC_open.Value
    CONFIG_INI[COUPON_GENERATOR_REPO, "open_hotkey"] := main_gui_Coupon_Generator_open.Value
    CONFIG_INI[FP_EXTRA_REPO, "open_hotkey"] := main_gui_FP_Extra_open.Value
    CONFIG_INI["Launcher", "open_hotkey"] := main_gui_Launcher_open.Value

    EnableHotkeys()

    MsgBox("Atalhos salvos.")
}

;==========End of MainGui==========;