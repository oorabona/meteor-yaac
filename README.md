# Yet Another Auto Complete for Meteor

A new Meteor AutoForm-aware auto completion and tag handling widget !

## What for ?

Autocomplete fields and handle tokenization.

## How to ?

Let's start with a SimpleSchema example. So imagine you need to autocomplete user names in some kind of input box..

You define your schema somewhere appropriate:

```coffee
@Demo = new SimpleSchema
  people:
    type: [String]
    defaultValue: -> [Meteor.userId()._id]
    autoform:
      type: 'ya-autocomplete'
      afFieldInput:
        placeholder: 'Comma separated list of user names...'
        settings:
          autoCompleteIfUnique: true
          containerClass: 'tagsinput'
          inputClass: 'token-input'
          tagClass: 'tag'
          inlineSuggestion: false
          autoCompleteIfUnique: true
          predictions: (key, input) ->
            query = {}
            if key isnt null
              query = _id: key
            else
              query = $or: [
                {emails: $elemMatch: address: $regex: input}
                {'profile.name': $regex: input, $options: 'i'}
                ]

            usernames = Meteor.users.find( query, {limit: 5}).map (user) ->
              name = user.profile?.name or user.emails[0].address
              {
                _id: user._id
                content: name
              }
            usernames
```

And then, if you want to use AutoForm to render you basically do:

```mustache
<template name="demo_tags_autoform">
  {{#quickForm schema="Demo" id="demo" doc=doc template="plain" validation="keyup" buttonContent=false}}
    {{>quickField name="tags"}}
    {{>quickField name="simple"}}
  {{/quickForm}}
</template>
```

For documentation about the above, please refer to [Meteor AutoForm](https://github.com/aldeed/meteor-autoform)

## Settings

As you have seen in the example, settings have their own object. The full list of options:

```coffee
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
```

Where:
- __inlineSuggestion__ ```[Default: false]```
Shows inline suggestion a la Google search input.

- __inlineClass__ ```[Default: '']```
- __inlineContainerClass__ ```[Default: '']```
Additional classes you want to set for inline search

- __hasTags__ ```[Default: true]```
Sets this if you want to enable tokenization of the input and tag creation. It implicitly enables the use of __separator__.

- __containerClass__ ```[Default: 'tagsinput']```
- __tagClass__ ```[Default: 'tags']```
Additional classes you want to set for tags

- __showAddTag__ ```[Default: true]```
Shows a "add" button before the input box (see demo)

- __popoverSuggestions__ ```[Default: true]```
Shows a "popover" with a list of suggestions (aka. _predictions_ see below)

- __showListIfEmpty__ ```[Default: false]```
Shows a list of suggestions even if input is empty.

- __allowMultiple__ ```[Default: false]```
Allows same tag to be added multiple times.

- __allowNonExistent__ ```[Default: false]```
Allows non existent (not found in _predictions_ see below) token to be added as a tag.

- __autoCompleteIfUnique__ ```[Default: true]```
If _predictions_ returns only one element from a given input, and user ask for tokenization (see _separator_ below), it will be auto completed.

- __separator__ ```[Default: ',']```
Used when _hasTags_ option is set (see above). It must be a single character which, once typed, will tell that the last word (_separator_ __WORD__ _separator_) is to be added to the token list.

- __refAttribute__ ```[Default: '_id']```
This will be the object attribute name that will be used to identify uniquely the tag. Must match the expected type defined by ```SimpleSchema```

- __predictions__
By default, it shows a simple warning because sometimes you might just not want to suggest anything at first and learn from user input instead.

At the moment, _predictions_ can be set as an ```Array``` or as a __callback function__.

It must return an ```Array```. This array can contain two kind of values:
- A ```String```, then the value will be used as _content_ and index will be automatically incremented.
- An ```Object```, then _refAttribute_ will be used to identify uniquely the prediction and _content_ attribute will be used to show tag label. Apart these two mandatory attributes, all other are passed "as is" to the template context.

See [below](#customization) for customization.

### The Array of Strings Case

Simplest case, you already know the possible values (or they do not need to be evaluated at runtime).

```coffee
  predictions: ['aloha','bahamas','coffee','code','delta']
```

Everything is handled automagically by YAAC. But you have to make sure the order does not change !

### The Callback Case

In that case, the callback function accepts two arguments:
* _key_: the value of a _refAttribute_ (see above), which is a somewhat tag key.
* _input_: current user input

Either one of the above is used at a time. So you will be sure that _input_ is ```null``` if _key_ is not and the opposite will also be true.

```coffee
predictions: (key, input) ->
  query = {}
  if key isnt null
    query = _id: key
  else
    query = $or: [
      {emails: $elemMatch: address: $regex: input}
      {'profile.name': $regex: input, $options: 'i'}
      ]

  usernames = Meteor.users.find( query, {limit: 5}).map (user) ->
    name = user.profile?.name or user.emails[0].address
    {
      _id: user._id
      content: name
    }
  usernames
```

```key``` argument is used when the form load data from doc. You will be asked to provide a returned object with enough data to render the tag element.

The way you handle predictions based on user input is totally up to you. This example shows an unoptimized version where you can search on user profile name and user email address.

If you want to enforce starting with, prefix ```input``` with a ```'^'``` as per RegExp docs. :wink:

## Customization

The default template is:

```mustache
<template name="yaac">
  {{#with setup}}
  <div class="{{atts.settings.containerClass}}">
    {{#if atts.settings.hasTags}}
    {{#each tags}}
    <span class="{{../atts.settings.tagClass}}">
      <span>{{content}}&nbsp;&nbsp;</span>
      <a class="tagsinput-remove-link"></a>
    </span>
    {{/each}}
    {{/if}}
    <div class="tagsinput-add-container">
      {{#if atts.settings.showAddTag}}
      <a class="tagsinput-add"><span class="{{atts.settings.addIconClass}}"></span></a>
      {{/if}}
      {{#if atts.settings.inlineSuggestion}}
      <div class="{{atts.settings.inlineContainerClass}}">
        <input {{afInlineInputAtts}}/>  {{! autocomplete disabled input}}
        <input {{afInputTextAtts}}/>    {{! real user input box}}
      </div>
      {{else}}
      <input {{afInputTextAtts}}/>
      {{/if}}
    </div>
    {{#if atts.settings.popoverSuggestions}}
    <div class="tagsinput-popover">
      <div class="tagsinput-popover-table">
        {{#each predictions}}
        <button type="button" tabindex="{{this.tabindex}}" class="btn btn-default tagsinput-add xitem">{{content}}</button>
        {{/each}}
      </div>
    </div>
    {{/if}}
  </div>
  {{/with}}
</template>
```

If you need something else to render, you will need to change default template.

# TODO

- Implement ```textarea```
- Bug fixing
- Code cleaning (those classes)
- Tests
- Better documentation
- Improved demo
