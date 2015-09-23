# Demo code

# For some page reactivity
DemoPage = new ReactiveDict

# ReactiveVars, we can use them if we want to process them elsewhere.
# We may or may not set to their default values, this will be handled by YAAC.
tags = new ReactiveVar
tags_p = new ReactiveVar
af_tags = new ReactiveVar
af_tags_p = new ReactiveVar
search = new ReactiveVar
search_p = new ReactiveVar
af_search = new ReactiveVar
af_search_p = new ReactiveVar

# First define a typical AF Schema
@Demo = new SimpleSchema
  tags:
    type: [Number]
    optional: true
    label: 'Tags autocomplete'
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

  search:
    type: [Number]
    optional: true
    label: 'Search like with hasTags=true and separator=space'
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
          predictionsDeps: af_search_p
          tagsDeps: af_search
          separator: ' '

Template.demo_no_autoform.helpers
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
      predictions: ['aloha','bahamas','coffee','code','delta']
      tagsDeps: tags
      predictionsDeps: tags_p
    }

  inline_input: ->
    {
      id: 'no_af_inline'
      placeholder: 'Enter a string, try starting with a...'
    }

  inline_settings: ->
    {
      # hasTags: false
      inlineSuggestion: true
      inlineClass: 'inline-suggest'
      inputClass: 'inline-input'
      inlineContainerClass: 'relative'
      autoCompleteIfUnique: true
      showAddTag: false
      popoverSuggestions: false
      predictions: ['aloha','bahamas','coffee','code','delta']
      tagsDeps: search
      predictionsDeps: search_p
      separator: ' '
    }

  show_tags: ->
    _.pluck(tags.get(),'content').join ', '

  show_search: ->
    _.pluck(search.get(),'content').join ', '

  show_tags_p: ->
    _.pluck(tags_p.get(),'content').join ', '

  show_search_p: ->
    _.pluck(search_p.get(),'content').join ', '

# AutoForm example
Template.demo_autoform.helpers
  doc: ->
    {
      tags: [0,1,4]
      inline: 'code'
    }

  show_tags: ->
    _.pluck(af_tags.get(),'content').join ', '

  show_search: ->
    _.pluck(af_search.get(),'content').join ', '

  show_object: ->
    JSON.stringify DemoPage.get('submitted'), null, 2

  show_tags_p: ->
    _.pluck(af_tags_p.get(),'content').join ', '

  show_search_p: ->
    _.pluck(af_search_p.get(),'content').join ', '

Template.demo_autoform.events
  'submit #demo': (evt) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    doc = AutoForm.getFormValues 'demo'
    cleaned = Demo.clean doc.insertDoc
    DemoPage.set 'submitted', cleaned
    return
