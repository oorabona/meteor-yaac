# For some page reactivity
DemoPage = new ReactiveDict

search = new ReactiveVar
search_p = new ReactiveVar
af_search = new ReactiveVar
af_search_p = new ReactiveVar

@Schemas = _.extend @Schemas or {},
  inline: new SimpleSchema
    array:
      type: [Number]
      optional: true
      label: 'Inline tags (array)'
      autoform:
        type: 'ya-autocomplete'
        afFieldInput:
          placeholder: 'Enter a string, try starting with a...'
          settings:
            inlineSuggestion: true
            inlineClass: 'inline-suggest'
            inputClass: 'inline-input'
            inlineContainerClass: 'relative'
            autoCompleteIfUnique: true
            showAddTag: false
            popoverSuggestions: false
            predictions: ['aloha','bahamas','coffee','code','delta']
            tagsDeps: af_search
            predictionsDeps: af_search_p
            separator: ' '
            refAttribute: '_id'

    collection:
      type: [Number]
      optional: true
      label: 'Inline tags (collection)'
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
            refAttribute: 'content'
            predictions: (key, input) ->
              if key
                Dictionary.find {word: key}, {limit: 10}
              else if input
                regex = new RegExp "^#{input}"
                Dictionary.find {word: regex}, {limit: 10}
                .map (word) ->
                  word.content = word.word
                  word

Template.inline.helpers
  doc: ->
    {
      array: ['aloha','bahamas', 'delta']
    }

  obj: -> DemoPage.get 'submitted'

  dict_input: ->
    {
      id: 'no_af_dict'
      placeholder: 'Enter a string, try starting with a...'
    }

  dict_settings: ->
    {
      inlineSuggestion: true
      inlineClass: 'inline-suggest'
      inputClass: 'inline-input'
      inlineContainerClass: 'relative'
      autoCompleteIfUnique: true
      showAddTag: false
      popoverSuggestions: false
      allowNonExistent: true
      tagsDeps: search
      predictionsDeps: search_p
      separator: ' '
      refAttribute: 'content'
      predictions: (key, input) ->
        if key
          Dictionary.find {word: key}, {limit: 10}
        else if input
          regex = new RegExp "^#{input}"
          Dictionary.find {word: regex}, {limit: 10}
          .map (word) ->
            word.content = word.word
            word
    }

  show_search: ->
    _.pluck(search.get(),'content').join ', '

  show_search_p: ->
    _.pluck(search_p.get(),'content').join ', '

Template.inline.events
  'submit': (evt) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    doc = AutoForm.getFormValues 'demo'
    cleaned = Schemas.inline.clean doc.insertDoc
    DemoPage.set 'submitted', cleaned
    return
