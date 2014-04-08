{Subscriber} = require 'emissary'

class MinimapColorHighlight
  Subscriber.includeInto(this)

  views: {}
  activate: (state) ->
    @colorHighlightPackage = atom.packages.getLoadedPackage('atom-color-highlight')
    @minimapPackage = atom.packages.getLoadedPackage('minimap')

    return @deactivate() unless @colorHighlightPackage? and @minimapPackage?

    @MinimapColorHighlightView = require('./minimap-color-highlight-view')()

    @minimap = require @minimapPackage.path
    @colorHighlight = require @colorHighlightPackage.path

    @minimap.registerPlugin 'color-highlight', this

  deactivate: ->
    @deactivatePlugin()
    @minimapPackage = null
    @colorHighlightPackage = null
    @colorHighlight = null
    @minimap = null

  isActive: -> @active
  activatePlugin: ->
    return if @active

    @active = true

    @createViews() if @minimap.active

    @subscribe @minimap, 'activated', @createViews
    @subscribe @minimap, 'deactivated', @destroyViews

  deactivatePlugin: ->
    return unless @active

    @active = false
    @destroyViews()
    @unsubscribe()

  createViews: =>
    return if @viewsCreated

    @viewsCreated = true
    @paneSubscription = @colorHighlight.eachColorHighlightEditor (editor) =>
      pane = editor.editorView.getPane()
      return unless pane?
      view = new @MinimapColorHighlightView pane

      @views[pane.model.id] = view

  destroyViews: =>
    return unless @viewsCreated

    @paneSubscription.off()
    @viewsCreated = false
    view.destroy() for id,view of @views
    @views = {}

module.exports = new MinimapColorHighlight
