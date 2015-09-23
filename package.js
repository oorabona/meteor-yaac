Package.describe({
  name: 'oorabona:yaac',
  summary: 'Autocomplete and tagging for Meteor (AutoForm compatible)',
  version: '0.9.2',
  git: 'https://github.com/oorabona/meteor-yaac.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.use('templating@1.0.0');
  api.use('blaze@2.0.0');
  api.use('aldeed:autoform@5.0.0', {weak: true});
  api.use('coffeescript@1.0.0');
  api.use('reactive-var@1.0.0');
  api.addFiles([
    'yaac.html',
    'yaac.coffee'
  ], 'client');
});
