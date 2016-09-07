var MyPreprocessor = function() {};

MyPreprocessor.prototype = {
    run: function(arguments) {
        arguments.completionFunction({"URL": document.URL, "title": document.title});
    }
};

var ExtensionPreprocessingJS = new MyPreprocessor;
