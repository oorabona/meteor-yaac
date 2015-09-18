# Yet Another AutoComplete widget for Meteor (AutoForm)

# If we have AutoForm installed somewhere ...
if Package['aldeed:autoform']
  {AutoForm} = Package['aldeed:autoform']
  AutoForm.addInputType "ya-autocomplete",
    template: 'yaac'
    valueOut: ->
      {tags} = @[0].dataset
      if typeof tags is 'string'
        tags.split '|'
      else
        @val()
    valueIn: (value) ->
      @value = value

setDefaultOptions = (settings) ->
  _.defaults settings or {}, {
    inlineSuggestion: false
    inlineClass: ''
    inlineContainerClass: ''
    hasTags: true
    containerClass: 'tagsinput'
    tagClass: 'tag'
    showAddTag: true
    popoverSuggestions: true
    showListIfEmpty: false
    allowMultiple: false
    allowNonExistent: false
    autoCompleteIfUnique: true
    separator: ','
    refAttribute: '_id'
    predictions: (tag, input) -> console.error "YAAC: No prediction callback set to handle input: #{input}!"
    predictionsDeps: new ReactiveVar false
    tagsDeps: new ReactiveVar []
  }

Template.yaac.rendered = ->
  # Manually trigger keyup event to make the list appear when rendered
  if @data.atts.settings.showListIfEmpty
    @$('input').trigger $.Event 'keyup'

Template.yaac.helpers
  setup: ->
    {value} = @
    {settings} = @atts
    @atts.settings = setDefaultOptions settings

    {refAttribute, tagsDeps, predictions} = @atts.settings

    if _.isArray value
      tags = value.map (tag) ->
        cleanTags = false
        if _.isArray predictions
          cleanTags = findInArray predictions, tag, null, refAttribute
        else if typeof predictions is 'function'
          cleanTags = predictions tag
          try
            check cleanTags, Match.Where (results) ->
              results.forEach (result) ->
                result[refAttribute] isnt 'undefined' and typeof result.content is 'string'
              true
          catch
            throw new Error "YAAC: predictions must be: [{#{refAttribute}: Number, content: String}, ...], got #{JSON.stringify cleanTags}"
        else
          throw new Error "Cannot handle this type: #{predictions}"
        cleanTags[0]

      tagsDeps.set tags

    @

  tags: ->
    @atts.settings.tagsDeps.get().map (tag, index) ->
      tag.index = index
      tag

  predictions: ->
    predictions = @atts.settings.predictionsDeps.get()
    if predictions then predictions.map (prediction, index) ->
      prediction.index = index
      prediction.tabindex = index + 1
      prediction
    else predictions

  afInlineInputAtts: ->
    {settings} = @atts
    predictions = settings.predictionsDeps.get()
    prediction = if predictions.length > 0 then predictions[0].content else ''
    {
      class: settings.inlineClass
      disabled: 'disabled'
      type: 'text'
      value: prediction
    }

  afInputTextAtts: ->
    atts = _.pick @atts, ['data-schema-key', 'id', 'name', 'placeholder']
    atts = AutoForm.Utility.addClass atts, @atts.settings.inputClass
    tags = @atts.settings.tagsDeps.get()
    {refAttribute} = @atts.settings
    if tags.length > 0
      atts['data-tags'] = _.pluck(tags, refAttribute).join '|'
    atts

Template.yaac.events
  'click .tagsinput-remove-link': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()

    inst = Template.instance()
    {settings} = inst.data.atts

    tags = settings.tagsDeps.get()
    tags.splice @index, 1
    settings.tagsDeps.set tags
    return

  'click .tagsinput-add': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()

    inst = Template.instance()
    {settings} = inst.data.atts

    input = tmpl.find('input[data-schema-key]')
    {index} = @
    results = settings.predictionsDeps.get()

    if typeof index isnt 'undefined'
      input.value = "#{@content}#{settings.separator}"
      settings.predictionsDeps.set [@]
    else
      input.value += settings.separator

    input.focus()

    # Manually trigger keyup event
    $(input).trigger $.Event 'keyup'
    return

  'keyup input[data-schema-key]': (evt, tmpl) ->
    {settings} = @atts

    {value} = evt.currentTarget

    predictions = settings.predictionsDeps.get()

    # We try to remove last character. Useful side effect, no tag under
    # 2 characters can be made, newValue is undefined if value.length < 2
    newValue = value[0..value.length-2]
    newTag = false
    input = evt.currentTarget

    # If our predictions are sharp, clone it to unbind data
    if predictions.length is 1
      if newValue is predictions[0].content or (newValue isnt predictions[0].content and settings.autoCompleteIfUnique)
        newTag = _.clone predictions[0]
    else
      if settings.allowNonExistent
        newTag = content: newValue

    {refAttribute} = settings

    # separator is used only if hasTags is true
    if settings.hasTags and value[value.length-1] is settings.separator
      input.value = ''
      if newTag
        tags = settings.tagsDeps.get()
        tags = [] unless _.isArray tags
        hasValue = tags.filter (tag) ->
          tag[refAttribute] is newTag[refAttribute]

        if settings.allowMultiple or hasValue.length is 0
          tags.push newTag
          settings.tagsDeps.set tags
          settings.predictionsDeps.set false
    else
      if newTag
        settings.predictionsDeps.set newTag

      cleanResults = []

      {predictions} = settings
      if _.isArray predictions
        cleanResults = findInArray predictions, null, value, refAttribute
      else if typeof predictions is 'function'
        cleanResults = predictions null, value
        try
          check cleanResults, Match.Where (results) ->
            results.forEach (result) ->
              result[refAttribute] isnt 'undefined' and typeof result.content is 'string'
            true
        catch
          throw new Error "YAAC: predictions must be: [{#{refAttribute}: Number, content: String}, ...]"
      else
        throw new Error "Cannot handle this type: #{predictions}"

      # If we have no result from our data source, we might still want to have
      # a visual feedback with current user input. Otherwise show nothing.
      if cleanResults.length is 0
        if settings.allowNonExistent
          settings.predictionsDeps.set [{index: 0, content: value}]
        else
          settings.predictionsDeps.set false
        return

      if !settings.showListIfEmpty and value is ''
        settings.predictionsDeps.set false
      else
        settings.predictionsDeps.set cleanResults
    return

# Helper function to handle Array based predictions
# Either key or value must be set !
findInArray = (predictions, key, value, refAttribute) ->
  regex = new RegExp "^#{value}" if value
  if (value is null and key is null) or (value isnt null and key isnt null)
    throw new Error "YAAC: Looks like a bug #{key} #{value}"

  predictions.map (p,idx) ->
    doc = {}
    if _.isObject p
      doc = p
      if typeof doc[refAttribute] is 'undefined'
        console.warn "YAAC: Predictions are Array based but inner Object do not contain any refAttribute (setup: #{refAttribute}), defaulting."
        doc[refAttribute] = idx
    else
      doc[refAttribute] = idx
      doc.content = p
    doc
  .filter (el) ->
    if value isnt null
      el.content.match regex
    else if key isnt null
      el[refAttribute] is key
