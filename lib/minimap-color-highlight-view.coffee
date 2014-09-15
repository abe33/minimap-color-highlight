{Subscriber} = require 'emissary'
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

  class MinimapColorHighlighView
    Subscriber.includeInto(this)

    constructor: (@model, @editorView) ->
      @decorationsByMarkerId = {}

      {@editor} = @editorView
      @model = colorHighlight.modelForEditorView(@editorView)

      @subscribe @model, 'updated', @markersUpdated
      @markersUpdated(@model.markers) if @model?

    destroy: ->
      @unsubscribe()
      @destroyDecorations()
      @minimapView?.find('.atom-color-highlight').remove()

     observeConfig: ->
      atom.config.observe 'atom-color-highlight.hideMarkersInComments', @rebuildDecorations
      atom.config.observe 'atom-color-highlight.hideMarkersInStrings', @rebuildDecorations
      atom.config.observe 'atom-color-highlight.markersAtEndOfLine', @rebuildDecorations
      atom.config.observe 'atom-color-highlight.dotMarkersSize', @rebuildDecorations
      atom.config.observe 'atom-color-highlight.dotMarkersSpading', @rebuildDecorations

    destroyDecorations: ->
      decoration.destroy() for id,decoration of @decorationsByMarkerId

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

    updateSelections: ->

    markersUpdated: (@markers) =>
      @getMinimap()
      .then (minimap) =>
        for marker in @markers
          continue if @markerHidden(marker)
          decoration = minimap.decorateMarker(marker, type: 'highlight', color: marker.bufferMarker.properties.cssColor)
          @decorationsByMarkerId[marker.id] = decoration

    rebuildDecorations: =>
      @destroyDecorations()
      @markersUpdated(@markers)

    markerHidden: (marker) ->
      @markerHiddenDueToComment(marker) or @markerHiddenDueToString(marker)
    markerHiddenDueToComment: (marker) ->
      bufferRange = marker.getBufferRange()
      scope = @editor.displayBuffer.scopesForBufferPosition(bufferRange.start).join(';')
      atom.config.get('atom-color-highlight.hideMarkersInComments') and scope.match(/comment/)?

    markerHiddenDueToString: (marker) ->
      bufferRange = marker.getBufferRange()
      scope = @editor.displayBuffer.scopesForBufferPosition(bufferRange.start).join(';')
      atom.config.get('atom-color-highlight.hideMarkersInStrings') and scope.match(/string/)?
