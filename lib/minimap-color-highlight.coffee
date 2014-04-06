MinimapColorHighlightView = require './minimap-color-highlight-view'

module.exports =
  minimapColorHighlightView: null

  activate: (state) ->
    @minimapColorHighlightView = new MinimapColorHighlightView(state.minimapColorHighlightViewState)

  deactivate: ->
    @minimapColorHighlightView.destroy()

  serialize: ->
    minimapColorHighlightViewState: @minimapColorHighlightView.serialize()
