{View} = require 'atom'

module.exports =
class MinimapColorHighlightView extends View
  @content: ->
    @div class: 'minimap-color-highlight overlay from-top', =>
      @div "The MinimapColorHighlight package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "minimap-color-highlight:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "MinimapColorHighlightView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
