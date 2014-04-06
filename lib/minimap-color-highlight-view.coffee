{$, EditorView} = require 'atom'

# HACK The exports is a function here because we are not sure that the
# `atom-color-highlight` and `minimap` packages will be available when this
# file is loaded. The binding instance will evaluate the module when
# created because at that point we're sure that both modules have been
# loaded.
module.exports = ->
  colorHighlightPackage = atom.packages.getLoadedPackage('atom-color-highlight')
  minimapPackage = atom.packages.getLoadedPackage('minimap')

  minimap = require (minimapPackage.path)
  colorHighlight = require (colorHighlightPackage.path)
  AtomColorHighlightView = require (colorHighlightPackage.path + '/lib/atom-color-highlight-view')

  class MinimapColorHighlighView extends AtomColorHighlightView
    constructor: (@paneView) ->
      @subscribe @paneView.model.$activeItem, @onActiveItemChanged

      editorView = @getEditor()
      model = colorHighlight.modelForEditorView(editorView)

      super(model, editorView)

      @markersUpdated(model.markers)

    onActiveItemChanged: (item) =>
      return if item is @activeItem
      @activeItem = item

      editorView = @getEditor()
      model = colorHighlight.modelForEditorView(editorView)

      @setEditorView(editorView)
      @setModel(model)

      @removeMarkers()
      @markersUpdated(model.markers)

    attach: ->
      minimapView = @getMinimap()

      if minimapView?
        minimapView.miniOverlayer.append(this)
        @adjustResults()

    # As there's a slightly different char width between the minimap font
    # and the editor font we'll retrieve both widths and compute the
    # ratio to properly scale the find results.
    # FIXME I can't wrap my head on why the fixed version of redacted
    # still returns different widths for chars, so during that time
    # I'll use fixed scale.
    adjustResults: ->
      return if @adjusted
      @css '-webkit-transform', "scale3d(0.69,1,1)"
      @adjusted = true

    getEditor: -> @paneView.activeView
    getMinimap: ->
      if @editorView instanceof EditorView
        return minimap.minimapForEditorView(@editorView)

    setEditorView: (editorView) ->
      return console.log(new Error().stack) if typeof editorView is 'function'
      @detach() if @getMinimap()?
      @editorView = editorView
      {@editor} = @editorView
      @attach()

    updateSelections: ->


    activeTabSupportMinimap: -> @getEditor()
