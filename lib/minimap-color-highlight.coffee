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

  activatePlugin: ->
    if @minimap.active
      @createViews()
    else
      @subscribe @minimap, 'activated', @createViews

    @subscribe @minimap, 'deactivated', @destroyViews

  deactivatePlugin: ->
    @destroyViews()
    @unsubscribe()

  createViews: =>
    atom.workspaceView.eachEditorView (editor) =>
      model = @colorHighlight.modelForEditorView(editor)
      view = new @MinimapColorHighlightView model, editor
      @views[editor.getModel().id] = view
      view.attach()

  destroyViews: ->
    view.destroy() for id,view of @views
    @views = {}

module.exports = new MinimapColorHighlight
