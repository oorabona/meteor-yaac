# Yet Another AutoComplete widget for Meteor (AutoForm)

# If AutoForm is installed, this would be useful to have :)
if Package['aldeed:autoform']
  {AutoForm} = Package['aldeed:autoform']
  AutoForm.addInputType "ya-autocomplete",
    template: 'afYaac'
    valueOut: ->
      {tags} = @[0].dataset
      if typeof tags is 'string'
        tags.split '|'
      else
        @val()
    valueIn: (value) ->
      @value = value

setDefaultOptions = (settings) ->
  setup = _.extend {
    inlineSuggestion: false
    inlineClass: ''
    inlineContainerClass: ''
    hasTags: true
    containerClass: 'tagsinput'
    tagClass: 'tag'
    removeTagClass: 'tagsinput-remove-link'
    inputContainerClass: 'tagsinput-add-container'
    addLinkClass: 'tagsinput-add'
    popoverContainerClass: 'tagsinput-popover'
    popoverInnerClass: 'tagsinput-popover-table'
    btnPredictionClass: 'btn btn-default'
    showAddTag: true
    popoverSuggestions: true
    showListIfEmpty: false
    allowMultiple: false
    allowNonExistent: false
    autoCompleteIfUnique: true
    separator: ','
    refAttribute: '_id'
    predictions: (tag, input) -> console.error "YAAC: No prediction callback set to handle input: #{input}!"
  }, settings or {}

  # Make sure we correctly init dependencies tracking
  if setup.predictionsDeps instanceof ReactiveVar
    setup.predictionsDeps.set false
  else
    setup.predictionsDeps = new ReactiveVar false

  if setup.tagsDeps instanceof ReactiveVar
    setup.tagsDeps.set []
  else
    setup.tagsDeps = new ReactiveVar []

  setup

# We wrap input and settings so that it fits nicely with the checks in afYaac.
Template.yaac.helpers
  setup: ->
    self = @
    {
      atts:
        placeholder: self.input.placeholder
        id: self.input.id
        'data-schema-key': self.input['data-schema-key'] or self.input.id
        settings: self.settings
    }

Template.afYaac.rendered = ->
  # Manually trigger keyup event to make the list appear when rendered
  if @data.atts.settings.showListIfEmpty
    @$('input').trigger $.Event 'keyup'

Template.afYaac.helpers
  setup: ->
    {value} = @
    {settings} = @atts
    @atts.settings = setDefaultOptions settings

    {refAttribute, tagsDeps, predictions} = @atts.settings

    # If we already have a value (loading)
    if _.isArray value
      # If this is an array, we must be dealing with a tag enabled structure.
      unless @atts.settings.hasTags
        throw new Error "Erm. Got input value #{JSON.stringify value} but we should not accept it (hasTags is false)."

      # We ask prediction callback for more information before rendering
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

  # To render predictions nicely, make sure they have index and tabindex set.
  predictions: ->
    predictions = @atts.settings.predictionsDeps.get()
    if predictions then predictions.map (prediction, index) ->
      prediction.index ?= index
      prediction.tabindex ?= index + 1
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

# We need to handle clicks from two classes: 'addLinkClass' and 'removeTagClass'
# So we only need to listen to one event and we check for currentTarget classList.
# If one of these two classes is found, handle the case, otherwise do not interfere!
Template.afYaac.events
  'click': (evt, tmpl) ->
    {classList} = evt.currentTarget

    inst = Template.instance()
    {settings} = inst.data.atts

    if classList.contains settings.removeTagClass
      evt.preventDefault()
      evt.stopImmediatePropagation()

      tags = settings.tagsDeps.get()
      tags.splice @index, 1
      settings.tagsDeps.set tags
    else if classList.contains settings.addLinkClass
      evt.preventDefault()
      evt.stopImmediatePropagation()

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
    # If we have more than one prediction, try to find an exact match
    else if _.isArray predictions
      hasValue = predictions.filter (prediction) -> prediction.content is newValue
      if hasValue.length > 0
        newTag = hasValue[0]
    # Lastly, we might be interested in adding new tags from user input
    else if settings.allowNonExistent
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
