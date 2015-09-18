@Demo = new SimpleSchema
  tags:
    type: [Number]
    optional: true
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

  simple:
    type: String
    optional: true
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
          # predictions: (input) ->
          #   console.log 'called predictions with', input
          #   input

Template.demo_tags_autoform.helpers
  doc: ->
    {
      tags: [0,1,4]
      simple: 'code'
    }
AutoForm.hooks
  demo:
    onSubmit: (doc) ->
      cleaned = Demo.clean doc
      console.log 'onsubmit', doc, cleaned
      # @done()
      false
