var GetURL = function() {};
GetURL.prototype = {
  run: function(arguments) {
    arguments.completionFunction({
      URL: document.URL,
      url: document.URL,
      title: document.title
    });
  },
  finalize: function(arguments) {}
};
