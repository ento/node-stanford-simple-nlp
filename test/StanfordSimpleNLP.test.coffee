should = require 'should'
path = require 'path'
fs = require 'fs'
tmp = require 'tmp'
java = require 'java'

defaultClassPathLength = java.classpath.length
standfordSimpleNlpModule = require '../index'
StanfordSimpleNLP = standfordSimpleNlpModule.StanfordSimpleNLP


touch = (path) ->
  fs.closeSync fs.openSync(path, 'w')


describe 'standfordSimpleNlpModule', ->

  describe 'StandordSimpleNLP', ->
    stanfordSimpleNLP = null

    beforeEach ->
      stanfordSimpleNLP = new StanfordSimpleNLP()
      java.classpath.pop() while java.classpath.length > defaultClassPathLength

    describe '.loadPipeline(...)', ->
      it 'should be done', (done) ->
        stanfordSimpleNLP.loadPipeline (err) ->
          should.not.exist err
          done()

      it 'should load jars from custom path', (done) ->
        stanfordSimpleNLP.loadPipeline {path: 'jar'}, (err) ->
          should.not.exist err
          done()

      it 'should fail if required jar is not found', (done) ->
        stanfordSimpleNLP.loadPipeline {path: 'doesnt-exist'}, (err) ->
          err.should.match /not found/
          done()

      it 'should fail if multiple versions are found', (done) ->
        tmp.dir {unsafeCleanup: true}, (err, dir) ->
          throw err if err?

          # takes advantage of the fact that the name of the
          # first required jar has a wildcard pattern.
          # otherwise, we'd need to `touch` preceding jars first.
          touch path.join(dir, 'ejml-1.0.jar')
          touch path.join(dir, 'ejml-2.0.jar')

          stanfordSimpleNLP.loadPipeline {path: dir}, (err) ->
            err.should.match /more than one version/
            done()

    describe '.loadPipelineSync(...)', ->
      it 'should be done', ->
        stanfordSimpleNLP.loadPipelineSync()

      it 'should load jars from custom path', ->
        stanfordSimpleNLP.loadPipelineSync path: 'jar'

      it 'should fail if required jar is not found', ->
        should.throws ->
          stanfordSimpleNLP.loadPipelineSync path: 'doesnt-exist'
        , /not found/

      it 'should fail if multiple versions are found', (done) ->
        tmp.dir {unsafeCleanup: true}, (err, dir) ->
          throw err if err?

          # takes advantage of the fact that the name of the
          # first required jar has a wildcard pattern.
          # otherwise, we'd need to `touch` preceding jars first.
          touch path.join(dir, 'ejml-1.0.jar')
          touch path.join(dir, 'ejml-2.0.jar')

          should.throws ->
            stanfordSimpleNLP.loadPipelineSync path: dir
          , /more than one version/

          done()

    describe '.process(...)', ->
      it 'should be done', (done) ->
        stanfordSimpleNLP.loadPipelineSync()
        stanfordSimpleNLP.process 'Hello, Sydney! I am Austin.', (err, result) ->
          should.not.exist err
          should.exist result
          done()
