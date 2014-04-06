{$, EditorView} = require 'atom'

# HACK The exports is a function here because we are not sure that the
# `find-and-replace` and `minimap` packages will be available when this
# file is loaded. The binding instance will evaluate the module when
# created because at that point we're sure that both modules have been
# loaded.
module.exports = ->
  colorHighlight = atom.packages.getLoadedPackage('atom-color-highlight')
  minimap = atom.packages.getLoadedPackage('minimap')

  minimapInstance = require (minimap.path)
  AtomColorHighlightView = require (colorHighlight.path + '/lib/atom-color-highlight-view')

  class MinimapColorHighlighView extends AtomColorHighlightView
    attach: ->
      minimap = @getMinimap()

      if minimap?
        minimap.miniOverlayer.append(this)
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

    getMinimap: ->
      if @editorView instanceof EditorView
        return minimapInstance.minimapForEditorView(@editorView)
