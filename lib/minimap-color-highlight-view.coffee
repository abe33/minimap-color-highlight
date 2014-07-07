{$} = require 'atom'

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

      @markersUpdated(model.markers) if model?

    destroy: ->
      @unsubscribe()
      @paneView = null
      @activeItem = null
      @destroyAllViews()
      @getMinimap()?.find('.atom-color-highlight').remove()

    onActiveItemChanged: (item) =>
      return if item is @activeItem
      @activeItem = item

      editorView = @getEditor()
      return unless editorView.hasClass('editor')
      model = colorHighlight.modelForEditorView(editorView)

      @setEditorView(editorView)
      @setModel(model)

      @removeMarkers()
      @markersUpdated(model.markers)

    attach: ->
      minimapView = @getMinimap()

      if minimapView?
        minimapIsAppended = minimapView.miniOverlayer.find('.atom-color-highlight').length is 1

        minimapView.miniOverlayer.append(this) unless minimapIsAppended
        @adjustResults()

    # As there's a slightly different char width between the minimap font
    # and the editor font we'll retrieve both widths and compute the
    # ratio to properly scale the find results.
    # FIXME I can't wrap my head on why the fixed version of redacted
    # still returns different widths for chars, so during that time
    # I'll use fixed scale.
    adjustResults: ->
      @css '-webkit-transform', "scale3d(#{minimap.getCharWidthRatio()},1,1)"

    getEditor: -> @paneView.activeView
    getMinimap: ->
      if @editorView?.hasClass('editor')
        return minimap.minimapForEditorView(@editorView)

    setEditorView: (editorView) ->
      return if typeof editorView is 'function'
      @detach() if @getMinimap()?
      @editorView = editorView
      {@editor} = @editorView
      @attach()

    updateSelections: ->


    activeTabSupportMinimap: -> @getEditor()

    # HACK We don't want the markers to disappear when they're not
    # visible in the editor visible area so we'll hook on the
    # `markersUpdated` method and replace the corresponding method
    # on the fly.
    markersUpdated: (markers) ->
      super(markers)
      mini = @getMinimap()
      for k,marker of @markerViews
        marker.intersectsRenderedScreenRows = (range) ->
          range.intersectsRowRange(mini.miniEditorView.firstRenderedScreenRow, mini.miniEditorView.lastRenderedScreenRow)
        marker.updateDisplay()
