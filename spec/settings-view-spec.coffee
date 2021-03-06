path = require 'path'
{$$} = require 'atom-space-pen-views'
SettingsView = require '../lib/settings-view'

describe "SettingsView", ->
  settingsView = null

  beforeEach ->
    settingsView = new SettingsView
    spyOn(settingsView, "initializePanels").andCallThrough()
    window.advanceClock(10000)
    waitsFor ->
      settingsView.initializePanels.callCount > 0

  describe "serialization", ->
    it "remembers which panel was visible", ->
      settingsView.showPanel('Themes')
      newSettingsView = new SettingsView(settingsView.serialize())
      settingsView.remove()
      jasmine.attachToDOM(newSettingsView.element)
      newSettingsView.initializePanels()
      expect(newSettingsView.activePanelName).toBe 'Themes'

    it "shows the previously active panel if it is added after deserialization", ->
      settingsView.addCorePanel('Panel 1', 'panel1', -> $$ -> @div id: 'panel-1')
      settingsView.showPanel('Panel 1')
      newSettingsView = new SettingsView(settingsView.serialize())
      newSettingsView.addPanel('Panel 1', 'panel1', -> $$ -> @div id: 'panel-1')
      newSettingsView.initializePanels()
      jasmine.attachToDOM(newSettingsView.element)
      expect(newSettingsView.activePanelName).toBe 'Panel 1'

    it "shows the Settings panel if the last saved active panel name no longer exists", ->
      settingsView.addCorePanel('Panel 1', 'panel1', -> $$ -> @div id: 'panel-1')
      settingsView.showPanel('Panel 1')
      newSettingsView = new SettingsView(settingsView.serialize())
      settingsView.remove()
      jasmine.attachToDOM(newSettingsView.element)
      newSettingsView.initializePanels()
      expect(newSettingsView.activePanelName).toBe 'Settings'

    it "serializes the active panel name even when the panels were never initialized", ->
      settingsView.showPanel('Themes')
      settingsView2 = new SettingsView(settingsView.serialize())
      settingsView3 = new SettingsView(settingsView2.serialize())
      jasmine.attachToDOM(settingsView3.element)
      settingsView3.initializePanels()
      expect(settingsView3.activePanelName).toBe 'Themes'

  describe ".addCorePanel(name, iconName, view)", ->
    it "adds a menu entry to the left and a panel that can be activated by clicking it", ->
      settingsView.addCorePanel('Panel 1', 'panel1', -> $$ -> @div id: 'panel-1')
      settingsView.addCorePanel('Panel 2', 'panel2', -> $$ -> @div id: 'panel-2')

      expect(settingsView.panelMenu.find('li a:contains(Panel 1)')).toExist()
      expect(settingsView.panelMenu.find('li a:contains(Panel 2)')).toExist()
      expect(settingsView.panelMenu.children(':first')).toHaveClass 'active'

      jasmine.attachToDOM(settingsView.element)
      settingsView.panelMenu.find('li a:contains(Panel 1)').click()
      expect(settingsView.panelMenu.children('.active').length).toBe 1
      expect(settingsView.panelMenu.find('li:contains(Panel 1)')).toHaveClass('active')
      expect(settingsView.panels.find('#panel-1')).toBeVisible()
      expect(settingsView.panels.find('#panel-2')).not.toExist()
      settingsView.panelMenu.find('li a:contains(Panel 2)').click()
      expect(settingsView.panelMenu.children('.active').length).toBe 1
      expect(settingsView.panelMenu.find('li:contains(Panel 2)')).toHaveClass('active')
      expect(settingsView.panels.find('#panel-1')).toBeHidden()
      expect(settingsView.panels.find('#panel-2')).toBeVisible()

  describe "when the package is activated", ->
    [mainModule] = []
    beforeEach ->
      jasmine.attachToDOM(atom.views.getView(atom.workspace))
      waitsForPromise ->
        atom.packages.activatePackage('settings-view')

    describe "when the settings view is opened with a settings-view:* command", ->
      openWithCommand = (command) ->
        atom.commands.dispatch(atom.views.getView(atom.workspace), command)
        waitsFor ->
          atom.workspace.getActivePaneItem()?

      beforeEach ->
        settingsView = null

      describe "settings-view:open", ->
        it "opens the settings view", ->
          openWithCommand('settings-view:open')
          runs ->
            expect(atom.workspace.getActivePaneItem().activePanelName).toBe 'Settings'

      describe "settings-view:show-keybindings", ->
        it "opens the settings view to the keybindings page", ->
          openWithCommand('settings-view:show-keybindings')
          runs ->
            expect(atom.workspace.getActivePaneItem().activePanelName).toBe 'Keybindings'

      describe "settings-view:change-themes", ->
        it "opens the settings view to the themes page", ->
          openWithCommand('settings-view:change-themes')
          runs ->
            expect(atom.workspace.getActivePaneItem().activePanelName).toBe 'Themes'

      describe "settings-view:uninstall-themes", ->
        it "opens the settings view to the themes page", ->
          openWithCommand('settings-view:uninstall-themes')
          runs ->
            expect(atom.workspace.getActivePaneItem().activePanelName).toBe 'Themes'

      describe "settings-view:uninstall-packages", ->
        it "opens the settings view to the install page", ->
          openWithCommand('settings-view:uninstall-packages')
          runs ->
            expect(atom.workspace.getActivePaneItem().activePanelName).toBe 'Packages'

      describe "settings-view:install-packages-and-themes", ->
        it "opens the settings view to the install page", ->
          openWithCommand('settings-view:install-packages-and-themes')
          runs ->
            expect(atom.workspace.getActivePaneItem().activePanelName).toBe 'Install'

      describe "settings-view:check-for-package-updates", ->
        it "opens the settings view to the install page", ->
          openWithCommand('settings-view:check-for-package-updates')
          runs ->
            expect(atom.workspace.getActivePaneItem().activePanelName).toBe 'Updates'

    describe "when atom.workspace.open() is used with a config URI", ->
      beforeEach ->
        settingsView = null

      it "opens the settings to the correct panel with atom://config/<panel-name>", ->
        waitsForPromise ->
          atom.workspace.open('atom://config').then (s) -> settingsView = s

        waits 1
        runs ->
          expect(settingsView.activePanelName).toBe 'Settings'

        waitsForPromise ->
          atom.workspace.open('atom://config/themes').then (s) -> settingsView = s

        waits 1
        runs ->
          expect(settingsView.activePanelName).toBe 'Themes'

        waitsForPromise ->
          atom.workspace.open('atom://config/install').then (s) -> settingsView = s

        waits 1
        runs ->
          expect(settingsView.activePanelName).toBe 'Install'

  describe "when an installed package is clicked from the Install panel", ->
    it "displays the package details", ->
      waitsFor ->
        atom.packages.activatePackage('settings-view')

      runs ->
        settingsView.packageManager.getClient()
        spyOn(settingsView.packageManager.client, 'featuredPackages').andCallFake (callback) ->
          callback(null, [{name: 'settings-view'}])
        settingsView.showPanel('Install')

      waitsFor ->
        settingsView.find('.package-card:not(.hidden)').length > 0

      runs ->
        settingsView.find('.package-card:not(.hidden):first').click()

        packageDetail = settingsView.find('.package-detail').view()
        expect(packageDetail.title.text()).toBe 'Settings View'
