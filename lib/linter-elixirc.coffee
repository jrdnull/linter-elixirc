linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
{BufferedProcess} = require 'atom'
os = require 'os'

class LinterElixirc extends Linter
  # The syntax that the linter handles.
  @syntax: 'source.elixir'

  # A string or array containing the command line (with args) used to lint.
  cmd: "elixirc -o #{os.tmpdir()} --warnings-as-errors"

  # A regex pattern used to extract information from the executable's output.
  regex: '^[^ ].+:(?<line>\\d+): (((?<warning>warning: ))|(?<error>))(?<message>.+)'

  regexFlags: 'm'

  linterName: 'elixirc'

  executablePath: null

  constructor: (editor)->
    super(editor)

    atom.config.observe 'linter-elixirc.elixircExecutablePath', =>
      @executablePath = atom.config.get 'linter-elixirc.elixircExecutablePath'

  destroy: ->
    atom.config.unobserve 'linter-elixirc.elixircExecutablePath'

  # Public: Primary entry point for a linter, executes the linter then calls
  #         processMessage in order to handle standard output
  #
  # Overridden as elixirc is outputting warnings to stderr
  lintFile: (filePath, callback) ->
    # build the command with arguments to lint the file
    {command, args} = @getCmdAndArgs(filePath)

    # options for BufferedProcess, same syntax with child_process.spawn
    options = {cwd: @cwd}

    data = []

    stdout = (output) ->
      data += output

    stderr = (output) ->
      data += output

    exit = =>
      @processMessage data, callback

    process = new BufferedProcess({command, args, options,
                                  stdout, stderr, exit})

    # Don't block UI more than 5seconds, it's really annoying on big files
    timeout_s = 5
    setTimeout ->
      process.kill()
    , timeout_s * 1000

module.exports = LinterElixirc
