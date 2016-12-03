should = require 'should'
path = require 'path'
fs = require 'fs'
tmp = require 'tmp'

standfordSimpleNlpModule = require '../index'
StanfordSimpleNLP = standfordSimpleNlpModule.StanfordSimpleNLP


touch = (path) ->
  fs.closeSync fs.openSync(path, 'w')


describe 'standfordSimpleNlpModule', ->

  describe 'StandordSimpleNLP', ->
    stanfordSimpleNLP = new StanfordSimpleNLP()

    describe '.loadPipeline(...)', ->
      it 'should be done', (done) ->
        stanfordSimpleNLP.loadPipeline (err) ->
          should.not.exist err
          done()

    describe '.loadPipelineSync(...)', ->
      it 'should be done', ->
        stanfordSimpleNLP.loadPipelineSync()

    describe '.process(...)', ->
      it 'should be done', (done) ->
        stanfordSimpleNLP.process 'Hello, Sydney! I am Austin.', (err, result) ->
          should.not.exist err
          should.exist result
          done()

  describe 'new StandordSimpleNLP() with custom path', ->
    stanfordSimpleNLP = new StanfordSimpleNLP(path: 'jar')

    describe '.loadPipeline(...)', ->
      it 'should be done', (done) ->
        stanfordSimpleNLP.loadPipeline (err) ->
          should.not.exist err
          done()

  describe 'new StandordSimpleNLP() with wrong path', ->
    it 'should fail', ->
      should.throws ->
        new StanfordSimpleNLP(path: 'doesnt-exist')
      , /not found/

  describe 'new StandordSimpleNLP() with multiple versions of corenlp', ->
    it 'should fail', (done) ->
      tmp.dir {unsafeCleanup: true}, (err, dir) ->
        throw err if err?

        # takes advantage of the fact that the name of the
        # first required jar has a wildcard pattern.
        # otherwise, we'd need to `touch` preceding jars first.
        touch path.join(dir, 'ejml-1.0.jar')
        touch path.join(dir, 'ejml-2.0.jar')

        should.throws ->
          new StanfordSimpleNLP(path: dir)
        , /more than one version/

        done()
