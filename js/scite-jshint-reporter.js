module.exports = {
    reporter: function reporter(results) {
        var sys = require('util'),
            len = results.length,
            str = '',
            file, error;

        results.forEach(function (result) {
            file = result.file;
            error = result.error;
            str += file  + ':' + error.line + ':' +
                error.character + ', ' + error.reason + '\n';
        });

        sys.puts(len > 0 ? (str + "\n" + len + ' error' + ((len === 1) ? '' : 's')) : "Lint Free!");
        process.exit(len > 0 ? 1 : 0);
    }
};
