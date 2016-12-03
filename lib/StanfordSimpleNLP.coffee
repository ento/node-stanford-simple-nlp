path = require 'path'
glob = require 'glob'
lodash = require 'lodash'
java = require 'java'
xml2js = require 'xml2js'

java.options.push '-Xmx4g'


getParsedTree = require './getParsedTree'


class StanfordSimpleNLP
  defaultOptions:
    annotators: [
      'tokenize'
      'ssplit'
      'pos'
      'lemma'
      'ner'
      'parse'
      'dcoref'
    ]

  requiredJars: [
    'ejml-*.jar'
    'joda-time.jar'
    'jollyday.jar'
    'xom.jar'
    'stanford-corenlp-*-models.jar'
    'stanford-corenlp-*+(0|1|2|3|4|5|6|7|8|9).jar'
  ]

  constructor: (options, callback) ->
    if typeof options is 'function'
      callback = options
      options = null

    if callback? and typeof callback is 'function'
      @loadPipeline options, callback


  populateJavaClasspath: (maybeJarDir, callback) ->
    jarDir = if maybeJarDir then path.resolve maybeJarDir else path.join __dirname, '..', 'jar'
    unless callback?
      callback = (err) ->
        throw err if err?
    for requiredJar in @requiredJars
      foundJars = glob.sync requiredJar, cwd: jarDir
      if foundJars.length == 0
        return callback new Error "Required jar #{requiredJar} not found in #{jarDir}: did you download and extract Stanford CoreNLP?"
      else if foundJars.length > 1
        return callback new Error "There are more than one version of #{requiredJar} in #{jarDir}: please remove the ones you don't want to use"
      else
        java.classpath.push path.join jarDir, foundJars[0]

    callback()

  loadPipeline: (options, callback) ->
    if typeof options is 'function'
      callback = options
      options = null

    options = lodash.assign {}, @defaultOptions, options
    if not options.annotators? or not Array.isArray(options.annotators)
      return callback new Error 'No annotators.'

    @populateJavaClasspath options.path, (err) =>
      return callback err if err?

      java.newInstance 'java.util.Properties', (err, properties) =>
        properties.setProperty 'annotators', options.annotators.join(', '), (err) =>
          return callback err  if err?

          java.newInstance 'edu.stanford.nlp.pipeline.StanfordCoreNLP', properties, (err, pipeline) =>
            return callback err  if err?

            @pipeline = pipeline
            callback null


  loadPipelineSync: (options) ->
    options = lodash.assign {}, @defaultOptions, options

    @populateJavaClasspath options.path
    properties = java.newInstanceSync 'java.util.Properties'
    properties.setPropertySync 'annotators', options.annotators.join(', ')
    @pipeline = java.newInstanceSync 'edu.stanford.nlp.pipeline.StanfordCoreNLP', properties


  process: (text, options, callback) ->
    if typeof options is 'function'
      callback = options
      options =
        xml:
          explicitRoot: false
          explicitArray: false
          attrkey: '$'

    return callback new Error 'Load a pipeline first.'  if not @pipeline?

    @pipeline.process text, (err, annotation) =>
      return callback err  if err?

      java.newInstance 'java.io.StringWriter', (err, stringWriter) =>
        return callback err  if err?

        @pipeline.xmlPrint annotation, stringWriter, (err) =>
          return callback err  if err?

          stringWriter.toString (err, xmlString) =>
            return callback err  if err?

            xml2js.parseString xmlString, options.xml, (err, result) =>
              return callback err  if err?

              # add parsedTree.
              try
                sentences = result?.document?.sentences?.sentence
                if typeof sentences is 'object' and Array.isArray sentences
                  for sentence in result?.document?.sentences?.sentence
                    sentence.parsedTree = getParsedTree sentence?.parse
                else
                  sentences.parsedTree = getParsedTree sentences?.parse
              catch err
                return callback err

              callback null, result



module.exports = StanfordSimpleNLP
