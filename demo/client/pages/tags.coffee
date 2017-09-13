# For some page reactivity
DemoPage = new ReactiveDict

# ReactiveVars, we can use them if we want to process them elsewhere.
# We may or may not set to their default values, this will be handled by YAAC.
tags = new ReactiveVar
tags_p = new ReactiveVar
af_tags = new ReactiveVar
af_tags_p = new ReactiveVar

# Define a typical AF Schema
@Schemas = _.extend @Schemas or {},
  tags: new SimpleSchema
    array:
      type: [Number]
      optional: true
      label: 'Tags (array), separator is ","'
      autoform:
        type: 'ya-autocomplete'
        afFieldInput:
          placeholder: 'Enter a tag, try starting with a...'
          settings:
            containerClass: 'tagsinput'
            inputClass: 'input'
            tagClass: 'tag'
            addIconClass: 'glyphicon glyphicon-plus'
            inlineSuggestion: false
            autoCompleteIfUnique: true
            predictions: ['aloha','bahamas','coffee','code','delta']
            tagsDeps: af_tags
            predictionsDeps: af_tags_p

Template.tags.helpers
  tags_input: ->
    {
      id: 'no_af_tags'
      placeholder: 'Enter a string, try starting with a...'
    }

  tags_settings: ->
    {
      containerClass: 'tagsinput'
      inputClass: 'input'
      tagClass: 'tag'
      addIconClass: 'glyphicon glyphicon-plus'
      inlineSuggestion: false
      autoCompleteIfUnique: true
      hasTags: true
      tagsDeps: tags
      predictionsDeps: tags_p
      refAttribute: 'word'
      predictions: (key, input) ->
        if key
          word = Dictionary.findOne word: key
          if word
            {_id: word.word}
        else if input
          regex = new RegExp "^#{input}"
          Dictionary.find({word: regex},{limit: 10}).fetch()
          # .map (word) ->
          #   {_id: word.word}
    }

  show_tags: ->
    _.pluck(tags.get(),'word').join ', '

  show_tags_p: ->
    _.pluck(tags_p.get(),'word').join ', '

  show_af_tags: ->
    _.pluck(af_tags.get(),'word').join ', '

  show_af_tags_p: ->
    _.pluck(af_tags_p.get(),'word').join ', '

  doc: ->
    {
      array: ['aloha','bahamas', 'delta']
    }

  obj: -> DemoPage.get 'submitted'

Template.tags.events
  'click button[type="submit"]': (evt) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    doc = AutoForm.getFormValues 'demo'
    cleaned = Schemas.tags.clean doc.insertDoc
    console.log 'got submit', doc, cleaned
    DemoPage.set 'submitted', cleaned
    return
