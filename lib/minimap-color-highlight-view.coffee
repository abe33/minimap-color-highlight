_ = require 'underscore-plus'
Q = require 'q'

# HACK The exports is a function here because we are not sure that the
# `atom-color-highlight` and `minimap` packages will be available when this
# file is loaded. The binding instance will evaluate the module when
# created because at that point we're sure that both modules have been
# loaded.
module.exports = (minimapPkg, colorHighlight) ->
  class MinimapColorHighlighView

    constructor: (@model, @editor) ->
      @decorationsByMarkerId = {}

      @subscription = @model.onDidUpdateMarkers @requestMarkersUpdate
      @requestMarkersUpdate() if @model?
      @observeConfig()

    destroy: ->
      @subscription.off()
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

    getMinimap: -> minimapPkg.minimapForEditor(@editor)

    updateSelections: ->

    requestMarkersUpdate: =>
      return if @frameRequested

      @frameRequested = true
      requestAnimationFrame =>
        @updateMarkers()
        @frameRequested = false

    updateMarkers: =>
      @markersUpdated(@model.markers)

    markersUpdated: (markers) =>
      markers ||= []
      minimap = @getMinimap()
      decorationsToRemove = _.clone(@decorationsByMarkerId)
      for marker in markers
        continue if @markerHidden(marker)

        if @decorationsByMarkerId[marker.id]?
          delete decorationsToRemove[marker.id]
        else
          decoration = minimap.decorateMarker(marker, type: 'highlight', color: marker.bufferMarker.properties.cssColor)
          @decorationsByMarkerId[marker.id] = decoration

      @markers = markers

      for id, decoration of decorationsToRemove
        decoration.destroy()
        delete @decorationsByMarkerId[id]

    rebuildDecorations: =>
      @destroyDecorations()
      @markersUpdated(@markers)

    markerHidden: (marker) ->
      @markerHiddenDueToComment(marker) or @markerHiddenDueToString(marker)

    getScope: (bufferRange) ->
      if @editor.displayBuffer.scopesForBufferPosition?
        @editor.displayBuffer.scopesForBufferPosition(bufferRange.start).join(';')
      else
        descriptor = @editor.displayBuffer.scopeDescriptorForBufferPosition(bufferRange.start)
        if descriptor.join?
          descriptor.join(';')
        else
          descriptor.scopes.join(';')

    markerHiddenDueToComment: (marker) ->
      bufferRange = marker.getBufferRange()
      scope = @getScope(bufferRange)
      atom.config.get('atom-color-highlight.hideMarkersInComments') and scope.match(/comment/)?

    markerHiddenDueToString: (marker) ->
      bufferRange = marker.getBufferRange()
      scope = @getScope(bufferRange)
      atom.config.get('atom-color-highlight.hideMarkersInStrings') and scope.match(/string/)?
