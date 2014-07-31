{$} = require 'atom'
Q = require 'q'
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
      @minimapView?.find('.atom-color-highlight').remove()

    onActiveItemChanged: (item) =>
      return if item is @activeItem
      @activeItem = item

      editorView = @getEditor()
      return unless editorView?.hasClass('editor')
      model = colorHighlight.modelForEditorView(editorView)

      @setEditorView(editorView)
      @setModel(model)

      @removeMarkers()
      @markersUpdated(model.markers) if model?

    attach: ->
      @minimapView?.find('.atom-color-highlight').remove()

      @getMinimap()
      .then (minimapView) =>
        if not @minimapView? or @minimapView.find('.atom-color-highlight').length is 0
          minimapView.miniOverlayer.append(this)
          @minimapView = minimapView
          @patchMarkers()

    getEditor: -> @paneView.activeView
    getMinimap: ->
      defer = Q.defer()
      if @editorView?.hasClass('editor')
        minimapView = minimap.minimapForEditorView(@editorView)
        if minimapView?
          defer.resolve(minimapView)
        else
          poll = =>
            minimapView = minimap.minimapForEditorView(@editorView)
            if minimapView?
              defer.resolve(minimapView)
            else
              setTimeout(poll, 10)

          setTimeout(poll, 10)
      else
        defer.reject("#{@editorView} is not a legal editor")

      defer.promise

    setEditorView: (editorView) ->
      return if typeof editorView is 'function'
      @detach() if @minimapView?
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
      return unless @minimapView?
      @patchMarkers()

    patchMarkers: ->
      for k,marker of @markerViews
        unless marker.patched
          getSize = marker.getSize
          getSpacing = marker.getSpacing
          marker.getSize = => getSize.call(marker) * @minimapView.scaleX
          marker.getSpacing = => getSpacing.call(marker) * @minimapView.scaleX
          marker.patched = true

        marker.intersectsRenderedScreenRows = (range) =>
          range.intersectsRowRange(@minimapView.miniEditorView.firstRenderedScreenRow, @minimapView.miniEditorView.lastRenderedScreenRow)
        marker.editorView = @minimapView
        marker.updateNeeded = true
        marker.updateDisplay()
