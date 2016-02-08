
helpers = require('atom-linter')
path = require('path')

getLibDir = (filepath) ->
  projpaths = atom.project.getPaths()
  home =
    if process.platform.startsWith 'win'
    then process.env.HOMEPATH else process.env.HOME
  curpath = path.dirname filepath
  while curpath != path.dirname(curpath)
    return false if curpath in projpaths
    return false if curpath is home
    return "-I#{curpath}" if path.basename(curpath) is 'lib'
    curpath = path.dirname curpath
  return false

# This provides linter support for Perl 6 using linter
# Please see https://atom.io/packages/linter
module.exports =
class Perl6Linter
  name: 'Perl 6 Syntax Check',
  grammarScopes: ['source.perl6', 'source.perl6fe'],
  scope: 'file',
  lintOnFly: true,
  lint: (textEditor) ->
    command = "perl6"
    lib = getLibDir(textEditor.getPath())
    args = ["-I#{lib}", '-c', "-"]
    options =
      stream : ""
      stdin  : textEditor.getText()
    return helpers.exec(command, args, options).then (output) ->
      console.log(output)

      # return nothing if no errors are found
      return [] if output.stdout.startsWith("Syntax OK") && output.stderr == ""

      # Try to find the error message and line number
      regex = /(.+)\sat\s.+\:(\d+)/
      stderr = output.stderr
      match = regex.exec(stderr)
      if match?
        # Success!
        message = match[1]
        line    = match[2] - 1
      else
        # We failed, at least show the message without line number information
        message = stderr.replace("===SORRY!===\n", "")
        line    = 0

      # The error message is for the whole line
      colEnd = textEditor.getBuffer().lineLengthForRow(line)

      # Return the message to atom lint plugin
      return [
        type: 'Error',
        text: message,
        range:[[line, 0], [line, colEnd]],
        filePath: textEditor.getPath()
      ]
