# a +2 b +3 c +4 d = 30

class Chromosome

  # ( a b c d ) -> chromosome

  factors: {
    a: 1
    b: 2
    c: 2
    d: 4   
  }

  equals: 30
  minValue: 0
  maxValue: 30
  # only to save index where (and if) the chromosome was operated
  crossoverPoint: null
  mutationPoint: null

  # array with gens
  code: null 

  constructor: ->
    @code = Array(Object.keys(@factors).length)
    for i in [1..@code.length]
      @code[i-1] = @randomNumberForVariable()

  clone: ->
    c = new Chromosome()
    for key of @
      if Object.prototype.hasOwnProperty.call(@,key)
        c[key] = @[key]
    c.code = @code.slice()
    return c


  randomNumberForVariable: ->
    # we restrict here the number between 0 and 30
    return Math.round((Math.random()*@maxValue)+@minValue)

  evaluate: ->
    #F_obj[1] = Abs(( 12 + 2*05 + 3*23 + 4*08 ) - 30)
    sum = 0
    @code.forEach (value, i) =>
      factor = @factors[Object.keys(@factors)[i]]
      sum += value * factor
    return Math.abs(sum - @equals)

  fitness: ->
    # the fittest chromosomes have higher probability to be selected for the next generation
    return 1 / ( 1 + @evaluate() ) 

  toString: (marker = '', index = 0, offset = 0)  ->
    # returns a nicer to read function string
    # ↓
    code = @code.slice() # copy array
    if marker
      code.splice(index, 0, marker)
      "( #{code.join(' ')} )"
    else
      "( #{code.join(' ')} )"

  asObjectiveFunction: (usingNumericValues = true) ->
    sum = []
    i = 0
    for name of @factors
      value = if usingNumericValues then @code[i] else name
      sum.push("(#{@factors[name]} * #{value})")
      i++
    return "#{sum.join(' + ')} - #{@equals}"

  probability: (totalFitness) ->
    # P = Fitness / Total
    return @fitness() / totalFitness

  randomCrossoverPoint: (length = @code.length) ->
    # is between 1 and length-2
    # 'a' | 'b' | 'c' | 'd' | 'e'  -> | possible crossover point
    # between 0 and 2 for [a,b,c] 
    Math.round((Math.random()*(length)))

  createDescendantBySingleCrossoverPoint: (secondChromosome, k = null) ->
    if k is null
      k = @randomCrossoverPoint()
    code = @code.slice(0, k).concat(secondChromosome.code.slice(k))
    c = new Chromosome()
    c.code = code
    c.crossoverPoint = k
    return c
    #@createDescendantByCrossoverPoints(k, secondChromosome)

class SolvingCombinationWithGeneticAlgorithm

  numberOfChromosomes: 6

  population: []
  parents: []
  pairs: []
  selectedParentsIndex: []
  crossoverRate: 0.25
  mutationRate: 0.1

  constructor: (options = {}) ->
    # apply options
    for attr of options
      @[attr] = options[attr]
    @population = []
    @parents = []
    @pairs = []
    @selectedParentsIndex = []
    return @


  initPopulation: ->
    @population = for i in [0..@numberOfChromosomes-1]
      c = new Chromosome()
      c.pos = i
      c
    return @

  evaluate: ->
    for chromosome in @population
      chromosome.evaluate()

  fitness: ->
    for chromosome in @population
      chromosome.fitness()

  totalFitness: ->
    @fitness().reduce (prev, curr, i, array) ->
      prev + curr

  probabilities: ->
    totalFitness = @totalFitness()
    for chromosome in @population
      chromosome.probability(totalFitness)


  cumulativeProbability: ->
    probabilities = @probabilities()
    probs = []
    probabilities.forEach (prob, i) ->
      cprob = if i>0 then probs[i-1] + prob else probabilities[0]
      probs.push(cprob)
    return probs

  selectNextGenerationByRouletteWheel: (randomNumbers = @randomNumbers()) ->
    nextGeneration = []
    cumulativeProbabilities = @cumulativeProbability()
    chromosomes = @population
    for randomProb, i in randomNumbers
      # initially select first
      winner = chromosomes[0]
      for j in [0..cumulativeProbabilities.length-2]
        if randomProb > cumulativeProbabilities[j] and randomProb <= cumulativeProbabilities[j+1]
          winner = chromosomes[j+1]
          break
      winner.pos = i
      nextGeneration.push(winner)
    nextGeneration

  selectPairsByCrossoverRate: (crossoverRate = @crossoverRate) ->
    parents = []
    r = []
    rMap = {}
    pairs = []
    @selectedParents = []
    # R[1] = 0.191
    # R[2] = 0.259
    # R[3] = 0.760
    # …
    indexes = []
    for chromosome, i in @population
      randomR = Math.random() # between 0 and 1
      if randomR < crossoverRate
        parents.push(chromosome)
        # @selectedParentsIndex.push(i)
        @selectedParents.push(chromosome)
        r.push(randomR)
        rMap[randomR] = { chromosome, i }
    r.sort()
    @parents = parents
    parents = @parents.slice() # copy array
    j = @population.length
    for randomR in r
      #              parent#1          parent#2
      parent_1 = parents.shift()
      parent_2 = rMap[randomR].chromosome
      pair = [ parent_1, parent_2 ]
      pairs.push(pair)
      

    return @pairs = pairs

  singlepointCrossover: (pairs = @pairs) ->
    children = []
    children = for pair in pairs
      pair[0].createDescendantBySingleCrossoverPoint(null, pair[1])
    return children
      
  assignChildrenToPopulation: (children) ->
    for child in children
      @population[child.pos] = child
    @population

  mutatePopulation: (mutationRate = @mutationRate) ->
    totalGen = @population[0].code.length * @population.length
    numberOfMutations = mutationRate * totalGen
    for chromosome, i in @population
      for gene, j in chromosome.code
        rand = (Math.random()*(totalGen-1))+1
        if rand < numberOfMutations
          # which gene should be mutate?
          pos = Math.floor(Math.random()*chromosome.code.length)
          chromosome.mutationPoint = j
          chromosome.code[j] = chromosome.randomNumberForVariable()
    @population


  round: (number, decimal = 10000) ->
    Math.round(number*decimal)/decimal

  randomNumbers: ->
    for chromosome in @population
      Math.random()


window.SolvingCombinationWithGeneticAlgorithm = SolvingCombinationWithGeneticAlgorithm
window.Chromosome = Chromosome


