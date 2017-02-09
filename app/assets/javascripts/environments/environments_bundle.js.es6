window.Vue = require('vue');
require('./components/environment');
require('../vue_shared/vue_resource_interceptor');

$(() => {
  window.gl = window.gl || {};

  if (gl.EnvironmentsListApp) {
    gl.EnvironmentsListApp.$destroy(true);
  }

  gl.EnvironmentsListApp = new gl.environmentsList.EnvironmentsComponent({
    el: document.querySelector('#environments-list-view'),
  });
});
