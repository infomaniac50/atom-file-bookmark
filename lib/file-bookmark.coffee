FileBookmarkView = require './file-bookmark-view'
{CompositeDisposable} = require 'atom'

fs = require "fs"
$ = jQuery = require "jquery"
_ = require 'underscore-plus'

class FileBookmark

  config: require('./config.coffee')

  show: null
  currentPath: null

  MSG_ADDED: "File bookmarked"
  MSG_REMOVED: "File removed from bookmarks"

  fileBookmarkView: null
  subscriptions: null

  activate: (state) ->
    if (state)
      @fileBookmarkView = atom.deserializers.deserialize state.fileBookmarkViewState
    else
      @fileBookmarkView = new FileBookmarkView()
    @show = no
    @currentPath = @_getCurrentPath()

    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:add': => @add()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:remove': => @remove()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-shortcut-icons': => @toggleShortcutIcons()
    # tooltips
    @tooltipDelay = {
      show: 100
      hide: 100
    }
    @subscriptions.add atom.tooltips.add @fileBookmarkView.favoriteIcon, {
      title: 'Bookmark'
      delay: @tooltipDelay
      placement: 'left'
    }
    @subscriptions.add atom.tooltips.add $('.fb-toggle-icon'), {
      title: 'Toggle panel'
      delay: @tooltipDelay
      placement: 'left'
    }
    @subscriptions.add atom.tooltips.add @fileBookmarkView.treeToggleIcon, {
      title: 'Toggle tree view'
      delay: @tooltipDelay
      placement: 'bottom'
    }

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem => @_handleChangeActivePane()
    @subscriptions.add atom.packages.onDidActivateInitialPackages => @_handleDependencies()

    # TODO: listen changes in settings and tree view activation

    $(@fileBookmarkView.element).on 'click', '.bookmark-this', => @toggleBookmark()
    $(@fileBookmarkView.element).on 'click', '.fb-toggle-icon', => @toggle()

    @fileBookmarkView.hide()
    if atom.config.get 'file-bookmark.icons'
      @_handleChangeActivePane()
    else
      @fileBookmarkView.fbIcons.classList.add 'hidden'

  deactivate: ->
    @subscriptions.dispose()
    @fileBookmarkView.destroy()

  serialize: ->
    fileBookmarkViewState: @fileBookmarkView.serialize()

  toggle: =>
    if @show
      @fileBookmarkView.hide()
    else
      @fileBookmarkView.show()
    @show = not @show

  toggleShortcutIcons: =>
    showIcons = not atom.config.get 'file-bookmark.icons'
    if showIcons
      @fileBookmarkView.fbIcons.classList.remove 'hidden'
    else
      @fileBookmarkView.fbIcons.classList.add 'hidden'
    atom.config.set 'file-bookmark.icons', showIcons

  toggleFileTree: ->
    if atom.packages.isPackageActive 'tree-view'
      atom.commands.dispatch atom.views.getView(atom.workspace), 'tree-view:toggle'

  toggleBookmark: ->
    if @_checkIfBookmarked @currentPath
      @remove()
    else
      @add()

  add: ->
    unless @_checkIfBookmarked @currentPath
      paths = @fileBookmarkView.getBookmarks()
      paths.push @currentPath
      @fileBookmarkView.setBookmarks paths
      @_postChangeRender()

  remove: ->
    if @_checkIfBookmarked @currentPath
      paths = @fileBookmarkView.getBookmarks().filter (item) => item isnt @currentPath
      @fileBookmarkView.setBookmarks paths
      @_postChangeRender()

  _postChangeRender: ->
      @_updateListPanel()
      @_updateBookmarkIcon()
      @_highlightActiveFile()

  _checkIfBookmarked: (path) ->
    exists = _.indexOf @fileBookmarkView.getBookmarks(), path
    if exists < 0
      return no
    else
      return yes

  _updateListPanel: ->
    @fileBookmarkView.renderItems()

  _getEditors: -> atom.workspace.getTextEditors()

  _getActiveEditor: -> atom.workspace.getActiveTextEditor()

  _pathExists: (path) -> fs.existsSync path

  _getCurrentPath: -> @_getActiveEditor()?.getPath()

  _handleChangeActivePane: =>
    # TODO: handle @_getActiveEditor()? (settings, search)
    @currentPath = @_getCurrentPath()
    if @_pathExists @currentPath
      @_updateBookmarkIcon()
      @_highlightActiveFile()

  _highlightActiveFile: =>
    $(".fb-filename").removeClass 'fb-selected'
    $("[data-path=\"#{@currentPath}\"]").addClass 'fb-selected'

  _handleDependencies: ->
    if atom.packages.isPackageActive 'tree-view'
      $(@fileBookmarkView.element).on 'click', '.fb-tree-toggle', => @toggleFileTree()
    else
      $('.file-bookmark-tree-toggle-icon').addClass 'hidden'

  _updateBookmarkIcon: ->
    bookmarked = @_checkIfBookmarked @currentPath
    @fileBookmarkView.updateBookmarkIcon bookmarked

module.exports = new FileBookmark()