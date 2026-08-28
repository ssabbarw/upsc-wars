var GetURL = function() {};
GetURL.prototype = {
  run: function(arguments) {
    arguments.completionFunction({
      URL: document.URL || document.location.href,
      url: document.URL || document.location.href,
      href: document.location.href,
      title: document.title
    });
  },
  finalize: function(arguments) {}
};
