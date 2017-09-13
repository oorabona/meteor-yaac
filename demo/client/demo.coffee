# Demo code

# Create a client only collection
@Dictionary = new Meteor.Collection null

Template.registerHelper 'showObject', (doc) ->
  JSON.stringify doc, null, 2

# Template.registerHelper 'getContent', (id) ->
#   IRdata._data[id].content

# Iron Router declaration
Router.configure
  layoutTemplate: 'layout'

Template.registerHelper 'notLoaded', -> Dictionary.find().count() is 0
Template.registerHelper 'dictCount', -> Dictionary.find().count()

Template.layout.events
  'click #loadColl': (evt) ->
    # Loading static dictionary from SIL English Wordlist
    dict = IRdata.get '/wordsEn.txt'
    if dict and typeof dict.content is 'string'
      words = dict.content.split /\r?\n/
      # console.log "Loading #{words.length} words..."

      words.forEach (word, index) ->
        Dictionary.insert word: word

    return

Router.map ->
  @route 'home',
    path: '/'
    waitOn: ->
      IRdata.load '/README.md'

  @route 'inline',
    path: '/inline'
    waitOn: ->
      IRdata.load '/wordsEn.txt'

  @route 'tags',
    path: '/tags'
    waitOn: ->
      IRdata.load '/wordsEn.txt'

  @route 'textarea',
    path: '/textarea'
    waitOn: ->
      IRdata.load '/wordsEn.txt'

  @route 'full',
    path: '/full'
    waitOn: ->
      IRdata.load '/wordsEn.txt'
