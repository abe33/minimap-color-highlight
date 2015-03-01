{CompositeDisposable} = require 'event-kit'
{requirePackages} = require 'atom-utils'

class MinimapColorHighlight

  views: {}
  constructor: ->
    @subscriptions = new CompositeDisposable

  activate: (state) ->

  consumeMinimapServiceV1: (@minimap) ->
    requirePackages('atom-color-highlight')
    .then ([@colorHighlight]) =>
      @MinimapColorHighlightView = require('./minimap-color-highlight-view')(@minimap, @colorHighlight)

      @minimap.registerPlugin 'color-highlight', this

  deactivate: ->
    @deactivatePlugin()
    @minimapPackage = null
    @colorHighlight = null
    @minimap = null

  isActive: -> @active
  activatePlugin: ->
    return if @active

    @active = true

    @createViews()

    @subscriptions.add @minimap.onDidActivate @createViews
    @subscriptions.add @minimap.onDidDeactivate @destroyViews

  deactivatePlugin: ->
    return unless @active

    @active = false
    @destroyViews()
    @subscriptions.dispose()

  createViews: =>
    return if @viewsCreated

    @viewsCreated = true
    @paneSubscription = @colorHighlight.observeColorHighlightModels (model) =>
      editor = model.editor
      view = new @MinimapColorHighlightView model, editor

      @views[editor.id] = view

      subscription = editor.onDidDestroy =>
        @views[editor.id]?.destroy()
        delete @views[editor.id]
        subscription.dispose()

  destroyViews: =>
    return unless @viewsCreated

    @paneSubscription.off()
    @viewsCreated = false
    view.destroy() for id,view of @views
    @views = {}

module.exports = new MinimapColorHighlight
